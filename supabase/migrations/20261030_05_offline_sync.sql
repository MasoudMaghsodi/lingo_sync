-- Migration: 20261030_05_offline_sync.sql
-- Description: Implement offline-first SRS review logs, idempotent sync RPC, and conflict-free replay.

-- 1. Create append-only srs_review_logs table for idempotent sync
CREATE TABLE IF NOT EXISTS public.srs_review_logs (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    flashcard_id BIGINT NOT NULL,
    client_event_id UUID NOT NULL,
    device_id TEXT,
    quality INT NOT NULL CHECK (quality BETWEEN 0 AND 5),
    repetition INT,
    interval INT,
    ease_factor DOUBLE PRECISION,
    reviewed_at TIMESTAMPTZ NOT NULL,
    server_received_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    CONSTRAINT unique_user_client_event UNIQUE (user_id, client_event_id)
);

-- Indexes for efficient queries and analytics
CREATE INDEX IF NOT EXISTS idx_srs_review_logs_user_flashcard 
    ON public.srs_review_logs(user_id, flashcard_id);

CREATE INDEX IF NOT EXISTS idx_srs_review_logs_reviewed_at 
    ON public.srs_review_logs(user_id, reviewed_at DESC);

-- Enable RLS
ALTER TABLE public.srs_review_logs ENABLE ROW LEVEL SECURITY;

-- RLS Policies
DROP POLICY IF EXISTS "Users can read own srs review logs" ON public.srs_review_logs;
CREATE POLICY "Users can read own srs review logs"
    ON public.srs_review_logs
    FOR SELECT
    USING (auth.uid() = user_id);

DROP POLICY IF EXISTS "Users can insert own srs review logs" ON public.srs_review_logs;
CREATE POLICY "Users can insert own srs review logs"
    ON public.srs_review_logs
    FOR INSERT
    WITH CHECK (auth.uid() = user_id);

-- 2. Idempotent Batch Sync RPC function
CREATE OR REPLACE FUNCTION public.sync_srs_reviews(p_reviews JSONB)
RETURNS JSONB
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, auth
AS $$
DECLARE
    v_user_id UUID;
    v_review JSONB;
    v_synced_count INT := 0;
    v_skipped_count INT := 0;
    v_client_event_id UUID;
    v_flashcard_id BIGINT;
    v_quality INT;
    v_repetition INT;
    v_interval INT;
    v_ease_factor DOUBLE PRECISION;
    v_next_review_date TIMESTAMPTZ;
    v_reviewed_at TIMESTAMPTZ;
    v_device_id TEXT;
    v_inserted_rows INT;
BEGIN
    v_user_id := auth.uid();
    IF v_user_id IS NULL THEN
        RAISE EXCEPTION 'Not authenticated';
    END IF;

    IF jsonb_typeof(p_reviews) IS DISTINCT FROM 'array' THEN
        RAISE EXCEPTION 'p_reviews must be a JSON array';
    END IF;

    FOR v_review IN SELECT * FROM jsonb_array_elements(p_reviews)
    LOOP
        v_client_event_id := (v_review->>'client_event_id')::UUID;
        v_flashcard_id := (v_review->>'flashcard_id')::BIGINT;
        v_quality := (v_review->>'quality')::INT;
        v_repetition := (v_review->>'repetition')::INT;
        v_interval := (v_review->>'interval')::INT;
        v_ease_factor := (v_review->>'ease_factor')::DOUBLE PRECISION;
        v_reviewed_at := COALESCE((v_review->>'reviewed_at')::TIMESTAMPTZ, now());
        v_next_review_date := (v_review->>'next_review_date')::TIMESTAMPTZ;
        v_device_id := v_review->>'device_id';

        -- 1. Insert review log with idempotent deduplication
        INSERT INTO public.srs_review_logs (
            user_id,
            flashcard_id,
            client_event_id,
            device_id,
            quality,
            repetition,
            interval,
            ease_factor,
            reviewed_at,
            server_received_at
        ) VALUES (
            v_user_id,
            v_flashcard_id,
            v_client_event_id,
            v_device_id,
            v_quality,
            v_repetition,
            v_interval,
            v_ease_factor,
            v_reviewed_at,
            now()
        )
        ON CONFLICT (user_id, client_event_id) DO NOTHING;

        GET DIAGNOSTICS v_inserted_rows = ROW_COUNT;

        IF v_inserted_rows > 0 THEN
            v_synced_count := v_synced_count + 1;

            -- 2. Update flashcards table with latest SM-2 schedule
            UPDATE public.flashcards
            SET 
                repetition = COALESCE(v_repetition, repetition),
                interval = COALESCE(v_interval, interval),
                ease_factor = COALESCE(v_ease_factor, ease_factor),
                next_review_date = COALESCE(v_next_review_date, next_review_date),
                updated_at = now()
            WHERE id = v_flashcard_id AND user_id = v_user_id;

        ELSE
            v_skipped_count := v_skipped_count + 1;
        END IF;
    END LOOP;

    RETURN jsonb_build_object(
        'success', true,
        'synced_count', v_synced_count,
        'skipped_count', v_skipped_count,
        'total', jsonb_array_length(p_reviews)
    );
END;
$$;
