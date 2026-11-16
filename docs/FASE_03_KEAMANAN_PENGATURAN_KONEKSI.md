# Dokumentasi Fase 3: Keamanan Awal, Kunci Aplikasi, Pengaturan, Zona Waktu, & Koneksi

## 1. Ringkasan Fase & Tujuan
Fase 3 berfokus pada pengerasan keamanan (*security hardening*), perlindungan privasi data sensitif melalui Kunci Aplikasi (PIN 6-digit & Biometrik lokal), penanganan kehilangan jaringan internet dengan sistem draf sementara (*ephemeral drafts*), serta pembaharuan modul Pengaturan menjadi interaktif penuh dengan pengecekan integritas pembaruan optimistik (`updated_at`).

## 2. Daftar Fitur & Komponen yang Dikerjakan
- **Kunci Aplikasi (`lib/features/auth/presentation/app_lock_screen.dart` & `lib/core/services/app_lock_service.dart`)**:
  - `F-SEC-02`: Mekanisme penguncian layar dengan keypad numerik PIN 6-digit dan autentikasi biometrik (sidik jari/wajah).
  - PIN disimpan secara aman di `flutter_secure_storage` dalam bentuk hash ter-salt (SHA-256) tanpa menyimpan teks asli (*plaintext*).
  - Deteksi jeda waktu (*timeout*) latar belakang via `AppLifecycleListener` untuk mengunci ulang aplikasi secara otomatis.
- **Pengaturan Interaktif Penuh (`lib/features/settings/presentation/settings_screen.dart`)**:
  - `F-SET-02`: Pengguna dapat mengubah nama tampilan profil, tema (Sistem, Terang, Gelap), zona waktu (`Asia/Jakarta`, `Asia/Makassar`, `Asia/Jayapura`, `UTC`), dan jam pergantian hari logis (`day_start_hour`).
  - Opsi keamanan: Mengaktifkan/menonaktifkan PIN, mengaktifkan biometrik, dan memilih durasi timeout penguncian (1, 5, 15, 30 menit).
  - Pengecekan *optimistic concurrency control* (`updated_at`) pada mutasi profil dan pengaturan.
- **Ketahanan Jaringan & Draf Sementara (`lib/core/services/ephemeral_draft_service.dart` & `lib/shared/widgets/offline_banner.dart`)**:
  - `F-NET-01`: Banner status offline yang otomatis muncul saat koneksi Supabase terputus, dilengkapi tombol "Coba Lagi".
  - `F-NET-02`: Penyimpanan draf sementara di memori perangkat pada editor catatan sehingga ketikan pengguna tidak pernah hilang meskipun koneksi mati saat menekan tombol simpan.
- **Isolasi RLS Dua Akun (`supabase/tests/02_fase3_security_test.sql`)**:
  - `F-SEC-01`: Rangkaian tes pgTAP yang menguji isolasi kolom pengaturan baru dan fungsi `check_connection()`.

## 3. Perubahan Database & Keamanan
- **Berkas Migrasi**: `supabase/migrations/0004_security_hardening.sql`
  - Kolom baru pada tabel `user_settings`:
    - `pin_enabled boolean not null default false`
    - `biometric_enabled boolean not null default false`
    - `lock_timeout_minutes integer not null default 5`
    - `updated_at timestamptz not null default now()`
  - Fungsi trigger `set_updated_at()` yang otomatis memperbarui nilai `updated_at = now()` sebelum operasi update pada tabel `profiles`, `user_settings`, dan `notes`.
  - Fungsi RPC `check_connection()` untuk verifikasi status server dan identitas pengguna terautentikasi.

## 4. Keputusan Teknis & Asumsi
- **Penyimpanan Kredensial Kunci**: PIN tidak pernah dikirim ke database Supabase, melainkan sepenuhnya dikelola di perangkat lokal pengguna via `flutter_secure_storage`.
- **Draf Sementara**: Draf disimpan secara lokal per entitas dan otomatis dibersihkan begitu data berhasil tersimpan ke Supabase.

## 5. Cakupan Pengujian
- **Unit Test**: `test/unit/app_lock_test.dart`
  - Pengujian pembuatan dan pencocokan hash PIN menggunakan salt acak.
  - Pengujian penolakan PIN yang tidak sesuai.
- **Pengujian Database pgTAP**:
  - `supabase/tests/02_fase3_security_test.sql` siap dijalankan melalui `supabase test db`.

## 6. Status Verifikasi Jujur & Daftar Tindak Lanjut Manual
- **Status Otomatis**: **Terimplementasi & Lulus Tes Lokal (`dart analyze` 0 issues, 10/10 tests passed)**.
- **Tindak Lanjut Manual untuk Pengguna**:
  1. Jalankan migrasi SQL `0004_security_hardening.sql` di Supabase SQL Editor.
  2. Buka Pengaturan di aplikasi, aktifkan PIN 6-digit, lalu coba kunci aplikasi dan buka kembali menggunakan keypad PIN atau biometrik sidik jari.
  3. Matikan koneksi Wi-Fi/data saat mengedit catatan untuk memverifikasi munculnya banner offline dan pemulihan draf sementara.
