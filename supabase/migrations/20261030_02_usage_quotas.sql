-- Migration: 20261030_02_usage_quotas.sql
-- Description: Server-side Voice Quotas, Atomic Decrement Metering & Tier Management.

-- 1. User Usage Quotas Table
CREATE TABLE IF NOT EXISTS public.user_usage_quotas (
    user_id UUID PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
    voice_seconds_balance INTEGER NOT NULL DEFAULT 900, -- 15 mins daily free
    voice_seconds_used_today INTEGER NOT NULL DEFAULT 0,
    tier TEXT NOT NULL DEFAULT 'free' CHECK (tier IN ('free', 'pro', 'unlimited')),
    last_reset_date DATE NOT NULL DEFAULT CURRENT_DATE,
    created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- Index for tier and reset queries
CREATE INDEX IF NOT EXISTS idx_user_usage_quotas_reset 
ON public.user_usage_quotas (last_reset_date, tier);

-- Enable RLS
ALTER TABLE public.user_usage_quotas ENABLE ROW LEVEL SECURITY;

DO $$ BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM pg_policies 
        WHERE tablename = 'user_usage_quotas' AND policyname = 'Users can view their own quota'
    ) THEN
        CREATE POLICY "Users can view their own quota"
        ON public.user_usage_quotas FOR SELECT
        TO authenticated
        USING (auth.uid() = user_id);
    END IF;

    IF NOT EXISTS (
        SELECT 1 FROM pg_policies 
        WHERE tablename = 'user_usage_quotas' AND policyname = 'Service role has full quota access'
    ) THEN
        CREATE POLICY "Service role has full quota access"
        ON public.user_usage_quotas FOR ALL
        TO service_role
        USING (true)
        WITH CHECK (true);
    END IF;
END $$;

-- 2. Function: Get or Initialize User Quota with auto-reset
CREATE OR REPLACE FUNCTION public.get_user_quota(p_user_id UUID)
RETURNS JSONB
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
    v_quota RECORD;
    v_today DATE := CURRENT_DATE;
BEGIN
    SELECT * INTO v_quota
    FROM public.user_usage_quotas
    WHERE user_id = p_user_id;

    IF NOT FOUND THEN
        INSERT INTO public.user_usage_quotas (user_id, voice_seconds_balance, voice_seconds_used_today, tier, last_reset_date)
        VALUES (p_user_id, 900, 0, 'free', v_today)
        RETURNING * INTO v_quota;
    ELSIF v_quota.last_reset_date < v_today THEN
        -- Daily reset for free accounts
        UPDATE public.user_usage_quotas
        SET voice_seconds_used_today = 0,
            voice_seconds_balance = CASE 
                WHEN tier = 'free' THEN 900 
                ELSE voice_seconds_balance 
            END,
            last_reset_date = v_today,
            updated_at = now()
        WHERE user_id = p_user_id
        RETURNING * INTO v_quota;
    END IF;

    RETURN jsonb_build_object(
        'user_id', v_quota.user_id,
        'voice_seconds_balance', v_quota.voice_seconds_balance,
        'voice_seconds_used_today', v_quota.voice_seconds_used_today,
        'tier', v_quota.tier,
        'last_reset_date', v_quota.last_reset_date
    );
END;
$$;

-- 3. Function: Atomic Decrement Voice Seconds
CREATE OR REPLACE FUNCTION public.decrement_voice_seconds(p_user_id UUID, p_seconds INTEGER)
RETURNS JSONB
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
    v_quota RECORD;
    v_today DATE := CURRENT_DATE;
    v_new_balance INTEGER;
BEGIN
    -- Ensure row exists and is reset if needed
    PERFORM public.get_user_quota(p_user_id);

    SELECT * INTO v_quota
    FROM public.user_usage_quotas
    WHERE user_id = p_user_id
    FOR UPDATE;

    -- Unlimited tier bypass
    IF v_quota.tier = 'unlimited' THEN
        UPDATE public.user_usage_quotas
        SET voice_seconds_used_today = voice_seconds_used_today + p_seconds,
            updated_at = now()
        WHERE user_id = p_user_id;

        RETURN jsonb_build_object(
            'allowed', true,
            'balance', 999999,
            'seconds_used_today', v_quota.voice_seconds_used_today + p_seconds,
            'tier', 'unlimited'
        );
    END IF;

    -- Check balance
    v_new_balance := v_quota.voice_seconds_balance - p_seconds;

    IF v_new_balance < 0 THEN
        RETURN jsonb_build_object(
            'allowed', false,
            'balance', v_quota.voice_seconds_balance,
            'seconds_used_today', v_quota.voice_seconds_used_today,
            'tier', v_quota.tier,
            'reason', 'insufficient_balance'
        );
    END IF;

    -- Atomic decrement
    UPDATE public.user_usage_quotas
    SET voice_seconds_balance = v_new_balance,
        voice_seconds_used_today = voice_seconds_used_today + p_seconds,
        updated_at = now()
    WHERE user_id = p_user_id;

    RETURN jsonb_build_object(
        'allowed', true,
        'balance', v_new_balance,
        'seconds_used_today', v_quota.voice_seconds_used_today + p_seconds,
        'tier', v_quota.tier
    );
END;
$$;
