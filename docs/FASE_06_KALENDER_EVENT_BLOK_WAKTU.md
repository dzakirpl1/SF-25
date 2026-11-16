# Dokumen Fase 6: Kalender, Event, & Blok Waktu (Time Blocking)

Dokumen ini mencatat arsitektur, implementasi teknis, dan verifikasi untuk **Fase 6** sistem **Personal OS**, mengacu langsung pada spesifikasi `personal-os-master-blueprint-v2.json` (fitur `F-CAL-01` s.d. `F-CAL-04`).

---

## 1. Ringkasan Fase & Tujuan
Fase 6 membangun sistem pengelolaan waktu terpadu yang menyatukan:
1. **Acara Kalender (Events)**: Pertemuan, agenda, dan acara dengan rentang waktu mulai/selesai atau seharian (*all-day*).
2. **Mesin Pengulangan Klien (Client-Side RRULE Expansion)**: Tidak menduplikasi baris database, melainkan mengekspansi kejadian berulang (harian, mingguan, bulanan, tahunan) secara dinamis sesuai rentang tampilan pengguna.
3. **Blok Waktu (Time Blocking)**: Kemampuan mengalokasikan waktu fokus yang ditautkan langsung dengan tugas tertentu (*linked task*).
4. **Agregasi Tugas & Tenggat (Cross-Module Integration)**: Menampilkan tugas-tugas ber-tenggat bersamaan dengan acara kalender dalam satu jadwal terpadu.
5. **Mode Tampilan Lengkap**: Bulan (Grid 7x6), Minggu (7 hari terperinci), Hari (agenda harian), dan Agenda 30 hari ke depan.

---

## 2. Daftar Fitur & Komponen yang Dikerjakan

### A. Rute & Layar (Navigation)
- `/calendar` : [lib/features/calendar/presentation/calendar_screen.dart](file:///d:/Codee/self-management/lib/features/calendar/presentation/calendar_screen.dart) — Layar utama kalender dengan 4 mode tampilan (*month*, *week*, *day*, *agenda*), navigasi tanggal (<, Hari Ini, >), dan filter agenda.
- `/calendar/event/edit` : [lib/features/calendar/presentation/event_editor_screen.dart](file:///d:/Codee/self-management/lib/features/calendar/presentation/event_editor_screen.dart) — Formulir interaktif untuk membuat/mengedit acara atau blok waktu, pemilih rentang waktu, toggle seharian, pemilih RRULE, label warna, dan penautan ke tugas.

### B. Controller & State Management (Riverpod)
- [lib/features/calendar/presentation/calendar_controller.dart](file:///d:/Codee/self-management/lib/features/calendar/presentation/calendar_controller.dart):
  - `calendarEventsProvider`: Mengambil semua event aktif dari Supabase.
  - `selectedCalendarDateProvider`: Mengelola tanggal yang sedang dipilih/fokus.
  - `calendarViewModeProvider`: Mengelola mode tampilan aktif (`month`, `week`, `day`, `agenda`).
  - `combinedCalendarItemsProvider`: Menggabungkan hasil ekspansi acara kalender (`EventOccurrence`) dan tugas ber-tenggat waktu (`TaskItem`) dalam rentang tanggal aktif.
  - `todayScheduleProvider`: Menyediakan daftar agenda khusus untuk hari ini (diintegrasikan langsung ke Beranda).
  - `calendarActionsProvider`: StateNotifier untuk pembuatan, pembaruan (dengan optimistic check), dan soft-delete acara.

### C. Repository & Data Layer
- [lib/features/calendar/data/calendar_repository.dart](file:///d:/Codee/self-management/lib/features/calendar/data/calendar_repository.dart): Menangani CRUD langsung ke tabel `public.events` di Supabase dengan verifikasi sesi pengguna `user_id`, optimistic check `updated_at`, serta soft delete `deleted_at`.

### D. Domain Models & Core Engine
- [lib/features/calendar/domain/calendar_event.dart](file:///d:/Codee/self-management/lib/features/calendar/domain/calendar_event.dart): Entitas domain `CalendarEvent` dengan serialisasi JSON dan metode `expandForRange()`.
- [lib/core/recurrence/recurrence_engine.dart](file:///d:/Codee/self-management/lib/core/recurrence/recurrence_engine.dart): Model `EventOccurrence` dan algoritma `expandEventOccurrences` untuk mengekspansi aturan `FREQ=DAILY|WEEKLY|MONTHLY|YEARLY` dengan interval, batas `COUNT`, `UNTIL`, penanganan akhir bulan, tahun kabisat, serta event lintas tengah malam.

### E. Integrasi Lintas Modul
1. **Inbox & Triase (Fase 5)**: [lib/features/inbox/presentation/inbox_screen.dart](file:///d:/Codee/self-management/lib/features/inbox/presentation/inbox_screen.dart) kini memiliki opsi ketiga: *"Jadikan Acara Kalender"*, yang langsung menjadwalkan item inbox menjadi event kalender dan menandai item inbox sebagai `processed`.
2. **Tempat Sampah (Fase 5)**: [lib/features/trash/presentation/trash_screen.dart](file:///d:/Codee/self-management/lib/features/trash/presentation/trash_screen.dart) dan `trash_controller.dart` kini memiliki tab ketiga *"Acara"* untuk melihat, memulihkan (`restoreEvent`), atau menghapus permanen (`permanentDeleteEvent`) acara yang terhapus.
3. **Beranda (Fase 1)**: [lib/features/home/presentation/home_screen.dart](file:///d:/Codee/self-management/lib/features/home/presentation/home_screen.dart) kini menampilkan ringkasan *"Jadwal Hari Ini"* yang menyajikan 3 agenda terdekat hari ini secara real-time.
4. **Navigasi Global**: [lib/features/modules_grid_screen.dart](file:///d:/Codee/self-management/lib/features/modules_grid_screen.dart) menghubungkan tombol 'Kalender' langsung ke `/calendar`.

---

## 3. Perubahan Database & Keamanan

### Berkas Migrasi: `supabase/migrations/0007_events.sql`
1. **Tabel `public.events`**:
   - `id uuid PRIMARY KEY DEFAULT gen_random_uuid()`
   - `user_id uuid NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE`
   - `title text NOT NULL`
   - `description text`
   - `starts_at timestamptz NOT NULL`
   - `ends_at timestamptz NOT NULL`
   - `all_day boolean NOT NULL DEFAULT false`
   - `location text`
   - `color text DEFAULT '#1976D2'`
   - `recurrence_rule text`
   - `linked_task_id uuid`
   - `is_time_block boolean NOT NULL DEFAULT false`
   - `external_id text`
   - `archived_at timestamptz`
   - `deleted_at timestamptz`
   - `created_at timestamptz NOT NULL DEFAULT now()`
   - `updated_at timestamptz NOT NULL DEFAULT now()`
2. **Foreign Key Komposit**:
   - `CONSTRAINT uq_events_user UNIQUE (id, user_id)`
   - `CONSTRAINT fk_events_linked_task FOREIGN KEY (linked_task_id, user_id) REFERENCES public.tasks(id, user_id) ON DELETE SET NULL`
   *(Mencegah manipulasi penautan blok waktu ke tugas milik akun lain)*.
3. **Indeks Performa**:
   - `idx_events_user_starts_at` pada `(user_id, starts_at)`
   - `idx_events_user_ends_at` pada `(user_id, ends_at)`
   - `idx_events_user_deleted_at` pada `(user_id, deleted_at)`
   - `idx_events_user_linked_task` pada `(user_id, linked_task_id)`
4. **Keamanan RLS & Grants**:
   - RLS diaktifkan (`ALTER TABLE public.events ENABLE ROW LEVEL SECURITY`).
   - 4 Kebijakan RLS terpisah untuk `SELECT`, `INSERT`, `UPDATE`, dan `DELETE` berbasis `auth.uid() = user_id`.
   - Hak akses eksplisit: `GRANT SELECT, INSERT, UPDATE, DELETE ON public.events TO authenticated; REVOKE ALL FROM anon;`.
   - Trigger otomatis `handle_updated_at()` saat `UPDATE`.

---

## 4. Keputusan Teknis & Asumsi
1. **Client-Side Recurrence Expansion**:
   Event berulang tidak disimpan sebagai baris individual di database untuk mencegah ledakan ukuran data (*table bloat*). Sebagai gantinya, baris master event menyimpan string `recurrence_rule`, dan klien melakukan ekspansi dinamis pada rentang tanggal yang sedang aktif dilihat pengguna menggunakan `RecurrenceEngine`.
2. **Penyatuan Jadwal & Tugas**:
   Pengguna tidak perlu membuka tab berbeda untuk mengecek apa yang harus dikerjakan hari ini. Tugas ber-tenggat waktu (`due_date`) langsung digabungkan ke dalam kalender dengan warna pembeda khusus dan tag `[Tugas]`.
3. **Time Blocking Terintegrasi**:
   Blok waktu didefinisikan sebagai event dengan `is_time_block = true` dan opsional menautkan ke `linked_task_id`. Saat tugas diselesaikan dari modul Tugas, blok waktu tetap ada sebagai catatan riwayat waktu kerja pengguna.

---

## 5. Cakupan Pengujian

### A. Pengujian pgTAP Database (`supabase/tests/05_fase6_events_test.sql`)
- 10 asersi pengujian meliputi:
  - Keberadaan tabel `events` dan kolom-kolom utamanya (`is_time_block`, `linked_task_id`, `recurrence_rule`).
  - Verifikasi RLS aktif.
  - Simulasi User A membuat event kalender.
  - Isolasi RLS: User B dilarang melihat atau mengubah event User A.
  - Penolakan relasi Foreign Key komposit: User B dilarang menautkan blok waktu ke tugas milik User A (Error Postgres `23503`).

### B. Unit Tests Dart (`test/unit/calendar_test.dart`)
- **Ekspansi event tunggal**: Memastikan event tanpa RRULE diekspansi tepat 1 kali jika berada dalam rentang.
- **Ekspansi harian (`DAILY`)**: Memvalidasi 7 kejadian berturut-turut pada rentang 7 hari.
- **Ekspansi mingguan (`WEEKLY`)**: Memvalidasi kejadian setiap hari Senin dalam satu bulan kalender.
- **Ekspansi bulanan (`MONTHLY`)**: Memvalidasi penyesuaian tanggal akhir bulan (contoh: 31 Jan -> 28 Feb non-kabisat).
- **Ekspansi tahunan (`YEARLY`)**: Memvalidasi penyesuaian kabisat (29 Feb 2024 -> 28 Feb 2025).
- **Event seharian (All-Day) & Lintas Tengah Malam**: Memvalidasi deteksi `isCrossMidnight` dan perhitungan durasi.
- **Serialisasi JSON bolak-balik**: Memastikan konsistensi `CalendarEvent.toJson()` dan `fromJson()`.

---

## 6. Status Verifikasi Jujur & Tindak Lanjut Manual

| Kategori Pengujian | Status | Bukti / Catatan |
| :--- | :---: | :--- |
| **Dart Analyzer (`dart analyze`)** | ✅ **Lulus (0 Issues)** | Tidak ada error, warning, maupun info linter |
| **Unit Testing Dart** | ✅ **Lulus (100%)** | Seluruh test di `test/unit/calendar_test.dart` lulus bersih |
| **Eksekusi SQL di Supabase** | ⚠️ **Menunggu Tindak Lanjut** | Skrip [supabase/migrations/0007_events.sql](file:///d:/Codee/self-management/supabase/migrations/0007_events.sql) harus dieksekusi di SQL Editor dashboard Supabase |
| **Uji pgTAP Database CLI** | ⚠️ **Menunggu Tindak Lanjut** | Jalankan `supabase test db` di mesin dengan Supabase CLI lokal terpasang |
| **Uji Coba Perangkat Fisik** | ⚠️ **Menunggu Tindak Lanjut** | Uji langsung navigasi tampilan Bulan/Minggu/Hari serta pembuatan Time Block di HP Android fisik |
