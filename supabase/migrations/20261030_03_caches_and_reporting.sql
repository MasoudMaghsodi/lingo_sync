-- Migration: 20261030_03_caches_and_reporting.sql
-- Description: Global caches indexing, CEFR validation, and content error reporting flow.

-- 1. Ensure case-insensitive index on global_dictionary
CREATE INDEX IF NOT EXISTS idx_global_dict_lower_word 
ON public.global_dictionary (LOWER(word));

-- 2. Content Error Reports Table
CREATE TABLE IF NOT EXISTS public.content_error_reports (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID REFERENCES auth.users(id) ON DELETE SET NULL,
    content_type TEXT NOT NULL CHECK (content_type IN ('flashcard', 'video_analysis', 'dictionary_word', 'mentor_reply')),
    content_id TEXT NOT NULL,
    error_category TEXT NOT NULL CHECK (error_category IN ('translation', 'grammar', 'pronunciation', 'offensive', 'other')),
    user_comment TEXT,
    status TEXT NOT NULL DEFAULT 'pending' CHECK (status IN ('pending', 'investigating', 'resolved', 'rejected')),
    created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    resolved_at TIMESTAMPTZ NULL
);

-- Indexes for error triage
CREATE INDEX IF NOT EXISTS idx_content_error_reports_status 
ON public.content_error_reports (status, created_at DESC);

CREATE INDEX IF NOT EXISTS idx_content_error_reports_content 
ON public.content_error_reports (content_type, content_id);

-- Enable RLS
ALTER TABLE public.content_error_reports ENABLE ROW LEVEL SECURITY;

DO $$ BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM pg_policies 
        WHERE tablename = 'content_error_reports' AND policyname = 'Authenticated users can submit reports'
    ) THEN
        CREATE POLICY "Authenticated users can submit reports"
        ON public.content_error_reports FOR INSERT
        TO authenticated
        WITH CHECK (auth.uid() = user_id);
    END IF;

    IF NOT EXISTS (
        SELECT 1 FROM pg_policies 
        WHERE tablename = 'content_error_reports' AND policyname = 'Users can view their own submitted reports'
    ) THEN
        CREATE POLICY "Users can view their own submitted reports"
        ON public.content_error_reports FOR SELECT
        TO authenticated
        USING (auth.uid() = user_id);
    END IF;

    IF NOT EXISTS (
        SELECT 1 FROM pg_policies 
        WHERE tablename = 'content_error_reports' AND policyname = 'Service role has full report access'
    ) THEN
        CREATE POLICY "Service role has full report access"
        ON public.content_error_reports FOR ALL
        TO service_role
        USING (true)
        WITH CHECK (true);
    END IF;
END $$;
