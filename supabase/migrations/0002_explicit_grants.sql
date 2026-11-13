-- Migration 0002: Explicit Grants
-- Sesuai Master Blueprint Personal OS v2.1.0 (Fase 1)

-- 1. Cabut akses default publik
revoke all on all tables in schema public from anon, public;
revoke all on all functions in schema public from anon, public;

-- 2. Berikan USAGE pada skema public untuk peran yang sah
grant usage on schema public to anon, authenticated;

-- 3. Hak akses eksplisit untuk pengguna terautentikasi (authenticated)
grant select, insert, update, delete on table public.profiles to authenticated;
grant select, insert, update, delete on table public.user_settings to authenticated;

-- 4. Hak eksekusi fungsi
grant execute on function public.handle_new_user() to service_role;
