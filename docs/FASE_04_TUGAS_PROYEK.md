# Dokumentasi Fase 4: Tugas, Subtugas, Pengulangan, & Proyek

## 1. Ringkasan Fase & Tujuan
Fase 4 mengimplementasikan modul inti produktivitas harian: manajemen Proyek (`projects`), Tugas (`tasks`), Subtugas (`subtasks`), pengurutan prioritas otomatis, Matriks Eisenhower 4-kuadran, filter waktu (Hari ini, Mendatang, Terlambat, Selesai), integrasi ringkasan tugas di Beranda, serta mesin pengulangan (*Recurrence Engine*) berbasis aturan RRULE.

## 2. Daftar Fitur & Komponen yang Dikerjakan
- **Mesin Pengulangan (`lib/core/recurrence/recurrence_engine.dart`)**:
  - `F-TASK-05`: Parser dan kalkulator aturan pengulangan (`FREQ=DAILY`, `FREQ=WEEKLY`, `FREQ=MONTHLY`, `FREQ=YEARLY`).
  - Penanganan khusus tanggal akhir bulan (contoh: 31 Jan -> 28 Feb pada tahun non-kabisat, 31 Mei -> 30 Jun).
  - Mekanisme otomatis pembuatan *instance* tugas berikutnya saat tugas berulang diselesaikan.
- **Modul Proyek (`lib/features/projects/`)**:
  - `F-PROJ-01`: CRUD proyek (`ProjectListScreen`), warna aksen proyek, deskripsi, tanggal target, dan soft delete.
- **Modul Tugas & Subtugas (`lib/features/tasks/`)**:
  - `F-TASK-01`: CRUD tugas dengan status (`todo`, `in_progress`, `completed`).
  - `F-TASK-02`: Tenggat waktu (*due date*) dan prioritas (P1: Tinggi, P2: Sedang, P3: Rendah, P4: Biasa).
  - `F-TASK-03`: Subtugas interaktif dengan centang *checklist* langsung dari kartu daftar tugas maupun editor.
  - `F-TASK-04`: Filter tab responsif (Semua, Hari Ini, Mendatang, Terlambat, Selesai).
  - `F-TASK-06`: Matriks Eisenhower tanpa AI yang membagi tugas aktif ke dalam 4 kuadran:
    - *Kuadran I*: Mendesak & Penting (Kerjakan Segera)
    - *Kuadran II*: Penting tapi Tidak Mendesak (Jadwalkan)
    - *Kuadran III*: Mendesak tapi Tidak Penting (Tinjau/Delegasi)
    - *Kuadran IV*: Tidak Mendesak & Tidak Penting (Eliminasi)
  - Integrasi Beranda: Menampilkan kartu ringkasan tugas mendesak & terlambat pada `HomeScreen`.

## 3. Perubahan Database & Keamanan
- **Berkas Migrasi**: `supabase/migrations/0005_tasks_projects.sql`
  - Tabel `projects`: `id`, `user_id`, `name`, `description`, `status`, `color`, `target_date`, `created_at`, `updated_at`, `deleted_at`.
  - Tabel `tasks`: `id`, `user_id`, `project_id`, `title`, `description`, `status`, `priority`, `is_important`, `is_urgent`, `due_date`, `recurrence_rule`, `completed_at`, `created_at`, `updated_at`, `deleted_at`.
  - Tabel `subtasks`: `id`, `user_id`, `task_id`, `title`, `is_done`, `position`, `created_at`, `updated_at`.
  - **Foreign Key Komposit**:
    - `tasks (project_id, user_id) REFERENCES projects(id, user_id) ON DELETE SET NULL`
    - `subtasks (task_id, user_id) REFERENCES tasks(id, user_id) ON DELETE CASCADE`
  - **Indeks**: Indeks pada `(user_id, status, due_date)`, `(user_id, project_id)`, `(user_id, priority)`.
  - **RLS & Grants**: RLS aktif 100% dan hak akses `GRANT` diberikan kepada role `authenticated`.

## 4. Keputusan Teknis & Asumsi
- **Tugas Berulang Deterministik**: Ketika tugas berulang ditandai selesai (`completed`), instance saat ini disimpan sebagai riwayat selesai dan sistem otomatis membuat tugas baru dengan tanggal jatuh tempo berikutnya sesuai interval.
- **Matriks Eisenhower**: Klasifikasi murni berdasarkan kombinasi boolean `is_important` dan `is_urgent` tanpa campur tangan model AI/eksternal.

## 5. Cakupan Pengujian
- **Unit Test**: `test/unit/recurrence_engine_test.dart`
  - Pengujian kalkulasi pengulangan harian, mingguan, dan bulanan (termasuk batas akhir bulan dan tahun kabisat).
  - Pengujian pengelompokan Kuadran I hingga IV Matriks Eisenhower.
- **Pengujian Database pgTAP**:
  - `supabase/tests/03_fase4_tasks_projects_test.sql` memverifikasi RLS dan Foreign Key komposit isolasi lintas pengguna.

## 6. Status Verifikasi Jujur & Daftar Tindak Lanjut Manual
- **Status Otomatis**: **Terimplementasi & Lulus Tes Lokal (`dart analyze` 0 issues, 16/16 tests passed)**.
- **Tindak Lanjut Manual untuk Pengguna**:
  1. Jalankan migrasi SQL `0005_tasks_projects.sql` di Supabase SQL Editor.
  2. Buka tab Tugas pada aplikasi, buat tugas baru dengan tenggat hari ini dan atur pengulangan 'Setiap Hari'.
  3. Coba centang selesai tugas tersebut, lalu verifikasi bahwa tugas berikutnya otomatis terbuat untuk esok hari.
  4. Buka tab 'Eisenhower' untuk melihat pengelompokan 4 kuadran.
