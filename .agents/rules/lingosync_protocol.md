# LingoSync v2.0 Protocol Rule

Apply to all tasks:
1. Mode: One shippable task at a time. Keep Task List and PROGRESS.md current. Stop at phase gates.
2. Architecture & Reasoning: Think deeply on DB schema, RLS, sync, quota/cost math, security, pedagogy. Never reopen approved decisions. If blocked after 2 tries, log in PROGRESS.md and ask.
3. Grounding: Read code before editing. Verify model IDs, prices, limits at ai.google.dev, supabase.com/docs, pub.dev. Never invent. Tag unverifiable items UNVERIFIED.
4. Safety: No destructive commands. Never run migrations on production directly; write versioned SQL in `supabase/migrations/`. Never print or commit secrets. Ask before adding dependencies or changing state management. Backward-compatible changes behind feature flags.
5. Cost safety: Automated tests must NEVER call paid Gemini endpoints. Use mocks/fixtures. Manual tests are spend-capped.
6. Honesty: Report only what was actually run. Tag with NOT_RUN, NEEDS_DEVICE_TEST, NEEDS_HUMAN_DATA. Never fabricate results.
7. Language: Persian conversation with English technical terms. Artifacts in Persian. Code, comments, commits, and `docs/` in English. User UI strings in Persian RTL.
8. Persistence: Update `docs/lingosync_v2/SPEC.md` and `PROGRESS.md` across sessions.
9. Scope: Extend existing patterns; no mass refactors; make small atomic commits.
