-- Migration 0001: Init (profiles, user_settings, RLS, trigger handle_new_user)
-- Sesuai Master Blueprint Personal OS v2.1.0 (Fase 1)

-- 1. Ekstensi UUID
create extension if not exists "uuid-ossp";

-- 2. Tabel Profiles
create table if not exists public.profiles (
  id uuid primary key references auth.users(id) on delete cascade,
  display_name text,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

-- 3. Tabel User Settings
create table if not exists public.user_settings (
  user_id uuid primary key references auth.users(id) on delete cascade,
  theme text not null default 'system',
  accent_color text not null default 'teal',
  timezone text not null default 'Asia/Jakarta',
  locale text not null default 'id_ID',
  currency text not null default 'IDR',
  week_start smallint not null default 1,
  day_start_hour smallint not null default 4,
  notification_prefs jsonb not null default '{}'::jsonb,
  app_lock_enabled boolean not null default false
);

-- 4. Aktifkan Row Level Security (RLS)
alter table public.profiles enable row level security;
alter table public.user_settings enable row level security;

-- 5. Kebijakan RLS Profiles
create policy "Pengguna dapat membaca profil sendiri"
  on public.profiles for select
  using (auth.uid() = id);

create policy "Pengguna dapat memperbarui profil sendiri"
  on public.profiles for update
  using (auth.uid() = id)
  with check (auth.uid() = id);

create policy "Pengguna dapat menyisipkan profil sendiri"
  on public.profiles for insert
  with check (auth.uid() = id);

-- 6. Kebijakan RLS User Settings
create policy "Pengguna dapat membaca pengaturan sendiri"
  on public.user_settings for select
  using (auth.uid() = user_id);

create policy "Pengguna dapat memperbarui pengaturan sendiri"
  on public.user_settings for update
  using (auth.uid() = user_id)
  with check (auth.uid() = user_id);

create policy "Pengguna dapat menyisipkan pengaturan sendiri"
  on public.user_settings for insert
  with check (auth.uid() = user_id);

-- 7. Fungsi & Trigger handle_new_user untuk auto-provisioning
create or replace function public.handle_new_user()
returns trigger
language plpgsql
security definer set search_path = public
as $$
begin
  insert into public.profiles (id, display_name, created_at, updated_at)
  values (
    new.id,
    coalesce(new.raw_user_meta_data->>'full_name', split_part(new.email, '@', 1)),
    now(),
    now()
  );

  insert into public.user_settings (user_id)
  values (new.id);

  return new;
end;
$$;

-- Trigger pada tabel auth.users
drop trigger if exists on_auth_user_created on auth.users;
create trigger on_auth_user_created
  after insert on auth.users
  for each row execute function public.handle_new_user();
