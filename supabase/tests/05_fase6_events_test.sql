-- ==============================================================================
-- PGTAP TEST SUITE: FASE 6 (CALENDAR EVENTS & TIME BLOCKS)
-- Menguji keberadaan tabel, RLS isolasi dua akun, dan Composite FK
-- ==============================================================================

begin;
select plan(10);

-- 1. Uji Keberadaan Tabel
select has_table('public', 'events', 'Tabel events harus ada');

-- 2. Uji Kolom Utama
select has_column('public', 'events', 'is_time_block', 'Kolom is_time_block harus ada');
select has_column('public', 'events', 'linked_task_id', 'Kolom linked_task_id harus ada');
select has_column('public', 'events', 'recurrence_rule', 'Kolom recurrence_rule harus ada');

-- 3. Uji RLS Aktif
select rls_is_enabled('public', 'events', 'RLS harus aktif di events');

-- 4. User A membuat Event dan Blok Waktu
select tests.authenticate_as('user_a@personalos.local');

insert into public.events (id, user_id, title, starts_at, ends_at, all_day)
values (
  '66666666-6666-6666-6666-666666666666',
  auth.uid(),
  'Rapat Strategi Mingguan',
  '2026-11-15T09:00:00Z',
  '2026-11-15T10:00:00Z',
  false
);

select results_eq(
  'select count(*)::integer from public.events where user_id = auth.uid() and id = ''66666666-6666-6666-6666-666666666666''',
  ARRAY[1],
  'User A berhasil membuat event kalender'
);

-- 5. User B tidak boleh melihat Event User A
select tests.authenticate_as('user_b@personalos.local');

select is_empty(
  'select * from public.events where id = ''66666666-6666-6666-6666-666666666666''',
  'User B tidak boleh melihat event kalender User A'
);

-- User B dilarang mengubah event milik User A
update public.events
set title = 'Event Bajakan'
where id = '66666666-6666-6666-6666-666666666666';

select tests.authenticate_as('user_a@personalos.local');
select results_eq(
  'select title from public.events where id = ''66666666-6666-6666-6666-666666666666''',
  ARRAY['Rapat Strategi Mingguan'],
  'Judul event User A tidak berubah oleh User B'
);

-- 6. Uji Composite FK: User B dilarang menautkan event miliknya ke task milik User A
select tests.authenticate_as('user_b@personalos.local');

select throws_ok(
  'insert into public.events (user_id, title, starts_at, ends_at, linked_task_id) values (auth.uid(), ''Blok Bajak'', ''2026-11-15T09:00:00Z'', ''2026-11-15T10:00:00Z'', ''44444444-4444-4444-4444-444444444444'')',
  '23503',
  'Foreign Key komposit menolak penautan task lintas pengguna'
);

select * from finish();
rollback;
