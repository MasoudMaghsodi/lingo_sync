import { serve } from "https://deno.land/std@0.168.0/http/server.ts";

const GEMINI_API_KEY = Deno.env.get("GEMINI_API_KEY");
// استفاده از هاست جدید Live API گوگل برای مدل 2.5
const HOST = "generativelanguage.googleapis.com";
const MODEL = "models/gemini-2.5-flash-native-audio"; // مدل Native Audio

serve((req) => {
  // این فانکشن فقط باید از طریق WebSocket فراخوانی شود
  if (req.headers.get("upgrade") !== "websocket") {
    return new Response("Expected WebSocket connection", { status: 400 });
  }

  const { socket, response } = Deno.upgradeWebSocket(req);

  // اتصال همزمان ما به سرور گوگل
  let geminiSocket: WebSocket;

  socket.onopen = () => {
    const url = `wss://${HOST}/ws/google.ai.generativelanguage.v1alpha.GenerativeService.BidiGenerateContent?key=${GEMINI_API_KEY}`;
    geminiSocket = new WebSocket(url);

    geminiSocket.onopen = () => {
      // 1. به محض اتصال، شخصیت استاد (System Instruction) و کانتکست پنهان را به گوگل می‌فرستیم
      const setupMessage = {
        setup: {
          model: MODEL,
          systemInstruction: {
            parts: [{
              text: `You are an elite, retired TOEFL/IELTS examiner with 30 years of experience.
Your personality is strict but deeply caring, acting as a personal mentor.
Rules:
1. Speak exclusively about language learning, personal development, TOEFL/IELTS, and time management.
2. Default language is academic English. Only use Persian (Farsi) if the user struggles, asks for translation, or needs a complex grammar concept explained.
3. Analyze the user's spoken English. Give constructive feedback on pronunciation, stress, and fluency.
4. If the user talks about unrelated daily stuff, cleverly steer the conversation back to their studies.
5. You will receive silent JSON updates about the user's progress. Use this data to praise or scold them appropriately.`
            }]
          }
        }
      };
      geminiSocket.send(JSON.stringify(setupMessage));
    };

    geminiSocket.onmessage = (event) => {
      // پیام‌های (صدا/متن) دریافتی از گوگل را مستقیماً به فلاتر می‌فرستیم
      socket.send(event.data);
    };

    geminiSocket.onclose = () => socket.close();
    geminiSocket.onerror = (e) => console.error("Gemini Socket Error:", e);
  };

  socket.onmessage = (event) => {
    // پیام‌های (صدای ضبط شده) از فلاتر را به گوگل می‌فرستیم
    if (geminiSocket && geminiSocket.readyState === WebSocket.OPEN) {
      geminiSocket.send(event.data);
    }
  };

  socket.onclose = () => {
    if (geminiSocket) geminiSocket.close();
  };

  return response;
});