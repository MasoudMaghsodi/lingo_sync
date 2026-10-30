require('dotenv').config();
const WebSocket = require('ws');
const { createClient } = require('@supabase/supabase-js');
const { recordAiTelemetry, checkDailySpendBreaker } = require('./telemetry-service');
const { buildMentorLiveSystemPrompt } = require('./context-builder');

const GEMINI_API_KEY = process.env.GEMINI_API_KEY;
const GEMINI_LIVE_MODEL = process.env.GEMINI_LIVE_MODEL || 'models/gemini-3.8-live';
const SUPABASE_URL = process.env.SUPABASE_URL;
const SUPABASE_SERVICE_KEY = process.env.SUPABASE_SERVICE_KEY;

const supabase = createClient(SUPABASE_URL, SUPABASE_SERVICE_KEY, {
    auth: { persistSession: false },
    realtime: { transport: WebSocket }
});

const PORT = 3001;
const wss = new WebSocket.Server({ port: PORT });
const generateSessionId = () => Math.random().toString(36).substring(2, 8).toUpperCase();

// همون regex استخراج videoId که ai-server.js استفاده می‌کنه — این‌جا هم لازمش داریم
// تا بشه فهمید تسک‌های ویدیویی امروز به کدوم video_analysis وصل می‌شن.
function extractVideoId(url) {
    const regExp = /^.*((youtu.be\/)|(v\/)|(\/u\/\w\/)|(embed\/)|(watch\?))\??v?=?([^#&?]*).*/;
    const match = url.match(regExp);
    return (match && match[7].length === 11) ? match[7] : null;
}

// 🚀 تایید هویت واقعی: کلاینت باید accessToken سشن Supabase خودش رو بفرسته.
// دیگه به هیچ userId خامی که کلاینت ادعا می‌کنه اعتماد نمی‌کنیم — چون این کلاینت
// از service_role استفاده می‌کنه و RLS رو دور می‌زنه، بدون این چک هرکسی با دونستن
// UUID یه کاربر می‌تونست کل پروفایل/امتیاز/تسک‌هاش رو بخونه.
async function verifyUser(accessToken) {
    if (!accessToken) return null;
    try {
        const { data, error } = await supabase.auth.getUser(accessToken);
        if (error || !data?.user) return null;
        return data.user;
    } catch (_) {
        return null;
    }
}

async function checkVoiceQuota(userId) {
    if (!userId) return { allowed: true, balance: 900 };
    try {
        const { data, error } = await supabase.rpc('get_user_quota', { p_user_id: userId });
        if (!error && data) {
            return {
                allowed: (data.voice_seconds_balance > 0 || data.tier === 'unlimited'),
                balance: data.voice_seconds_balance,
                tier: data.tier
            };
        }
    } catch (_) {}
    return { allowed: true, balance: 900 };
}

async function decrementVoiceQuota(userId, seconds) {
    if (!userId || seconds <= 0) return;
    try {
        await supabase.rpc('decrement_voice_seconds', { p_user_id: userId, p_seconds: seconds });
    } catch (_) {}
}

async function fetchOmniContext(userId) {
    try {
        const [profileRes, statsRes, dueFlashcardsRes] = await Promise.all([
            supabase.from('profiles').select('*').eq('id', userId).single(),
            supabase.from('user_stats').select('*').eq('id', userId).single(),
            supabase.from('flashcards').select('id').eq('user_id', userId).lte('next_review_date', new Date().toISOString()),
        ]);

        const currentDay = statsRes.data?.current_day || 1;

        const [todayTasksRes, doneTasksRes, learnedWordsRes, dueWordsRes, errorGenomeRes] = await Promise.all([
            supabase.from('daily_tasks').select('id, title, task_type, video_url').eq('day_number', currentDay),
            // آخرین ۱۵ تسکی که کاربر واقعاً انجام داده — نه فقط تسک‌های امروز
            supabase.from('user_task_progress')
                .select('completed_at, daily_tasks(title, task_type, day_number)')
                .eq('user_id', userId)
                .order('completed_at', { ascending: false })
                .limit(15),
            // آخرین ۲۰ لغتی که به فلش‌کارت‌هاش اضافه شده
            supabase.from('flashcards')
                .select('global_dictionary(word)')
                .eq('user_id', userId)
                .order('created_at', { ascending: false })
                .limit(20),
            // ۳ لغت مرور روز برای Active Recall Raid
            supabase.from('flashcards')
                .select('global_dictionary(word)')
                .eq('user_id', userId)
                .lte('next_review_date', new Date().toISOString())
                .limit(3),
            // ۳ الگوی خطای اخیر برای Error Genome
            supabase.from('user_error_genome')
                .select('category, verbatim_quote, corrected_version')
                .eq('user_id', userId)
                .order('last_seen_at', { ascending: false })
                .limit(3)
                .catch(() => ({ data: [] }))
        ]);

        // از بین تسک‌های امروز، اونایی که ویدیویی‌ان رو با تحلیل ذخیره‌شده‌شون جفت کن
        // تا استاد بدونه دقیقاً امروز چی قراره ببینه/دیده.
        const videoTasks = (todayTasksRes.data || []).filter((t) => t.video_url);
        let watchedVideoSummaries = [];
        if (videoTasks.length > 0) {
            const videoIds = videoTasks.map((t) => extractVideoId(t.video_url)).filter(Boolean);
            if (videoIds.length > 0) {
                const { data: analyses } = await supabase
                    .from('video_analysis')
                    .select('video_id, title, summary')
                    .in('video_id', videoIds);
                watchedVideoSummaries = analyses || [];
            }
        }

        return {
            profile: profileRes.data || {},
            stats: statsRes.data || {},
            currentDay,
            todayTasks: todayTasksRes.data || [],
            completedTasks: (doneTasksRes.data || []).map((r) => r.daily_tasks).filter(Boolean),
            pendingVocabCount: dueFlashcardsRes.data?.length || 0,
            learnedWords: (learnedWordsRes.data || []).map((r) => r.global_dictionary?.word).filter(Boolean),
            dueWords: (dueWordsRes?.data || []).map((r) => r.global_dictionary?.word).filter(Boolean),
            errorPatterns: (errorGenomeRes?.data || []).map((e) => `${e.category}: "${e.verbatim_quote}" -> "${e.corrected_version}"`),
            watchedVideoSummaries,
        };
    } catch (err) {
        console.error('fetchOmniContext error:', err.message);
        return null;
    }
}


const SESSION_HARD_CAP_SEC = 900;       // 15 minutes hard cap
const SESSION_WARNING_SEC = 840;        // 14 minutes warning
const VAD_SILENCE_PAUSE_SEC = 10;       // 10s silence pause
const VAD_SILENCE_DISCONNECT_SEC = 30;  // 30s silence disconnect

wss.on('connection', (ws) => {
    const sessionId = generateSessionId();
    console.log(`\n🟢 [Session: ${sessionId}] CLIENT_CONNECTED`);

    let geminiWs = null;
    let isSetupComplete = false;
    let turnCompleteSent = false;
    let silenceTimer = null;
    let authenticatedUserId = null;
    let sessionStartTime = null;
    let audioInChunks = 0;
    let audioOutChunks = 0;
    let capWarningSent = false;
    let sessionCapTimer = null;
    let vadPauseTimer = null;
    let vadDisconnectTimer = null;

    function resetVadTimers() {
        clearTimeout(vadPauseTimer);
        clearTimeout(vadDisconnectTimer);

        vadPauseTimer = setTimeout(() => {
            if (ws.readyState === WebSocket.OPEN && isSetupComplete) {
                console.log(`⏸️ [Session: ${sessionId}] 10s silence detected -> sending vad_pause`);
                ws.send(JSON.stringify({ type: 'vad_pause', message: 'مکالمه به دلیل ۱۰ ثانیه سکوت موقتاً متوقف شد.' }));
            }
        }, VAD_SILENCE_PAUSE_SEC * 1000);

        vadDisconnectTimer = setTimeout(() => {
            if (ws.readyState === WebSocket.OPEN) {
                console.log(`⏹️ [Session: ${sessionId}] 30s silence detected -> sending vad_disconnect`);
                ws.send(JSON.stringify({ type: 'vad_disconnect', message: 'اتصال به دلیل ۳۰ ثانیه عدم فعالیت قطع شد.' }));
                ws.close();
            }
        }, VAD_SILENCE_DISCONNECT_SEC * 1000);
    }

    function recordSessionTelemetry() {
        if (sessionCapTimer) clearInterval(sessionCapTimer);
        if (vadPauseTimer) clearTimeout(vadPauseTimer);
        if (vadDisconnectTimer) clearTimeout(vadDisconnectTimer);

        if (authenticatedUserId && sessionStartTime) {
            const durationSec = Math.max(1, Math.round((Date.now() - sessionStartTime) / 1000));
            const estimatedAudioInSec = Math.min(durationSec, Math.round(audioInChunks * 0.1 * 10) / 10);
            const estimatedAudioOutSec = Math.min(durationSec, Math.round(audioOutChunks * 0.1 * 10) / 10);
            recordAiTelemetry({
                supabase,
                module: 'live_voice',
                model: GEMINI_LIVE_MODEL,
                fallbackTriggered: false,
                tokensIn: Math.round(estimatedAudioInSec * 25),
                tokensOut: Math.round(estimatedAudioOutSec * 25),
                audioSecondsIn: estimatedAudioInSec,
                audioSecondsOut: estimatedAudioOutSec,
                latencyMs: durationSec * 1000,
                userId: authenticatedUserId
            }).catch(() => {});

            // Atomic decrement in database
            decrementVoiceQuota(authenticatedUserId, durationSec);
            sessionStartTime = null;
        }
    }

    ws.on('message', async (data) => {
        let payload;
        try {
            payload = JSON.parse(data.toString());
        } catch (_) {
            return;
        }

        if (payload.type === 'ping') {
            ws.send(JSON.stringify({ type: 'pong' }));
            return;
        }

        if (payload.type === 'setup') {
            const user = await verifyUser(payload.accessToken);
            if (!user) {
                console.log(`⛔ [Session: ${sessionId}] AUTH_REJECTED`);
                ws.send(JSON.stringify({ type: 'ai_disconnected' }));
                ws.close();
                return;
            }

            authenticatedUserId = user.id;

            // Check voice quota balance
            const quota = await checkVoiceQuota(authenticatedUserId);
            if (!quota.allowed) {
                console.log(`⛔ [Session: ${sessionId}] INSUFFICIENT_VOICE_QUOTA for user ${authenticatedUserId}`);
                ws.send(JSON.stringify({
                    type: 'ai_disconnected',
                    error: 'اعتبار مکالمه صوتی روزانه شما به پایان رسیده است.'
                }));
                ws.close();
                return;
            }

            // Daily spend circuit breaker check ($1.50)
            const spendCheck = await checkDailySpendBreaker({
                supabase,
                userId: authenticatedUserId,
                dailyLimitUsd: 1.50
            });
            if (!spendCheck.allowed) {
                console.log(`⛔ [Session: ${sessionId}] DAILY_SPEND_EXCEEDED for user ${authenticatedUserId}`);
                ws.send(JSON.stringify({
                    type: 'ai_disconnected',
                    error: 'سقف مصرف روزانه هوش مصنوعی شما به پایان رسیده است.'
                }));
                ws.close();
                return;
            }

            sessionStartTime = Date.now();
            console.log(`🔄 [Session: ${sessionId}] SETUP_RECEIVED for user ${authenticatedUserId}`);
            const omniContext = await fetchOmniContext(authenticatedUserId);
            initializeGemini(ws, omniContext, sessionId);
            return;
        }

        if (payload.type === 'audio' && isSetupComplete && geminiWs?.readyState === WebSocket.OPEN) {
            turnCompleteSent = false;
            audioInChunks++;
            resetVadTimers();

            geminiWs.send(JSON.stringify({
                realtimeInput: { mediaChunks: [{ mimeType: 'audio/pcm;rate=16000', data: payload.data }] }
            }));
            clearTimeout(silenceTimer);
            silenceTimer = setTimeout(() => {
                if (geminiWs?.readyState === WebSocket.OPEN && !turnCompleteSent) {
                    console.log(`⏱️ [Session: ${sessionId}] User pause detected -> triggering turnComplete`);
                    geminiWs.send(JSON.stringify({ clientContent: { turnComplete: true } }));
                }
            }, 800);
        }
    });

    function initializeGemini(clientWs, ctx, sid) {
        if (geminiWs && geminiWs.readyState === WebSocket.OPEN) geminiWs.close();
        isSetupComplete = false;
        turnCompleteSent = false;

        const url = `wss://generativelanguage.googleapis.com/ws/google.ai.generativelanguage.v1beta.GenerativeService.BidiGenerateContent?key=${GEMINI_API_KEY}`;
        geminiWs = new WebSocket(url);

        geminiWs.on('open', () => {
            console.log(`🚀 [Session: ${sid}] GEMINI_OPEN -> Sending Setup (model: ${GEMINI_LIVE_MODEL})`);
            const systemPrompt = buildMentorLiveSystemPrompt(ctx);

            geminiWs.send(JSON.stringify({
                setup: {
                    model: GEMINI_LIVE_MODEL,
                    generationConfig: { responseModalities: ['AUDIO'], speechConfig: { voiceConfig: { prebuiltVoiceConfig: { voiceName: 'Aoede' } } } },
                    systemInstruction: { parts: [{ text: systemPrompt }] }
                }
            }));
        });

        geminiWs.on('message', (geminiData) => {
            try {
                const response = JSON.parse(geminiData.toString());

                if (response.setupComplete) {
                    console.log(`✅ [Session: ${sid}] SETUP_COMPLETE`);
                    isSetupComplete = true;
                    resetVadTimers();

                    // Start session hard-cap monitor (15 minutes)
                    if (sessionCapTimer) clearInterval(sessionCapTimer);
                    sessionCapTimer = setInterval(() => {
                        if (!sessionStartTime || !clientWs || clientWs.readyState !== WebSocket.OPEN) return;
                        const elapsedSec = Math.round((Date.now() - sessionStartTime) / 1000);
                        if (elapsedSec >= SESSION_WARNING_SEC && !capWarningSent) {
                            capWarningSent = true;
                            console.log(`⚠️ [Session: ${sid}] 14-min session warning sent`);
                            clientWs.send(JSON.stringify({ type: 'session_warning', message: 'یک دقیقه از جلسه مکالمه شما باقی مانده است.' }));
                        }
                        if (elapsedSec >= SESSION_HARD_CAP_SEC) {
                            console.log(`⏱️ [Session: ${sid}] 15-min hard cap reached -> closing`);
                            clientWs.send(JSON.stringify({
                                type: 'session_ended',
                                reason: 'time_limit',
                                message: 'جلسه ۱۵ دقیقه‌ای شما به پایان رسید. خسته نباشید!'
                            }));
                            clearInterval(sessionCapTimer);
                            clientWs.close();
                        }
                    }, 1000);

                    if (clientWs.readyState === WebSocket.OPEN) clientWs.send(JSON.stringify({ type: 'ready' }));
                    return;
                }

                if (response.serverContent) {
                    const sc = response.serverContent;

                    if (sc.interrupted) {
                        if (clientWs.readyState === WebSocket.OPEN) clientWs.send(JSON.stringify({ type: 'interrupt' }));
                        return;
                    }

                    if (sc.modelTurn) {
                        clearTimeout(silenceTimer);
                        clearTimeout(vadPauseTimer);
                        clearTimeout(vadDisconnectTimer);

                        for (let part of sc.modelTurn.parts) {
                            if (part.inlineData && clientWs.readyState === WebSocket.OPEN) {
                                audioOutChunks++;
                                clientWs.send(JSON.stringify({ type: 'audio', data: part.inlineData.data }));
                            }
                        }
                    }

                    if (sc.turnComplete || sc.generationComplete) {
                        if (!turnCompleteSent) {
                            console.log(`🏁 [Session: ${sid}] TURN_COMPLETE`);
                            turnCompleteSent = true;
                            resetVadTimers();
                            if (clientWs.readyState === WebSocket.OPEN) clientWs.send(JSON.stringify({ type: 'turn_complete' }));
                        }
                    }
                }
            } catch (e) {}
        });

        geminiWs.on('close', () => {
            console.log(`🔴 [Session: ${sid}] GEMINI_DISCONNECTED`);
            recordSessionTelemetry();
            isSetupComplete = false;
            if (clientWs.readyState === WebSocket.OPEN) clientWs.send(JSON.stringify({ type: 'ai_disconnected' }));
        });
    }

    ws.on('close', () => {
        clearTimeout(silenceTimer);
        console.log(`🔌 [Session: ${sessionId}] CLIENT_PHYSICALLY_DISCONNECTED`);
        recordSessionTelemetry();
        if (geminiWs && geminiWs.readyState === WebSocket.OPEN) geminiWs.close();
    });
});

console.log(`🚀 [NODE] THICK SERVER Architecture running on port ${PORT}`);

// Graceful Shutdown
process.on('SIGTERM', () => {
    console.log('SIGTERM signal received: closing WebSocket server');
    wss.close(() => {
        console.log('WebSocket server closed');
        process.exit(0);
    });
});