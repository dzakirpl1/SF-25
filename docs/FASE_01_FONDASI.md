# Dokumentasi Fase 1: Fondasi Flutter dan Supabase

## 1. Ringkasan Fase & Tujuan
Fase 1 meletakkan fondasi autentikasi, manajemen profil dan pengaturan pengguna, penanganan sesi persisten, tema Material 3, lokalisasi Bahasa Indonesia (`id_ID`), serta kerangka navigasi dasar (5 bottom navigation tabs dan Beranda modular).

## 2. Daftar Fitur & Komponen yang Dikerjakan
- **Fitur Autentikasi (`lib/features/auth/`)**:
  - `F-AUTH-01`: Login via email & password (`LoginScreen`).
  - `F-AUTH-02`: Logout dengan konfirmasi dialog pembersihan sesi.
  - `F-AUTH-03`: Pemulihan sesi otomatis saat aplikasi dibuka via Riverpod StreamProvider `authStateProvider`.
- **Fitur Pengaturan (`lib/features/settings/`)**:
  - `F-SET-01`: Halaman pengaturan awal (`SettingsScreen`) yang menampilkan avatar pemilik, email aktif, preferensi tema, zona waktu (`Asia/Jakarta`), mata uang (`IDR`), dan jam awal hari (`day_start_hour`).
- **Fitur Beranda (`lib/features/home/`)**:
  - `F-HOME-01`: Beranda dinamis (`HomeScreen`) dengan salam personal pemilik, kalkulasi tanggal logis ramah Indonesia, kartu aksi instan *Quick Capture*, dan pratinjau catatan terbaru.
- **Navigasi Global (`lib/app/`)**:
  - `ShellScreen`: 5 pilar navigasi (`Beranda`, `Catatan`, `Tugas`, `Kalender`, `Modul`).
  - `router.dart`: Pengalihan otentikasi otomatis (`redirect: unauthenticated -> /login`, `authenticated -> /home`).

## 3. Perubahan Database & Keamanan
- **Berkas Migrasi**:
  - `supabase/migrations/0001_init.sql`:
    - Tabel `profiles`: `id` (FK ke `auth.users`), `display_name`, `created_at`, `updated_at`.
    - Tabel `user_settings`: `user_id` (PK, FK ke `auth.users`), `theme`, `accent_color`, `timezone`, `locale`, `currency`, `week_start`, `day_start_hour`, `notification_prefs`, `app_lock_enabled`.
    - Trigger `handle_new_user()` pada `auth.users` untuk *auto-provisioning* baris profil & pengaturan awal saat akun dibuat.
    - Kebijakan RLS ketat berbasis `auth.uid() = id / user_id`.
  - `supabase/migrations/0002_explicit_grants.sql`:
    - Pencabutan seluruh hak akses publik default (`revoke all from anon, public`).
    - Pemberian hak `grant usage on schema public` dan CRUD eksplisit tabel `profiles` dan `user_settings` khusus untuk role `authenticated`.

## 4. Keputusan Teknis & Asumsi
- **Format Stempel Waktu**: Semua waktu disimpan dalam UTC (`timestamptz`). Konversi ke waktu tampilan lokal dilakukan saat *rendering*.
- **Konfigurasi Variabel Lingkungan**: Menggunakan `--dart-define` untuk `SUPABASE_URL` dan `SUPABASE_ANON_KEY`, dengan nilai cadangan (*fallback*) ke instans proyek pemilik.

## 5. Cakupan Pengujian
- **Unit Test**:
  - `test/unit/currency_utils_test.dart`: Validasi pemformatan rupiah integer/bigint (`Rp 1.250.000`).
  - `test/unit/date_utils_test.dart`: Validasi kalkulasi tanggal logis sebelum dan sesudah ambang batas `day_start_hour` (jam 04:00 dini hari).
- **Pengujian Integrasi**:
  - Script validasi `scratch/verify_e2e_live.py`: Verifikasi login live ke endpoint Supabase `https://zvbixisduvvadtvnhzla.supabase.co`, memastikan akun `haisayang2021@gmail.com` berhasil login dan data profil otomatis terisi.

## 6. Status Verifikasi Jujur & Daftar Tindak Lanjut Manual
- **Status Otomatis**: **Terimplementasi & Lulus Tes Lokal & Lulus Verifikasi REST API Supabase**.
- **Tindak Lanjut Manual untuk Pengguna**:
  1. Jalankan `flutter run` di perangkat emulator/fisik untuk memverifikasi transisi visual dari layar login ke beranda.
