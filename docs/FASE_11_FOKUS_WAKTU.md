# Dokumen Fase 11: Fokus & Waktu (Pomodoro Timer & Pelacak Waktu)

Dokumen ini mencatat arsitektur, implementasi teknis, dan verifikasi untuk **Fase 11** sistem **SF-25**, mengacu langsung pada spesifikasi `personal-os-master-blueprint-v2.json` (fitur `F-FOC-01`, `F-FOC-02`, `F-TIME-01`, dan `F-TIME-02`).

---

## 1. Ringkasan Fase & Tujuan
Fase 11 menghadirkan alat produktivitas kerja mendalam (*deep work*) dan pencatatan alokasi waktu:
1. **Timer Pomodoro Interaktif**: Pengatur waktu fokus dengan hitungan mundur visual progres melingkar, mendukung 3 mode utama:
   - Sesi Fokus (*Pomodoro*): 25 menit.
   - Rehat Singkat (*Short Break*): 5 menit.
   - Rehat Panjang (*Long Break*): 15 menit.
2. **Keterhubungan dengan Modul Tugas & Proyek**: Sesi fokus dapat dihubungkan ke ID Tugas (`task_id`) atau Proyek (`project_id`) untuk mengukur waktu nyata pengerjaan sebuah tugas.
3. **Pencatat Waktu Aktivitas Mandiri (*Time Tracking Entries*)**: Timesheet harian untuk mencatat aktivitas lepas atau proyek tertentu dengan kalkulasi durasi terformat otomatis ("1j 30m").
4. **Statistik Fokus & Waktu Reaktif**:
   - Total durasi fokus hari ini.
   - Jumlah sesi fokus selesai hari ini.
   - Total menit fokus dalam 7 hari terakhir.
   - Total jam kerja timesheet mingguan.

---

## 2. Daftar Fitur & Komponen yang Dikerjakan

### A. Rute & Layar (Navigation)
- `/focus`: [lib/features/focus/presentation/focus_screen.dart](file:///d:/Codee/self-management/lib/features/focus/presentation/focus_screen.dart) — Layar utama Pomodoro dengan indikator melingkar, kontrol play/pause/reset/complete, pemilihan mode, dropdown tautan tugas, dan riwayat sesi fokus.
- `/time`: [lib/features/focus/presentation/time_tracker_screen.dart](file:///d:/Codee/self-management/lib/features/focus/presentation/time_tracker_screen.dart) — Layar timesheet pelacak waktu dengan banner statistik mingguan, dialog pencatatan aktivitas, dan riwayat entri waktu.
- Grid Modul: [lib/features/modules_grid_screen.dart](file:///d:/Codee/self-management/lib/features/modules_grid_screen.dart) — Menu 'Fokus & Waktu' aktif menuju `/focus`.

### B. Controller & State Management (Riverpod)
- [lib/features/focus/presentation/focus_controller.dart](file:///d:/Codee/self-management/lib/features/focus/presentation/focus_controller.dart):
  - `focusSessionsProvider`: Mengambil riwayat sesi fokus aktif pengguna dari Supabase.
  - `timeEntriesProvider`: Mengambil riwayat timesheet aktivitas aktif.
  - `focusStatsProvider`: Mengagregasikan durasi fokus hari ini, sesi selesai, dan total waktu mingguan.
  - `pomodoroTimerProvider`: StateNotifier pengelola siklus timer detik demi detik, transisi mode, dan otomatisasi penyimpanan sesi saat timer selesai.
  - `focusActionsProvider`: StateNotifier operasi CRUD sesi fokus dan entri waktu.

### C. Repository Layer
- [lib/features/focus/data/focus_repository.dart](file:///d:/Codee/self-management/lib/features/focus/data/focus_repository.dart): Mengelola kueri database Supabase ke tabel `public.focus_sessions` dan `public.time_entries`, termasuk soft delete `deleted_at`.

### D. Domain Models
- [lib/features/focus/domain/focus_session.dart](file:///d:/Codee/self-management/lib/features/focus/domain/focus_session.dart): Entitas sesi fokus dengan getter `isPomodoro` dan `isBreak`.
- [lib/features/focus/domain/time_entry.dart](file:///d:/Codee/self-management/lib/features/focus/domain/time_entry.dart): Entitas catatan waktu dengan utilitas `formattedDuration`.
- [lib/features/focus/domain/focus_statistics.dart](file:///d:/Codee/self-management/lib/features/focus/domain/focus_statistics.dart): DTO kalkulasi ringkasan produktivitas harian dan mingguan.

---

## 3. Perubahan Database & Keamanan

### Berkas Migrasi: `supabase/migrations/0012_focus_time.sql`
1. **Tabel `public.focus_sessions`**:
   - `id uuid PRIMARY KEY DEFAULT gen_random_uuid()`
   - `user_id uuid NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE`
   - `task_id uuid`
   - `project_id uuid`
   - `started_at timestamptz NOT NULL DEFAULT now()`
   - `ended_at timestamptz`
   - `planned_minutes integer NOT NULL DEFAULT 25 CHECK (planned_minutes > 0)`
   - `actual_minutes integer NOT NULL DEFAULT 0 CHECK (actual_minutes >= 0)`
   - `completed boolean NOT NULL DEFAULT true`
   - `session_type text NOT NULL DEFAULT 'pomodoro' CHECK (session_type IN ('pomodoro', 'short_break', 'long_break', 'custom'))`
   - `note text`
   - `deleted_at timestamptz`
   - `created_at timestamptz NOT NULL DEFAULT now()`
   - `updated_at timestamptz NOT NULL DEFAULT now()`
   - `CONSTRAINT uq_focus_sessions_user UNIQUE (id, user_id)`
   - `CONSTRAINT fk_focus_sessions_task FOREIGN KEY (task_id, user_id) REFERENCES public.tasks(id, user_id) ON DELETE SET NULL`
   - `CONSTRAINT fk_focus_sessions_project FOREIGN KEY (project_id, user_id) REFERENCES public.projects(id, user_id) ON DELETE SET NULL`
2. **Tabel `public.time_entries`**:
   - `id uuid PRIMARY KEY DEFAULT gen_random_uuid()`
   - `user_id uuid NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE`
   - `project_id uuid`
   - `activity text NOT NULL`
   - `started_at timestamptz NOT NULL DEFAULT now()`
   - `ended_at timestamptz`
   - `duration_seconds integer NOT NULL DEFAULT 0 CHECK (duration_seconds >= 0)`
   - `note text`
   - `deleted_at timestamptz`
   - `created_at timestamptz NOT NULL DEFAULT now()`
   - `updated_at timestamptz NOT NULL DEFAULT now()`
   - `CONSTRAINT uq_time_entries_user UNIQUE (id, user_id)`
   - `CONSTRAINT fk_time_entries_project FOREIGN KEY (project_id, user_id) REFERENCES public.projects(id, user_id) ON DELETE SET NULL`
3. **Keamanan RLS & Grants**:
   - Mengaktifkan RLS 100% pada kedua tabel dengan kebijakan `user_id = auth.uid()` untuk `SELECT`, `INSERT`, `UPDATE`, `DELETE`.
   - `REVOKE ALL ON ALL TABLES IN SCHEMA public FROM anon` dan `GRANT SELECT, INSERT, UPDATE, DELETE TO authenticated`.
   - Triggers `handle_updated_at` terpasang.

### Pengujian pgTAP: `supabase/tests/10_fase11_focus_time_test.sql`
- Memuat 8 assertion pengujian:
  - Struktur tabel `focus_sessions` dan `time_entries`.
  - Isolasi RLS data antarpengguna.
  - Foreign Key komposit dan batasan constraint integritas data.

---

## 4. Status Verifikasi

| Komponen Uji | Metode | Status | Catatan |
|---|---|---|---|
| Domain Models & Pomodoro State | `test/unit/focus_time_test.dart` | **LULUS** | 4 assertion serialisasi, durasi terformat, progres timer |
| Suite Test Unit Penuh | `dart run test/all_tests.dart` | **LULUS** | 49/49 tests lulus |
| Analisis Statis Kode | `dart analyze lib test` | **LULUS** | 0 issues found |
| Skema Database & RLS | `supabase/migrations/0012_focus_time.sql` | **Siap Push** | Menunggu eksekusi migration via `supabase db push` atau SQL Editor di project Supabase |
| Pengujian Database pgTAP | `supabase/tests/10_fase11_focus_time_test.sql` | **Siap Test** | Menunggu eksekusi via `supabase test db` |
