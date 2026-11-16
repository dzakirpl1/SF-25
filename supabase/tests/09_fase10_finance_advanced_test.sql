-- ==============================================================================
-- PGTAP TEST SUITE: FASE 10 (FINANCE ADVANCED: BUDGETS, SAVINGS, DEBTS)
-- Menguji keberadaan tabel, RLS isolasi antarpengguna, FK komposit, dan constraint
-- ==============================================================================

begin;
select plan(13);

-- 1. Uji Keberadaan Tabel
select has_table('public', 'budgets', 'Tabel budgets harus ada');
select has_table('public', 'savings_goals', 'Tabel savings_goals harus ada');
select has_table('public', 'savings_contributions', 'Tabel savings_contributions harus ada');
select has_table('public', 'debts', 'Tabel debts harus ada');
select has_table('public', 'debt_payments', 'Tabel debt_payments harus ada');

-- 2. Uji RLS Aktif
select rls_is_enabled('public', 'budgets', 'RLS harus aktif di budgets');
select rls_is_enabled('public', 'savings_goals', 'RLS harus aktif di savings_goals');
select rls_is_enabled('public', 'savings_contributions', 'RLS harus aktif di savings_contributions');
select rls_is_enabled('public', 'debts', 'RLS harus aktif di debts');
select rls_is_enabled('public', 'debt_payments', 'RLS harus aktif di debt_payments');

-- 3. User A membuat Target Tabungan dan Utang
select tests.authenticate_as('user_a@personalos.local');

insert into public.savings_goals (id, user_id, name, target_amount)
values (
  'bbbb1111-1111-1111-1111-111111111111',
  auth.uid(),
  'Dana Liburan Akhir Tahun',
  10000000
);

insert into public.debts (id, user_id, person_name, direction, principal)
values (
  'cccc1111-1111-1111-1111-111111111111',
  auth.uid(),
  'Budi Santoso',
  'owed_to_me',
  1500000
);

-- 4. User B tidak boleh membaca data User A
select tests.authenticate_as('user_b@personalos.local');

select is_empty(
  'select * from public.savings_goals where id = ''bbbb1111-1111-1111-1111-111111111111''',
  'User B tidak boleh melihat savings goal User A'
);

select is_empty(
  'select * from public.debts where id = ''cccc1111-1111-1111-1111-111111111111''',
  'User B tidak boleh melihat catatan utang/piutang User A'
);

-- 5. User B tidak boleh mengubah atau menambah pembayaran ke utang User A (Composite FK check)
select throws_ok(
  $$insert into public.debt_payments (user_id, debt_id, amount)
    values (auth.uid(), 'cccc1111-1111-1111-1111-111111111111', 500000)$$,
  'User B tidak boleh mencatat pembayaran ke utang milik User A'
);

select * from finish();
rollback;
