-- ==============================================================================
-- Migration 0008: Habits and Routines
-- Sesuai Master Blueprint Personal OS v2.1.0 (Fase 7: F-HAB-01 s.d. F-ROUT-02)
-- ==============================================================================

-- 1. Tabel Kebiasaan (habits)
create table if not exists public.habits (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users(id) on delete cascade,
  name text not null,
  description text,
  color text default '#4CAF50',
  icon text default 'check_circle',
  frequency_type text not null default 'daily', -- daily, specific_days, weekly_target
  frequency_config jsonb default '{}'::jsonb, -- e.g. {"days": [1,2,3,4,5]} atau {"target": 4}
  target_per_period integer not null default 1,
  archived_at timestamptz,
  deleted_at timestamptz,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  constraint uq_habits_user unique (id, user_id)
);

-- 2. Tabel Catatan/Log Kebiasaan (habit_logs)
create table if not exists public.habit_logs (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users(id) on delete cascade,
  habit_id uuid not null,
  log_date date not null,
  done boolean not null default true,
  note text,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  constraint uq_habit_logs_user unique (id, user_id),
  constraint uq_habit_log_date unique (habit_id, log_date),
  constraint fk_habit_logs_habit foreign key (habit_id, user_id)
    references public.habits(id, user_id) on delete cascade
);

-- 3. Tabel Rutinitas (routines)
create table if not exists public.routines (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users(id) on delete cascade,
  name text not null,
  description text,
  time_of_day text not null default 'morning', -- morning, evening, custom
  active_days jsonb default '[1,2,3,4,5,6,7]'::jsonb,
  archived_at timestamptz,
  deleted_at timestamptz,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  constraint uq_routines_user unique (id, user_id)
);

-- 4. Tabel Langkah Rutinitas (routine_steps)
create table if not exists public.routine_steps (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users(id) on delete cascade,
  routine_id uuid not null,
  title text not null,
  position integer not null default 0,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  constraint uq_routine_steps_user unique (id, user_id),
  constraint fk_routine_steps_routine foreign key (routine_id, user_id)
    references public.routines(id, user_id) on delete cascade
);

-- 5. Tabel Log Penyelesaian Rutinitas Harian (routine_logs)
create table if not exists public.routine_logs (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users(id) on delete cascade,
  routine_id uuid not null,
  log_date date not null,
  completed_step_ids jsonb not null default '[]'::jsonb,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  constraint uq_routine_logs_user unique (id, user_id),
  constraint uq_routine_log_date unique (routine_id, log_date),
  constraint fk_routine_logs_routine foreign key (routine_id, user_id)
    references public.routines(id, user_id) on delete cascade
);

-- 6. Indeks Performa
create index if not exists idx_habits_user_deleted on public.habits(user_id, deleted_at);
create index if not exists idx_habit_logs_user_date on public.habit_logs(user_id, log_date);
create index if not exists idx_routines_user_deleted on public.routines(user_id, deleted_at);
create index if not exists idx_routine_steps_routine on public.routine_steps(routine_id, position);
create index if not exists idx_routine_logs_user_date on public.routine_logs(user_id, log_date);

-- 7. Row Level Security (RLS)
alter table public.habits enable row level security;
alter table public.habit_logs enable row level security;
alter table public.routines enable row level security;
alter table public.routine_steps enable row level security;
alter table public.routine_logs enable row level security;

-- Policies habits
create policy "Users can select own habits" on public.habits for select using (auth.uid() = user_id);
create policy "Users can insert own habits" on public.habits for insert with check (auth.uid() = user_id);
create policy "Users can update own habits" on public.habits for update using (auth.uid() = user_id) with check (auth.uid() = user_id);
create policy "Users can delete own habits" on public.habits for delete using (auth.uid() = user_id);

-- Policies habit_logs
create policy "Users can select own habit_logs" on public.habit_logs for select using (auth.uid() = user_id);
create policy "Users can insert own habit_logs" on public.habit_logs for insert with check (auth.uid() = user_id);
create policy "Users can update own habit_logs" on public.habit_logs for update using (auth.uid() = user_id) with check (auth.uid() = user_id);
create policy "Users can delete own habit_logs" on public.habit_logs for delete using (auth.uid() = user_id);

-- Policies routines
create policy "Users can select own routines" on public.routines for select using (auth.uid() = user_id);
create policy "Users can insert own routines" on public.routines for insert with check (auth.uid() = user_id);
create policy "Users can update own routines" on public.routines for update using (auth.uid() = user_id) with check (auth.uid() = user_id);
create policy "Users can delete own routines" on public.routines for delete using (auth.uid() = user_id);

-- Policies routine_steps
create policy "Users can select own routine_steps" on public.routine_steps for select using (auth.uid() = user_id);
create policy "Users can insert own routine_steps" on public.routine_steps for insert with check (auth.uid() = user_id);
create policy "Users can update own routine_steps" on public.routine_steps for update using (auth.uid() = user_id) with check (auth.uid() = user_id);
create policy "Users can delete own routine_steps" on public.routine_steps for delete using (auth.uid() = user_id);

-- Policies routine_logs
create policy "Users can select own routine_logs" on public.routine_logs for select using (auth.uid() = user_id);
create policy "Users can insert own routine_logs" on public.routine_logs for insert with check (auth.uid() = user_id);
create policy "Users can update own routine_logs" on public.routine_logs for update using (auth.uid() = user_id) with check (auth.uid() = user_id);
create policy "Users can delete own routine_logs" on public.routine_logs for delete using (auth.uid() = user_id);

-- 8. Hak Akses Eksplisit
grant select, insert, update, delete on public.habits to authenticated;
grant select, insert, update, delete on public.habit_logs to authenticated;
grant select, insert, update, delete on public.routines to authenticated;
grant select, insert, update, delete on public.routine_steps to authenticated;
grant select, insert, update, delete on public.routine_logs to authenticated;

revoke all on public.habits from anon;
revoke all on public.habit_logs from anon;
revoke all on public.routines from anon;
revoke all on public.routine_steps from anon;
revoke all on public.routine_logs from anon;

-- 9. Trigger Otomatis Pembaruan updated_at
drop trigger if exists set_habits_updated_at on public.habits;
create trigger set_habits_updated_at before update on public.habits for each row execute function public.handle_updated_at();

drop trigger if exists set_habit_logs_updated_at on public.habit_logs;
create trigger set_habit_logs_updated_at before update on public.habit_logs for each row execute function public.handle_updated_at();

drop trigger if exists set_routines_updated_at on public.routines;
create trigger set_routines_updated_at before update on public.routines for each row execute function public.handle_updated_at();

drop trigger if exists set_routine_steps_updated_at on public.routine_steps;
create trigger set_routine_steps_updated_at before update on public.routine_steps for each row execute function public.handle_updated_at();

drop trigger if exists set_routine_logs_updated_at on public.routine_logs;
create trigger set_routine_logs_updated_at before update on public.routine_logs for each row execute function public.handle_updated_at();
