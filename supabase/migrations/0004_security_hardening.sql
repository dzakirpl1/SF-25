-- ==============================================================================
-- Migration 0004: Security Hardening, Optimistic Helpers, and User Settings Expansion
-- Sesuai Master Blueprint Personal OS v2.1.0 (Fase 3)
-- ==============================================================================

-- 1. Tambah kolom keamanan dan audit pada user_settings
alter table public.user_settings
  add column if not exists pin_enabled boolean not null default false,
  add column if not exists biometric_enabled boolean not null default false,
  add column if not exists lock_timeout_minutes integer not null default 5,
  add column if not exists updated_at timestamptz not null default now();

-- 2. Fungsi otomatis set_updated_at() untuk menjaga stempel waktu
create or replace function public.set_updated_at()
returns trigger
language plpgsql
as $$
begin
  new.updated_at = now();
  return new;
end;
$$;

-- Pasang trigger updated_at pada tabel Fase 1 & 2 jika belum ada
drop trigger if exists trg_profiles_updated_at on public.profiles;
create trigger trg_profiles_updated_at
  before update on public.profiles
  for each row execute function public.set_updated_at();

drop trigger if exists trg_user_settings_updated_at on public.user_settings;
create trigger trg_user_settings_updated_at
  before update on public.user_settings
  for each row execute function public.set_updated_at();

drop trigger if exists trg_notes_updated_at on public.notes;
create trigger trg_notes_updated_at
  before update on public.notes
  for each row execute function public.set_updated_at();

-- 3. Fungsi Server Health Check ringan untuk uji status koneksi Supabase
create or replace function public.check_connection()
returns jsonb
language plpgsql
security definer
as $$
begin
  return jsonb_build_object(
    'status', 'online',
    'server_time', now(),
    'authenticated_user', auth.uid()
  );
end;
$$;

grant execute on function public.check_connection() to authenticated;
