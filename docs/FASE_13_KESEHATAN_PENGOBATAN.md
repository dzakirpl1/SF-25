# Dokumen Fase 13: Kesehatan, Kebugaran, & Pengobatan

Dokumen ini mencatat arsitektur, implementasi teknis, dan verifikasi untuk **Fase 13** sistem **SF-25**, mengacu langsung pada spesifikasi `personal-os-master-blueprint-v2.json` (fitur `F-HLT-01`, `F-HLT-02`, `F-HLT-03`, `F-HLT-04`, `F-HLT-05`, `F-MED-01`, dan `F-MED-02`).

---

## 1. Ringkasan Fase & Tujuan
Fase 13 menyediakan instrumen pelacakan kesehatan raga, kualitas pemulihan, dan manajemen pengobatan:
1. **Pelacak Asupan Air Minum (*Hydration Tracker*)**:
   - Pencatatan log air minum dengan pintasan 1-ketukan: `+250 ml (Gelas)` dan `+500 ml (Botol)`.
   - Progress bar pencapaian target harian default 2000 ml.
2. **Pelacak Tidur & Kualitas Istirahat (*Sleep Tracker*)**:
   - Pencatatan jam tidur dan jam bangun dengan penghitungan durasi jam-menit otomatis.
   - Evaluasi kualitas tidur skala 1–5 (Sangat Buruk s.d. Sangat Nyenyak).
3. **Catatan Olahraga & Kebugaran (*Workouts*)**:
   - Pencatatan ragam aktivitas (Lari, Gym, Renang, Sepeda, Jalan Kaki, Yoga) dengan durasi menit dan perkiraan kalori terbakar.
   - Ringkasan frekuensi olahraga dalam 7 hari terakhir.
4. **Daftar Obat, Suplemen, & Log Kepatuhan (*Medication Management*)**:
   - Pencatatan obat/suplemen aktif, dosis aturan minum, dan jadwal jam harian.
   - Fitur 1-ketukan untuk menandai obat sudah diminum pada hari tersebut (`medication_logs`).
5. **Pengukuran Tubuh & Log Makanan (*Body & Meals*)**:
   - Skema database siap pakai untuk berat badan, lingkar tubuh, dan catatan makan harian.

---

## 2. Daftar Fitur & Komponen yang Dikerjakan

### A. Rute & Layar (Navigation)
- `/health`: [lib/features/health/presentation/health_screen.dart](file:///d:/Codee/self-management/lib/features/health/presentation/health_screen.dart) — Dashboard kesehatan terpadu: progress air minum harian, ringkasan tidur semalam, olahraga 7 hari terakhir, dan daftar obat hari ini.
- `/health/workouts`: [lib/features/health/presentation/workouts_screen.dart](file:///d:/Codee/self-management/lib/features/health/presentation/workouts_screen.dart) — Riwayat lengkap sesi olahraga dan dialog pencatatan aktivitas fisik baru.
- `/health/medications`: [lib/features/health/presentation/medications_screen.dart](file:///d:/Codee/self-management/lib/features/health/presentation/medications_screen.dart) — Layar pengelolaan obat/suplemen, aturan dosis, jadwal jam konsumsi, dan aksi hapus.
- Grid Modul: [lib/features/modules_grid_screen.dart](file:///d:/Codee/self-management/lib/features/modules_grid_screen.dart) — Menu 'Kesehatan' aktif menuju `/health`.

### B. Controller & State Management (Riverpod)
- [lib/features/health/presentation/health_controller.dart](file:///d:/Codee/self-management/lib/features/health/presentation/health_controller.dart):
  - `workoutsProvider`: Riwayat aktivitas olahraga.
  - `sleepLogsProvider`: Riwayat tidur.
  - `waterLogsProvider`: Riwayat asupan air minum.
  - `medicationsProvider`: Daftar obat aktif pengguna.
  - `healthSummaryProvider`: Perhitungan total air hari ini, status ketercapaian target, durasi tidur semalam, dan total olahraga mingguan.
  - `healthActionsProvider`: Notifier untuk aksi cepat catat air minum, simpan tidur, simpan olahraga, dan tandai obat diminum.

### C. Repository Layer
- [lib/features/health/data/health_repository.dart](file:///d:/Codee/self-management/lib/features/health/data/health_repository.dart): Menangani operasi Supabase untuk tabel `workouts`, `sleep_logs`, `water_logs`, `medications`, dan `medication_logs`.

### D. Domain Models
- [lib/features/health/domain/workout.dart](file:///d:/Codee/self-management/lib/features/health/domain/workout.dart)
- [lib/features/health/domain/sleep_log.dart](file:///d:/Codee/self-management/lib/features/health/domain/sleep_log.dart)
- [lib/features/health/domain/water_log.dart](file:///d:/Codee/self-management/lib/features/health/domain/water_log.dart)
- [lib/features/health/domain/medication.dart](file:///d:/Codee/self-management/lib/features/health/domain/medication.dart)
- [lib/features/health/domain/health_summary.dart](file:///d:/Codee/self-management/lib/features/health/domain/health_summary.dart)

---

## 3. Perubahan Database & Keamanan

### Berkas Migrasi: `supabase/migrations/0014_health.sql`
1. **Tabel-Tabel Baru**:
   - `public.workouts`: ID, user_id, jenis, waktu mulai, durasi menit, estimasi kalori, catatan.
   - `public.sleep_logs`: ID, user_id, jam tidur, jam bangun, kualitas (1–5), catatan.
   - `public.water_logs`: ID, user_id, waktu log, nominal ml.
   - `public.body_measurements`: ID, user_id, berat badan kg, data ukuran jsonb.
   - `public.medications`: ID, user_id, nama obat, dosis, array jadwal jsonb, status aktif.
   - `public.medication_logs`: ID, user_id, FK komposit `(medication_id, user_id)`, waktu jadwal, waktu minum, status (`taken`, `skipped`, `missed`).
   - `public.meal_logs`: ID, user_id, waktu makan, jenis hidangan, deskripsi, catatan.
2. **Keamanan RLS & Grants**:
   - Mengaktifkan RLS 100% pada ke-7 tabel dengan kebijakan `user_id = auth.uid()` untuk `SELECT`, `INSERT`, `UPDATE`, `DELETE`.
   - `REVOKE ALL ON ALL TABLES IN SCHEMA public FROM anon` dan `GRANT SELECT, INSERT, UPDATE, DELETE TO authenticated`.
   - Triggers `handle_updated_at` terpasang di semua tabel.

### Pengujian pgTAP: `supabase/tests/12_fase13_health_test.sql`
- Memuat 10 assertion pengujian untuk memverifikasi keberadaan seluruh tabel kesehatan, RLS aktif, dan integritas Foreign Key komposit.

---

## 4. Status Verifikasi

| Komponen Uji | Metode | Status | Catatan |
|---|---|---|---|
| Domain Models (`Workout`, `SleepLog`, `WaterLog`, `Medication`, `HealthSummary`) | `test/unit/health_test.dart` | **LULUS** | 4 assertion serialisasi, durasi tidur, dan progress hidrasi |
| Suite Test Unit Penuh | `dart run test/all_tests.dart` | **LULUS** | 57/57 tests lulus |
| Analisis Statis Kode | `dart analyze lib test` | **LULUS** | 0 issues found |
| Skema Database & RLS | `supabase/migrations/0014_health.sql` | **Siap Push** | Menunggu eksekusi migration via `supabase db push` atau SQL Editor di project Supabase |
| Pengujian Database pgTAP | `supabase/tests/12_fase13_health_test.sql` | **Siap Test** | Menunggu eksekusi via `supabase test db` |
