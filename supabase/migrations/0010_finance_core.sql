-- ==============================================================================
-- Migration 0010: Finance Core (Money Tracker Inti - Fase 9)
-- Sesuai Master Blueprint Personal OS v2.1.0 (F-FIN-01 s.d. F-FIN-06)
-- ==============================================================================

-- 1. Tabel Dompet dan Rekening (wallets)
create table if not exists public.wallets (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users(id) on delete cascade,
  name text not null,
  type text not null default 'cash', -- cash, bank, ewallet, other
  initial_balance bigint not null default 0, -- Satuan rupiah penuh
  color text default '#00796B',
  icon text default 'account_balance_wallet',
  archived_at timestamptz,
  deleted_at timestamptz,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  constraint uq_wallets_user unique (id, user_id)
);

-- 2. Tabel Kategori Keuangan Berjenjang (fin_categories)
create table if not exists public.fin_categories (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users(id) on delete cascade,
  parent_id uuid,
  name text not null,
  kind text not null default 'expense', -- income, expense
  icon text default 'category',
  color text default '#E53935',
  deleted_at timestamptz,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  constraint uq_fin_categories_user unique (id, user_id),
  constraint fk_fin_categories_parent foreign key (parent_id, user_id)
    references public.fin_categories(id, user_id) on delete set null
);

-- 3. Tabel Transaksi Keuangan (transactions)
create table if not exists public.transactions (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users(id) on delete cascade,
  wallet_id uuid not null,
  to_wallet_id uuid, -- Diisi jika type = 'transfer'
  category_id uuid,
  type text not null check (type in ('income', 'expense', 'transfer')),
  amount bigint not null check (amount > 0), -- Satuan rupiah penuh
  occurred_at timestamptz not null default now(),
  note text,
  deleted_at timestamptz,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  constraint uq_transactions_user unique (id, user_id),
  constraint fk_transactions_wallet foreign key (wallet_id, user_id)
    references public.wallets(id, user_id) on delete cascade,
  constraint fk_transactions_to_wallet foreign key (to_wallet_id, user_id)
    references public.wallets(id, user_id) on delete set null,
  constraint fk_transactions_category foreign key (category_id, user_id)
    references public.fin_categories(id, user_id) on delete set null,
  constraint chk_transfer_wallet check (
    (type = 'transfer' and to_wallet_id is not null and to_wallet_id <> wallet_id) or
    (type <> 'transfer')
  )
);

-- 4. Indeks Performa
create index if not exists idx_wallets_user_deleted on public.wallets(user_id, deleted_at);
create index if not exists idx_fin_categories_user_kind on public.fin_categories(user_id, kind);
create index if not exists idx_transactions_user_occurred on public.transactions(user_id, occurred_at desc);
create index if not exists idx_transactions_user_wallet on public.transactions(user_id, wallet_id);

-- 5. Row Level Security (RLS)
alter table public.wallets enable row level security;
alter table public.fin_categories enable row level security;
alter table public.transactions enable row level security;

-- Policies wallets
create policy "Users can select own wallets" on public.wallets for select using (auth.uid() = user_id);
create policy "Users can insert own wallets" on public.wallets for insert with check (auth.uid() = user_id);
create policy "Users can update own wallets" on public.wallets for update using (auth.uid() = user_id) with check (auth.uid() = user_id);
create policy "Users can delete own wallets" on public.wallets for delete using (auth.uid() = user_id);

-- Policies fin_categories
create policy "Users can select own fin_categories" on public.fin_categories for select using (auth.uid() = user_id);
create policy "Users can insert own fin_categories" on public.fin_categories for insert with check (auth.uid() = user_id);
create policy "Users can update own fin_categories" on public.fin_categories for update using (auth.uid() = user_id) with check (auth.uid() = user_id);
create policy "Users can delete own fin_categories" on public.fin_categories for delete using (auth.uid() = user_id);

-- Policies transactions
create policy "Users can select own transactions" on public.transactions for select using (auth.uid() = user_id);
create policy "Users can insert own transactions" on public.transactions for insert with check (auth.uid() = user_id);
create policy "Users can update own transactions" on public.transactions for update using (auth.uid() = user_id) with check (auth.uid() = user_id);
create policy "Users can delete own transactions" on public.transactions for delete using (auth.uid() = user_id);

-- 6. Hak Akses Eksplisit
grant select, insert, update, delete on public.wallets to authenticated;
grant select, insert, update, delete on public.fin_categories to authenticated;
grant select, insert, update, delete on public.transactions to authenticated;

revoke all on public.wallets from anon;
revoke all on public.fin_categories from anon;
revoke all on public.transactions from anon;

-- 7. Trigger Otomatis updated_at
drop trigger if exists set_wallets_updated_at on public.wallets;
create trigger set_wallets_updated_at before update on public.wallets for each row execute function public.handle_updated_at();

drop trigger if exists set_fin_categories_updated_at on public.fin_categories;
create trigger set_fin_categories_updated_at before update on public.fin_categories for each row execute function public.handle_updated_at();

drop trigger if exists set_transactions_updated_at on public.transactions;
create trigger set_transactions_updated_at before update on public.transactions for each row execute function public.handle_updated_at();
