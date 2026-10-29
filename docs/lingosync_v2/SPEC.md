# LingoSync v2.0 — Condensed Specification

## 1. Product Core Loop & North Star
- **Product Vision**: Adaptive English coach for Persian-speaking, exam-focused learners (IELTS/TOEFL, CEFR B1–C2).
- **North Star Metric (WCLC)**: Weekly Learners with Closed Loop (Capture -> SRS Review -> Verified Use within 7 days).
- **Core Loop**:
  1. Input: Vocabulary, phrases, grammar from YouTube, dictionary, or learner errors.
  2. Retention: SM-2 spaced repetition (Leitner) including error-driven cards.
  3. Remediation: Micro-drills targeting Personal Error Genome.
  4. Active Production: Live voice or exam simulator eliciting target words.
  5. Evidence-based Feedback: Verified usage (exact quote, confidence >= 0.7) updates daily plan.

## 2. Locked Architecture Decisions
- **L1**: WebSocket proxy stays on Node.js (long-lived). Supabase Edge Functions for short request/response only.
- **L2**: Server is sole authority for quotas, entitlements, and cost. Hive state is never trusted. Quota decrements are atomic SQL RPCs.
- **L3**: No Gemini API keys in Flutter. Handshake authenticated via Supabase JWT. Concurrency: 1 live session per user.
- **L4**: Dynamic routing via `ai_model_routing_config` & `ai_pricing_config`. Text: Gemini 3.x uses `thinking_level`. Live: omit thinking.
- **L5**: Task-based routing: High-stakes (3.8 Flash -> 3.7/3.6 Flash, thinking HIGH/MEDIUM); Cacheable (3.8/3.6 Flash, MEDIUM); Light tasks (Flash-Lite, LOW).
- **L6**: 3-Agent Council runs on request/complex queries (Grammar & Colloquial parallel -> Judge synthesis).
- **L7**: Live session policy: 15-min cap (wrap-up at 14:00), client VAD silence cutoff (10s silence pause, 30s close), concise 2-3 sentence mentor responses.
- **L8**: Degraded voice mode upon quota exhaustion: clip -> cheap STT -> text generation -> cached/on-device TTS (separate text-credit bucket) or graceful text chat fallback.
- **L9**: 3-Tier Mentor Context (500-800 tokens max): T1 Stable profile, T2 Today's vector (5 due cards + 3 error patterns), T3 Rolling 3-line session summary.
- **L10**: Shared tables never store full raw video/transcript long-term. Derived metadata only. User/transcript text treated as untrusted in prompts.
- **L11**: CEFR validation strictly uses commercially licensed word lists (CEFR-J, NGSL). Badges: `Wordlist-verified` or `AI-estimated`.
- **L12**: Exam features labeled "IELTS-style" / "TOEFL-style" with mandatory disclaimer: «این نمره یک تخمین آموزشی داخلی است...».
- **L13**: Payments behind `PaymentProvider` interface with server-side validation in `user_subscriptions`.
- **L14**: Real-time margin rules: contribution margin >= 40% at P80, >= 65% blended. USD circuit breaker per user ($1.50/day) & global kill switch.
- **L15**: Full instrumentation: every KPI computable from stored event tables.

## 3. Product & UX Specifications
- **Onboarding (Aha < 90s)**: Anonymous auth, mic consent modal, 60s placement dialog, instant approximate CEFR, 1st weakness, 5 cards, streak day 1.
- **Daily Sync Mission**: 10-minute guided path (0-2m: 5-10 cards recall; 2-4m: error drill; 4-8m: live voice elicitation; 8-10m: feedback). Quick Sync (2m) preserves streak.
- **Resilient Streak**: Event-sourced `streak_events` in user's IANA local timezone, 1 freeze per 7 days (max 2), 1 rest day/week, 48h repair.
- **Backlog Vacation Mode**: If due > 50, show clamped daily slice (15-35), spreading over 7-10 days without mutating SM-2 intervals.
- **Competence-Based XP**: Timer/open app = 0 XP. 3x XP for 7+ day interval recall and verified spoken use. Daily caps per source.
- **Adaptive Plan**: Weekly re-weighting of task mix; Graduation flow past Day 50 into higher CEFR/interview simulation.
- **Personal Error Genome**: Categorized L1 interference logging (>=0.6 confidence, exact substring quote), 5 remediation stages, auto-generated error cards.
- **Active Recall Raid & Code-Switch Rescue**: Unprompted target elicitation; natural English rescue on Persian intrusions.
- **60-Second C1 Upgrade Studio**: Council rewrites user response to C1 CEFR using 2 active SRS cards + 1 advanced grammar point.
- **Exam Twin (Phase 3)**: Formal IELTS/TOEFL speaking simulation with real timing, 4 criteria scoring, and beta disclaimer.

## 4. Database Schema Additions
- Routing & Pricing: `ai_model_routing_config`, `ai_pricing_config`, `feature_flags`, `ai_telemetry_logs`.
- Quotas & Billing: `user_usage_quotas`, `user_subscriptions`, `user_consents`, `voice_sessions`.
- Learning & SRS: `user_error_genome`, `word_usage_evidence`, `daily_missions`, `streak_events`, `streak_state`, `srs_review_logs`.
- Caching: `global_dictionary_cache`, `global_video_lessons_cache`.

## 5. Execution Phasing
- **Phase 0**: Discovery, model verification, codebase audit, planning (Read-only).
- **Phase 1 (Weeks 1-4)**: P1-0 (Live Model Migration to `gemini-3.8-live`), Telemetry, Server Quotas, Caches, Onboarding, Daily Sync, Resilient Streak, 3-Tier Context.
- **Phase 2 (Weeks 5-10)**: Monetization/Subscriptions, Error Genome, Code-Switch Rescue, Recall Raid, C1 Studio, Adaptive Plan.
- **Phase 3 (Weeks 11-16)**: Exam Twin, Branching Simulator spike, Pronunciation Lab spike, Cohort Leagues.
