-- ==============================================================================
-- Migration: 0014_health.sql
-- Modul: Kesehatan, Kebugaran & Pengobatan (Health, Sleep, Water, Meds)
-- Fase: 13
-- Standar: RLS 100%, FK Komposit (id, user_id), Soft Delete, Zero Anon
-- ==============================================================================

-- ------------------------------------------------------------------------------
-- 1. TABEL: public.workouts (Catatan Olahraga)
-- ------------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS public.workouts (
    id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id uuid NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    type text NOT NULL, -- Lari, Gym, Renang, Sepeda, Jalan, Yoga, dll
    started_at timestamptz NOT NULL DEFAULT now(),
    duration_minutes integer NOT NULL CHECK (duration_minutes > 0),
    calories_burned integer CHECK (calories_burned >= 0),
    note text,
    deleted_at timestamptz,
    created_at timestamptz NOT NULL DEFAULT now(),
    updated_at timestamptz NOT NULL DEFAULT now(),

    CONSTRAINT uq_workouts_user UNIQUE (id, user_id)
);

CREATE INDEX IF NOT EXISTS idx_workouts_user_started ON public.workouts(user_id, started_at DESC);

-- ------------------------------------------------------------------------------
-- 2. TABEL: public.sleep_logs (Pelacak Tidur)
-- ------------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS public.sleep_logs (
    id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id uuid NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    sleep_at timestamptz NOT NULL,
    wake_at timestamptz NOT NULL,
    quality smallint NOT NULL CHECK (quality BETWEEN 1 AND 5), -- 1: Sangat Buruk, 5: Sangat Nyenyak
    note text,
    deleted_at timestamptz,
    created_at timestamptz NOT NULL DEFAULT now(),
    updated_at timestamptz NOT NULL DEFAULT now(),

    CONSTRAINT uq_sleep_logs_user UNIQUE (id, user_id)
);

CREATE INDEX IF NOT EXISTS idx_sleep_logs_user_wake ON public.sleep_logs(user_id, wake_at DESC);

-- ------------------------------------------------------------------------------
-- 3. TABEL: public.water_logs (Pelacak Asupan Air Minum)
-- ------------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS public.water_logs (
    id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id uuid NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    logged_at timestamptz NOT NULL DEFAULT now(),
    amount_ml integer NOT NULL CHECK (amount_ml > 0),
    deleted_at timestamptz,
    created_at timestamptz NOT NULL DEFAULT now(),
    updated_at timestamptz NOT NULL DEFAULT now(),

    CONSTRAINT uq_water_logs_user UNIQUE (id, user_id)
);

CREATE INDEX IF NOT EXISTS idx_water_logs_user_logged ON public.water_logs(user_id, logged_at DESC);

-- ------------------------------------------------------------------------------
-- 4. TABEL: public.body_measurements (Berat & Ukuran Tubuh)
-- ------------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS public.body_measurements (
    id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id uuid NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    measured_at timestamptz NOT NULL DEFAULT now(),
    weight_kg numeric(5,2) NOT NULL CHECK (weight_kg > 0),
    measurements jsonb NOT NULL DEFAULT '{}'::jsonb,
    deleted_at timestamptz,
    created_at timestamptz NOT NULL DEFAULT now(),
    updated_at timestamptz NOT NULL DEFAULT now(),

    CONSTRAINT uq_body_measurements_user UNIQUE (id, user_id)
);

CREATE INDEX IF NOT EXISTS idx_body_measurements_user_measured ON public.body_measurements(user_id, measured_at DESC);

-- ------------------------------------------------------------------------------
-- 5. TABEL: public.medications (Daftar Obat & Suplemen)
-- ------------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS public.medications (
    id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id uuid NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    name text NOT NULL,
    dosage text NOT NULL,
    schedule jsonb NOT NULL DEFAULT '[]'::jsonb, -- Waktu konsumsi: ["08:00", "20:00"]
    start_date date,
    end_date date,
    active boolean NOT NULL DEFAULT true,
    deleted_at timestamptz,
    created_at timestamptz NOT NULL DEFAULT now(),
    updated_at timestamptz NOT NULL DEFAULT now(),

    CONSTRAINT uq_medications_user UNIQUE (id, user_id)
);

CREATE INDEX IF NOT EXISTS idx_medications_user_active ON public.medications(user_id, active);

-- ------------------------------------------------------------------------------
-- 6. TABEL: public.medication_logs (Log Kepatuhan Minum Obat)
-- ------------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS public.medication_logs (
    id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id uuid NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    medication_id uuid NOT NULL,
    scheduled_at timestamptz NOT NULL,
    taken_at timestamptz,
    status text NOT NULL DEFAULT 'taken' CHECK (status IN ('taken', 'skipped', 'missed')),
    deleted_at timestamptz,
    created_at timestamptz NOT NULL DEFAULT now(),
    updated_at timestamptz NOT NULL DEFAULT now(),

    CONSTRAINT uq_medication_logs_user UNIQUE (id, user_id),
    CONSTRAINT fk_medication_logs_med FOREIGN KEY (medication_id, user_id)
        REFERENCES public.medications(id, user_id) ON DELETE CASCADE
);

CREATE INDEX IF NOT EXISTS idx_medication_logs_user_scheduled ON public.medication_logs(user_id, scheduled_at DESC);

-- ------------------------------------------------------------------------------
-- 7. TABEL: public.meal_logs (Catatan Makan Harian)
-- ------------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS public.meal_logs (
    id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id uuid NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    eaten_at timestamptz NOT NULL DEFAULT now(),
    meal_type text NOT NULL DEFAULT 'lunch' CHECK (meal_type IN ('breakfast', 'lunch', 'dinner', 'snack')),
    description text NOT NULL,
    note text,
    deleted_at timestamptz,
    created_at timestamptz NOT NULL DEFAULT now(),
    updated_at timestamptz NOT NULL DEFAULT now(),

    CONSTRAINT uq_meal_logs_user UNIQUE (id, user_id)
);

CREATE INDEX IF NOT EXISTS idx_meal_logs_user_eaten ON public.meal_logs(user_id, eaten_at DESC);

-- ------------------------------------------------------------------------------
-- 8. TRIGGERS: updated_at
-- ------------------------------------------------------------------------------
CREATE TRIGGER trg_workouts_updated_at BEFORE UPDATE ON public.workouts FOR EACH ROW EXECUTE FUNCTION public.handle_updated_at();
CREATE TRIGGER trg_sleep_logs_updated_at BEFORE UPDATE ON public.sleep_logs FOR EACH ROW EXECUTE FUNCTION public.handle_updated_at();
CREATE TRIGGER trg_water_logs_updated_at BEFORE UPDATE ON public.water_logs FOR EACH ROW EXECUTE FUNCTION public.handle_updated_at();
CREATE TRIGGER trg_body_measurements_updated_at BEFORE UPDATE ON public.body_measurements FOR EACH ROW EXECUTE FUNCTION public.handle_updated_at();
CREATE TRIGGER trg_medications_updated_at BEFORE UPDATE ON public.medications FOR EACH ROW EXECUTE FUNCTION public.handle_updated_at();
CREATE TRIGGER trg_medication_logs_updated_at BEFORE UPDATE ON public.medication_logs FOR EACH ROW EXECUTE FUNCTION public.handle_updated_at();
CREATE TRIGGER trg_meal_logs_updated_at BEFORE UPDATE ON public.meal_logs FOR EACH ROW EXECUTE FUNCTION public.handle_updated_at();

-- ------------------------------------------------------------------------------
-- 9. ROW LEVEL SECURITY (RLS) & GRANTS
-- ------------------------------------------------------------------------------
ALTER TABLE public.workouts ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.sleep_logs ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.water_logs ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.body_measurements ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.medications ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.medication_logs ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.meal_logs ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users manage own workouts" ON public.workouts FOR ALL USING (user_id = auth.uid()) WITH CHECK (user_id = auth.uid());
CREATE POLICY "Users manage own sleep logs" ON public.sleep_logs FOR ALL USING (user_id = auth.uid()) WITH CHECK (user_id = auth.uid());
CREATE POLICY "Users manage own water logs" ON public.water_logs FOR ALL USING (user_id = auth.uid()) WITH CHECK (user_id = auth.uid());
CREATE POLICY "Users manage own body measurements" ON public.body_measurements FOR ALL USING (user_id = auth.uid()) WITH CHECK (user_id = auth.uid());
CREATE POLICY "Users manage own medications" ON public.medications FOR ALL USING (user_id = auth.uid()) WITH CHECK (user_id = auth.uid());
CREATE POLICY "Users manage own medication logs" ON public.medication_logs FOR ALL USING (user_id = auth.uid()) WITH CHECK (user_id = auth.uid());
CREATE POLICY "Users manage own meal logs" ON public.meal_logs FOR ALL USING (user_id = auth.uid()) WITH CHECK (user_id = auth.uid());

REVOKE ALL ON TABLE public.workouts FROM anon;
REVOKE ALL ON TABLE public.sleep_logs FROM anon;
REVOKE ALL ON TABLE public.water_logs FROM anon;
REVOKE ALL ON TABLE public.body_measurements FROM anon;
REVOKE ALL ON TABLE public.medications FROM anon;
REVOKE ALL ON TABLE public.medication_logs FROM anon;
REVOKE ALL ON TABLE public.meal_logs FROM anon;

GRANT SELECT, INSERT, UPDATE, DELETE ON TABLE public.workouts TO authenticated;
GRANT SELECT, INSERT, UPDATE, DELETE ON TABLE public.sleep_logs TO authenticated;
GRANT SELECT, INSERT, UPDATE, DELETE ON TABLE public.water_logs TO authenticated;
GRANT SELECT, INSERT, UPDATE, DELETE ON TABLE public.body_measurements TO authenticated;
GRANT SELECT, INSERT, UPDATE, DELETE ON TABLE public.medications TO authenticated;
GRANT SELECT, INSERT, UPDATE, DELETE ON TABLE public.medication_logs TO authenticated;
GRANT SELECT, INSERT, UPDATE, DELETE ON TABLE public.meal_logs TO authenticated;
