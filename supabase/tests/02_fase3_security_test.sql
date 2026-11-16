-- ==============================================================================
-- PGTAP TEST SUITE: FASE 3 (SECURITY HARDENING & USER SETTINGS)
-- ==============================================================================

begin;
select plan(8);

-- 1. Uji kolom baru di user_settings
select has_column('public', 'user_settings', 'pin_enabled', 'Kolom pin_enabled harus ada');
select has_column('public', 'user_settings', 'biometric_enabled', 'Kolom biometric_enabled harus ada');
select has_column('public', 'user_settings', 'lock_timeout_minutes', 'Kolom lock_timeout_minutes harus ada');
select has_column('public', 'user_settings', 'updated_at', 'Kolom updated_at harus ada');

-- 2. Uji fungsi check_connection
select has_function('public', 'check_connection', 'Fungsi check_connection harus ada');

-- 3. Uji trigger updated_at otomatis pada user_settings
select tests.authenticate_as('user_a@personalos.local');

-- Ambil updated_at awal
select updated_at as orig_updated_at from public.user_settings where user_id = auth.uid() \gset

-- Lakukan pembaruan
update public.user_settings set timezone = 'Asia/Makassar' where user_id = auth.uid();

-- Verifikasi nilai updated_at telah diperbarui
select isnt(
  (select updated_at from public.user_settings where user_id = auth.uid()),
  :'orig_updated_at',
  'Trigger set_updated_at harus memperbarui stempel updated_at secara otomatis'
);

-- 4. Uji isolasi RLS: User B tidak boleh dapat memodifikasi pengaturan User A
select tests.authenticate_as('user_b@personalos.local');
update public.user_settings set timezone = 'Asia/Jayapura' where user_id = :'user_a_id';

select is(
  (select timezone from public.user_settings where user_id = :'user_a_id'),
  'Asia/Makassar',
  'User B dilarang mengubah pengaturan User A'
);

select is(
  (select timezone from public.user_settings where user_id = auth.uid()),
  'Asia/Jakarta',
  'Pengaturan User B tetap independen'
);

select * from finish();
rollback;
