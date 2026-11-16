-- ==============================================================================
-- PGTAP TEST SUITE: FASE 9 (FINANCE CORE: WALLETS, CATEGORIES, TRANSACTIONS)
-- Menguji RLS isolasi dua akun, FK komposit, dan constraint transfer
-- ==============================================================================

begin;
select plan(12);

-- 1. Uji Keberadaan Tabel
select has_table('public', 'wallets', 'Tabel wallets harus ada');
select has_table('public', 'fin_categories', 'Tabel fin_categories harus ada');
select has_table('public', 'transactions', 'Tabel transactions harus ada');

-- 2. Uji RLS Aktif
select rls_is_enabled('public', 'wallets', 'RLS harus aktif di wallets');
select rls_is_enabled('public', 'fin_categories', 'RLS harus aktif di fin_categories');
select rls_is_enabled('public', 'transactions', 'RLS harus aktif di transactions');

-- 3. User A membuat Dompet dan Transaksi
select tests.authenticate_as('user_a@personalos.local');

insert into public.wallets (id, user_id, name, type, initial_balance)
values (
  'aaaa1111-1111-1111-1111-111111111111',
  auth.uid(),
  'Dompet Tunai',
  'cash',
  500000
);

insert into public.transactions (user_id, wallet_id, type, amount, note)
values (
  auth.uid(),
  'aaaa1111-1111-1111-1111-111111111111',
  'income',
  250000,
  'Gaji Lepas'
);

-- 4. User B dilarang melihat dompet User A
select tests.authenticate_as('user_b@personalos.local');

select is_empty(
  'select * from public.wallets where id = ''aaaa1111-1111-1111-1111-111111111111''',
  'User B tidak boleh melihat dompet User A'
);

select is_empty(
  'select * from public.transactions where wallet_id = ''aaaa1111-1111-1111-1111-111111111111''',
  'User B tidak boleh melihat transaksi User A'
);

-- 5. User B dilarang mencatat transaksi ke dompet User A (Composite FK Check)
select throws_ok(
  'insert into public.transactions (user_id, wallet_id, type, amount) values (auth.uid(), ''aaaa1111-1111-1111-1111-111111111111'', ''expense'', 10000)',
  '23503',
  'Composite FK menolak transaksi ke dompet milik akun lain'
);

-- 6. Constraint Cek Transfer (to_wallet_id wajib jika type = transfer)
select tests.authenticate_as('user_a@personalos.local');

select throws_ok(
  'insert into public.transactions (user_id, wallet_id, type, amount) values (auth.uid(), ''aaaa1111-1111-1111-1111-111111111111'', ''transfer'', 50000)',
  '23514',
  'Transfer tanpa to_wallet_id ditolak constraint check'
);

select * from finish();
rollback;
