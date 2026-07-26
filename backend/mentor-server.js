require('dotenv').config();
const WebSocket = require('ws');
const { createClient } = require('@supabase/supabase-js');

const GEMINI_API_KEY = process.env.GEMINI_API_KEY;
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

async function fetchOmniContext(userId) {
    try {
        const [profileRes, statsRes, dueFlashcardsRes] = await Promise.all([
            supabase.from('profiles').select('*').eq('id', userId).single(),
            supabase.from('user_stats').select('*').eq('id', userId).single(),
            supabase.from('flashcards').select('id').eq('user_id', userId).lte('next_review_date', new Date().toISOString()),
        ]);

        const currentDay = statsRes.data?.current_day || 1;

        const [todayTasksRes, doneTasksRes, learnedWordsRes] = await Promise.all([
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
            watchedVideoSummaries,
        };
    } catch (err) {
        console.error('fetchOmniContext error:', err.message);
        return null;
    }
}

function buildSystemPrompt(ctx) {
    const name = ctx?.profile?.full_name || 'زبان‌آموز';
    const level = ctx?.profile?.english_level || 'نامشخص';
    const score = ctx?.stats?.score ?? 0;
    const streak = ctx?.stats?.streak_days ?? 0;
    const day = ctx?.currentDay ?? 1;

    const todayTasksStr = (ctx?.todayTasks || [])
        .map((t) => `- (${t.task_type}) ${t.title}`)
        .join('\n') || 'هیچ تسکی برای امروز ثبت نشده.';

    const completedStr = (ctx?.completedTasks || [])
        .map((t) => `- روز ${t.day_number}: (${t.task_type}) ${t.title}`)
        .join('\n') || 'هنوز هیچ تسکی رو کامل نکرده.';

    const learnedWordsStr = (ctx?.learnedWords || []).join('، ') || 'هنوز لغتی به فلش‌کارت‌هاش اضافه نکرده.';

    const videosStr = (ctx?.watchedVideoSummaries || [])
        .map((v) => `- ${v.title || v.video_id}: ${v.summary || 'بدون خلاصه'}`)
        .join('\n') || 'ویدیوی تحلیل‌شده‌ای برای امروز موجود نیست.';

    return `You are an elite, warm, and encouraging TOEFL/IELTS speaking mentor talking live with your student in English (respond in English unless they switch to Persian).

STUDENT PROFILE
- Name: ${name}
- Level: ${level}
- Current day in program: ${day}
- Total score: ${score} XP
- Current streak: ${streak} days
- Words due for flashcard review: ${ctx?.pendingVocabCount ?? 0}

TODAY'S PLAN (day ${day})
${todayTasksStr}

RECENTLY COMPLETED TASKS (most recent first)
${completedStr}

RECENTLY LEARNED VOCABULARY (already in their flashcard deck)
${learnedWordsStr}

TODAY'S VIDEO LESSON(S)
${videosStr}

INSTRUCTIONS
- Use the above naturally in conversation — e.g. congratulate streaks, reference words they've already learned instead of re-teaching them, ask about todays video/topic, nudge them toward due flashcards if there are many.
- Never invent facts about their progress that aren't listed above.
- Keep answers natural, concise, and conversational — this is a live voice call, not an essay.
- CRITICAL AUDIO RULE: You MUST speak in extremely short, bite-sized bursts (1 to 3 sentences maximum). DO NOT give long monologues. Pause frequently and ask short follow-up questions to keep the conversation perfectly real-time and ping-pong style.`;
}

wss.on('connection', (ws) => {
    const sessionId = generateSessionId();
    console.log(`\n🟢 [Session: ${sessionId}] CLIENT_CONNECTED`);

    let geminiWs = null;
    let isSetupComplete = false;
    let turnCompleteSent = false;
    let authenticatedUserId = null;

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
            console.log(`🔄 [Session: ${sessionId}] SETUP_RECEIVED for user ${authenticatedUserId}`);
            const omniContext = await fetchOmniContext(authenticatedUserId);
            initializeGemini(ws, omniContext, sessionId);
            return;
        }

        if (payload.type === 'audio' && isSetupComplete && geminiWs?.readyState === WebSocket.OPEN) {
            turnCompleteSent = false;
            geminiWs.send(JSON.stringify({
                realtimeInput: { mediaChunks: [{ mimeType: 'audio/pcm;rate=16000', data: payload.data }] }
            }));
        }
    });

    function initializeGemini(clientWs, ctx, sid) {
        if (geminiWs && geminiWs.readyState === WebSocket.OPEN) geminiWs.close();
        isSetupComplete = false;
        turnCompleteSent = false;

        const url = `wss://generativelanguage.googleapis.com/ws/google.ai.generativelanguage.v1beta.GenerativeService.BidiGenerateContent?key=${GEMINI_API_KEY}`;
        geminiWs = new WebSocket(url);

        geminiWs.on('open', () => {
            console.log(`🚀 [Session: ${sid}] GEMINI_OPEN -> Sending Setup`);
            const systemPrompt = buildSystemPrompt(ctx);

            geminiWs.send(JSON.stringify({
                setup: {
                    model: 'models/gemini-2.5-flash-native-audio-latest',
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
                        for (let part of sc.modelTurn.parts) {
                            if (part.inlineData && clientWs.readyState === WebSocket.OPEN) {
                                clientWs.send(JSON.stringify({ type: 'audio', data: part.inlineData.data }));
                            }
                        }
                    }

                    if (sc.turnComplete || sc.generationComplete) {
                        if (!turnCompleteSent) {
                            console.log(`🏁 [Session: ${sid}] TURN_COMPLETE`);
                            turnCompleteSent = true;
                            if (clientWs.readyState === WebSocket.OPEN) clientWs.send(JSON.stringify({ type: 'turn_complete' }));
                        }
                    }
                }
            } catch (e) {}
        });

        geminiWs.on('close', () => {
            console.log(`🔴 [Session: ${sid}] GEMINI_DISCONNECTED`);
            isSetupComplete = false;
            if (clientWs.readyState === WebSocket.OPEN) clientWs.send(JSON.stringify({ type: 'ai_disconnected' }));
        });
    }

    ws.on('close', () => {
        console.log(`🔌 [Session: ${sessionId}] CLIENT_PHYSICALLY_DISCONNECTED`);
        if (geminiWs && geminiWs.readyState === WebSocket.OPEN) geminiWs.close();
    });
});

console.log(`🚀 [NODE] THICK SERVER Architecture running on port ${PORT}`);