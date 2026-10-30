-- Migration: 20261030_06_error_genome_and_subscriptions.sql
-- Description: Personal Error Genome tracking, error-driven SRS cards, and subscription entitlements.

-- 1. Create user_error_genome table
CREATE TABLE IF NOT EXISTS public.user_error_genome (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    category TEXT NOT NULL,
    verbatim_quote TEXT NOT NULL,
    corrected_version TEXT NOT NULL,
    explanation_fa TEXT,
    audio_timestamp TEXT,
    confidence DOUBLE PRECISION NOT NULL CHECK (confidence >= 0.6 AND confidence <= 1.0),
    l1_interference_flag BOOLEAN NOT NULL DEFAULT true,
    taxonomy_version TEXT NOT NULL DEFAULT 'v1',
    remediation_stage INT NOT NULL DEFAULT 1 CHECK (remediation_stage BETWEEN 1 AND 5),
    occurrence_count INT NOT NULL DEFAULT 1,
    last_seen_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- Unique constraint for deduping per user + category + normalized quote
CREATE UNIQUE INDEX IF NOT EXISTS idx_error_genome_dedup 
    ON public.user_error_genome (user_id, category, LOWER(TRIM(verbatim_quote)));

CREATE INDEX IF NOT EXISTS idx_error_genome_user_stage 
    ON public.user_error_genome (user_id, remediation_stage);

-- Enable RLS
ALTER TABLE public.user_error_genome ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "Users can read own error genome" ON public.user_error_genome;
CREATE POLICY "Users can read own error genome"
    ON public.user_error_genome
    FOR SELECT
    USING (auth.uid() = user_id);

DROP POLICY IF EXISTS "Users can insert own error genome" ON public.user_error_genome;
CREATE POLICY "Users can insert own error genome"
    ON public.user_error_genome
    FOR INSERT
    WITH CHECK (auth.uid() = user_id);

DROP POLICY IF EXISTS "Users can update own error genome" ON public.user_error_genome;
CREATE POLICY "Users can update own error genome"
    ON public.user_error_genome
    FOR UPDATE
    USING (auth.uid() = user_id);

-- 2. Create user_subscriptions table
CREATE TABLE IF NOT EXISTS public.user_subscriptions (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE UNIQUE,
    tier TEXT NOT NULL DEFAULT 'free' CHECK (tier IN ('free', 'plus', 'exam_pro', 'sprint_pass')),
    status TEXT NOT NULL DEFAULT 'active' CHECK (status IN ('active', 'expired', 'cancelled', 'grace_period')),
    provider TEXT NOT NULL DEFAULT 'mock' CHECK (provider IN ('mock', 'bazaar', 'myket', 'zarinpal', 'stripe', 'play_store', 'app_store')),
    transaction_id TEXT,
    expires_at TIMESTAMPTZ,
    renews_at TIMESTAMPTZ,
    details JSONB DEFAULT '{}'::jsonb,
    created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- Enable RLS
ALTER TABLE public.user_subscriptions ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "Users can read own subscription" ON public.user_subscriptions;
CREATE POLICY "Users can read own subscription"
    ON public.user_subscriptions
    FOR SELECT
    USING (auth.uid() = user_id);

-- 3. Entitlement & Quota RPC
CREATE OR REPLACE FUNCTION public.get_user_entitlements(p_user_id UUID)
RETURNS JSONB
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, auth
AS $$
DECLARE
    v_tier TEXT := 'free';
    v_status TEXT := 'active';
    v_expires_at TIMESTAMPTZ;
BEGIN
    SELECT tier, status, expires_at
    INTO v_tier, v_status, v_expires_at
    FROM public.user_subscriptions
    WHERE user_id = p_user_id;

    -- If expired, downgrade to free
    IF v_expires_at IS NOT NULL AND v_expires_at < now() THEN
        v_tier := 'free';
    END IF;

    IF v_tier IS NULL THEN
        v_tier := 'free';
    END IF;

    IF v_tier = 'exam_pro' THEN
        RETURN jsonb_build_object(
            'tier', 'exam_pro',
            'voice_minutes_monthly', 400,
            'video_extractions_weekly', 999,
            'council_daily_calls', 20,
            'exam_twin_enabled', true,
            'c1_studio_enabled', true
        );
    ELSIF v_tier = 'plus' THEN
        RETURN jsonb_build_object(
            'tier', 'plus',
            'voice_minutes_monthly', 150,
            'video_extractions_weekly', 10,
            'council_daily_calls', 3,
            'exam_twin_enabled', false,
            'c1_studio_enabled', true
        );
    ELSIF v_tier = 'sprint_pass' THEN
        RETURN jsonb_build_object(
            'tier', 'sprint_pass',
            'voice_minutes_monthly', 200,
            'video_extractions_weekly', 25,
            'council_daily_calls', 5,
            'exam_twin_enabled', true,
            'c1_studio_enabled', true
        );
    ELSE
        -- Free Tier defaults
        RETURN jsonb_build_object(
            'tier', 'free',
            'voice_minutes_monthly', 10,
            'video_extractions_weekly', 1,
            'council_daily_calls', 1,
            'exam_twin_enabled', false,
            'c1_studio_enabled', false
        );
    END IF;
END;
$$;
