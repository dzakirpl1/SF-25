-- ==============================================================================
-- Migration: 0011_finance_advanced.sql
-- Modul: Keuangan Lanjutan (Budgets, Savings Goals, Debts & Debt Payments)
-- Fase: 10
-- Standar: RLS 100%, FK Komposit (id, user_id), Soft Delete, Zero Anon
-- ==============================================================================

-- ------------------------------------------------------------------------------
-- 1. TABEL: public.budgets (Anggaran Kategori Bulanan)
-- ------------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS public.budgets (
    id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id uuid NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    category_id uuid NOT NULL,
    month date NOT NULL, -- Hari pertama setiap bulan: yyyy-MM-01
    limit_amount bigint NOT NULL CHECK (limit_amount > 0),
    deleted_at timestamptz,
    created_at timestamptz NOT NULL DEFAULT now(),
    updated_at timestamptz NOT NULL DEFAULT now(),

    CONSTRAINT uq_budgets_user UNIQUE (id, user_id),
    CONSTRAINT uq_budgets_user_cat_month UNIQUE (user_id, category_id, month),
    CONSTRAINT fk_budgets_category FOREIGN KEY (category_id, user_id)
        REFERENCES public.fin_categories(id, user_id) ON DELETE CASCADE
);

CREATE INDEX IF NOT EXISTS idx_budgets_user_month ON public.budgets(user_id, month);

-- ------------------------------------------------------------------------------
-- 2. TABEL: public.savings_goals (Target Tabungan)
-- ------------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS public.savings_goals (
    id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id uuid NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    name text NOT NULL,
    target_amount bigint NOT NULL CHECK (target_amount > 0),
    target_date date,
    wallet_id uuid,
    color text NOT NULL DEFAULT '#00897B',
    icon text NOT NULL DEFAULT 'savings',
    archived_at timestamptz,
    deleted_at timestamptz,
    created_at timestamptz NOT NULL DEFAULT now(),
    updated_at timestamptz NOT NULL DEFAULT now(),

    CONSTRAINT uq_savings_goals_user UNIQUE (id, user_id),
    CONSTRAINT fk_savings_goals_wallet FOREIGN KEY (wallet_id, user_id)
        REFERENCES public.wallets(id, user_id) ON DELETE SET NULL
);

CREATE INDEX IF NOT EXISTS idx_savings_goals_user ON public.savings_goals(user_id);

-- ------------------------------------------------------------------------------
-- 3. TABEL: public.savings_contributions (Setoran Tabungan)
-- ------------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS public.savings_contributions (
    id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id uuid NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    goal_id uuid NOT NULL,
    amount bigint NOT NULL CHECK (amount > 0),
    contributed_at timestamptz NOT NULL DEFAULT now(),
    transaction_id uuid,
    note text,
    deleted_at timestamptz,
    created_at timestamptz NOT NULL DEFAULT now(),
    updated_at timestamptz NOT NULL DEFAULT now(),

    CONSTRAINT uq_savings_contributions_user UNIQUE (id, user_id),
    CONSTRAINT fk_savings_contributions_goal FOREIGN KEY (goal_id, user_id)
        REFERENCES public.savings_goals(id, user_id) ON DELETE CASCADE,
    CONSTRAINT fk_savings_contributions_tx FOREIGN KEY (transaction_id, user_id)
        REFERENCES public.transactions(id, user_id) ON DELETE SET NULL
);

CREATE INDEX IF NOT EXISTS idx_savings_contributions_goal ON public.savings_contributions(goal_id, user_id);

-- ------------------------------------------------------------------------------
-- 4. TABEL: public.debts (Pencatatan Utang & Piutang)
-- ------------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS public.debts (
    id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id uuid NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    person_name text NOT NULL,
    person_id uuid,
    direction text NOT NULL CHECK (direction IN ('owed_by_me', 'owed_to_me')),
    principal bigint NOT NULL CHECK (principal > 0),
    due_date date,
    note text,
    settled_at timestamptz,
    deleted_at timestamptz,
    created_at timestamptz NOT NULL DEFAULT now(),
    updated_at timestamptz NOT NULL DEFAULT now(),

    CONSTRAINT uq_debts_user UNIQUE (id, user_id)
);

CREATE INDEX IF NOT EXISTS idx_debts_user_direction ON public.debts(user_id, direction);

-- ------------------------------------------------------------------------------
-- 5. TABEL: public.debt_payments (Pembayaran Cicilan Utang/Piutang)
-- ------------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS public.debt_payments (
    id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id uuid NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    debt_id uuid NOT NULL,
    amount bigint NOT NULL CHECK (amount > 0),
    paid_at timestamptz NOT NULL DEFAULT now(),
    transaction_id uuid,
    note text,
    deleted_at timestamptz,
    created_at timestamptz NOT NULL DEFAULT now(),
    updated_at timestamptz NOT NULL DEFAULT now(),

    CONSTRAINT uq_debt_payments_user UNIQUE (id, user_id),
    CONSTRAINT fk_debt_payments_debt FOREIGN KEY (debt_id, user_id)
        REFERENCES public.debts(id, user_id) ON DELETE CASCADE,
    CONSTRAINT fk_debt_payments_tx FOREIGN KEY (transaction_id, user_id)
        REFERENCES public.transactions(id, user_id) ON DELETE SET NULL
);

CREATE INDEX IF NOT EXISTS idx_debt_payments_debt ON public.debt_payments(debt_id, user_id);

-- ------------------------------------------------------------------------------
-- 6. TRIGGERS: updated_at
-- ------------------------------------------------------------------------------
CREATE TRIGGER trg_budgets_updated_at
    BEFORE UPDATE ON public.budgets
    FOR EACH ROW EXECUTE FUNCTION public.handle_updated_at();

CREATE TRIGGER trg_savings_goals_updated_at
    BEFORE UPDATE ON public.savings_goals
    FOR EACH ROW EXECUTE FUNCTION public.handle_updated_at();

CREATE TRIGGER trg_savings_contributions_updated_at
    BEFORE UPDATE ON public.savings_contributions
    FOR EACH ROW EXECUTE FUNCTION public.handle_updated_at();

CREATE TRIGGER trg_debts_updated_at
    BEFORE UPDATE ON public.debts
    FOR EACH ROW EXECUTE FUNCTION public.handle_updated_at();

CREATE TRIGGER trg_debt_payments_updated_at
    BEFORE UPDATE ON public.debt_payments
    FOR EACH ROW EXECUTE FUNCTION public.handle_updated_at();

-- ------------------------------------------------------------------------------
-- 7. ROW LEVEL SECURITY (RLS) & GRANTS
-- ------------------------------------------------------------------------------
ALTER TABLE public.budgets ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.savings_goals ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.savings_contributions ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.debts ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.debt_payments ENABLE ROW LEVEL SECURITY;

-- Budgets RLS
CREATE POLICY "Users can manage own budgets"
    ON public.budgets FOR ALL
    USING (user_id = auth.uid())
    WITH CHECK (user_id = auth.uid());

-- Savings Goals RLS
CREATE POLICY "Users can manage own savings goals"
    ON public.savings_goals FOR ALL
    USING (user_id = auth.uid())
    WITH CHECK (user_id = auth.uid());

-- Savings Contributions RLS
CREATE POLICY "Users can manage own savings contributions"
    ON public.savings_contributions FOR ALL
    USING (user_id = auth.uid())
    WITH CHECK (user_id = auth.uid());

-- Debts RLS
CREATE POLICY "Users can manage own debts"
    ON public.debts FOR ALL
    USING (user_id = auth.uid())
    WITH CHECK (user_id = auth.uid());

-- Debt Payments RLS
CREATE POLICY "Users can manage own debt payments"
    ON public.debt_payments FOR ALL
    USING (user_id = auth.uid())
    WITH CHECK (user_id = auth.uid());

-- Grants
REVOKE ALL ON TABLE public.budgets FROM anon;
REVOKE ALL ON TABLE public.savings_goals FROM anon;
REVOKE ALL ON TABLE public.savings_contributions FROM anon;
REVOKE ALL ON TABLE public.debts FROM anon;
REVOKE ALL ON TABLE public.debt_payments FROM anon;

GRANT SELECT, INSERT, UPDATE, DELETE ON TABLE public.budgets TO authenticated;
GRANT SELECT, INSERT, UPDATE, DELETE ON TABLE public.savings_goals TO authenticated;
GRANT SELECT, INSERT, UPDATE, DELETE ON TABLE public.savings_contributions TO authenticated;
GRANT SELECT, INSERT, UPDATE, DELETE ON TABLE public.debts TO authenticated;
GRANT SELECT, INSERT, UPDATE, DELETE ON TABLE public.debt_payments TO authenticated;
