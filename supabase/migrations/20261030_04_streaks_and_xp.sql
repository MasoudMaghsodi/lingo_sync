-- Migration: 20261030_04_streaks_and_xp.sql
-- Description: Resilient streak tracking, streak freeze protection, vacation backlog mode, and competence XP.

-- 1. Add streak resilience & timezone columns to user_stats
ALTER TABLE public.user_stats
ADD COLUMN IF NOT EXISTS streak_freeze_count INTEGER NOT NULL DEFAULT 1,
ADD COLUMN IF NOT EXISTS is_vacation_mode BOOLEAN NOT NULL DEFAULT false,
ADD COLUMN IF NOT EXISTS vacation_until DATE NULL,
ADD COLUMN IF NOT EXISTS timezone TEXT NOT NULL DEFAULT 'Asia/Tehran';

-- 2. Function: Evaluate and Update User Streak atomically
CREATE OR REPLACE FUNCTION public.evaluate_user_streak(
    p_user_id UUID,
    p_client_date DATE DEFAULT CURRENT_DATE
)
RETURNS JSONB
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
    v_stats RECORD;
    v_last_date DATE;
    v_streak INTEGER;
    v_freezes INTEGER;
    v_vacation BOOLEAN;
    v_diff INTEGER;
    v_freeze_used BOOLEAN := false;
BEGIN
    SELECT * INTO v_stats
    FROM public.user_stats
    WHERE id = p_user_id
    FOR UPDATE;

    IF NOT FOUND THEN
        RETURN jsonb_build_object('error', 'User stats not found');
    END IF;

    v_last_date := v_stats.last_active_date;
    v_streak := COALESCE(v_stats.streak_days, 0);
    v_freezes := COALESCE(v_stats.streak_freeze_count, 1);
    v_vacation := COALESCE(v_stats.is_vacation_mode, false);

    -- 1. First time active
    IF v_last_date IS NULL THEN
        v_streak := 1;
    -- 2. Already active today
    ELSIF v_last_date = p_client_date THEN
        -- Keep existing streak unchanged
        NULL;
    ELSE
        v_diff := p_client_date - v_last_date;

        -- 3. Consecutive day (yesterday was active)
        IF v_diff = 1 THEN
            v_streak := v_streak + 1;
        -- 4. Vacation mode active
        ELSIF v_vacation AND (v_stats.vacation_until IS NULL OR p_client_date <= v_stats.vacation_until) THEN
            v_streak := v_streak + 1;
        -- 5. Missed 1 day (diff = 2) and freeze available
        ELSIF v_diff = 2 AND v_freezes > 0 THEN
            v_freezes := v_freezes - 1;
            v_streak := v_streak + 1;
            v_freeze_used := true;
        -- 6. Streak broken
        ELSE
            v_streak := 1;
        END IF;
    END IF;

    -- Update user_stats
    UPDATE public.user_stats
    SET streak_days = v_streak,
        streak_freeze_count = v_freezes,
        last_active_date = p_client_date,
        last_active = now()
    WHERE id = p_user_id;

    RETURN jsonb_build_object(
        'user_id', p_user_id,
        'streak_days', v_streak,
        'streak_freeze_count', v_freezes,
        'freeze_used', v_freeze_used,
        'last_active_date', p_client_date,
        'is_vacation_mode', v_vacation
    );
END;
$$;

-- 3. Function: Toggle Vacation Mode
CREATE OR REPLACE FUNCTION public.set_vacation_mode(
    p_user_id UUID,
    p_enabled BOOLEAN,
    p_until DATE DEFAULT NULL
)
RETURNS JSONB
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
BEGIN
    UPDATE public.user_stats
    SET is_vacation_mode = p_enabled,
        vacation_until = p_until,
        last_active = now()
    WHERE id = p_user_id;

    RETURN jsonb_build_object(
        'user_id', p_user_id,
        'is_vacation_mode', p_enabled,
        'vacation_until', p_until
    );
END;
$$;
