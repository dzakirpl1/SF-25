-- ==============================================================================
-- Migration 0007: Calendar Events and Time Blocks
-- Sesuai Master Blueprint Personal OS v2.1.0 (Fase 6: F-CAL-01 s.d. F-CAL-04)
-- ==============================================================================

-- 1. Tabel Acara Kalender dan Blok Waktu (events)
create table if not exists public.events (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users(id) on delete cascade,
  title text not null,
  description text,
  starts_at timestamptz not null,
  ends_at timestamptz not null,
  all_day boolean not null default false,
  location text,
  color text default '#1976D2',
  recurrence_rule text, -- RRULE format: e.g. FREQ=WEEKLY;INTERVAL=1
  linked_task_id uuid, -- Relasi ke tugas untuk Blok Waktu (Time Blocking)
  is_time_block boolean not null default false,
  external_id text, -- ID sinkronisasi opsional kalender eksternal
  archived_at timestamptz,
  deleted_at timestamptz,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  constraint uq_events_user unique (id, user_id),
  constraint fk_events_linked_task foreign key (linked_task_id, user_id)
    references public.tasks(id, user_id) on delete set null
);

-- 2. Indeks Performa untuk Kalender
create index if not exists idx_events_user_starts_at on public.events(user_id, starts_at);
create index if not exists idx_events_user_ends_at on public.events(user_id, ends_at);
create index if not exists idx_events_user_deleted_at on public.events(user_id, deleted_at);
create index if not exists idx_events_user_linked_task on public.events(user_id, linked_task_id);

-- 3. Row Level Security (RLS)
alter table public.events enable row level security;

create policy "Users can select own events"
  on public.events for select
  using (auth.uid() = user_id);

create policy "Users can insert own events"
  on public.events for insert
  with check (auth.uid() = user_id);

create policy "Users can update own events"
  on public.events for update
  using (auth.uid() = user_id)
  with check (auth.uid() = user_id);

create policy "Users can delete own events"
  on public.events for delete
  using (auth.uid() = user_id);

-- 4. Hak Akses Eksplisit Role authenticated
grant select, insert, update, delete on public.events to authenticated;
revoke all on public.events from anon;

-- 5. Trigger Otomatis Pembaruan updated_at
drop trigger if exists set_events_updated_at on public.events;
create trigger set_events_updated_at
  before update on public.events
  for each row
  execute function public.handle_updated_at();
