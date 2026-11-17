# Indeks Dokumentasi SF-25

Dokumentasi ini adalah sumber kebenaran (*single source of truth*) pengembangan proyek **SF-25**, mengacu langsung pada arsitektur `personal-os-master-blueprint-v2.json`.

---

## Peta Fase Pengembangan

| Fase | Judul Modul | Berkas Dokumentasi | Status Verifikasi |
| :---: | :--- | :--- | :---: |
| **0** | **Audit & Persiapan Awal** | [FASE_00_AUDIT_PERSIAPAN.md](FASE_00_AUDIT_PERSIAPAN.md) | ✅ Selesai & Lulus Audit |
| **1** | **Fondasi Flutter & Supabase** | [FASE_01_FONDASI.md](FASE_01_FONDASI.md) | ✅ Terimplementasi & Teruji Live |
| **2** | **Catatan & Kategori** | [FASE_02_CATATAN_KATEGORI.md](FASE_02_CATATAN_KATEGORI.md) | ✅ Terimplementasi & Teruji Live |
| **3** | **Keamanan Awal, PIN/Biometrik, Pengaturan & Koneksi** | [FASE_03_KEAMANAN_PENGATURAN_KONEKSI.md](FASE_03_KEAMANAN_PENGATURAN_KONEKSI.md) | ✅ Terimplementasi & Lulus Tes Lokal |
| **4** | **Tugas, Subtugas, Pengulangan, & Proyek** | [FASE_04_TUGAS_PROYEK.md](FASE_04_TUGAS_PROYEK.md) | ✅ Terimplementasi & Lulus Tes Lokal |
| **5** | **Inbox, Template, Tempat Sampah, & Tautan Links** | [FASE_05_INBOX_ORGANISASI_LANJUT.md](FASE_05_INBOX_ORGANISASI_LANJUT.md) | ✅ Terimplementasi & Lulus Tes Lokal |
| **6** | **Kalender & Blok Waktu** | [FASE_06_KALENDER_EVENT_BLOK_WAKTU.md](FASE_06_KALENDER_EVENT_BLOK_WAKTU.md) | ✅ Terimplementasi & Lulus Tes Lokal |
| **7** | **Kebiasaan & Rutinitas** | [FASE_07_KEBIASAAN_RUTINITAS.md](FASE_07_KEBIASAAN_RUTINITAS.md) | ✅ Terimplementasi & Lulus Tes Lokal |
| **8** | **Pengingat & Notifikasi** | [FASE_08_PENGINGAT_NOTIFIKASI.md](FASE_08_PENGINGAT_NOTIFIKASI.md) | ✅ Terimplementasi & Lulus Tes Lokal |
| **9** | **Money Tracker Inti** | [FASE_09_MONEY_TRACKER_INTI.md](FASE_09_MONEY_TRACKER_INTI.md) | ✅ Terimplementasi & Lulus Tes Lokal |
| **10** | **Keuangan Lanjutan (Anggaran, Tabungan, & Utang)** | [FASE_10_KEUANGAN_LANJUTAN.md](FASE_10_KEUANGAN_LANJUTAN.md) | ✅ Terimplementasi & Lulus Tes Lokal |
| **11** | **Fokus & Waktu (Pomodoro & Timesheet)** | [FASE_11_FOKUS_WAKTU.md](FASE_11_FOKUS_WAKTU.md) | ✅ Terimplementasi & Lulus Tes Lokal |
| **12** | **Jurnal, Mood, Refleksi, & Sasaran (OKRs)** | [FASE_12_JURNAL_MOOD_GOALS.md](FASE_12_JURNAL_MOOD_GOALS.md) | ✅ Terimplementasi & Lulus Tes Lokal |
| **13** | **Kesehatan, Kebugaran, & Pengobatan** | [FASE_13_KESEHATAN_PENGOBATAN.md](FASE_13_KESEHATAN_PENGOBATAN.md) | ✅ Terimplementasi & Lulus Tes Lokal |

---

## Standar & Aturan Mutlak
1. **Keamanan RLS**: Semua tabel wajib memiliki kebijakan RLS `auth.uid() = user_id`.
2. **Foreign Key Komposit**: Relasi antartabel milik pengguna wajib mengikat `(id, user_id)` untuk mencegah relasi silang akun.
3. **Format Presisi Rupiah**: Semua nominal uang wajib disimpan bertipe `bigint` rupiah penuh (bukan float).
4. **Waktu UTC & Tanggal Logis**: Semua stempel waktu disimpan dalam UTC (`timestamptz`). Hari logis dikalkulasikan via `day_start_hour` di `user_settings`.
5. **Zero AI & Online First**: Tanpa algoritma AI, tanpa SQLite lokal; Supabase adalah sumber kebenaran tunggal dengan penanganan draft sementara di memori perangkat.
