require('dotenv').config();
const express = require('express');
const cors = require('cors');
const { GoogleGenerativeAI } = require('@google/generative-ai');
const { createClient } = require('@supabase/supabase-js');

const app = express();
app.use(cors());
app.use(express.json());

const GEMINI_API_KEY = process.env.GEMINI_API_KEY;
const SUPABASE_URL = process.env.SUPABASE_URL;
const SUPABASE_SERVICE_KEY = process.env.SUPABASE_SERVICE_KEY;
const supabase = createClient(SUPABASE_URL, SUPABASE_SERVICE_KEY);
const genAI = new GoogleGenerativeAI(GEMINI_API_KEY);

const NL_SERVER_IP = "194.246.82.160";
const SECRET_KEY = process.env.YT_PROXY_SECRET_KEY || "LingoSync_TopSecret_2026";

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
            `http://${NL_SERVER_IP}:3000/transcript?videoId=${videoId}&key=${SECRET_KEY}`
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

async function generateJsonFromGemini(prompt, maxOutputTokens) {
    const model = genAI.getGenerativeModel({
        model: "gemini-3.1-flash-lite",
        generationConfig: { maxOutputTokens },
    });

    let result;
    try {
        result = await model.generateContent(prompt);
    } catch (error) {
        if (isQuotaOrRateLimitError(error)) {
            const quotaError = new Error('QUOTA_EXCEEDED');
            quotaError.isQuotaError = true;
            throw quotaError;
        }
        throw error;
    }

    const rawText = result.response.text();
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

async function generateMainContent(transcript, videoId) {
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
    return generateJsonFromGemini(prompt, MAIN_CONTENT_MAX_TOKENS);
}

async function generateVocabulary(transcript) {
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
    return generateJsonFromGemini(prompt, VOCABULARY_MAX_TOKENS);
}

// ==========================================
// ۱. پردازش ویدیو + گرامر کودکانه + ترجمه ترنسکریپت
// ==========================================
app.post('/api/process_youtube', async (req, res) => {
    try {
        const { videoUrl, taskId } = req.body;
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

        const mainContent = await generateMainContent(transcript, videoId);

        let vocabulary = [];
        try {
            const vocabResult = await generateVocabulary(transcript);
            vocabulary = Array.isArray(vocabResult.vocabulary) ? vocabResult.vocabulary : [];
        } catch (vocabError) {
            if (vocabError.isQuotaError) throw vocabError;
            console.error(`⚠️ Vocabulary extraction failed for ${videoId} (main content still saved):`, vocabError.message);
        }

        const analysis = {
            video_id: videoId,
            title: mainContent.title,
            summary: mainContent.summary,
            full_transcript_translation: mainContent.full_transcript_translation,
            grammar_points: mainContent.grammar_points,
            vocabulary,
        };

        const { error: upsertError } = await supabase.from('video_analysis').upsert({
            video_id: analysis.video_id,
            title: analysis.title || null,
            summary: analysis.summary,
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
app.post('/api/analyze_word', async (req, res) => {
    try {
        const { word } = req.body;
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

        const analysis = await generateJsonFromGemini(prompt, MAIN_CONTENT_MAX_TOKENS);
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
app.post('/api/ask_video_ai', async (req, res) => {
    try {
        const { videoId, question } = req.body;
        const transcriptData = await fetchTranscript(videoId);
        const transcript = transcriptData.map(t => t.text).join(' ');

        const model = genAI.getGenerativeModel({
            model: "gemini-3.1-flash-lite",
            generationConfig: { maxOutputTokens: MAIN_CONTENT_MAX_TOKENS },
        });
        const prompt = `You are a helpful AI. Answer ONLY based on this transcript: "${transcript}". \nUser Question: "${question}"\nAnswer in Persian politely.`;

        let result;
        try {
            result = await model.generateContent(prompt);
        } catch (error) {
            if (isQuotaOrRateLimitError(error)) {
                return res.status(429).json({ error: 'محدودیت استفاده از هوش مصنوعی موقتاً پر شده. بعداً دوباره تلاش کنید.' });
            }
            throw error;
        }

        res.json({ answer: result.response.text() });
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

app.listen(3002, () => console.log('🚀 AI Express Server running on port 3002'));