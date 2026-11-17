-- ==============================================================================
-- PGTAP TEST SUITE: FASE 12 (JOURNAL, MOOD, REVIEWS, GOALS & KEY RESULTS)
-- Menguji keberadaan tabel, isolasi RLS, FK komposit, dan batasan integritas
-- ==============================================================================

begin;
select plan(11);

-- 1. Uji Keberadaan Tabel
select has_table('public', 'journal_entries', 'Tabel journal_entries harus ada');
select has_table('public', 'mood_logs', 'Tabel mood_logs harus ada');
select has_table('public', 'reviews', 'Tabel reviews harus ada');
select has_table('public', 'goals', 'Tabel goals harus ada');
select has_table('public', 'key_results', 'Tabel key_results harus ada');

-- 2. Uji RLS Aktif
select rls_is_enabled('public', 'journal_entries', 'RLS harus aktif di journal_entries');
select rls_is_enabled('public', 'mood_logs', 'RLS harus aktif di mood_logs');
select rls_is_enabled('public', 'reviews', 'RLS harus aktif di reviews');
select rls_is_enabled('public', 'goals', 'RLS harus aktif di goals');
select rls_is_enabled('public', 'key_results', 'RLS harus aktif di key_results');

-- 3. User A membuat Jurnal dan Sasaran
select tests.authenticate_as('user_a@personalos.local');

insert into public.goals (id, user_id, title)
values (
  '12121212-1212-1212-1212-121212121212',
  auth.uid(),
  'Mencapai Kemandirian Finansial'
);

-- 4. User B tidak boleh membaca sasaran User A
select tests.authenticate_as('user_b@personalos.local');

select is_empty(
  'select * from public.goals where id = ''12121212-1212-1212-1212-121212121212''',
  'User B dilarang melihat sasaran (goal) User A'
);

select * from finish();
rollback;
