-- ==============================================================================
-- PGTAP TEST SUITE: FASE 1 & FASE 2
-- Menguji isolasi ketat RLS 2 akun, composite FK, dan proteksi RPC
-- ==============================================================================

begin;
select plan(14);

-- 1. Pastikan ekstensi pgtap aktif
select has_extension('pgtap');

-- 2. Setup Dua Pengguna Simulasi (User A & User B)
create extension if not exists "uuid-ossp";

select tests.create_supabase_user('user_a@personalos.local', 'pass123') as user_a_id \gset
select tests.create_supabase_user('user_b@personalos.local', 'pass123') as user_b_id \gset

-- 3. Uji Keberadaan Tabel
select has_table('public', 'profiles', 'Tabel profiles harus ada');
select has_table('public', 'user_settings', 'Tabel user_settings harus ada');
select has_table('public', 'note_categories', 'Tabel note_categories harus ada');
select has_table('public', 'notes', 'Tabel notes harus ada');

-- 4. Uji RLS Aktif pada Semua Tabel
select rls_is_enabled('public', 'profiles', 'RLS harus aktif di profiles');
select rls_is_enabled('public', 'user_settings', 'RLS harus aktif di user_settings');
select rls_is_enabled('public', 'note_categories', 'RLS harus aktif di note_categories');
select rls_is_enabled('public', 'notes', 'RLS harus aktif di notes');

-- 5. Simulasi Interaksi User A
select tests.authenticate_as('user_a@personalos.local');

-- User A membuat kategori
insert into public.note_categories (id, user_id, name, color)
values ('11111111-1111-1111-1111-111111111111', auth.uid(), 'Pekerjaan', '#00796B');

-- User A membuat catatan di dalam kategori tersebut
insert into public.notes (id, user_id, category_id, title, content)
values ('22222222-2222-2222-2222-222222222222', auth.uid(), '11111111-1111-1111-1111-111111111111', 'Catatan A', 'Isi A');

-- 6. Uji Isolasi Akun: User B Masuk
select tests.authenticate_as('user_b@personalos.local');

-- User B TIDAK boleh bisa melihat catatan milik User A
select is_empty(
  'select * from public.notes where id = ''22222222-2222-2222-2222-222222222222''',
  'User B tidak boleh dapat melihat catatan milik User A'
);

-- User B TIDAK boleh bisa melihat kategori milik User A
select is_empty(
  'select * from public.note_categories where id = ''11111111-1111-1111-1111-111111111111''',
  'User B tidak boleh dapat melihat kategori milik User A'
);

-- User B TIDAK boleh bisa mengubah catatan milik User A
update public.notes set title = 'Dibajak B' where id = '22222222-2222-2222-2222-222222222222';
select isnt(
  (select title from public.notes where id = '22222222-2222-2222-2222-222222222222'),
  'Dibajak B',
  'User B tidak boleh dapat mengubah catatan milik User A'
);

-- 7. Uji RPC delete_note_category: Ditolak jika ada catatan aktif
select tests.authenticate_as('user_a@personalos.local');

select throws_ok(
  'select public.delete_note_category(''11111111-1111-1111-1111-111111111111'')',
  'P0001',
  'Kategori sedang digunakan oleh catatan aktif dan tidak dapat dihapus',
  'RPC delete_note_category wajib menolak jika masih dipakai catatan aktif'
);

select * from finish();
rollback;
