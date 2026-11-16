-- ==============================================================================
-- Migration 0006: Inbox, Tags, Note Tags, Templates, and Polymorphic Links
-- Sesuai Master Blueprint Personal OS v2.1.0 (Fase 5)
-- ==============================================================================

-- 1. Tabel Inbox Items (inbox_items)
create table if not exists public.inbox_items (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users(id) on delete cascade,
  content text not null,
  source text not null default 'manual', -- manual, share, voice, widget
  processed_at timestamptz,
  converted_type text, -- note, task, event, transaction
  converted_id uuid,
  deleted_at timestamptz,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  constraint uq_inbox_items_user unique (id, user_id)
);

-- 2. Tabel Templates Generik (templates)
create table if not exists public.templates (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users(id) on delete cascade,
  type text not null default 'note', -- note, task_list, shopping, checklist, trip
  name text not null,
  payload jsonb not null default '{}'::jsonb,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  constraint uq_templates_user unique (id, user_id)
);

-- 3. Tabel Label / Tag (tags)
create table if not exists public.tags (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users(id) on delete cascade,
  name text not null,
  color text default '#00796B',
  created_at timestamptz not null default now(),
  constraint uq_tags_user unique (id, user_id),
  constraint uq_tags_user_name unique (user_id, name)
);

-- 4. Tabel Relasi Catatan dan Tag (note_tags)
create table if not exists public.note_tags (
  note_id uuid not null,
  tag_id uuid not null,
  user_id uuid not null references auth.users(id) on delete cascade,
  primary key (note_id, tag_id, user_id),
  constraint fk_note_tags_note foreign key (note_id, user_id)
    references public.notes(id, user_id) on delete cascade,
  constraint fk_note_tags_tag foreign key (tag_id, user_id)
    references public.tags(id, user_id) on delete cascade
);

-- 5. Tabel Relasi Lintas Modul (links)
create table if not exists public.links (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users(id) on delete cascade,
  source_type text not null, -- note, task, project
  source_id uuid not null,
  target_type text not null, -- note, task, project
  target_id uuid not null,
  created_at timestamptz not null default now(),
  constraint uq_links_user unique (id, user_id)
);

-- 6. Indeks Performa
create index if not exists idx_inbox_user_active on public.inbox_items(user_id, processed_at) where deleted_at is null;
create index if not exists idx_templates_user_type on public.templates(user_id, type);
create index if not exists idx_tags_user on public.tags(user_id);
create index if not exists idx_links_user_source on public.links(user_id, source_type, source_id);
create index if not exists idx_links_user_target on public.links(user_id, target_type, target_id);

-- 7. Aktifkan RLS
alter table public.inbox_items enable row level security;
alter table public.templates enable row level security;
alter table public.tags enable row level security;
alter table public.note_tags enable row level security;
alter table public.links enable row level security;

-- 8. Kebijakan RLS
create policy "Kelola inbox milik sendiri" on public.inbox_items for all
  using (auth.uid() = user_id) with check (auth.uid() = user_id);

create policy "Kelola templates milik sendiri" on public.templates for all
  using (auth.uid() = user_id) with check (auth.uid() = user_id);

create policy "Kelola tags milik sendiri" on public.tags for all
  using (auth.uid() = user_id) with check (auth.uid() = user_id);

create policy "Kelola note_tags milik sendiri" on public.note_tags for all
  using (auth.uid() = user_id) with check (auth.uid() = user_id);

create policy "Kelola links milik sendiri" on public.links for all
  using (auth.uid() = user_id) with check (auth.uid() = user_id);

-- 9. Grant Eksplisit
grant select, insert, update, delete on table public.inbox_items to authenticated;
grant select, insert, update, delete on table public.templates to authenticated;
grant select, insert, update, delete on table public.tags to authenticated;
grant select, insert, update, delete on table public.note_tags to authenticated;
grant select, insert, update, delete on table public.links to authenticated;

-- 10. Triggers updated_at
drop trigger if exists trg_inbox_items_updated_at on public.inbox_items;
create trigger trg_inbox_items_updated_at
  before update on public.inbox_items
  for each row execute function public.set_updated_at();

drop trigger if exists trg_templates_updated_at on public.templates;
create trigger trg_templates_updated_at
  before update on public.templates
  for each row execute function public.set_updated_at();
