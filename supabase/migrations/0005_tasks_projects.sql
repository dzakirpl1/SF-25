-- ==============================================================================
-- Migration 0005: Projects, Tasks, and Subtasks
-- Sesuai Master Blueprint Personal OS v2.1.0 (Fase 4)
-- ==============================================================================

-- 1. Tabel Proyek (projects)
create table if not exists public.projects (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users(id) on delete cascade,
  name text not null,
  description text,
  status text not null default 'active', -- active, completed, archived
  color text default '#00796B',
  target_date date,
  archived_at timestamptz,
  deleted_at timestamptz,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  constraint uq_projects_user unique (id, user_id)
);

-- 2. Tabel Tugas (tasks)
create table if not exists public.tasks (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users(id) on delete cascade,
  project_id uuid,
  title text not null,
  description text,
  status text not null default 'todo', -- todo, in_progress, completed
  priority smallint not null default 4, -- 1: Tinggi, 2: Sedang, 3: Rendah, 4: Tidak Ada
  is_important boolean not null default false, -- Eisenhower
  is_urgent boolean not null default false, -- Eisenhower
  due_date timestamptz,
  recurrence_rule text, -- RRULE format: e.g. FREQ=DAILY;INTERVAL=1
  completed_at timestamptz,
  archived_at timestamptz,
  deleted_at timestamptz,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  constraint uq_tasks_user unique (id, user_id),
  constraint fk_tasks_project_user foreign key (project_id, user_id)
    references public.projects(id, user_id) on delete set null
);

-- 3. Tabel Subtugas (subtasks)
create table if not exists public.subtasks (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users(id) on delete cascade,
  task_id uuid not null,
  title text not null,
  is_done boolean not null default false,
  position integer not null default 0,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  constraint uq_subtasks_user unique (id, user_id),
  constraint fk_subtasks_task_user foreign key (task_id, user_id)
    references public.tasks(id, user_id) on delete cascade
);

-- 4. Indeks Performa
create index if not exists idx_projects_user_active on public.projects(user_id, status) where deleted_at is null;
create index if not exists idx_tasks_user_active on public.tasks(user_id, status, due_date) where deleted_at is null;
create index if not exists idx_tasks_user_project on public.tasks(user_id, project_id) where deleted_at is null;
create index if not exists idx_tasks_user_priority on public.tasks(user_id, priority) where deleted_at is null;
create index if not exists idx_subtasks_user_task on public.subtasks(user_id, task_id, position);

-- 5. Aktifkan RLS
alter table public.projects enable row level security;
alter table public.tasks enable row level security;
alter table public.subtasks enable row level security;

-- 6. Kebijakan RLS
create policy "Pengguna dapat mengelola proyek sendiri"
  on public.projects for all
  using (auth.uid() = user_id)
  with check (auth.uid() = user_id);

create policy "Pengguna dapat mengelola tugas sendiri"
  on public.tasks for all
  using (auth.uid() = user_id)
  with check (auth.uid() = user_id);

create policy "Pengguna dapat mengelola subtugas sendiri"
  on public.subtasks for all
  using (auth.uid() = user_id)
  with check (auth.uid() = user_id);

-- 7. Grant Eksplisit
grant select, insert, update, delete on table public.projects to authenticated;
grant select, insert, update, delete on table public.tasks to authenticated;
grant select, insert, update, delete on table public.subtasks to authenticated;

-- 8. Trigger updated_at
drop trigger if exists trg_projects_updated_at on public.projects;
create trigger trg_projects_updated_at
  before update on public.projects
  for each row execute function public.set_updated_at();

drop trigger if exists trg_tasks_updated_at on public.tasks;
create trigger trg_tasks_updated_at
  before update on public.tasks
  for each row execute function public.set_updated_at();

drop trigger if exists trg_subtasks_updated_at on public.subtasks;
create trigger trg_subtasks_updated_at
  before update on public.subtasks
  for each row execute function public.set_updated_at();
