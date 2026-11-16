-- ==============================================================================
-- Migration 0009: Reminders and Device Tokens (Fase 8)
-- Sesuai Master Blueprint Personal OS v2.1.0 (F-REM-01 s.d. F-REM-04)
-- ==============================================================================

-- 1. Tabel Pengingat (reminders)
create table if not exists public.reminders (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users(id) on delete cascade,
  title text not null,
  body text,
  target_type text not null default 'custom', -- task, event, medicine, document, day, custom
  target_id uuid, -- ID entitas yang diingatkan (polimorfik)
  remind_at timestamptz not null,
  status text not null default 'scheduled', -- scheduled, sent, snoozed, dismissed
  snoozed_until timestamptz,
  deleted_at timestamptz,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  constraint uq_reminders_user unique (id, user_id)
);

-- 2. Tabel Token Perangkat untuk Push Notification / FCM (device_tokens)
create table if not exists public.device_tokens (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users(id) on delete cascade,
  fcm_token text not null,
  platform text not null default 'android', -- android, ios, web
  last_seen_at timestamptz not null default now(),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  constraint uq_device_tokens_user unique (id, user_id),
  constraint uq_device_token_val unique (user_id, fcm_token)
);

-- 3. Indeks Performa
create index if not exists idx_reminders_user_remind_at on public.reminders(user_id, remind_at);
create index if not exists idx_reminders_user_status on public.reminders(user_id, status);
create index if not exists idx_reminders_user_deleted on public.reminders(user_id, deleted_at);
create index if not exists idx_device_tokens_user on public.device_tokens(user_id);

-- 4. Row Level Security (RLS)
alter table public.reminders enable row level security;
alter table public.device_tokens enable row level security;

-- Policies reminders
create policy "Users can select own reminders" on public.reminders for select using (auth.uid() = user_id);
create policy "Users can insert own reminders" on public.reminders for insert with check (auth.uid() = user_id);
create policy "Users can update own reminders" on public.reminders for update using (auth.uid() = user_id) with check (auth.uid() = user_id);
create policy "Users can delete own reminders" on public.reminders for delete using (auth.uid() = user_id);

-- Policies device_tokens
create policy "Users can select own device_tokens" on public.device_tokens for select using (auth.uid() = user_id);
create policy "Users can insert own device_tokens" on public.device_tokens for insert with check (auth.uid() = user_id);
create policy "Users can update own device_tokens" on public.device_tokens for update using (auth.uid() = user_id) with check (auth.uid() = user_id);
create policy "Users can delete own device_tokens" on public.device_tokens for delete using (auth.uid() = user_id);

-- 5. Hak Akses Eksplisit
grant select, insert, update, delete on public.reminders to authenticated;
grant select, insert, update, delete on public.device_tokens to authenticated;

revoke all on public.reminders from anon;
revoke all on public.device_tokens from anon;

-- 6. Trigger Otomatis Pembaruan updated_at
drop trigger if exists set_reminders_updated_at on public.reminders;
create trigger set_reminders_updated_at before update on public.reminders for each row execute function public.handle_updated_at();

drop trigger if exists set_device_tokens_updated_at on public.device_tokens;
create trigger set_device_tokens_updated_at before update on public.device_tokens for each row execute function public.handle_updated_at();
