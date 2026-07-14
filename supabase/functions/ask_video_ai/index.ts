import { serve } from "https://deno.land/std@0.168.0/http/server.ts"
import { GoogleGenerativeAI } from "npm:@google/generative-ai"

const corsHeaders = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type',
}

serve(async (req) => {
  if (req.method === 'OPTIONS') {
    return new Response('ok', { headers: corsHeaders });
  }

  try {
    const { videoId, question } = await req.json();
    if (!videoId || !question) throw new Error("اطلاعات ناقص است.");

    // ۱. دریافت ترنسکریپت از سرور هلند
    const NL_SERVER_IP = "194.246.82.160"; // آی‌پی سرور هلندت را اینجا بگذار
    const SECRET_KEY = "LingoSync_TopSecret_2026";
    
    const transcriptRes = await fetch(`http://${NL_SERVER_IP}:3000/transcript?videoId=${videoId}&key=${SECRET_KEY}`);
    if (!transcriptRes.ok) {
       throw new Error("خطا در ارتباط با سرور واسط.");
    }
    const transcriptData = await transcriptRes.json();
    const transcript = transcriptData.map((t: any) => t.text).join(' ');

    // ۲. اتصال به جمینای
    const apiKey = Deno.env.get('GEMINI_API_KEY');
    const genAI = new GoogleGenerativeAI(apiKey!);
    const model = genAI.getGenerativeModel({ model: "gemini-3.1-flash-lite" });

    const prompt = `
      You are an AI assistant helping a student understand a specific video.
      Transcript of the video: "${transcript}"
      
      User's Question: "${question}"
      
      Rules:
      1. Answer ONLY based on the transcript provided above.
      2. If the user's question is unrelated to the video, politely refuse and tell them you can only answer questions about this specific video.
      3. Answer in Persian, be helpful, and explain clearly.
    `;

    const result = await model.generateContent(prompt);
    
    return new Response(JSON.stringify({ answer: result.response.text() }), {
      headers: { ...corsHeaders, "Content-Type": "application/json" },
      status: 200,
    });

  } catch (error) {
    return new Response(JSON.stringify({ error: error.message }), {
      headers: { ...corsHeaders, "Content-Type": "application/json" },
      status: 400,
    });
  }
});