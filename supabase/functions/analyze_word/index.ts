import { serve } from "https://deno.land/std@0.168.0/http/server.ts"
import { GoogleGenerativeAI } from "npm:@google/generative-ai"

const corsHeaders = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type',
}

serve(async (req) => {
  // هندل کردن درخواست‌های فلاتر (CORS)
  if (req.method === 'OPTIONS') {
    return new Response('ok', { headers: corsHeaders })
  }

  try {
    const { word } = await req.json()
    if (!word) throw new Error("کلمه‌ای برای تحلیل ارسال نشده است.")

    const apiKey = Deno.env.get('GEMINI_API_KEY')
    const genAI = new GoogleGenerativeAI(apiKey!)
    const model = genAI.getGenerativeModel({ model: "gemini-3.1-flash-lite" })

    const prompt = `
      Act as an expert English-Persian linguist. Analyze the English word "${word}" exhaustively to maximize learning value.
      Return ONLY a valid JSON object. Provide accurate Persian translations for EVERYTHING.
      You MUST provide synonyms for ALL CEFR levels (A1, A2, B1, B2, C1, C2). If a direct synonym doesn't exist for a level, provide the closest related word.
      Include a comprehensive list of antonyms and collocations (at least 5 of each if possible).
      Use this exact JSON structure:
      {
        "word": "${word}",
        "part_of_speech": "...",
        "english_meaning": "...",
        "persian_meaning": "...",
        "examples": ["...", "...", "..."],
        "synonyms_by_level": {
          "A1": {"word": "...", "persian": "..."}, "A2": {"word": "...", "persian": "..."}, "B1": {"word": "...", "persian": "..."}, "B2": {"word": "...", "persian": "..."}, "C1": {"word": "...", "persian": "..."}, "C2": {"word": "...", "persian": "..."}
        },
        "antonyms": [{"word": "...", "persian": "..."}, {"word": "...", "persian": "..."}],
        "collocations": [{"word": "...", "persian": "..."}, {"word": "...", "persian": "..."}]
      }
    `

    const result = await model.generateContent(prompt)
    let responseText = result.response.text()
    
    // تمیز کردن خروجی JSON
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