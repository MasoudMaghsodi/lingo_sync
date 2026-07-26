const express = require('express');
const { YoutubeTranscript } = require('youtube-transcript');

const app = express();
// کلید امنیتی اختصاصی خودت
const SECRET_KEY = "test"; 

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

const PORT = 3000;
app.listen(PORT, () => {
    console.log(`YouTube Proxy Server is running on port ${PORT}`);
});