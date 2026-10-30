-- Migration: 20261030_07_exam_twin_and_leagues.sql
-- Description: Exam Twin (IELTS/TOEFL speaking attempts and scoring) & Cohort Leagues schema.

-- 1. Create exam_attempts table
CREATE TABLE IF NOT EXISTS public.exam_attempts (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    exam_type TEXT NOT NULL CHECK (exam_type IN ('ielts_speaking', 'toefl_speaking')),
    part_number INT DEFAULT 1 CHECK (part_number BETWEEN 1 AND 3),
    overall_band DOUBLE PRECISION CHECK (overall_band >= 0.0 AND overall_band <= 9.0),
    fluency_coherence_score DOUBLE PRECISION,
    lexical_resource_score DOUBLE PRECISION,
    grammatical_range_score DOUBLE PRECISION,
    pronunciation_score DOUBLE PRECISION,
    feedback_fa TEXT,
    detailed_rubric JSONB DEFAULT '{}'::jsonb,
    transcript_quotes JSONB DEFAULT '[]'::jsonb,
    is_calibrated BOOLEAN NOT NULL DEFAULT false,
    duration_seconds INT DEFAULT 0,
    created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- Indexes
CREATE INDEX IF NOT EXISTS idx_exam_attempts_user 
    ON public.exam_attempts(user_id, created_at DESC);

-- Enable RLS
ALTER TABLE public.exam_attempts ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "Users can read own exam attempts" ON public.exam_attempts;
CREATE POLICY "Users can read own exam attempts"
    ON public.exam_attempts
    FOR SELECT
    USING (auth.uid() = user_id);

DROP POLICY IF EXISTS "Users can insert own exam attempts" ON public.exam_attempts;
CREATE POLICY "Users can insert own exam attempts"
    ON public.exam_attempts
    FOR INSERT
    WITH CHECK (auth.uid() = user_id);

-- 2. Create cohort_leagues table
CREATE TABLE IF NOT EXISTS public.cohort_leagues (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    league_name TEXT NOT NULL,
    cefr_level TEXT NOT NULL DEFAULT 'B2',
    week_start DATE NOT NULL DEFAULT CURRENT_DATE,
    created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- Enable RLS
ALTER TABLE public.cohort_leagues ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "Authenticated users can read leagues" ON public.cohort_leagues;
CREATE POLICY "Authenticated users can read leagues"
    ON public.cohort_leagues
    FOR SELECT
    TO authenticated
    USING (true);

-- 3. Create league_members table
CREATE TABLE IF NOT EXISTS public.league_members (
    league_id UUID NOT NULL REFERENCES public.cohort_leagues(id) ON DELETE CASCADE,
    user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    weekly_xp INT NOT NULL DEFAULT 0,
    rank INT NOT NULL DEFAULT 1,
    updated_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    PRIMARY KEY (league_id, user_id)
);

-- Enable RLS
ALTER TABLE public.league_members ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "Authenticated users can read league members" ON public.league_members;
CREATE POLICY "Authenticated users can read league members"
    ON public.league_members
    FOR SELECT
    TO authenticated
    USING (true);

DROP POLICY IF EXISTS "Users can update own league member record" ON public.league_members;
CREATE POLICY "Users can update own league member record"
    ON public.league_members
    FOR UPDATE
    USING (auth.uid() = user_id);
