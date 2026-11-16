-- ==============================================================================
-- PGTAP TEST SUITE: FASE 5 (INBOX, TEMPLATES, TAGS, LINKS)
-- ==============================================================================

begin;
select plan(12);

-- 1. Uji Keberadaan Tabel
select has_table('public', 'inbox_items', 'Tabel inbox_items harus ada');
select has_table('public', 'templates', 'Tabel templates harus ada');
select has_table('public', 'tags', 'Tabel tags harus ada');
select has_table('public', 'note_tags', 'Tabel note_tags harus ada');
select has_table('public', 'links', 'Tabel links harus ada');

-- 2. Uji RLS Aktif
select rls_is_enabled('public', 'inbox_items', 'RLS aktif di inbox_items');
select rls_is_enabled('public', 'templates', 'RLS aktif di templates');
select rls_is_enabled('public', 'tags', 'RLS aktif di tags');
select rls_is_enabled('public', 'note_tags', 'RLS aktif di note_tags');
select rls_is_enabled('public', 'links', 'RLS aktif di links');

-- 3. Uji Isolasi Akun User A vs User B
select tests.authenticate_as('user_a@personalos.local');

insert into public.inbox_items (id, user_id, content)
values ('66666666-6666-6666-6666-666666666666', auth.uid(), 'Ide mentah User A');

select tests.authenticate_as('user_b@personalos.local');

select is_empty(
  'select * from public.inbox_items where id = ''66666666-6666-6666-6666-666666666666''',
  'User B dilarang melihat inbox milik User A'
);

-- Uji Composite FK: User B dilarang menautkan tag ke catatan User A
select throws_ok(
  'insert into public.note_tags (note_id, tag_id, user_id) values (''22222222-2222-2222-2222-222222222222'', ''77777777-7777-7777-7777-777777777777'', auth.uid())',
  '23503',
  NULL,
  'Composite FK note_tags harus menolak referensi catatan milik akun lain'
);

select * from finish();
rollback;
