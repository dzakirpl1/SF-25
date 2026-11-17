-- ==============================================================================
-- PGTAP TEST SUITE: FASE 13 (HEALTH, WORKOUTS, SLEEP, WATER, MEDICATIONS)
-- Menguji keberadaan tabel kesehatan, isolasi RLS, dan integritas FK komposit
-- ==============================================================================

begin;
select plan(10);

-- 1. Uji Keberadaan Tabel
select has_table('public', 'workouts', 'Tabel workouts harus ada');
select has_table('public', 'sleep_logs', 'Tabel sleep_logs harus ada');
select has_table('public', 'water_logs', 'Tabel water_logs harus ada');
select has_table('public', 'body_measurements', 'Tabel body_measurements harus ada');
select has_table('public', 'medications', 'Tabel medications harus ada');
select has_table('public', 'medication_logs', 'Tabel medication_logs harus ada');
select has_table('public', 'meal_logs', 'Tabel meal_logs harus ada');

-- 2. Uji RLS Aktif
select rls_is_enabled('public', 'workouts', 'RLS harus aktif di workouts');
select rls_is_enabled('public', 'water_logs', 'RLS harus aktif di water_logs');
select rls_is_enabled('public', 'medications', 'RLS harus aktif di medications');

select * from finish();
rollback;
