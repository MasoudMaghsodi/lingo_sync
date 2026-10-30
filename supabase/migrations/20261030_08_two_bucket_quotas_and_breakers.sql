-- Migration: 20261030_08_two_bucket_quotas_and_breakers.sql
-- Description: Two-bucket server quotas (Live Voice + AI Actions + Turn-based sub-bucket) & tiered spend circuit breakers.

-- 1. Upgrade user_usage_quotas with AI actions and turn-based voice
ALTER TABLE public.user_usage_quotas 
    ADD COLUMN IF NOT EXISTS monthly_ai_actions_balance INTEGER NOT NULL DEFAULT 8,
    ADD COLUMN IF NOT EXISTS monthly_ai_actions_used INTEGER NOT NULL DEFAULT 0,
    ADD COLUMN IF NOT EXISTS turn_based_seconds_used INTEGER NOT NULL DEFAULT 0;

-- Update tier check constraint to include 'elite'
ALTER TABLE public.user_usage_quotas DROP CONSTRAINT IF EXISTS user_usage_quotas_tier_check;
ALTER TABLE public.user_usage_quotas ADD CONSTRAINT user_usage_quotas_tier_check 
    CHECK (tier IN ('free', 'pro', 'elite', 'unlimited'));

-- 2. Global System Config Table (Circuit Breakers & Kill Switches)
CREATE TABLE IF NOT EXISTS public.global_system_config (
    key TEXT PRIMARY KEY,
    value JSONB NOT NULL,
    description TEXT,
    updated_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- Enable RLS on global_system_config
ALTER TABLE public.global_system_config ENABLE ROW LEVEL SECURITY;

DO $$ BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM pg_policies 
        WHERE tablename = 'global_system_config' AND policyname = 'Public read global system config'
    ) THEN
        CREATE POLICY "Public read global system config"
        ON public.global_system_config FOR SELECT
        TO authenticated, anon
        USING (true);
    END IF;

    IF NOT EXISTS (
        SELECT 1 FROM pg_policies 
        WHERE tablename = 'global_system_config' AND policyname = 'Service role manage global system config'
    ) THEN
        CREATE POLICY "Service role manage global system config"
        ON public.global_system_config FOR ALL
        TO service_role
        USING (true)
        WITH CHECK (true);
    END IF;
END $$;

-- Insert default global circuit breaker settings ($25.00/day default limit)
INSERT INTO public.global_system_config (key, value, description)
VALUES 
    ('spend_circuit_breakers', '{
        "global_daily_budget_usd": 25.00,
        "alert_threshold_50_sent": false,
        "alert_threshold_80_sent": false,
        "kill_switch_active": false,
        "per_user_limits": {
            "free": 0.08,
            "pro": 0.25,
            "elite": 0.45,
            "unlimited": 100.00
        }
    }'::jsonb, 'Global and per-tier AI spend limits and alert flags')
ON CONFLICT (key) DO NOTHING;

-- 3. Function: Atomic Decrement AI Actions
CREATE OR REPLACE FUNCTION public.decrement_ai_actions(p_user_id UUID, p_count INTEGER DEFAULT 1)
RETURNS JSONB
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
    v_quota RECORD;
    v_new_balance INTEGER;
BEGIN
    SELECT * INTO v_quota
    FROM public.user_usage_quotas
    WHERE user_id = p_user_id
    FOR UPDATE;

    IF NOT FOUND THEN
        -- Initialize with pro tier default during testing
        INSERT INTO public.user_usage_quotas (
            user_id, voice_seconds_balance, voice_seconds_used_today, 
            monthly_ai_actions_balance, monthly_ai_actions_used, tier
        ) VALUES (p_user_id, 6000, 0, 40, 0, 'pro')
        RETURNING * INTO v_quota;
    END IF;

    IF v_quota.tier = 'unlimited' THEN
        UPDATE public.user_usage_quotas
        SET monthly_ai_actions_used = monthly_ai_actions_used + p_count,
            updated_at = now()
        WHERE user_id = p_user_id;

        RETURN jsonb_build_object(
            'allowed', true,
            'balance', 99999,
            'actions_used', v_quota.monthly_ai_actions_used + p_count,
            'tier', 'unlimited'
        );
    END IF;

    v_new_balance := v_quota.monthly_ai_actions_balance - p_count;

    IF v_new_balance < 0 THEN
        RETURN jsonb_build_object(
            'allowed', false,
            'balance', v_quota.monthly_ai_actions_balance,
            'actions_used', v_quota.monthly_ai_actions_used,
            'tier', v_quota.tier,
            'reason', 'insufficient_ai_actions'
        );
    END IF;

    UPDATE public.user_usage_quotas
    SET monthly_ai_actions_balance = v_new_balance,
        monthly_ai_actions_used = monthly_ai_actions_used + p_count,
        updated_at = now()
    WHERE user_id = p_user_id;

    RETURN jsonb_build_object(
        'allowed', true,
        'balance', v_new_balance,
        'actions_used', v_quota.monthly_ai_actions_used + p_count,
        'tier', v_quota.tier
    );
END;
$$;

-- 4. Function: Check Global and User Spend Breakers
CREATE OR REPLACE FUNCTION public.check_spend_breakers(p_user_id UUID, p_user_tier TEXT DEFAULT 'pro')
RETURNS JSONB
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
    v_config RECORD;
    v_global_spend NUMERIC;
    v_user_spend NUMERIC;
    v_global_limit NUMERIC;
    v_user_limit NUMERIC;
    v_kill_switch BOOLEAN;
    v_today_start TIMESTAMPTZ := date_trunc('day', timezone('Asia/Tehran', now()));
BEGIN
    SELECT value INTO v_config
    FROM public.global_system_config
    WHERE key = 'spend_circuit_breakers';

    v_global_limit := COALESCE((v_config.value->>'global_daily_budget_usd')::NUMERIC, 25.00);
    v_kill_switch := COALESCE((v_config.value->>'kill_switch_active')::BOOLEAN, false);
    v_user_limit := COALESCE((v_config.value->'per_user_limits'->>p_user_tier)::NUMERIC, 0.25);

    -- Calculate global spend today (Tehran time)
    SELECT COALESCE(SUM(cost_estimate_usd), 0) INTO v_global_spend
    FROM public.ai_telemetry_logs
    WHERE created_at >= v_today_start;

    -- Calculate user spend today
    IF p_user_id IS NOT NULL THEN
        SELECT COALESCE(SUM(cost_estimate_usd), 0) INTO v_user_spend
        FROM public.ai_telemetry_logs
        WHERE user_id = p_user_id AND created_at >= v_today_start;
    ELSE
        v_user_spend := 0;
    END IF;

    RETURN jsonb_build_object(
        'allowed', (NOT v_kill_switch) AND (v_global_spend < v_global_limit) AND (v_user_spend < v_user_limit),
        'global_spend_usd', v_global_spend,
        'global_limit_usd', v_global_limit,
        'global_kill_switch', v_kill_switch,
        'user_spend_usd', v_user_spend,
        'user_limit_usd', v_user_limit,
        'tier', p_user_tier
    );
END;
$$;
