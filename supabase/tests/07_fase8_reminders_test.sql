-- ==============================================================================
-- PGTAP TEST SUITE: FASE 8 (REMINDERS & DEVICE TOKENS)
-- Menguji isolasi RLS dan constraint tabel pengingat dan token FCM
-- ==============================================================================

begin;
select plan(10);

-- 1. Uji Keberadaan Tabel
select has_table('public', 'reminders', 'Tabel reminders harus ada');
select has_table('public', 'device_tokens', 'Tabel device_tokens harus ada');

-- 2. Uji Kolom Utama
select has_column('public', 'reminders', 'target_type', 'Kolom target_type harus ada');
select has_column('public', 'reminders', 'snoozed_until', 'Kolom snoozed_until harus ada');
select has_column('public', 'device_tokens', 'fcm_token', 'Kolom fcm_token harus ada');

-- 3. Uji RLS Aktif
select rls_is_enabled('public', 'reminders', 'RLS harus aktif di reminders');
select rls_is_enabled('public', 'device_tokens', 'RLS harus aktif di device_tokens');

-- 4. User A membuat Pengingat dan Mendaftarkan Token FCM
select tests.authenticate_as('user_a@personalos.local');

insert into public.reminders (id, user_id, title, remind_at, status)
values (
  '99999999-9999-9999-9999-999999999999',
  auth.uid(),
  'Minum Vitamin C',
  '2026-11-17T08:00:00Z',
  'scheduled'
);

insert into public.device_tokens (user_id, fcm_token, platform)
values (
  auth.uid(),
  'fcm_mock_token_user_a_123456',
  'android'
);

-- 5. User B tidak boleh melihat pengingat User A
select tests.authenticate_as('user_b@personalos.local');

select is_empty(
  'select * from public.reminders where id = ''99999999-9999-9999-9999-999999999999''',
  'User B tidak boleh melihat pengingat User A'
);

select is_empty(
  'select * from public.device_tokens where fcm_token = ''fcm_mock_token_user_a_123456''',
  'User B tidak boleh melihat token perangkat User A'
);

select * from finish();
rollback;
