-- ==============================================================================
-- Migration: 0013_reflection_goals.sql
-- Modul: Refleksi Diri & Sasaran (Journal, Mood Tracker, Reviews, Goals & OKRs)
-- Fase: 12
-- Standar: RLS 100%, FK Komposit (id, user_id), Soft Delete, Zero Anon
-- ==============================================================================

-- ------------------------------------------------------------------------------
-- 1. TABEL: public.journal_entries (Jurnal & Refleksi Harian)
-- ------------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS public.journal_entries (
    id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id uuid NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    entry_date date NOT NULL,
    prompt text,
    content text NOT NULL,
    deleted_at timestamptz,
    created_at timestamptz NOT NULL DEFAULT now(),
    updated_at timestamptz NOT NULL DEFAULT now(),

    CONSTRAINT uq_journal_entries_user UNIQUE (id, user_id),
    CONSTRAINT uq_journal_entries_date UNIQUE (user_id, entry_date)
);

CREATE INDEX IF NOT EXISTS idx_journal_entries_user_date ON public.journal_entries(user_id, entry_date DESC);

-- ------------------------------------------------------------------------------
-- 2. TABEL: public.mood_logs (Pelacak Mood Harian)
-- ------------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS public.mood_logs (
    id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id uuid NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    log_date date NOT NULL,
    score smallint NOT NULL CHECK (score BETWEEN 1 AND 5), -- 1: Sangat Buruk, 5: Luar Biasa
    tags jsonb NOT NULL DEFAULT '[]'::jsonb,
    note text,
    deleted_at timestamptz,
    created_at timestamptz NOT NULL DEFAULT now(),
    updated_at timestamptz NOT NULL DEFAULT now(),

    CONSTRAINT uq_mood_logs_user UNIQUE (id, user_id),
    CONSTRAINT uq_mood_logs_date UNIQUE (user_id, log_date)
);

CREATE INDEX IF NOT EXISTS idx_mood_logs_user_date ON public.mood_logs(user_id, log_date DESC);

-- ------------------------------------------------------------------------------
-- 3. TABEL: public.reviews (Evaluasi Berkala: Harian, Mingguan, Bulanan)
-- ------------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS public.reviews (
    id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id uuid NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    period text NOT NULL CHECK (period IN ('daily', 'weekly', 'monthly')),
    period_start date NOT NULL,
    answers jsonb NOT NULL DEFAULT '{}'::jsonb,
    deleted_at timestamptz,
    created_at timestamptz NOT NULL DEFAULT now(),
    updated_at timestamptz NOT NULL DEFAULT now(),

    CONSTRAINT uq_reviews_user UNIQUE (id, user_id),
    CONSTRAINT uq_reviews_user_period UNIQUE (user_id, period, period_start)
);

CREATE INDEX IF NOT EXISTS idx_reviews_user_period ON public.reviews(user_id, period, period_start DESC);

-- ------------------------------------------------------------------------------
-- 4. TABEL: public.goals (Sasaran / Tujuan Jangka Panjang)
-- ------------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS public.goals (
    id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id uuid NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    title text NOT NULL,
    description text,
    target_date date,
    status text NOT NULL DEFAULT 'active' CHECK (status IN ('active', 'completed', 'paused', 'cancelled')),
    archived_at timestamptz,
    deleted_at timestamptz,
    created_at timestamptz NOT NULL DEFAULT now(),
    updated_at timestamptz NOT NULL DEFAULT now(),

    CONSTRAINT uq_goals_user UNIQUE (id, user_id)
);

CREATE INDEX IF NOT EXISTS idx_goals_user_status ON public.goals(user_id, status);

-- ------------------------------------------------------------------------------
-- 5. TABEL: public.key_results (Hasil Kunci Terukur / Key Results)
-- ------------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS public.key_results (
    id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id uuid NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    goal_id uuid NOT NULL,
    title text NOT NULL,
    metric_type text NOT NULL DEFAULT 'manual' CHECK (metric_type IN ('manual', 'tasks', 'habit')),
    target_value numeric NOT NULL CHECK (target_value > 0),
    current_value numeric NOT NULL DEFAULT 0 CHECK (current_value >= 0),
    unit text NOT NULL DEFAULT '%',
    linked_id uuid,
    deleted_at timestamptz,
    created_at timestamptz NOT NULL DEFAULT now(),
    updated_at timestamptz NOT NULL DEFAULT now(),

    CONSTRAINT uq_key_results_user UNIQUE (id, user_id),
    CONSTRAINT fk_key_results_goal FOREIGN KEY (goal_id, user_id)
        REFERENCES public.goals(id, user_id) ON DELETE CASCADE
);

CREATE INDEX IF NOT EXISTS idx_key_results_goal ON public.key_results(goal_id, user_id);

-- ------------------------------------------------------------------------------
-- 6. TRIGGERS: updated_at
-- ------------------------------------------------------------------------------
CREATE TRIGGER trg_journal_entries_updated_at
    BEFORE UPDATE ON public.journal_entries
    FOR EACH ROW EXECUTE FUNCTION public.handle_updated_at();

CREATE TRIGGER trg_mood_logs_updated_at
    BEFORE UPDATE ON public.mood_logs
    FOR EACH ROW EXECUTE FUNCTION public.handle_updated_at();

CREATE TRIGGER trg_reviews_updated_at
    BEFORE UPDATE ON public.reviews
    FOR EACH ROW EXECUTE FUNCTION public.handle_updated_at();

CREATE TRIGGER trg_goals_updated_at
    BEFORE UPDATE ON public.goals
    FOR EACH ROW EXECUTE FUNCTION public.handle_updated_at();

CREATE TRIGGER trg_key_results_updated_at
    BEFORE UPDATE ON public.key_results
    FOR EACH ROW EXECUTE FUNCTION public.handle_updated_at();

-- ------------------------------------------------------------------------------
-- 7. ROW LEVEL SECURITY (RLS) & GRANTS
-- ------------------------------------------------------------------------------
ALTER TABLE public.journal_entries ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.mood_logs ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.reviews ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.goals ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.key_results ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users can manage own journal entries"
    ON public.journal_entries FOR ALL
    USING (user_id = auth.uid())
    WITH CHECK (user_id = auth.uid());

CREATE POLICY "Users can manage own mood logs"
    ON public.mood_logs FOR ALL
    USING (user_id = auth.uid())
    WITH CHECK (user_id = auth.uid());

CREATE POLICY "Users can manage own reviews"
    ON public.reviews FOR ALL
    USING (user_id = auth.uid())
    WITH CHECK (user_id = auth.uid());

CREATE POLICY "Users can manage own goals"
    ON public.goals FOR ALL
    USING (user_id = auth.uid())
    WITH CHECK (user_id = auth.uid());

CREATE POLICY "Users can manage own key results"
    ON public.key_results FOR ALL
    USING (user_id = auth.uid())
    WITH CHECK (user_id = auth.uid());

REVOKE ALL ON TABLE public.journal_entries FROM anon;
REVOKE ALL ON TABLE public.mood_logs FROM anon;
REVOKE ALL ON TABLE public.reviews FROM anon;
REVOKE ALL ON TABLE public.goals FROM anon;
REVOKE ALL ON TABLE public.key_results FROM anon;

GRANT SELECT, INSERT, UPDATE, DELETE ON TABLE public.journal_entries TO authenticated;
GRANT SELECT, INSERT, UPDATE, DELETE ON TABLE public.mood_logs TO authenticated;
GRANT SELECT, INSERT, UPDATE, DELETE ON TABLE public.reviews TO authenticated;
GRANT SELECT, INSERT, UPDATE, DELETE ON TABLE public.goals TO authenticated;
GRANT SELECT, INSERT, UPDATE, DELETE ON TABLE public.key_results TO authenticated;
