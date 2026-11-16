# SF-25

> *Sistem Manajemen Diri Terpadu (Self-Management Framework 25) — Satu aplikasi cepat, privat, dan terpercaya untuk mengelola catatan, tugas, waktu, kebiasaan, keuangan, dan seluruh aspek kehidupan sehari-hari.*

Proyek ini dibangun menggunakan **Flutter** dan **Supabase PostgreSQL** berdasarkan spesifikasi arsitektur di `personal-os-master-blueprint-v2.json`.

---

## Status Fase Pengembangan

| Fase | Nama Fase | Status | Keterangan |
| :---: | :--- | :---: | :--- |
| **0** | Audit & Persiapan Awal | **SELESAI** | Lingkungan & struktur dasar terverifikasi ([docs/FASE_00_AUDIT_PERSIAPAN.md](file:///d:/Codee/self-management/docs/FASE_00_AUDIT_PERSIAPAN.md)) |
| **1** | Fondasi Flutter & Supabase | **SELESAI** | Auth, Profile, Settings dasar, Beranda ([docs/FASE_01_FONDASI.md](file:///d:/Codee/self-management/docs/FASE_01_FONDASI.md)) |
| **2** | Catatan & Kategori | **SELESAI** | CRUD Catatan, Kategori, Soft Delete, RLS ([docs/FASE_02_CATATAN_KATEGORI.md](file:///d:/Codee/self-management/docs/FASE_02_CATATAN_KATEGORI.md)) |
| **3** | Keamanan, PIN, Pengaturan, & Koneksi | **SELESAI** | Kunci PIN/Biometrik, Pengaturan interaktif, Zona Waktu, Draf Memori ([docs/FASE_03_KEAMANAN_PENGATURAN_KONEKSI.md](file:///d:/Codee/self-management/docs/FASE_03_KEAMANAN_PENGATURAN_KONEKSI.md)) |
| **4** | Tugas, Proyek, & Mesin Pengulangan | **SELESAI** | Proyek, Subtugas, Matriks Eisenhower, Recurrence RRULE ([docs/FASE_04_TUGAS_PROYEK.md](file:///d:/Codee/self-management/docs/FASE_04_TUGAS_PROYEK.md)) |
| **5** | Inbox, Template, Tempat Sampah, & Tautan | **SELESAI** | Triase Inbox 1-Ketukan, Template generik, Tempat Sampah, Markdown ([docs/FASE_05_INBOX_ORGANISASI_LANJUT.md](file:///d:/Codee/self-management/docs/FASE_05_INBOX_ORGANISASI_LANJUT.md)) |
| **6** | Kalender, Event, & Blok Waktu | **SELESAI** | Tampilan Bulan/Minggu/Hari/Agenda, Time Blocking, RRULE expansion ([docs/FASE_06_KALENDER_EVENT_BLOK_WAKTU.md](file:///d:/Codee/self-management/docs/FASE_06_KALENDER_EVENT_BLOK_WAKTU.md)) |
| **7** | Kebiasaan & Rutinitas | **SELESAI** | Streak dinamis tanggal logis, checklist pagi/malam, riwayat heatmap ([docs/FASE_07_KEBIASAAN_RUTINITAS.md](file:///d:/Codee/self-management/docs/FASE_07_KEBIASAAN_RUTINITAS.md)) |
| **8** | Pengingat & Notifikasi | **SELESAI** | Pengingat terjadwal, aksi tunda/selesai, skema token FCM/MCP ([docs/FASE_08_PENGINGAT_NOTIFIKASI.md](file:///d:/Codee/self-management/docs/FASE_08_PENGINGAT_NOTIFIKASI.md)) |
| **9** | Money Tracker Inti | **SELESAI** | Dompet multi-rekening, kategori finansial, transaksi, saldo dinamis ([docs/FASE_09_MONEY_TRACKER_INTI.md](file:///d:/Codee/self-management/docs/FASE_09_MONEY_TRACKER_INTI.md)) |
| **10** | Keuangan Lanjutan | **SELESAI** | Anggaran bulanan, target tabungan & setoran, manajemen utang piutang ([docs/FASE_10_KEUANGAN_LANJUTAN.md](file:///d:/Codee/self-management/docs/FASE_10_KEUANGAN_LANJUTAN.md)) |

---

## Prinsip & Standar Teknis
1. **Online-First (Supabase)**: Database PostgreSQL Supabase adalah sumber kebenaran tunggal (*single source of truth*).
2. **Keamanan RLS 100%**: RLS aktif di seluruh tabel pengguna dengan Foreign Key komposit `(id, user_id)`.
3. **Capture Cepat**: FAB Global tersedia di setiap layar untuk aksi *Quick Capture*.
4. **Presisi Moneter**: Uang dicatat dalam satuan `bigint` rupiah penuh (bukan float).
5. **Waktu UTC & Tanggal Logis**: Disimpan sebagai `timestamptz` UTC; tanggal logis dihitung dinamis via `day_start_hour`.

---

## Menjalankan Proyek
Jalankan aplikasi dengan parameter `--dart-define`:

```bash
flutter run --dart-define=SUPABASE_URL=https://zvbixisduvvadtvnhzla.supabase.co --dart-define=SUPABASE_ANON_KEY=sb_publishable_eYjEwW2R3dj2cHDbIl9G_g_sYGUvTcx
```

## Menjalankan Pengujian
```bash
# Analisis kode (linter & type checking)
dart analyze lib test

# Format kode
dart format lib test

# Menjalankan unit tests
dart run test/all_tests.dart
```
