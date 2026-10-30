# LingoSync v2.0 — Condensed Launch Specification
Supersedes earlier specs as of 2026-10-30. Max 150 lines.

## 1. Product Vision & Core Loops
- **North Star Metric (WCLC)**: Weekly Learners with Closed Loop (Capture -> SRS Review -> Verified Spoken Use in <= 7d).
- **Core 10-Min Daily Sync**: 2m Active Recall -> 2m Genome Micro-lesson -> 4m Live Voice (>=3 target words) -> 2m Feedback.
- **Quick Sync (2m)**: >=5 SRS reviews or >=60s verified speaking keeps streak alive.
- **Pedagogy Policy**: Single Mentor persona. Delayed correction (<=1 recast/min in live audio, breakdown in end summary). Progressive L1 fading (A1-B1 Persian, B2/C1 English). Council is on-demand "Deep Analysis" («تحلیل عمیق») consuming AI Actions.
- **Exam Labelling**: Readiness Index (0-100) until calibrated. No raw IELTS/TOEFL band numbers. Mandatory disclaimer: «این نمره یک تخمین آموزشی داخلی است...».

## 2. Economics & Two-Bucket Quotas
- **Quotas**: Free (24m live, 8 AI Actions), Pro (100m live, 40 AI Actions), Elite (250m live, 120 AI Actions). Turn-based voice is a metered sub-bucket.
- **Pricing & Margins**: Dynamic in `ai_pricing_config`. Min 40% margin at P80, >=65% cohort blended.
- **Circuit Breakers**: Daily per-user spend caps (Free $0.08, Pro $0.25, Elite $0.45; reset 00:00 Asia/Tehran). Global kill switch with Telegram/email alerts at 50%/80%/100%.

## 3. Architecture & Audio Transport
- **Models**:
  - Live Voice: `gemini-3.8-live` (AUDIO response, output transcription, no thinking_level/config, proactive audio on, 128k context).
  - Text Chain: `gemini-3.8-flash` (HIGH) -> `gemini-3.6-flash` -> `gemini-3.5-flash-lite` -> `gemini-3.1-flash-lite`. No temperature/topP/sampling params on 3.x; use `thinking_level`.
  - Cache: Server-side only (text/multimodal REST >=32k tokens). Live WebSocket does NOT support context caching.
- **Audio Transport**: Opus 16-24 kbps, 20ms frames, DTX/VAD. Proxy transcodes Opus <-> PCM16. Protocol handshake negotiates `protocol_version` & `codec` (opus|pcm16). Spike on Mi 10T, Galaxy A36, Redmi Note 8 Pro.
- **Resilience**: Heartbeat <=10s, 20-30s session hold, Gemini session resumption handles, output buffer <=3s. Degraded mode switches to turn-based clip -> STT -> Flash -> TTS.
- **Client & Backend**: Flutter 3 (Riverpod, layered, RTL, 3D Glass/Parallax UI) + Node.js Proxy (Staging VPS, Prod 2-4 vCPU / 4-8GB RAM) + Supabase (Postgres, RLS, offline SQLite outbox with UUIDv4).

## 4. UI/UX & Modern 3D Design
- **Home**: Header (CEFR, countdown, streak gauge) + 3D Parallax Daily Sync Card + Bottom "۳ خطایی که در حال اصلاح آنها هستم" with progress bars.
- **Voice HUD**: 3D Reactive Holographic Orb (morphing mesh shader responding to live amplitude, listening, thinking, speaking) + hint cards showing Persian cue only + ping/codec HUD.
- **Visual Polish**: 3D Depth Glassmorphism, Gyroscopic perspective tilt, smooth 60/120fps with fallback shader for low-end devices.

## 5. Security, Auth & Release
- **Auth**: Supabase Phone OTP via Iranian SMS hook (Kavenegar/Melipayamak) with abuse protection; Email/Google fallback.
- **Anti-Abuse**: Play Integrity / Attestation; non-GMS fallback to OTP + server device/IP limits. Max 90s audio for guest placement ($0.02-0.03 cap).
- **Packaging**: ProGuard rules for native audio/JNI, 64-bit ABIs, Bazaar/Myket in-app billing + Zarinpal/NextPay web checkout.
