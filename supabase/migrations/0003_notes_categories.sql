-- Migration 0003: Notes and Categories
-- Sesuai Master Blueprint Personal OS v2.1.0 (Fase 2)

-- 1. Tabel Kategori Catatan (note_categories)
create table if not exists public.note_categories (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users(id) on delete cascade,
  name text not null,
  color text,
  created_at timestamptz not null default now(),
  constraint uq_note_category_user unique (id, user_id)
);

-- 2. Tabel Catatan (notes)
create table if not exists public.notes (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users(id) on delete cascade,
  category_id uuid,
  title text,
  content text not null default '',
  is_pinned boolean not null default false,
  archived_at timestamptz,
  deleted_at timestamptz,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  constraint fk_notes_category_user foreign key (category_id, user_id)
    references public.note_categories(id, user_id) on delete set null
);

-- 3. Indeks Performa
create index if not exists idx_notes_user_active on public.notes(user_id, deleted_at, archived_at);
create index if not exists idx_notes_user_category on public.notes(user_id, category_id);
create index if not exists idx_notes_user_pinned on public.notes(user_id, is_pinned desc);
create index if not exists idx_note_categories_user on public.note_categories(user_id);

-- 4. Aktifkan RLS
alter table public.note_categories enable row level security;
alter table public.notes enable row level security;

-- 5. Kebijakan RLS note_categories
create policy "Pengguna dapat mengelola kategori sendiri"
  on public.note_categories for all
  using (auth.uid() = user_id)
  with check (auth.uid() = user_id);

-- 6. Kebijakan RLS notes
create policy "Pengguna dapat mengelola catatan sendiri"
  on public.notes for all
  using (auth.uid() = user_id)
  with check (auth.uid() = user_id);

-- 7. Grant eksplisit
grant select, insert, update, delete on table public.note_categories to authenticated;
grant select, insert, update, delete on table public.notes to authenticated;

-- 8. Fungsi Database: delete_note_category
-- Melindungi kategori agar tidak dapat dihapus jika masih digunakan oleh catatan aktif
create or replace function public.delete_note_category(category_uuid uuid)
returns boolean
language plpgsql
security invoker
as $$
declare
  active_count int;
begin
  -- Periksa apakah kategori sedang dipakai oleh catatan aktif milik user
  select count(*)
  into active_count
  from public.notes
  where category_id = category_uuid
    and user_id = auth.uid()
    and deleted_at is null;

  if active_count > 0 then
    raise exception 'Kategori sedang digunakan oleh catatan aktif dan tidak dapat dihapus'
      using errcode = 'P0001';
  end if;

  -- Hapus kategori
  delete from public.note_categories
  where id = category_uuid
    and user_id = auth.uid();

  return true;
end;
$$;

grant execute on function public.delete_note_category(uuid) to authenticated;
