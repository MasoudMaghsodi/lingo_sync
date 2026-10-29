-- Migration: 20261030_01_telemetry_and_pricing.sql
-- Description: AI model pricing configuration, telemetry logs, and daily spend circuit breaker.

-- 1. AI Pricing Configuration Table
CREATE TABLE IF NOT EXISTS public.ai_pricing_config (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    model_id TEXT NOT NULL,
    modality TEXT NOT NULL CHECK (modality IN ('text', 'audio', 'image')),
    direction TEXT NOT NULL CHECK (direction IN ('input', 'output')),
    usd_per_million_tokens NUMERIC(10, 4) NOT NULL,
    effective_from TIMESTAMPTZ NOT NULL DEFAULT now(),
    effective_to TIMESTAMPTZ NULL,
    created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- Index for active pricing lookup
CREATE INDEX IF NOT EXISTS idx_ai_pricing_lookup 
ON public.ai_pricing_config (model_id, modality, direction, effective_from DESC);

-- Enable RLS
ALTER TABLE public.ai_pricing_config ENABLE ROW LEVEL SECURITY;

-- Read policy: authenticated and anon users can view active pricing
DO $$ BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM pg_policies 
        WHERE tablename = 'ai_pricing_config' AND policyname = 'Allow read access to pricing for all users'
    ) THEN
        CREATE POLICY "Allow read access to pricing for all users"
        ON public.ai_pricing_config FOR SELECT
        TO authenticated, anon
        USING (true);
    END IF;
END $$;

-- 2. Seed Initial Pricing Data (Gemini 3.x Family & Live)
INSERT INTO public.ai_pricing_config (model_id, modality, direction, usd_per_million_tokens)
VALUES
    ('gemini-3.8-flash', 'text', 'input', 0.15),
    ('gemini-3.8-flash', 'text', 'output', 0.60),
    ('gemini-3.6-flash', 'text', 'input', 0.10),
    ('gemini-3.6-flash', 'text', 'output', 0.40),
    ('gemini-3.5-flash-lite', 'text', 'input', 0.075),
    ('gemini-3.5-flash-lite', 'text', 'output', 0.30),
    ('gemini-3.1-flash-lite', 'text', 'input', 0.075),
    ('gemini-3.1-flash-lite', 'text', 'output', 0.30),
    ('gemini-3.8-live', 'text', 'input', 0.15),
    ('gemini-3.8-live', 'audio', 'input', 0.60),
    ('gemini-3.8-live', 'audio', 'output', 2.40)
ON CONFLICT DO NOTHING;

-- 3. AI Telemetry Logs Table
CREATE TABLE IF NOT EXISTS public.ai_telemetry_logs (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    module TEXT NOT NULL,
    model TEXT NOT NULL,
    fallback_triggered BOOLEAN NOT NULL DEFAULT false,
    tokens_in INTEGER NOT NULL DEFAULT 0,
    tokens_out INTEGER NOT NULL DEFAULT 0,
    audio_seconds_in NUMERIC(8, 2) NOT NULL DEFAULT 0,
    audio_seconds_out NUMERIC(8, 2) NOT NULL DEFAULT 0,
    latency_ms INTEGER NOT NULL DEFAULT 0,
    cost_estimate_usd NUMERIC(10, 6) NOT NULL DEFAULT 0,
    user_id UUID REFERENCES auth.users(id) ON DELETE SET NULL,
    created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- Indexes for performance & daily rollup queries
CREATE INDEX IF NOT EXISTS idx_ai_telemetry_user_daily 
ON public.ai_telemetry_logs (user_id, created_at DESC);

CREATE INDEX IF NOT EXISTS idx_ai_telemetry_module_model 
ON public.ai_telemetry_logs (module, model, created_at DESC);

-- Enable RLS
ALTER TABLE public.ai_telemetry_logs ENABLE ROW LEVEL SECURITY;

-- Policies for telemetry
DO $$ BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM pg_policies 
        WHERE tablename = 'ai_telemetry_logs' AND policyname = 'Users can view their own telemetry'
    ) THEN
        CREATE POLICY "Users can view their own telemetry"
        ON public.ai_telemetry_logs FOR SELECT
        TO authenticated
        USING (auth.uid() = user_id);
    END IF;

    IF NOT EXISTS (
        SELECT 1 FROM pg_policies 
        WHERE tablename = 'ai_telemetry_logs' AND policyname = 'Service role has full access'
    ) THEN
        CREATE POLICY "Service role has full access"
        ON public.ai_telemetry_logs FOR ALL
        TO service_role
        USING (true)
        WITH CHECK (true);
    END IF;
END $$;

-- 4. Circuit Breaker RPC: Check Daily Spend & Quota Cap ($1.50 default)
CREATE OR REPLACE FUNCTION public.check_user_ai_spend(p_user_id UUID, p_daily_limit_usd NUMERIC DEFAULT 1.50)
RETURNS JSONB
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
    v_today_spend NUMERIC;
    v_exceeded BOOLEAN;
BEGIN
    SELECT COALESCE(SUM(cost_estimate_usd), 0)
    INTO v_today_spend
    FROM public.ai_telemetry_logs
    WHERE user_id = p_user_id
      AND created_at >= date_trunc('day', now());

    v_exceeded := (v_today_spend >= p_daily_limit_usd);

    RETURN jsonb_build_object(
        'user_id', p_user_id,
        'today_spend_usd', v_today_spend,
        'daily_limit_usd', p_daily_limit_usd,
        'quota_exceeded', v_exceeded,
        'remaining_usd', GREATEST(0, p_daily_limit_usd - v_today_spend)
    );
END;
$$;
