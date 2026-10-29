# LingoSync v2.0 — Progress & Decision Log

## Date: 2026-10-30

### 1. Architectural & Strategic Decisions (Locked)
- **D-01 (Voice Proxy Location)**: Long-lived live audio WebSocket proxy remains on Node.js container (`yt-proxy-ai-mentor-1`) on Netherlands server (`146.103.124.117`). Short REST queries use Express/Supabase Edge.
- **D-02 (Live Audio Model)**: Live WebSocket verified working on `models/gemini-3.8-live` with `responseModalities: ["AUDIO"]` and `version: 3.1-flash-live-03-2026`. `gemini-2.5-flash-native-audio-latest` resolves to `preview-12-2025` which sunsets on 2026-11-17 (18 days remaining). Migration P1-0 to `gemini-3.8-live` is prioritized immediately.
- **D-03 (Text Models Hierarchy)**: Task-based routing with fallback: `gemini-3.8-flash` -> `gemini-3.6-flash` -> `gemini-3.5-flash-lite` -> `gemini-3.1-flash-lite`. Gemini 3.x utilizes `thinking_level` (LOW/MEDIUM/HIGH) without deprecated sampling parameters.
- **D-04 (Server Authority)**: Quotas, balances, and cost tracking reside exclusively on server/Supabase RPCs. Client state in Hive is strictly a read/replay cache.
- **D-05 (Security Hardening)**: Internal docker ports bound to `127.0.0.1`. Inbound traffic routed via Nginx TLS. JWT authentication enforced on proxy handshakes.

### 2. Assumptions
- **A-01**: Google Gemini Live API pricing for `gemini-3.8-live` will be kept dynamic via server-side `ai_pricing_config` table and defaults to standard token rates.
- **A-02**: Supabase anonymous auth can be safely linked with email/password or OAuth when learner reaches "Aha" moment.
- **A-03**: Existing 50-day task structure will be migrated without data loss into `daily_missions` table.
- **A-04**: YouTube caption storage will shift to derived metadata only (vocabulary, grammar points, summary) to maintain full copyright compliance.

### 3. Task Status

| Task ID | Description | Phase | Status | Notes |
|---|---|---|---|---|
| **P0-DISC** | Codebase Map, Model Audit, Gap Analysis, Plan | Phase 0 | **DONE** | Complete audit delivered |
| **P1-0** | Hotfix: Live Voice migration to `gemini-3.8-live` | Phase 1 | **DONE** | Migrated proxy, verified live WSS `setupComplete` & audio roundtrip |
| **P1-1** | Telemetry, Pricing Config, Spend Circuit Breaker | Phase 1 | **DONE** | Created SQL migration, `telemetry-service.js`, spend circuit breaker ($1.50/day) |
| **P1-2** | Server-side Quotas, Proxy Metering, VAD, Session Cap | Phase 1 | **DONE** | SQL migration, 15m session cap, silence VAD (10s/30s), atomic decrement |
| **P1-3** | Global Caches, CEFR Validation, Report Error Flow | Phase 1 | **DONE** | SQL migration, case-insensitive indexing, CEFR normalization, /api/report_error |
| **P1-4** | Onboarding Flow & Daily Sync 10-min Mission Screen | Phase 1 | **IN PROGRESS** | Anonymous placement test, Daily Sync loop |
| **P1-5** | Resilient Streak, Backlog Vacation Mode, Competence XP | Phase 1 | QUEUED | Pure functions, IANA timezones |
| **P1-6** | 3-Tier Mentor Context Injection | Phase 1 | QUEUED | 500-800 tokens budget |

### 4. Open Questions (Awaiting User Input)
1. **Payment Provider Priority**: Choice between Bazaar/Myket in-app billing, Zarinpal web gateway, or Google Play Billing for initial Phase 2 launch.
2. **Product Analytics Tool**: Confirmation on whether to use PostHog, Mixpanel, Firebase Analytics, or in-house `analytics_events` table in Supabase.
3. **Transcript Retention Policy**: Retention window for user conversation transcripts (default recommendation: 90 days rolling TTL with instant user deletion).
4. **Human-Rated Exam Samples**: Mechanism for providing the 40+ human-rated IELTS speaking benchmark samples for Exam Twin calibration.
5. **YouTube Transcript Legal Posture**: Approval to transition shared cache from raw transcripts to educational derived metadata only.
6. **Staging vs Production Environment**: Policy on executing Supabase migration files (remote staging branch vs versioned PR reviews).
