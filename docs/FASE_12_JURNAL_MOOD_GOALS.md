# Dokumen Fase 12: Jurnal, Mood, Refleksi, & Sasaran (OKRs)

Dokumen ini mencatat arsitektur, implementasi teknis, dan verifikasi untuk **Fase 12** sistem **SF-25**, mengacu langsung pada spesifikasi `personal-os-master-blueprint-v2.json` (fitur `F-JRN-01`, `F-JRN-02`, `F-JRN-03`, `F-MOOD-01`, `F-REV-01`, `F-REV-02`, `F-GOAL-01`, dan `F-GOAL-02`).

---

## 1. Ringkasan Fase & Tujuan
Fase 12 melengkapi sistem dengan modul kesadaran diri (*mindfulness*), pelacak emosi, dan kompas pencapaian hidup:
1. **Jurnal & Refleksi Harian**:
   - Pencatatan jurnal dengan pemilih tanggal dinamis dan batasan satu entri unik per hari (`user_id, entry_date`).
   - Pilihan *Prompt* refleksi harian (misal: "Apa 3 hal yang paling disyukuri?", "Pencapaian kecil", "Evaluasi energi").
   - Fitur Kilas Balik (*On This Day*): Menampilkan tulisan jurnal dari tepat 1 tahun lalu pada tanggal yang sama.
2. **Pelacak Mood Harian (*Mood Tracker*)**:
   - Skala mood 1–5 dengan visual emoji (`1: 😢 Sangat Buruk`, `2: 🙁 Kurang Baik`, `3: 😐 Biasa Saja`, `4: 🙂 Baik`, `5: 😄 Luar Biasa`).
   - Tag emosi fleksibel (`Senang`, `Bersyukur`, `Produktif`, `Lelah`, `Cemas`, `Stres`, dll).
   - Kolom catatan deskriptif untuk merekam pemicu emosi.
3. **Sasaran Jangka Panjang & Key Results (Goals & OKRs)**:
   - Manajemen tujuan hidup (*Goals*) dengan target tanggal pencapaian.
   - Hasil kunci terukur (*Key Results*) dengan target angka, nilai terkini, dan satuan unit (misal %, bab, buku, km).
   - Perhitungan otomatis rata-rata persentase penyelesaian (*overall progress*) di level sasaran induk.
4. **Review Berkala (*Periodic Reviews*)**:
   - Skema evaluasi terstruktur untuk periode harian (*daily*), mingguan (*weekly*), dan bulanan (*monthly*) dengan jawaban format `jsonb`.

---

## 2. Daftar Fitur & Komponen yang Dikerjakan

### A. Rute & Layar (Navigation)
- `/journal`: [lib/features/reflection/presentation/journal_screen.dart](file:///d:/Codee/self-management/lib/features/reflection/presentation/journal_screen.dart) — Editor jurnal harian, kartu kilas balik 1 tahun lalu, chip pilihan prompt refleksi, dan riwayat jurnal.
- `/mood`: [lib/features/reflection/presentation/mood_screen.dart](file:///d:/Codee/self-management/lib/features/reflection/presentation/mood_screen.dart) — Layar input mood harian, selector emoji interaktif, filter tag faktor perasaan, dan riwayat mood.
- `/goals`: [lib/features/reflection/presentation/goals_screen.dart](file:///d:/Codee/self-management/lib/features/reflection/presentation/goals_screen.dart) — Dashboard sasaran jangka panjang, visual kartu progress OKR, dialog tambah Key Result, dan pembaruan progres nilai.
- Grid Modul: [lib/features/modules_grid_screen.dart](file:///d:/Codee/self-management/lib/features/modules_grid_screen.dart) — Menu 'Jurnal & Refleksi' aktif menuju `/journal`.

### B. Controller & State Management (Riverpod)
- [lib/features/reflection/presentation/reflection_controller.dart](file:///d:/Codee/self-management/lib/features/reflection/presentation/reflection_controller.dart):
  - `journalEntriesProvider` & `onThisDayJournalProvider`: Mengambil riwayat jurnal dan kilas balik 1 tahun lalu.
  - `moodLogsProvider`: Mengambil catatan mood harian.
  - `reviewsProvider`: Mengambil catatan review berkala.
  - `computedGoalsProvider`: Menggabungkan data sasaran dengan Key Results untuk kalkulasi rata-rata progres.
  - `reflectionActionsProvider`: Notifier untuk operasi CRUD jurnal, mood, review, goal, dan key results.

### C. Repository Layer
- [lib/features/reflection/data/reflection_repository.dart](file:///d:/Codee/self-management/lib/features/reflection/data/reflection_repository.dart): Mengelola kueri database Supabase ke tabel `journal_entries`, `mood_logs`, `reviews`, `goals`, dan `key_results`.

### D. Domain Models
- [lib/features/reflection/domain/journal_entry.dart](file:///d:/Codee/self-management/lib/features/reflection/domain/journal_entry.dart)
- [lib/features/reflection/domain/mood_log.dart](file:///d:/Codee/self-management/lib/features/reflection/domain/mood_log.dart)
- [lib/features/reflection/domain/periodic_review.dart](file:///d:/Codee/self-management/lib/features/reflection/domain/periodic_review.dart)
- [lib/features/reflection/domain/goal.dart](file:///d:/Codee/self-management/lib/features/reflection/domain/goal.dart)

---

## 3. Perubahan Database & Keamanan

### Berkas Migrasi: `supabase/migrations/0013_reflection_goals.sql`
1. **Tabel `public.journal_entries`**:
   - `id uuid PRIMARY KEY DEFAULT gen_random_uuid()`
   - `user_id uuid NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE`
   - `entry_date date NOT NULL`
   - `prompt text`
   - `content text NOT NULL`
   - `deleted_at timestamptz`
   - `created_at timestamptz NOT NULL DEFAULT now()`
   - `updated_at timestamptz NOT NULL DEFAULT now()`
   - `CONSTRAINT uq_journal_entries_user UNIQUE (id, user_id)`
   - `CONSTRAINT uq_journal_entries_date UNIQUE (user_id, entry_date)`
2. **Tabel `public.mood_logs`**:
   - `id uuid PRIMARY KEY DEFAULT gen_random_uuid()`
   - `user_id uuid NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE`
   - `log_date date NOT NULL`
   - `score smallint NOT NULL CHECK (score BETWEEN 1 AND 5)`
   - `tags jsonb NOT NULL DEFAULT '[]'::jsonb`
   - `note text`
   - `deleted_at timestamptz`
   - `created_at timestamptz NOT NULL DEFAULT now()`
   - `updated_at timestamptz NOT NULL DEFAULT now()`
   - `CONSTRAINT uq_mood_logs_user UNIQUE (id, user_id)`
   - `CONSTRAINT uq_mood_logs_date UNIQUE (user_id, log_date)`
3. **Tabel `public.reviews`**:
   - `id uuid PRIMARY KEY DEFAULT gen_random_uuid()`
   - `user_id uuid NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE`
   - `period text NOT NULL CHECK (period IN ('daily', 'weekly', 'monthly'))`
   - `period_start date NOT NULL`
   - `answers jsonb NOT NULL DEFAULT '{}'::jsonb`
   - `deleted_at timestamptz`
   - `created_at timestamptz NOT NULL DEFAULT now()`
   - `updated_at timestamptz NOT NULL DEFAULT now()`
   - `CONSTRAINT uq_reviews_user UNIQUE (id, user_id)`
   - `CONSTRAINT uq_reviews_user_period UNIQUE (user_id, period, period_start)`
4. **Tabel `public.goals`**:
   - `id uuid PRIMARY KEY DEFAULT gen_random_uuid()`
   - `user_id uuid NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE`
   - `title text NOT NULL`
   - `description text`
   - `target_date date`
   - `status text NOT NULL DEFAULT 'active' CHECK (status IN ('active', 'completed', 'paused', 'cancelled'))`
   - `archived_at timestamptz`
   - `deleted_at timestamptz`
   - `created_at timestamptz NOT NULL DEFAULT now()`
   - `updated_at timestamptz NOT NULL DEFAULT now()`
   - `CONSTRAINT uq_goals_user UNIQUE (id, user_id)`
5. **Tabel `public.key_results`**:
   - `id uuid PRIMARY KEY DEFAULT gen_random_uuid()`
   - `user_id uuid NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE`
   - `goal_id uuid NOT NULL`
   - `title text NOT NULL`
   - `metric_type text NOT NULL DEFAULT 'manual' CHECK (metric_type IN ('manual', 'tasks', 'habit'))`
   - `target_value numeric NOT NULL CHECK (target_value > 0)`
   - `current_value numeric NOT NULL DEFAULT 0 CHECK (current_value >= 0)`
   - `unit text NOT NULL DEFAULT '%'`
   - `linked_id uuid`
   - `deleted_at timestamptz`
   - `created_at timestamptz NOT NULL DEFAULT now()`
   - `updated_at timestamptz NOT NULL DEFAULT now()`
   - `CONSTRAINT uq_key_results_user UNIQUE (id, user_id)`
   - `CONSTRAINT fk_key_results_goal FOREIGN KEY (goal_id, user_id) REFERENCES public.goals(id, user_id) ON DELETE CASCADE`
6. **Keamanan RLS & Grants**:
   - Seluruh 5 tabel mengaktifkan RLS 100% dengan kebijakan `user_id = auth.uid()` untuk `SELECT`, `INSERT`, `UPDATE`, `DELETE`.
   - `REVOKE ALL ON ALL TABLES IN SCHEMA public FROM anon` dan `GRANT SELECT, INSERT, UPDATE, DELETE TO authenticated`.
   - Trigger `handle_updated_at` terpasang di semua tabel.

### Pengujian pgTAP: `supabase/tests/11_fase12_reflection_goals_test.sql`
- Memuat 11 assertion pengujian struktur tabel, RLS isolasi dua akun, dan Foreign Key komposit.

---

## 4. Status Verifikasi

| Komponen Uji | Metode | Status | Catatan |
|---|---|---|---|
| Domain Models (`JournalEntry`, `MoodLog`, `PeriodicReview`, `Goal`, `KeyResult`) | `test/unit/reflection_goals_test.dart` | **LULUS** | 4 assertion serialisasi, emosi, dan kalkulasi progres |
| Suite Test Unit Penuh | `dart run test/all_tests.dart` | **LULUS** | 53/53 tests lulus |
| Analisis Statis Kode | `dart analyze lib test` | **LULUS** | 0 issues found |
| Skema Database & RLS | `supabase/migrations/0013_reflection_goals.sql` | **Siap Push** | Menunggu eksekusi migration via `supabase db push` atau SQL Editor di project Supabase |
| Pengujian Database pgTAP | `supabase/tests/11_fase12_reflection_goals_test.sql` | **Siap Test** | Menunggu eksekusi via `supabase test db` |
