# Dokumen Fase 7: Kebiasaan & Rutinitas Harian

Dokumen ini mencatat arsitektur, implementasi teknis, dan verifikasi untuk **Fase 7** sistem **Personal OS**, mengacu langsung pada spesifikasi `personal-os-master-blueprint-v2.json` (fitur `F-HAB-01` s.d. `F-ROUT-02`).

---

## 1. Ringkasan Fase & Tujuan
Fase 7 menghadirkan sistem pelacakan kebiasaan dan otomatisasi rutinitas harian untuk mendukung produktivitas dan gaya hidup disiplin:
1. **Kebiasaan (Habits)**: Pencatatan kebiasaan berulang dengan target frekuensi fleksibel (harian maupun hari-hari tertentu dalam seminggu).
2. **Kalkulator Streak Berdasarkan Hari Logis**: Perhitungan rentetan hari beruntun (*current streak*), rekor terpanjang (*longest streak*), dan rasio penyelesaian 30 hari yang menghormati `day_start_hour` dan `timezone` di `user_settings`.
3. **Pengecualian Akhir Pekan**: Pada kebiasaan hari kerja (`specific_days`: Sen-Jum), akhir pekan yang terlewat tidak mematahkan rentetan *streak*.
4. **Rutinitas Harian (Routines & Steps)**: Checklist berulang untuk rutinitas pagi (*morning*), malam (*evening*), atau waktu khusus (*custom*).
5. **Check-in Cepat Lintas Modul**: Terintegrasi langsung di layar Beranda (*Home*), menu modul, dan Tempat Sampah (*Trash*).

---

## 2. Daftar Fitur & Komponen yang Dikerjakan

### A. Rute & Layar (Navigation)
- `/habits` : [lib/features/habits/presentation/habits_screen.dart](file:///d:/Codee/self-management/lib/features/habits/presentation/habits_screen.dart) — Layar utama dengan dua tab:
  - **Tab Kebiasaan**: Kartu kebiasaan interaktif, tombol centang satu-ketukan, indikator api streak (`🔥 X hari beruntun`), statistik rekor terpanjang, dan bar progres penyelesaian 30 hari.
  - **Tab Rutinitas**: Kartu ekspansi rutinitas (Pagi / Malam), rasio langkah selesai hari ini, dan checklist interaktif tiap langkah rutinitas.
- `/habits/edit` : [lib/features/habits/presentation/habit_editor_screen.dart](file:///d:/Codee/self-management/lib/features/habits/presentation/habit_editor_screen.dart) — Formulir pembuatan & penyuntingan kebiasaan, pengaturan tipe frekuensi (Harian vs Hari-Hari Tertentu dengan chip pemilih Sen-Min), palet warna, dan deskripsi.
- `/routines/edit` : [lib/features/habits/presentation/routine_editor_screen.dart](file:///d:/Codee/self-management/lib/features/habits/presentation/routine_editor_screen.dart) — Formulir rutinitas, pemilih waktu (pagi/malam/khusus), serta penambahan/pengurutan ulang daftar langkah secara dinamis (`ReorderableListView`).

### B. Controller & State Management (Riverpod)
- [lib/features/habits/presentation/habit_controller.dart](file:///d:/Codee/self-management/lib/features/habits/presentation/habit_controller.dart):
  - `habitListProvider`: Mengambil semua kebiasaan aktif dari database Supabase.
  - `habitLogsProvider`: Mengambil riwayat log kebiasaan 90 hari terakhir.
  - `habitsWithStreakProvider`: Mengombinasikan data kebiasaan dengan kalkulasi streak dinamis berbasis tanggal logis saat ini.
  - `habitActionsProvider`: StateNotifier untuk `createHabit`, `updateHabit`, `toggleHabitToday`, dan `deleteHabit`.
- [lib/features/habits/presentation/routine_controller.dart](file:///d:/Codee/self-management/lib/features/habits/presentation/routine_controller.dart):
  - `routineListProvider`: Mengambil seluruh rutinitas beserta langkah-langkahnya.
  - `routineLogsTodayProvider`: Mengambil log penyelesaian langkah rutinitas pada tanggal logis hari ini.
  - `routineActionsProvider`: StateNotifier untuk `createRoutine`, `updateRoutine`, `toggleStepToday`, dan `deleteRoutine`.

### C. Repository & Data Layer
- [lib/features/habits/data/habit_repository.dart](file:///d:/Codee/self-management/lib/features/habits/data/habit_repository.dart): Menangani operasi database tabel `public.habits` dan `public.habit_logs` dengan verifikasi sesi pengguna `user_id`, optimistic check `updated_at`, dan soft delete `deleted_at`.
- [lib/features/habits/data/routine_repository.dart](file:///d:/Codee/self-management/lib/features/habits/data/routine_repository.dart): Menangani operasi relasional antara `public.routines`, `public.routine_steps`, dan `public.routine_logs`.

### D. Domain Models & Logika Inti
- [lib/core/habits/habit_streak_calculator.dart](file:///d:/Codee/self-management/lib/core/habits/habit_streak_calculator.dart): Algoritma murni untuk kalkulasi streak beruntun, rekor terpanjang, dan kepatuhan frekuensi hari kerja tanpa merusak streak saat hari libur.
- [lib/features/habits/domain/habit.dart](file:///d:/Codee/self-management/lib/features/habits/domain/habit.dart) & [habit_log.dart](file:///d:/Codee/self-management/lib/features/habits/domain/habit_log.dart): Model data kebiasaan dan entri log tanggal.
- [lib/features/habits/domain/routine.dart](file:///d:/Codee/self-management/lib/features/habits/domain/routine.dart), [routine_step.dart](file:///d:/Codee/self-management/lib/features/habits/domain/routine_step.dart), & [routine_log.dart](file:///d:/Codee/self-management/lib/features/habits/domain/routine_log.dart): Model data rutinitas berulang.

### E. Integrasi Lintas Modul
1. **Beranda (Fase 1)**: [lib/features/home/presentation/home_screen.dart](file:///d:/Codee/self-management/lib/features/home/presentation/home_screen.dart) kini memiliki widget *"Kebiasaan Hari Ini"* yang memungkinkan check-in langsung dari beranda dengan pembaruan instan status streak.
2. **Tempat Sampah (Fase 5)**: [lib/features/trash/presentation/trash_screen.dart](file:///d:/Codee/self-management/lib/features/trash/presentation/trash_screen.dart) dan `trash_controller.dart` kini memiliki tab keempat *"Kebiasaan"* untuk memulihkan atau menghapus permanen kebiasaan yang terhapus.
3. **Navigasi Global**: [lib/features/modules_grid_screen.dart](file:///d:/Codee/self-management/lib/features/modules_grid_screen.dart) mengaktifkan menu 'Kebiasaan & Rutinitas' ke rute `/habits`.

---

## 3. Perubahan Database & Keamanan

### Berkas Migrasi: `supabase/migrations/0008_habits_routines.sql`
1. **Tabel-Tabel Baru**:
   - `public.habits`: Menyimpan master kebiasaan, frekuensi, target, warna, `deleted_at`.
   - `public.habit_logs`: Menyimpan entri centang harian bertanggal `log_date` (unik per `(habit_id, log_date)`).
   - `public.routines`: Menyimpan master rutinitas (`time_of_day`: morning, evening, custom).
   - `public.routine_steps`: Menyimpan langkah-langkah dalam rutinitas dengan urutan posisi `position`.
   - `public.routine_logs`: Menyimpan log penyelesaian langkah rutinitas pada `log_date`.
2. **Foreign Key Komposit (Perlindungan Anti Lintas Akun)**:
   - `habit_logs(habit_id, user_id) -> habits(id, user_id)`
   - `routine_steps(routine_id, user_id) -> routines(id, user_id)`
   - `routine_logs(routine_id, user_id) -> routines(id, user_id)`
3. **Keamanan RLS & Grants**:
   - RLS aktif di kelima tabel baru.
   - Kebijakan RLS membatasi `auth.uid() = user_id` untuk `SELECT`, `INSERT`, `UPDATE`, dan `DELETE`.
   - Hak akses eksplisit `GRANT ... TO authenticated; REVOKE ALL FROM anon;`.
   - Trigger otomatis `handle_updated_at()` pada setiap pembaruan data.

---

## 4. Keputusan Teknis & Asumsi
1. **Tanggal Logis Sebagai Sumber Kebenaran Tanggal**:
   Log kebiasaan dan rutinitas dicatat dalam kolom bertipe `date` (`yyyy-MM-dd`) yang dihitung dari waktu UTC saat ini disesuaikan dengan `user_settings.day_start_hour` dan `timezone`. Hal ini mencegah kebiasaan malam hari (misal jam 01:00 dini hari) salah tercatat sebagai kebiasaan hari berikutnya.
2. **Kalkulasi Streak di Klien**:
   Mirip dengan ekspansi acara kalender pada Fase 6, streak dihitung di sisi klien oleh `HabitStreakCalculator` dari riwayat log yang ditarik, menjaga fleksibilitas jika pengguna mengubah jam mulai hari atau preferensi hari kerja tanpa memerlukan *batch job cron* di database.

---

## 5. Cakupan Pengujian

### A. Pengujian pgTAP Database (`supabase/tests/06_fase7_habits_routines_test.sql`)
- 12 asersi pengujian meliputi:
  - Keberadaan 5 tabel Fase 7 (`habits`, `habit_logs`, `routines`, `routine_steps`, `routine_logs`).
  - Verifikasi RLS aktif di seluruh tabel.
  - Simulasi User A membuat habit dan habit log.
  - Isolasi RLS: User B dilarang melihat habit dan log milik User A.
  - Penolakan relasi Foreign Key komposit: User B dilarang membuat log untuk habit User A (Error Postgres `23503`).
  - Penolakan duplikasi tanggal log pada habit yang sama (Unique constraint `23505`).

### B. Unit Tests Dart (`test/unit/habit_streak_test.dart`)
- **Streak Harian Beruntun**: Validasi perhitungan rentetan hari jika hari ini sudah dikerjakan.
- **Streak Lanjutan Kemarin**: Memvalidasi bahwa streak tidak patah jika hari ini belum selesai selama kemarin telah diselesaikan.
- **Deteksi Streak Patah**: Streak bernilai 0 jika kemarin bolos dan hari ini belum selesai.
- **Pengecualian Akhir Pekan (`specific_days`)**: Memvalidasi bahwa hari libur (Sabtu-Minggu) tidak merusak streak hari kerja (Sen-Jum).
- **Rasio Kepatuhan 30 Hari**: Memvalidasi proporsi hari selesai terhadap total hari wajib.
- **Serialisasi JSON Model Domain**: Pengujian bolak-balik untuk `Habit`, `HabitLog`, `Routine`, dan `RoutineStep`.

---

## 6. Status Verifikasi Jujur & Tindak Lanjut Manual

| Kategori Pengujian | Status | Bukti / Catatan |
| :--- | :---: | :--- |
| **Dart Analyzer (`dart analyze`)** | ✅ **Lulus (0 Issues)** | Tidak ada error, warning, maupun info linter |
| **Unit Testing Dart** | ✅ **Lulus (100%)** | Seluruh test di `test/unit/habit_streak_test.dart` lulus bersih |
| **Eksekusi SQL di Supabase** | ⚠️ **Menunggu Tindak Lanjut** | Skrip [supabase/migrations/0008_habits_routines.sql](file:///d:/Codee/self-management/supabase/migrations/0008_habits_routines.sql) harus dieksekusi di SQL Editor dashboard Supabase |
| **Uji pgTAP Database CLI** | ⚠️ **Menunggu Tindak Lanjut** | Jalankan `supabase test db` di mesin dengan Supabase CLI lokal terpasang |
| **Uji Coba Perangkat Fisik** | ⚠️ **Menunggu Tindak Lanjut** | Uji langsung check-in kebiasaan dari Beranda dan checklist rutinitas di HP Android fisik |
