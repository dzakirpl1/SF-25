# Dokumentasi Fase 0: Audit & Persiapan Awal

## 1. Ringkasan Fase & Tujuan
Fase 0 bertujuan memastikan kesiapan pondasi infrastruktur, lingkungan pengembangan Flutter, struktur direktori *feature-first*, serta kelayakan proyek Supabase sebelum penulisan kode modul inti dimulai. Proyek ini mengacu langsung pada spesifikasi `personal-os-master-blueprint-v2.json` versi 2.1.0.

## 2. Daftar Fitur & Komponen yang Dikerjakan
- **Struktur Folder Standar**:
  - `lib/app/`: Routing utama dan shell navigasi.
  - `lib/core/`: Utilitas waktu/tanggal logis, pemformat rupiah, dan konfigurasi Supabase.
  - `lib/shared/`: Komponen widget lintas fitur (state loading, empty, error, dan dialog konfirmasi).
  - `lib/features/`: Arsitektur *feature-first* (auth, settings, home, notes, categories).
  - `supabase/migrations/`: Berkas SQL berurutan.
  - `supabase/tests/`: Skrip pengujian isolasi data pgTAP.
  - `docs/`: Dokumentasi sumber kebenaran proyek.
- **Konfigurasi Dependensi (`pubspec.yaml`)**:
  - Flutter SDK 3.44.7, Dart SDK 3.12.2.
  - `flutter_riverpod`, `go_router`, `supabase_flutter`, `intl`, `flutter_secure_storage`, `uuid`, `fl_chart`.

## 3. Perubahan Database & Keamanan
- Penyiapan proyek Supabase Cloud `dzakirpl1's Project` (region `ap-south-1`).
- Penetapan standar konvensi:
  - Primary Key: `uuid` dengan generator `gen_random_uuid()`.
  - Kolom audit: `created_at` dan `updated_at` bertipe `timestamptz` (UTC).
  - Row Level Security (RLS) diaktifkan secara wajib di 100% tabel pengguna.
  - Larangan menyertakan `service_role` key pada klien Flutter.

## 4. Keputusan Teknis & Asumsi
- **Online-first / Single Source of Truth**: Data kebenaran tunggal berada di Supabase. Tidak menggunakan database lokal SQLite atau mesin sinkronisasi dua arah.
- **Satu Pengguna (Pemilik)**: Aplikasi ditujukan khusus untuk pemilik tunggal. Pendaftaran mandiri (public signup) dimatikan di Supabase.
- **Tanpa Fitur AI**: Semua proses capture, penentuan prioritas, dan statistik menggunakan logika deterministik murni.

## 5. Cakupan Pengujian
- **Audit Lingkungan**: `flutter doctor` dan verifikasi Dart SDK.
- **Verifikasi Dependensi**: Resolusi dependensi via `dart pub get` (109 dependensi terunduh bersih).

## 6. Status Verifikasi Jujur & Daftar Tindak Lanjut Manual
- **Status Otomatis**: **Terimplementasi & Lulus Tes Lokal**.
- **Tindak Lanjut Manual untuk Pengguna**:
  1. Pastikan opsi *Allow new users to sign up* pada menu Supabase Dashboard (`Authentication -> Providers -> Email`) telah dinonaktifkan untuk mencegah pihak asing mendaftar.
