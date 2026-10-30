require('dotenv').config();
const express = require('express');
const helmet = require('helmet');
const rateLimit = require('express-rate-limit');
const { YoutubeTranscript } = require('youtube-transcript');

const app = express();
app.set('trust proxy', 1);
app.use(helmet());

// کلید امنیتی اختصاصی از محیط
const SECRET_KEY = process.env.YT_PROXY_SECRET_KEY;
if (!SECRET_KEY) {
    console.error('❌ FATAL: YT_PROXY_SECRET_KEY environment variable is not defined.');
    process.exit(1);
}

// محافظت در برابر اسپم و فشار به یوتیوب
const transcriptLimiter = rateLimit({
    windowMs: 15 * 60 * 1000, // 15 دقیقه
    max: 120, // حداکثر 120 درخواست در 15 دقیقه
    message: { error: 'تعداد درخواست‌ها بیش از حد مجاز است. لطفاً بعداً تلاش کنید.' },
    standardHeaders: true,
    legacyHeaders: false,
});

app.use('/transcript', transcriptLimiter);

// Health Check Endpoint
app.get('/health', (req, res) => {
    res.json({
        status: 'ok',
        service: 'yt-proxy',
        uptime: process.uptime(),
        timestamp: new Date().toISOString(),
    });
});

// C20: Iranian SMS Send-Hook for Supabase Auth
const { getSmsProvider } = require('./sms-service');
app.post('/api/auth/sms-hook', express.json(), async (req, res) => {
    try {
        const { user, sms } = req.body || {};
        const phone = user?.phone;
        const otp = sms?.otp;
        if (!phone || !otp) {
            return res.status(400).json({ error: 'Missing phone or otp' });
        }
        const smsProvider = getSmsProvider();
        const result = await smsProvider.sendOtp({ phoneNumber: phone, code: otp });
        res.json({ success: true, result });
    } catch (err) {
        console.error('SMS hook error:', err.message);
        res.status(500).json({ error: err.message });
    }
});

app.get('/transcript', async (req, res) => {
    const videoId = req.query.videoId;
    const key = req.query.key;

    if (key !== SECRET_KEY) {
        return res.status(403).json({ error: 'دسترسی غیرمجاز (کلید امنیتی اشتباه است)' });
    }
    if (!videoId) {
        return res.status(400).json({ error: 'آی‌دی ویدیو ارسال نشده است' });
    }

    try {
        const transcript = await YoutubeTranscript.fetchTranscript(videoId);
        res.json(transcript);
    } catch (error) {
        res.status(500).json({ error: error.message });
    }
});

const PORT = process.env.PORT || 3000;
const server = app.listen(PORT, () => {
    console.log(`🚀 YouTube Proxy Server is running securely on port ${PORT}`);
});

// Graceful Shutdown
process.on('SIGTERM', () => {
    console.log('SIGTERM signal received: closing HTTP server');
    server.close(() => {
        console.log('HTTP server closed');
        process.exit(0);
    });
});