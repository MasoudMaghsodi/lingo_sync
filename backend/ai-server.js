require('dotenv').config();
const express = require('express');
const cors = require('cors');
const helmet = require('helmet');
const rateLimit = require('express-rate-limit');
const { GoogleGenerativeAI } = require('@google/generative-ai');
const { createClient } = require('@supabase/supabase-js');

const app = express();
app.set('trust proxy', 1);
app.use(helmet());
app.use(cors());
app.use(express.json());

const GEMINI_API_KEY = process.env.GEMINI_API_KEY;
const SUPABASE_URL = process.env.SUPABASE_URL;
const SUPABASE_SERVICE_KEY = process.env.SUPABASE_SERVICE_KEY;
const supabase = createClient(SUPABASE_URL, SUPABASE_SERVICE_KEY);
const genAI = new GoogleGenerativeAI(GEMINI_API_KEY);
const { recordAiTelemetry, checkDailySpendBreaker } = require('./telemetry-service');

const YT_PROXY_HOST = process.env.YT_PROXY_HOST || process.env.NL_SERVER_IP || "127.0.0.1";
const SECRET_KEY = process.env.YT_PROXY_SECRET_KEY;
if (!SECRET_KEY) {
    console.error('❌ FATAL: YT_PROXY_SECRET_KEY environment variable is not defined.');
    process.exit(1);
}

// Circuit Breaker Middleware: سقف مصرف روزانه هوش مصنوعی ($1.50 برای هر کاربر)
async function circuitBreakerMiddleware(req, res, next) {
    const userId = req.authenticatedUser?.id || req.body?.userId;
    if (userId) {
        try {
            const check = await checkDailySpendBreaker({ supabase, userId, dailyLimitUsd: 1.50 });
            if (!check.allowed) {
                return res.status(429).json({
                    error: 'سقف مصرف روزانه هوش مصنوعی ($1.50) برای حساب شما به پایان رسیده است.',
                    quota_exceeded: true,
                    todaySpendUsd: check.todaySpendUsd,
                    dailyLimitUsd: check.dailyLimitUsd
                });
            }
        } catch (_) {}
    }
    next();
}

// Rate Limiting برای جلوگیری از مصرف بی رویه سهمیه جمینای
const aiLimiter = rateLimit({
    windowMs: 15 * 60 * 1000,
    max: 60, // حداکثر 60 درخواست AI در 15 دقیقه به ازای هر IP
    message: { error: 'تعداد درخواست‌ها بیش از حد مجاز است. لطفاً چند دقیقه بعد تلاش کنید.' },
    standardHeaders: true,
    legacyHeaders: false,
});

app.use('/api/', aiLimiter);

// Middleware: اعتبارسنجی توکن کاربر یا کلید امنیتی سرور
async function verifyAuthOrSecret(req, res, next) {
    const secret = req.headers['x-secret-key'];
    if (secret && secret === SECRET_KEY) {
        return next();
    }
    const authHeader = req.headers['authorization'];
    if (authHeader && authHeader.startsWith('Bearer ')) {
        const token = authHeader.substring(7);
        try {
            const { data: { user }, error } = await supabase.auth.getUser(token);
            if (!error && user) {
                req.authenticatedUser = user;
                return next();
            }
        } catch (_) {}
    }
    return res.status(401).json({ error: 'دسترسی غیرمجاز: نیاز به لاگین یا کلید امنیتی است.' });
}

// Health Check Endpoint
app.get('/health', (req, res) => {
    res.json({
        status: 'ok',
        service: 'ai-express',
        uptime: process.uptime(),
        timestamp: new Date().toISOString(),
    });
});

const MAIN_CONTENT_MAX_TOKENS = 8192;
const VOCABULARY_MAX_TOKENS = 8192;

function extractVideoId(url) {
    const regExp = /^.*((youtu.be\/)|(v\/)|(\/u\/\w\/)|(embed\/)|(watch\?))\??v?=?([^#&?]*).*/;
    const match = url.match(regExp);
    return (match && match[7] && match[7].length === 11) ? match[7] : null;
}

function isQuotaOrRateLimitError(error) {
    const status = error?.status || error?.response?.status;
    const message = (error?.message || '').toLowerCase();
    return (
        status === 429 ||
        message.includes('quota') ||
        message.includes('rate limit') ||
        message.includes('resource_exhausted') ||
        message.includes('too many requests')
    );
}

/// 🚀 پیام خطای واقعیِ برگشتی از سرور واسط ترنسکریپت (server.js) رو
/// استخراج می‌کنه، به‌جای اینکه صرفاً یک متن ژنریک نشون بدیم — این تفاوت
/// بین "کلید امنیتی اشتباهه"، "این ویدیو زیرنویس نداره"، یا هر خطای
/// دیگه‌ای رو روشن می‌کنه. همچنین خطای شبکه‌ای در خودِ fetch (مثلاً
/// دسترس‌ناپذیر بودن سرور واسط) رو جدا از خطای HTTP غیر-200 مدیریت
/// می‌کنه، تا پیام خطا همیشه دقیق باشه.
async function fetchTranscript(videoId) {
    let transcriptRes;
    try {
        transcriptRes = await fetch(
            `http://${YT_PROXY_HOST}:3000/transcript?videoId=${videoId}&key=${SECRET_KEY}`
        );
    } catch (networkErr) {
        throw new Error(`خطا در اتصال به سرور واسط ترنسکریپت: ${networkErr.message}`);
    }

    if (!transcriptRes.ok) {
        let upstreamMessage = `HTTP ${transcriptRes.status}`;
        try {
            const errBody = await transcriptRes.json();
            if (errBody?.error) upstreamMessage = errBody.error;
        } catch (_) {
            // بدنه‌ی پاسخ JSON نبود — فقط کد وضعیت رو نگه می‌داریم.
        }
        throw new Error(`خطا در دریافت زیرنویس از سرور واسط: ${upstreamMessage}`);
    }

    return transcriptRes.json();
}

const CANDIDATE_MODELS = ['gemini-3.8-flash', 'gemini-3.6-flash', 'gemini-3.5-flash-lite', 'gemini-3.1-flash-lite'];

function withTimeout(promise, ms, label = 'Operation') {
    let timer;
    const timeoutPromise = new Promise((_, reject) => {
        timer = setTimeout(() => reject(new Error(`${label} timed out after ${ms}ms`)), ms);
    });
    return Promise.race([promise, timeoutPromise]).finally(() => clearTimeout(timer));
}

async function generateContentWithFallback(prompt, generationConfig = {}, timeoutMs = 8000, options = {}) {
    let lastError = null;
    let fallbackTriggered = false;
    const startTime = Date.now();

    for (let i = 0; i < CANDIDATE_MODELS.length; i++) {
        const modelName = CANDIDATE_MODELS[i];
        if (i > 0) fallbackTriggered = true;
        try {
            const model = genAI.getGenerativeModel({
                model: modelName,
                generationConfig,
            });
            const result = await withTimeout(
                model.generateContent(prompt),
                timeoutMs,
                `Model ${modelName}`
            );
            const responseText = result.response.text();
            const latencyMs = Date.now() - startTime;

            // Record telemetry asynchronously (non-blocking)
            const tokensIn = Math.round(prompt.length / 4);
            const tokensOut = Math.round(responseText.length / 4);
            recordAiTelemetry({
                supabase,
                module: options.module || 'general',
                model: modelName,
                fallbackTriggered,
                tokensIn,
                tokensOut,
                latencyMs,
                userId: options.userId || null
            }).catch(() => {});

            return responseText;
        } catch (error) {
            lastError = error;
            console.warn(`⚠️ Model ${modelName} failed (${error.message}). Attempting next fallback...`);
        }
    }
    if (isQuotaOrRateLimitError(lastError)) {
        const quotaError = new Error('QUOTA_EXCEEDED');
        quotaError.isQuotaError = true;
        throw quotaError;
    }
    throw lastError;
}

async function generateJsonFromGemini(prompt, maxOutputTokens, options = {}) {
    const rawText = await generateContentWithFallback(prompt, { maxOutputTokens }, 8000, options);
    const jsonText = rawText.replace(/```json/g, '').replace(/```/g, '').trim();

    if (!jsonText.startsWith('{')) {
        throw new Error('مدل پاسخ معتبری برنگرداند (شاید متن کوتاه/نامفهوم بود).');
    }

    try {
        return JSON.parse(jsonText);
    } catch (parseError) {
        console.error('⚠️ Gemini returned malformed/truncated JSON:', parseError.message);
        const truncatedError = new Error(
            'خروجی هوش مصنوعی ناقص یا نامعتبر بود (احتمالاً به سقف طول پاسخ خورده).'
        );
        truncatedError.isTruncationError = true;
        throw truncatedError;
    }
}

async function syncVocabularyToGlobalDictionary(vocabulary) {
    if (!Array.isArray(vocabulary) || vocabulary.length === 0) {
        return { synced: 0, failed: 0 };
    }

    let synced = 0;
    let failed = 0;

    for (const entry of vocabulary) {
        const rawWord = (entry && entry.word ? String(entry.word) : '').trim();
        if (!rawWord) continue;

        const normalizedWord = rawWord.toLowerCase();

        try {
            const { error } = await supabase
                .from('global_dictionary')
                .upsert({ word: normalizedWord, ai_analysis: entry }, { onConflict: 'word' });
            if (error) throw error;
            synced++;
        } catch (err) {
            failed++;
            console.error(`⚠️ Failed to sync word "${rawWord}":`, err.message);
        }
    }

    return { synced, failed };
}

async function generateMainContent(transcript, videoId, userId = null) {
    const prompt = `
      Act as an expert English-Persian linguist and TOEFL mentor. Analyze the following transcript.
      Return ONLY a valid JSON object.

      Extract 4 components:
      1. "title": A short, clear lesson title in Persian (max 8 words) summarizing what this video teaches.
      2. "summary": Detailed summary in Persian.
      3. "full_transcript_translation": Translate the ENTIRE transcript into natural conversational Persian. Do not summarize or shorten it — translate every sentence.
      4. "grammar_points": 3-5 key advanced grammar structures. For "persian_explanation", explain the rule exactly as if you are talking to a 5-year-old child in Persian (simple, fun, analogy-based).

      JSON Structure:
      {
        "video_id": "${videoId}",
        "title": "...",
        "summary": "...",
        "full_transcript_translation": "...",
        "grammar_points": [{"structure_name": "...", "persian_explanation": "...", "example_from_transcript": "..."}]
      }
      Transcript: ${transcript}
    `;
    return generateJsonFromGemini(prompt, MAIN_CONTENT_MAX_TOKENS, { module: 'video_main', userId });
}

async function generateVocabulary(transcript, userId = null) {
    const prompt = `
      Act as an expert English-Persian linguist and TOEFL mentor. Analyze the following transcript.
      Return ONLY a valid JSON object with a single key "vocabulary".

      COMPREHENSIVE extraction — this is critical, read carefully:
      - Extract EVERY word, phrase, idiom, or collocation in the transcript that a TOEFL learner (CEFR A1 through C2) would benefit from studying. Do NOT limit yourself to a small sample.
      - There is NO upper limit on count. For a typical 10-20 minute educational video, expect this to naturally produce somewhere between 40 and 90+ vocabulary entries depending on how dense the vocabulary is — extract as many as the transcript actually supports, not a token handful.
      - Include words across ALL CEFR levels, not just advanced ones: basic words (A1/A2) that appear alongside intermediate and advanced ones all count if they're worth a learner's attention.
      - For EACH extracted word, "synonyms_by_level" must attempt a real synonym at EVERY level from A1 to C2 (not empty placeholders).
      - Do not skip a word just because it seems "too easy" — completeness of coverage matters more than only picking impressive words.

      JSON Structure:
      {
        "vocabulary": [
            {
                "word": "...", "part_of_speech": "...", "english_meaning": "...", "persian_meaning": "...", "examples": ["..."],
                "synonyms_by_level": { "A1": {"word": "...", "persian": "..."}, "A2": {"word": "...", "persian": "..."}, "B1": {"word": "...", "persian": "..."}, "B2": {"word": "...", "persian": "..."}, "C1": {"word": "...", "persian": "..."}, "C2": {"word": "...", "persian": "..."} },
                "antonyms": [{"word": "...", "persian": "..."}], "collocations": [{"word": "...", "persian": "..."}]
            }
        ]
      }
      Transcript: ${transcript}
    `;
    return generateJsonFromGemini(prompt, VOCABULARY_MAX_TOKENS, { module: 'video_vocab', userId });
}

// ==========================================
// ۱. پردازش ویدیو + گرامر کودکانه + ترجمه ترنسکریپت
// ==========================================
app.post('/api/process_youtube', verifyAuthOrSecret, circuitBreakerMiddleware, async (req, res) => {
    try {
        const { videoUrl, taskId } = req.body;
        const currentUserId = req.authenticatedUser?.id || null;
        if (!videoUrl) throw new Error("لینک ویدیو ارسال نشده است.");

        let dayNumber = null;
        if (taskId) {
            const { data: taskRow } = await supabase
                .from('daily_tasks')
                .select('day_number, video_url')
                .eq('id', taskId)
                .maybeSingle();
            if (taskRow) {
                dayNumber = taskRow.day_number;
                if (taskRow.video_url && taskRow.video_url !== videoUrl) {
                    console.warn(`⚠️ videoUrl ارسالی با video_url ثبت‌شده برای taskId=${taskId} یکی نیست.`);
                }
            }
        }

        const videoId = extractVideoId(videoUrl);
        if (!videoId) throw new Error("لینک یوتیوب نامعتبر است.");

        const transcriptData = await fetchTranscript(videoId);
        const transcript = transcriptData.map(t => t.text).join(' ');
        if (!transcript.trim()) throw new Error("زیرنویس این ویدیو خالی است.");

        const mainContent = await generateMainContent(transcript, videoId, currentUserId);

        let vocabulary = [];
        try {
            const vocabResult = await generateVocabulary(transcript, currentUserId);
            vocabulary = Array.isArray(vocabResult.vocabulary) ? vocabResult.vocabulary : [];
        } catch (vocabError) {
            if (vocabError.isQuotaError) throw vocabError;
            console.error(`⚠️ Vocabulary extraction failed for ${videoId} (main content still saved):`, vocabError.message);
        }

        const analysis = {
            video_id: videoId,
            title: mainContent.title,
            summary: mainContent.summary,
            full_transcript: transcript,
            full_transcript_translation: mainContent.full_transcript_translation,
            grammar_points: mainContent.grammar_points,
            vocabulary,
        };

        const { error: upsertError } = await supabase.from('video_analysis').upsert({
            video_id: analysis.video_id,
            title: analysis.title || null,
            summary: analysis.summary,
            full_transcript: analysis.full_transcript,
            full_transcript_translation: analysis.full_transcript_translation,
            grammar_points: analysis.grammar_points,
            vocabulary: analysis.vocabulary,
            day_number: dayNumber,
            task_id: taskId || null,
        });
        if (upsertError) throw upsertError;

        const syncResult = await syncVocabularyToGlobalDictionary(analysis.vocabulary);
        console.log(`📚 Dictionary sync for ${videoId}: ${syncResult.synced} synced, ${syncResult.failed} failed. Total extracted: ${analysis.vocabulary.length}`);

        res.json(analysis);
    } catch (error) {
        if (req.body?.taskId && error.message === "لینک یوتیوب نامعتبر است.") {
            await supabase
                .from('daily_tasks')
                .update({ is_ai_processed: true })
                .eq('id', req.body.taskId);
            console.warn(`⏭️  Task ${req.body.taskId} has a non-YouTube video_url — marked as processed and skipped permanently.`);
        }

        if (error.isQuotaError) {
            console.error('🛑 Gemini quota/rate-limit hit — pausing further processing for now.');
            return res.status(429).json({ error: 'محدودیت استفاده از هوش مصنوعی موقتاً پر شده. بعداً دوباره تلاش کنید.' });
        }

        // 🚀 حالا error.message شامل پیام واقعی سرور واسطه (نه یک متن
        // ژنریک ثابت)، پس این خطا در لاگ کران‌جاب هم دقیق‌تر دیده می‌شه.
        res.status(400).json({ error: error.message });
    }
});

// ==========================================
// ۲. تحلیل لغت (با سیستم سینونیم CEFR و هندلینگ JSON)
// ==========================================
app.post('/api/analyze_word', verifyAuthOrSecret, circuitBreakerMiddleware, async (req, res) => {
    try {
        const { word } = req.body;
        const currentUserId = req.authenticatedUser?.id || null;
        if (!word) throw new Error("کلمه‌ای ارسال نشده است.");

        const prompt = `Act as an expert English-Persian linguist. Analyze the word "${word}".
        CRITICAL RULE: You MUST return ONLY a valid JSON object. DO NOT output any conversational text, greetings, or explanations like "Please provide...".
        If the word is short like "hi", just analyze it as a greeting/exclamation.
        "synonyms_by_level" must give a real, distinct synonym at EVERY CEFR level from A1 through C2 — not a placeholder and not left empty, even if some levels require a slightly looser synonym or a short explanatory phrase instead of a single word.
        Use this exact JSON structure:
        {
            "word": "${word}", "part_of_speech": "...", "english_meaning": "...", "persian_meaning": "...", "examples": ["..."],
            "synonyms_by_level": { "A1": {"word": "...", "persian": "..."}, "A2": {"word": "...", "persian": "..."}, "B1": {"word": "...", "persian": "..."}, "B2": {"word": "...", "persian": "..."}, "C1": {"word": "...", "persian": "..."}, "C2": {"word": "...", "persian": "..."} },
            "antonyms": [{"word": "...", "persian": "..."}], "collocations": [{"word": "...", "persian": "..."}]
        }`;

        const analysis = await generateJsonFromGemini(prompt, MAIN_CONTENT_MAX_TOKENS, {
            module: 'dictionary_word',
            userId: currentUserId
        });
        await syncVocabularyToGlobalDictionary([analysis]);

        res.json(analysis);
    } catch (error) {
        console.error("Analyze Error:", error.message);
        if (error.isQuotaError) {
            return res.status(429).json({ error: 'محدودیت استفاده از هوش مصنوعی موقتاً پر شده. بعداً دوباره تلاش کنید.' });
        }
        res.status(400).json({ error: error.message });
    }
});

// ==========================================
// ۳. پرسش از هوش مصنوعی درباره ویدیو
// ==========================================
app.post('/api/ask_video_ai', verifyAuthOrSecret, circuitBreakerMiddleware, async (req, res) => {
    try {
        const { videoId, question } = req.body;
        const currentUserId = req.authenticatedUser?.id || null;
        const transcriptData = await fetchTranscript(videoId);
        const transcript = transcriptData.map(t => t.text).join(' ');

        const prompt = `You are a helpful AI. Answer ONLY based on this transcript: "${transcript}". \nUser Question: "${question}"\nAnswer in Persian politely.`;
        const answer = await generateContentWithFallback(prompt, { maxOutputTokens: MAIN_CONTENT_MAX_TOKENS }, 8000, {
            module: 'ask_video_ai',
            userId: currentUserId
        });
        res.json({ answer });
    } catch (error) {
        res.status(400).json({ error: error.message });
    }
});

// ==========================================
// ۴. افزودن دسته‌ای واژگان به فلش‌کارت‌های یک کاربر
// ==========================================
app.post('/api/add_to_flashcards', async (req, res) => {
    try {
        const { userId, words } = req.body;
        if (!userId || !Array.isArray(words) || words.length === 0) {
            throw new Error("userId و لیست words الزامی هستند.");
        }

        const normalizedWords = [...new Set(
            words.map(w => String(w).trim().toLowerCase()).filter(Boolean)
        )];

        const { data: dictRows, error: dictErr } = await supabase
            .from('global_dictionary')
            .select('id, word')
            .in('word', normalizedWords);
        if (dictErr) throw dictErr;

        if (!dictRows || dictRows.length === 0) {
            return res.json({
                added: 0,
                alreadyHad: 0,
                notFoundInDictionary: normalizedWords.length,
            });
        }

        const { data: existing, error: existingErr } = await supabase
            .from('flashcards')
            .select('word_id')
            .eq('user_id', userId)
            .in('word_id', dictRows.map(r => r.id));
        if (existingErr) throw existingErr;

        const existingIds = new Set((existing || []).map(r => r.word_id));
        const toInsert = dictRows
            .filter(r => !existingIds.has(r.id))
            .map(r => ({ user_id: userId, word_id: r.id }));

        if (toInsert.length > 0) {
            const { error: insertErr } = await supabase.from('flashcards').insert(toInsert);
            if (insertErr) throw insertErr;
        }

        res.json({
            added: toInsert.length,
            alreadyHad: existingIds.size,
            notFoundInDictionary: normalizedWords.length - dictRows.length,
        });
    } catch (error) {
        res.status(400).json({ error: error.message });
    }
});

// ==========================================
// ۵. شورای تحلیل چند ایجنتی هوش مصنوعی (Multi-Agent Consensus Council)
// ==========================================
app.post('/api/multi_agent_consensus', verifyAuthOrSecret, circuitBreakerMiddleware, async (req, res) => {
    try {
        const { topic, context = '', question } = req.body;
        const currentUserId = req.authenticatedUser?.id || null;
        if (!topic && !question) throw new Error("موضوع یا سوال کاربر الزامی است.");

        const query = question || topic;

        // ایجنت ۱: تحلیل‌گر ساختار و گرامر (Linguistic & Grammar Analyst)
        const agent1Prompt = `Role: Senior Linguistic & Grammar Analyst for TOEFL/IELTS.
Context: "${context}"
User Query: "${query}"
Task: Analyze grammatical structures, syntax, part of speech, formal vs informal rules, and common mistakes Persian speakers make with this concept. Be concise, authoritative, and structured.`;

        // ایجنت ۲: مربی کاربرد طبیعی و مکالمه (Colloquial & Pragmatic Coach)
        const agent2Prompt = `Role: Native Pragmatic & Everyday Usage Coach.
Context: "${context}"
User Query: "${query}"
Task: Provide real-world colloquial examples, CEFR level assessment, natural spoken idioms, and modern native phrasing alternatives. Keep it practical and engaging.`;

        // اجرای موازی دو ایجنت اول
        const [grammarAnalysis, pragmaticAnalysis] = await Promise.all([
            generateContentWithFallback(agent1Prompt, { maxOutputTokens: 800 }, 8000, {
                module: 'multi_agent_grammar',
                userId: currentUserId
            }).catch(e => `تحلیل گرامری: ${e.message}`),
            generateContentWithFallback(agent2Prompt, { maxOutputTokens: 800 }, 8000, {
                module: 'multi_agent_pragmatic',
                userId: currentUserId
            }).catch(e => `تحلیل کاربردی: ${e.message}`)
        ]);

        // ایجنت ۳: استاد ارشد و داور جمع‌بندی‌کننده (Synthesizer & Master Mentor)
        const synthesizerPrompt = `Role: Master Mentor & Synthesizer for English Learners (Persian speaking).
User Query: "${query}"
Context: "${context}"

Perspective 1 (Grammar Specialist):
${grammarAnalysis}

Perspective 2 (Everyday Usage Coach):
${pragmaticAnalysis}

Task: Review both perspectives, resolve any nuances, and provide a single, masterfully unified, friendly, and complete lesson in Persian (with English examples).
Structure:
1. نتیجه‌گیری و پاسخ روشن به سوال
2. نکات کلیدی گرامری و ساختاری
3. مثال‌های واقعی و مکالمه‌ای
4. یک توصیه کوتاه آموزشی برای به خاطر سپردن`;

        const finalConsensus = await generateContentWithFallback(synthesizerPrompt, { maxOutputTokens: 1400 }, 8000, {
            module: 'multi_agent_consensus',
            userId: currentUserId
        });

        res.json({
            consensus: finalConsensus,
            perspectives: {
                grammar: grammarAnalysis,
                pragmatic: pragmaticAnalysis
            }
        });
    } catch (error) {
        res.status(400).json({ error: error.message });
    }
});

// ==========================================
// ۶. چت متنی همراه با کانتکست کامل کاربر (Omni-Context Mentor Chat)
// ==========================================
app.post('/api/mentor_chat', verifyAuthOrSecret, circuitBreakerMiddleware, async (req, res) => {
    try {
        const { message, history = [], userId: bodyUserId } = req.body;
        const userId = req.authenticatedUser?.id || bodyUserId;
        if (!message) throw new Error("متن پیام الزامی است.");

        let userContextStr = '';
        if (userId) {
            try {
                const [profileRes, statsRes, dueCountRes] = await Promise.all([
                    supabase.from('profiles').select('*').eq('id', userId).maybeSingle(),
                    supabase.from('user_stats').select('*').eq('id', userId).maybeSingle(),
                    supabase.from('flashcards').select('id', { count: 'exact', head: true })
                        .eq('user_id', userId)
                        .lte('next_review_date', new Date().toISOString())
                ]);

                const profile = profileRes.data || {};
                const stats = statsRes.data || {};
                const dueCount = dueCountRes.count ?? 0;

                userContextStr = `
اطلاعات زبان‌آموز:
- نام: ${profile.full_name || 'کاربر'}
- سطح زبان: ${profile.english_level || 'B2'}
- امتیاز کل: ${stats.score ?? 0} XP
- روز جاری در دوره: روز ${stats.current_day ?? 1}
- زنجیره فعالیت: ${stats.streak_days ?? 0} روز پیاپی
- تعداد فلش‌کارت‌های نیازمند مرور امروز: ${dueCount} لغت`;
            } catch (_) {}
        }

        const historyContext = (Array.isArray(history) ? history : [])
            .slice(-6)
            .map(h => `${h.sender === 'user' ? 'کاربر' : 'منتور'}: ${h.text}`)
            .join('\n');

        const prompt = `You are "LingoSync AI Mentor", a warm, inspiring, expert TOEFL/IELTS English mentor and coach.
${userContextStr}

تاریخچه گفتگوی اخیر:
${historyContext}

پیام جدید کاربر:
"${message}"

دستورالعمل‌ها:
- اگر کاربر فارسی نوشت، به فارسی روان و صمیمی پاسخ بده اما کلمات و عبارات انگلیسی را با مثال آموزش بده. اگر انگلیسی نوشت، به انگلیسی بنویس.
- پیشرفت کاربر را در نظر بگیر و او را تشویق کن (مثلاً اگر امتیاز یا زنجیره روزانه دارد).
- اگر درباره گرامر، لغت، ترجمه یا برنامه درسی سوالی پرسید، با متد آموزشی استاندارد و مثال‌های کاربردی راهنمایی کن.
- پاسخ صمیمی، منظم و همراه با اشتیاق آموزشی باشد.`;

        const reply = await generateContentWithFallback(prompt, { maxOutputTokens: 1200 }, 8000, {
            module: 'mentor_chat',
            userId
        });
        res.json({ reply });
    } catch (error) {
        res.status(400).json({ error: error.message });
    }
});

// ==========================================
// 🤖 ربات اتوماسیون پس‌زمینه (Cron Job)
// ==========================================
setInterval(async () => {
    console.log('🤖 Auto-processing background check...');
    try {
        const { data: pendingTasks } = await supabase
            .from('daily_tasks')
            .select('*')
            .not('video_url', 'is', null)
            .eq('is_ai_processed', false);

        if (!pendingTasks || pendingTasks.length === 0) {
            console.log('✅ No pending videos to process.');
            return;
        }

        console.log(`📋 Found ${pendingTasks.length} pending task(s) to process this run.`);

        for (let task of pendingTasks) {
            console.log(`⏳ Processing Video for Day ${task.day_number}...`);
            const processRes = await fetch(`http://localhost:3002/api/process_youtube`, {
                method: 'POST',
                headers: { 'Content-Type': 'application/json' },
                body: JSON.stringify({ videoUrl: task.video_url, taskId: task.id })
            });

            if (processRes.ok) {
                await supabase.from('daily_tasks').update({ is_ai_processed: true }).eq('id', task.id);
                console.log(`✅ Success: Video for Day ${task.day_number} processed and cached!`);
                continue;
            }

            if (processRes.status === 429) {
                console.warn(`🛑 Gemini quota hit while processing Day ${task.day_number} — stopping this batch, will retry next run.`);
                break;
            }

            const errBody = await processRes.json().catch(() => ({}));
            console.error(`❌ Failed to process Day ${task.day_number}:`, errBody.error || processRes.statusText);
        }
    } catch (e) { console.error('Auto-process error:', e.message); }
}, 1000 * 60 * 60);

const server = app.listen(3002, () => console.log('🚀 AI Express Server running on port 3002'));

// Graceful Shutdown
process.on('SIGTERM', () => {
    console.log('SIGTERM signal received: closing AI Express server');
    server.close(() => {
        console.log('AI Express server closed');
        process.exit(0);
    });
});