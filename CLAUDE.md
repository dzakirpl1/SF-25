# Panduan Pengembangan Personal OS (CLAUDE.md)

## Identitas Proyek
- **Nama**: Personal OS
- **Target**: Sistem Operasi Pribadi untuk satu pengguna tunggal (pemilik).
- **Distribusi**: Sideload APK Android dengan signing keystore mandiri.
- **Bahasa UI**: Bahasa Indonesia (`id_ID`).
- **Identifier Kode**: Bahasa Inggris (`camelCase`, `PascalCase`, `snake_case` di DB).

## Standar & Aturan Mutlak
1. **Sumber Kebenaran**: Dokumen di `docs/` dan `personal-os-master-blueprint-v2.json`.
2. **Keamanan Database**:
   - Seluruh tabel pengguna wajib mengaktifkan Row Level Security (RLS) `auth.uid() = user_id`.
   - Foreign Key komposit `(id, user_id)` wajib digunakan pada relasi antartabel pengguna.
   - Tabel utama memiliki kolom `created_at`, `updated_at`, dan `deleted_at` (soft delete).
   - Operasi `UPDATE` wajib mengecek `updated_at` (optimistic concurrency control).
3. **Konektivitas**:
   - Online-first via Supabase PostgreSQL. Tidak ada SQLite lokal atau 2-way sync.
   - Draft sementara disimpan di memori/storage ringan jika koneksi terputus agar ketikan pengguna tidak hilang.
4. **Presisi Keuangan**:
   - Uang disimpan sebagai `bigint` rupiah penuh (bukan float).
   - Saldo dompet dihitung dinamis dari `initial_balance + transaksi`.

## Perintah Kerja Penting
```bash
# Analisis Kode
dart analyze lib test

# Format Kode
dart format lib test

# Menjalankan Unit Test
dart run test/all_tests.dart

# Menjalankan Aplikasi
flutter run --dart-define=SUPABASE_URL=... --dart-define=SUPABASE_ANON_KEY=...
```
