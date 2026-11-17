-- ==============================================================================
-- Migration: 0012_focus_time.sql
-- Modul: Fokus & Waktu (Focus Sessions / Pomodoro & Time Tracking Entries)
-- Fase: 11
-- Standar: RLS 100%, FK Komposit (id, user_id), Soft Delete, Zero Anon
-- ==============================================================================

-- ------------------------------------------------------------------------------
-- 1. TABEL: public.focus_sessions (Sesi Fokus / Pomodoro)
-- ------------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS public.focus_sessions (
    id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id uuid NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    task_id uuid,
    project_id uuid,
    started_at timestamptz NOT NULL DEFAULT now(),
    ended_at timestamptz,
    planned_minutes integer NOT NULL DEFAULT 25 CHECK (planned_minutes > 0),
    actual_minutes integer NOT NULL DEFAULT 0 CHECK (actual_minutes >= 0),
    completed boolean NOT NULL DEFAULT true,
    session_type text NOT NULL DEFAULT 'pomodoro' CHECK (session_type IN ('pomodoro', 'short_break', 'long_break', 'custom')),
    note text,
    deleted_at timestamptz,
    created_at timestamptz NOT NULL DEFAULT now(),
    updated_at timestamptz NOT NULL DEFAULT now(),

    CONSTRAINT uq_focus_sessions_user UNIQUE (id, user_id),
    CONSTRAINT fk_focus_sessions_task FOREIGN KEY (task_id, user_id)
        REFERENCES public.tasks(id, user_id) ON DELETE SET NULL,
    CONSTRAINT fk_focus_sessions_project FOREIGN KEY (project_id, user_id)
        REFERENCES public.projects(id, user_id) ON DELETE SET NULL
);

CREATE INDEX IF NOT EXISTS idx_focus_sessions_user_started ON public.focus_sessions(user_id, started_at DESC);
CREATE INDEX IF NOT EXISTS idx_focus_sessions_task ON public.focus_sessions(task_id, user_id);

-- ------------------------------------------------------------------------------
-- 2. TABEL: public.time_entries (Pelacak Waktu / Timesheet Aktivitas & Proyek)
-- ------------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS public.time_entries (
    id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id uuid NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    project_id uuid,
    activity text NOT NULL,
    started_at timestamptz NOT NULL DEFAULT now(),
    ended_at timestamptz,
    duration_seconds integer NOT NULL DEFAULT 0 CHECK (duration_seconds >= 0),
    note text,
    deleted_at timestamptz,
    created_at timestamptz NOT NULL DEFAULT now(),
    updated_at timestamptz NOT NULL DEFAULT now(),

    CONSTRAINT uq_time_entries_user UNIQUE (id, user_id),
    CONSTRAINT fk_time_entries_project FOREIGN KEY (project_id, user_id)
        REFERENCES public.projects(id, user_id) ON DELETE SET NULL
);

CREATE INDEX IF NOT EXISTS idx_time_entries_user_started ON public.time_entries(user_id, started_at DESC);
CREATE INDEX IF NOT EXISTS idx_time_entries_project ON public.time_entries(project_id, user_id);

-- ------------------------------------------------------------------------------
-- 3. TRIGGERS: updated_at
-- ------------------------------------------------------------------------------
CREATE TRIGGER trg_focus_sessions_updated_at
    BEFORE UPDATE ON public.focus_sessions
    FOR EACH ROW EXECUTE FUNCTION public.handle_updated_at();

CREATE TRIGGER trg_time_entries_updated_at
    BEFORE UPDATE ON public.time_entries
    FOR EACH ROW EXECUTE FUNCTION public.handle_updated_at();

-- ------------------------------------------------------------------------------
-- 4. ROW LEVEL SECURITY (RLS) & GRANTS
-- ------------------------------------------------------------------------------
ALTER TABLE public.focus_sessions ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.time_entries ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users can manage own focus sessions"
    ON public.focus_sessions FOR ALL
    USING (user_id = auth.uid())
    WITH CHECK (user_id = auth.uid());

CREATE POLICY "Users can manage own time entries"
    ON public.time_entries FOR ALL
    USING (user_id = auth.uid())
    WITH CHECK (user_id = auth.uid());

REVOKE ALL ON TABLE public.focus_sessions FROM anon;
REVOKE ALL ON TABLE public.time_entries FROM anon;

GRANT SELECT, INSERT, UPDATE, DELETE ON TABLE public.focus_sessions TO authenticated;
GRANT SELECT, INSERT, UPDATE, DELETE ON TABLE public.time_entries TO authenticated;
