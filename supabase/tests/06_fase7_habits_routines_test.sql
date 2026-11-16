-- ==============================================================================
-- PGTAP TEST SUITE: FASE 7 (HABITS, HABIT LOGS, ROUTINES, STEPS, LOGS)
-- Menguji keberadaan tabel, RLS isolasi dua akun, dan Composite FK
-- ==============================================================================

begin;
select plan(12);

-- 1. Uji Keberadaan Tabel
select has_table('public', 'habits', 'Tabel habits harus ada');
select has_table('public', 'habit_logs', 'Tabel habit_logs harus ada');
select has_table('public', 'routines', 'Tabel routines harus ada');
select has_table('public', 'routine_steps', 'Tabel routine_steps harus ada');
select has_table('public', 'routine_logs', 'Tabel routine_logs harus ada');

-- 2. Uji RLS Aktif
select rls_is_enabled('public', 'habits', 'RLS harus aktif di habits');
select rls_is_enabled('public', 'habit_logs', 'RLS harus aktif di habit_logs');
select rls_is_enabled('public', 'routines', 'RLS harus aktif di routines');

-- 3. User A membuat Habit dan Log
select tests.authenticate_as('user_a@personalos.local');

insert into public.habits (id, user_id, name, frequency_type)
values (
  '77777777-7777-7777-7777-777777777777',
  auth.uid(),
  'Minum Air 2 Liter',
  'daily'
);

insert into public.habit_logs (id, user_id, habit_id, log_date, done)
values (
  '88888888-8888-8888-8888-888888888888',
  auth.uid(),
  '77777777-7777-7777-7777-777777777777',
  '2026-11-15',
  true
);

-- 4. User B dilarang melihat habit milik User A
select tests.authenticate_as('user_b@personalos.local');

select is_empty(
  'select * from public.habits where id = ''77777777-7777-7777-7777-777777777777''',
  'User B tidak boleh melihat habit User A'
);

select is_empty(
  'select * from public.habit_logs where id = ''88888888-8888-8888-8888-888888888888''',
  'User B tidak boleh melihat habit_logs User A'
);

-- 5. User B dilarang membuat log untuk habit milik User A (Composite FK Check)
select throws_ok(
  'insert into public.habit_logs (user_id, habit_id, log_date, done) values (auth.uid(), ''77777777-7777-7777-7777-777777777777'', ''2026-11-15'', true)',
  '23503',
  'Composite FK menolak pembuatan log ke habit milik akun lain'
);

-- 6. Uji Unik (habit_id, log_date)
select tests.authenticate_as('user_a@personalos.local');

select throws_ok(
  'insert into public.habit_logs (user_id, habit_id, log_date, done) values (auth.uid(), ''77777777-7777-7777-7777-777777777777'', ''2026-11-15'', false)',
  '23505',
  'Constraint unik menolak duplikasi log_date untuk satu habit'
);

select * from finish();
rollback;
