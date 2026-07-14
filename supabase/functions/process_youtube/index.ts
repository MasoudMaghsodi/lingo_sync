import { serve } from "https://deno.land/std@0.168.0/http/server.ts"
import { GoogleGenerativeAI } from "npm:@google/generative-ai"

const corsHeaders = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type',
}

// تابع کمکی برای استخراج آی‌دی ویدیو از انواع لینک‌های یوتیوب
function extractVideoId(url: string): string | null {
  const regExp = /^.*((youtu.be\/)|(v\/)|(\/u\/\w\/)|(embed\/)|(watch\?))\??v?=?([^#&?]*).*/;
  const match = url.match(regExp);
  return (match && match[7].length === 11) ? match[7] : null;
}

serve(async (req) => {
  if (req.method === 'OPTIONS') return new Response('ok', { headers: corsHeaders })

  try {
    const { videoUrl } = await req.json()
    if (!videoUrl) throw new Error("لینک ویدیو ارسال نشده است.")

    const videoId = extractVideoId(videoUrl);
    if (!videoId) throw new Error("لینک یوتیوب نامعتبر است.");

    // ۱. استخراج زیرنویس از طریق سرور هلند اختصاصی خودمان
    const NL_SERVER_IP = "194.246.82.160"; // <--- آی‌پی سرور هلند را اینجا بگذار
    const SECRET_KEY = "LingoSync_TopSecret_2026";
    
    const transcriptRes = await fetch(`http://${NL_SERVER_IP}:3000/transcript?videoId=${videoId}&key=${SECRET_KEY}`);
    
    if (!transcriptRes.ok) {
       throw new Error("خطا از سمت سرور هلند. ویدیو زیرنویس ندارد یا آی‌پی مسدود است.");
    }
    
    if (!transcriptRes.ok) {
       throw new Error("خطا در دریافت زیرنویس. ممکن است ویدیو زیرنویس نداشته باشد یا در دسترس نباشد.");
    }
    const transcriptData = await transcriptRes.json();
    const transcript = transcriptData.map((t: any) => t.text).join(' ');

    if (!transcript || transcript.trim() === '') {
       throw new Error("زیرنویس این ویدیو خالی است.");
    }

    // ۲. اتصال به جمینای 
    const apiKey = Deno.env.get('GEMINI_API_KEY')
    const genAI = new GoogleGenerativeAI(apiKey!)
    const model = genAI.getGenerativeModel({ model: "gemini-3.1-flash-lite" })

    // پرامپت مهندسی‌شده برای استخراج جامع (خلاصه، گرامر، لغت)
    const prompt = `
      Act as an expert English-Persian linguist and TOEFL mentor. Analyze the following transcript.
      Return ONLY a valid JSON object. Provide accurate and detailed Persian translations.
      
      Extract three main components:
      1. "summary": A very detailed summary of the video's content (in Persian). Don't be too brief.
      2. "grammar_points": Extract 3-5 key advanced grammar structures used in the text. For each, explain the rule briefly in Persian and provide the exact example sentence from the transcript.
      3. "vocabulary": Extract AT LEAST 15 to 25 important vocabulary words (levels B1 to C2). Do not limit to only extremely hard words; include good conversational and academic words. Provide synonyms for ALL CEFR levels, antonyms, and collocations.

      Use this EXACT JSON structure:
      {
        "video_id": "${videoId}",
        "summary": "خلاصه کامل ویدیو در اینجا...",
        "grammar_points": [
          {
            "structure_name": "...",
            "persian_explanation": "...",
            "example_from_transcript": "..."
          }
        ],
        "vocabulary": [
          {
            "word": "...",
            "part_of_speech": "...",
            "english_meaning": "...",
            "persian_meaning": "...",
            "examples": ["...", "..."],
            "synonyms_by_level": { "A1": {"word": "...", "persian": "..."}, "A2": {"word": "...", "persian": "..."}, "B1": {"word": "...", "persian": "..."}, "B2": {"word": "...", "persian": "..."}, "C1": {"word": "...", "persian": "..."}, "C2": {"word": "...", "persian": "..."} },
            "antonyms": [{"word": "...", "persian": "..."}, {"word": "...", "persian": "..."}],
            "collocations": [{"word": "...", "persian": "..."}, {"word": "...", "persian": "..."}]
          }
        ]
      }
      Transcript: ${transcript}
    `

    const result = await model.generateContent(prompt)
    let responseText = result.response.text()
    
    responseText = responseText.replace(/```json/g, '').replace(/```/g, '').trim()
    const jsonResponse = JSON.parse(responseText)

    return new Response(JSON.stringify(jsonResponse), {
      headers: { ...corsHeaders, "Content-Type": "application/json" },
      status: 200,
    })

  } catch (error) {
    return new Response(JSON.stringify({ error: error.message }), {
      headers: { ...corsHeaders, "Content-Type": "application/json" },
      status: 400,
    })
  }
})