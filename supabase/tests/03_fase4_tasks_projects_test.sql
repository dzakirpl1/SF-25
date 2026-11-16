-- ==============================================================================
-- PGTAP TEST SUITE: FASE 4 (PROJECTS, TASKS, SUBTASKS)
-- Menguji isolasi RLS dan relasi composite FK untuk Fase 4
-- ==============================================================================

begin;
select plan(10);

-- 1. Uji Keberadaan Tabel
select has_table('public', 'projects', 'Tabel projects harus ada');
select has_table('public', 'tasks', 'Tabel tasks harus ada');
select has_table('public', 'subtasks', 'Tabel subtasks harus ada');

-- 2. Uji RLS Aktif
select rls_is_enabled('public', 'projects', 'RLS harus aktif di projects');
select rls_is_enabled('public', 'tasks', 'RLS harus aktif di tasks');
select rls_is_enabled('public', 'subtasks', 'RLS harus aktif di subtasks');

-- 3. Simulasi User A membuat proyek dan tugas
select tests.authenticate_as('user_a@personalos.local');

insert into public.projects (id, user_id, name)
values ('33333333-3333-3333-3333-333333333333', auth.uid(), 'Proyek Alpha');

insert into public.tasks (id, user_id, project_id, title, priority, is_important, is_urgent)
values (
  '44444444-4444-4444-4444-444444444444',
  auth.uid(),
  '33333333-3333-3333-3333-333333333333',
  'Tugas A1',
  1,
  true,
  true
);

insert into public.subtasks (id, user_id, task_id, title)
values ('55555555-5555-5555-5555-555555555555', auth.uid(), '44444444-4444-4444-4444-444444444444', 'Subtugas A1.1');

-- 4. User B mencoba melihat atau memanipulasi data User A
select tests.authenticate_as('user_b@personalos.local');

select is_empty(
  'select * from public.projects where id = ''33333333-3333-3333-3333-333333333333''',
  'User B tidak boleh melihat proyek User A'
);

select is_empty(
  'select * from public.tasks where id = ''44444444-4444-4444-4444-444444444444''',
  'User B tidak boleh melihat tugas User A'
);

select is_empty(
  'select * from public.subtasks where id = ''55555555-5555-5555-5555-555555555555''',
  'User B tidak boleh melihat subtugas User A'
);

-- User B dilarang menautkan tugas miliknya ke proyek milik User A (Composite FK check)
select throws_ok(
  'insert into public.tasks (user_id, project_id, title) values (auth.uid(), ''33333333-3333-3333-3333-333333333333'', ''Tugas Bajak'')',
  '23503',
  NULL,
  'Composite FK harus mencegah penautan tugas ke proyek milik akun lain'
);

select * from finish();
rollback;
