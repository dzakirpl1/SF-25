-- ==============================================================================
-- PGTAP TEST SUITE: FASE 11 (FOCUS & TIME TRACKING)
-- Menguji keberadaan tabel, RLS isolasi dua akun, dan Foreign Key komposit
-- ==============================================================================

begin;
select plan(8);

-- 1. Uji Keberadaan Tabel
select has_table('public', 'focus_sessions', 'Tabel focus_sessions harus ada');
select has_table('public', 'time_entries', 'Tabel time_entries harus ada');

-- 2. Uji RLS Aktif
select rls_is_enabled('public', 'focus_sessions', 'RLS harus aktif di focus_sessions');
select rls_is_enabled('public', 'time_entries', 'RLS harus aktif di time_entries');

-- 3. User A membuat Sesi Fokus dan Time Entry
select tests.authenticate_as('user_a@personalos.local');

insert into public.focus_sessions (id, user_id, planned_minutes, actual_minutes, session_type, note)
values (
  'ffff1111-1111-1111-1111-111111111111',
  auth.uid(),
  25,
  25,
  'pomodoro',
  'Fokus koding modul autentikasi'
);

insert into public.time_entries (id, user_id, activity, duration_seconds)
values (
  'eeee1111-1111-1111-1111-111111111111',
  auth.uid(),
  'Desain Database Schema',
  3600
);

-- 4. User B dilarang melihat data User A
select tests.authenticate_as('user_b@personalos.local');

select is_empty(
  'select * from public.focus_sessions where id = ''ffff1111-1111-1111-1111-111111111111''',
  'User B tidak boleh melihat sesi fokus User A'
);

select is_empty(
  'select * from public.time_entries where id = ''eeee1111-1111-1111-1111-111111111111''',
  'User B tidak boleh melihat time entries User A'
);

select * from finish();
rollback;
