# Dokumen Fase 10: Keuangan Lanjutan (Anggaran, Target Tabungan, & Utang Piutang)

Dokumen ini mencatat arsitektur, implementasi teknis, dan verifikasi untuk **Fase 10** sistem **SF-25**, mengacu langsung pada spesifikasi `personal-os-master-blueprint-v2.json` (fitur `F-BUD-01`, `F-BUD-02`, `F-SAV-01`, `F-SAV-02`, `F-DEBT-01`, dan `F-DEBT-02`).

---

## 1. Ringkasan Fase & Tujuan
Fase 10 melengkapi modul keuangan inti dengan manajemen perencanaan, tabungan, dan liabilitas:
1. **Anggaran Bulanan per Kategori (Budgets)**: Pengguna dapat menetapkan batas pengeluaran bulanan per kategori dengan tanggal logis bulan `yyyy-MM-01`.
2. **Sistem Peringatan Ambang Batas Anggaran**:
   - Status **Aman (`safe`)**: Pengeluaran < 80% dari batas anggaran (indikator warna hijau).
   - Status **Waspada (`warning`)**: Pengeluaran mencapai 80%–99% dari batas anggaran (indikator warna oranye/kuning).
   - Status **Terlampaui (`exceeded`)**: Pengeluaran >= 100% dari batas anggaran (indikator warna merah dengan hitungan nominal selisih berlebih).
3. **Target Tabungan Berkelanjutan (Savings Goals & Contributions)**:
   - Pembuatan target tabungan terencana (misal dana darurat, liburan, gadget) dengan nominal target dan tenggat waktu opsional.
   - Pencatatan setoran tabungan berkala (*contributions*) yang secara dinamis menghitung persentase progres dan mendeteksi pencapaian 100% (*completed*).
4. **Manajemen Utang & Piutang Komprehensif (Debts & Debt Payments)**:
   - Pencatatan dua arah: **Utang Saya** (*owed_by_me* - pinjaman yang harus dibayar) dan **Piutang Saya** (*owed_to_me* - uang yang dipinjam orang lain).
   - Riwayat cicilan pelunasan (*debt payments*) dan aksi cepat satu ketukan untuk menandai lunas penuh (*settled*).
5. **Presisi Nominal Rupiah**: Seluruh nominal di kelima tabel menggunakan `bigint` rupiah penuh (bukan float) guna menjamin akurasi finansial.

---

## 2. Daftar Fitur & Komponen yang Dikerjakan

### A. Rute & Layar (Navigation)
- `/finance/budgets`: [lib/features/finance/presentation/budget_screen.dart](file:///d:/Codee/self-management/lib/features/finance/presentation/budget_screen.dart) — Layar anggaran bulanan dengan navigasi antarbulan, visual linear progress indicator, status peringatan, dan dialog pembuatan/penyuntingan batas kategori.
- `/finance/savings`: [lib/features/finance/presentation/savings_screen.dart](file:///d:/Codee/self-management/lib/features/finance/presentation/savings_screen.dart) — Layar target tabungan, kartu progres persentase, dialog setoran berkala, dan penanda status target tercapai.
- `/finance/debts`: [lib/features/finance/presentation/debt_screen.dart](file:///d:/Codee/self-management/lib/features/finance/presentation/debt_screen.dart) — Layar utang & piutang dengan TabBar terpisah ("Utang Saya" vs "Piutang Saya"), kartu ringkasan total sisa di bagian atas, dialog pembayaran cicilan, dan konfirmasi pelunasan.
- Integrasi Dashboard: [lib/features/finance/presentation/finance_screen.dart](file:///d:/Codee/self-management/lib/features/finance/presentation/finance_screen.dart) — Tombol pintas navigasi cepat (*Quick Action Chips*) langsung ke Anggaran, Tabungan, dan Utang Piutang.

### B. Controller & State Management (Riverpod)
- [lib/features/finance/presentation/budget_controller.dart](file:///d:/Codee/self-management/lib/features/finance/presentation/budget_controller.dart):
  - `selectedBudgetMonthProvider`: Menyimpan bulan aktif yang sedang ditinjau pengguna.
  - `rawBudgetsProvider`: Mengambil batas anggaran kategori dari tabel `budgets`.
  - `computedBudgetsProvider`: Menghitung total belanja per kategori di bulan tersebut secara reaktif dari `allTransactionsProvider`, menghitung sisa atau kelebihan dana, serta mengevaluasi status peringatan (`safe`, `warning`, `exceeded`).
  - `budgetActionsProvider`: Notifier untuk operasi upsert dan soft delete anggaran.
- [lib/features/finance/presentation/savings_controller.dart](file:///d:/Codee/self-management/lib/features/finance/presentation/savings_controller.dart):
  - `rawSavingsGoalsProvider` & `rawSavingsContributionsProvider`: Mengambil data target dan riwayat setoran tabungan.
  - `computedSavingsGoalsProvider`: Menghitung jumlah saldo terkumpul dan rasio ketercapaian secara reaktif.
  - `savingsActionsProvider`: Notifier CRUD target dan pencatatan setoran tabungan.
- [lib/features/finance/presentation/debt_controller.dart](file:///d:/Codee/self-management/lib/features/finance/presentation/debt_controller.dart):
  - `rawDebtsProvider` & `rawDebtPaymentsProvider`: Mengambil data utang piutang dan cicilan.
  - `computedDebtsProvider`: Mengagregasi sisa pokok utang dan status lunas secara reaktif.
  - `debtActionsProvider`: Notifier CRUD utang, pencatatan pembayaran cicilan, dan pelunasan.

### C. Repository Layer
- [lib/features/finance/data/finance_repository.dart](file:///d:/Codee/self-management/lib/features/finance/data/finance_repository.dart): Menangani seluruh kueri database Supabase untuk tabel `public.budgets`, `public.savings_goals`, `public.savings_contributions`, `public.debts`, dan `public.debt_payments`, termasuk filter `deleted_at IS NULL` dan optimistic concurrency check.

### D. Domain Models
- [lib/features/finance/domain/budget.dart](file:///d:/Codee/self-management/lib/features/finance/domain/budget.dart): Entitas anggaran bulanan dengan getter `progress`, `remainingAmount`, `overAmount`, `isWarning`, dan `isExceeded`.
- [lib/features/finance/domain/savings_goal.dart](file:///d:/Codee/self-management/lib/features/finance/domain/savings_goal.dart): Entitas target tabungan dan setoran berkala (`SavingsContribution`) dengan getter `isCompleted` dan `remainingAmount`.
- [lib/features/finance/domain/debt.dart](file:///d:/Codee/self-management/lib/features/finance/domain/debt.dart): Entitas utang/piutang dan pembayaran cicilan (`DebtPayment`) dengan pembedaan arah (`owed_by_me` / `owed_to_me`), kalkulasi sisa pokok, dan status pelunasan `isSettled`.

---

## 3. Perubahan Database & Keamanan

### Berkas Migrasi: `supabase/migrations/0011_finance_advanced.sql`
1. **Tabel `public.budgets`**:
   - `id uuid PRIMARY KEY DEFAULT gen_random_uuid()`
   - `user_id uuid NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE`
   - `category_id uuid NOT NULL`
   - `month date NOT NULL` (format `yyyy-MM-01`)
   - `limit_amount bigint NOT NULL CHECK (limit_amount > 0)`
   - `deleted_at timestamptz`
   - `created_at timestamptz NOT NULL DEFAULT now()`
   - `updated_at timestamptz NOT NULL DEFAULT now()`
   - `CONSTRAINT uq_budgets_user UNIQUE (id, user_id)`
   - `CONSTRAINT uq_budgets_user_cat_month UNIQUE (user_id, category_id, month)`
   - `CONSTRAINT fk_budgets_category FOREIGN KEY (category_id, user_id) REFERENCES public.fin_categories(id, user_id) ON DELETE CASCADE`
2. **Tabel `public.savings_goals`**:
   - `id uuid PRIMARY KEY DEFAULT gen_random_uuid()`
   - `user_id uuid NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE`
   - `name text NOT NULL`
   - `target_amount bigint NOT NULL CHECK (target_amount > 0)`
   - `target_date date`
   - `wallet_id uuid`
   - `color text NOT NULL DEFAULT '#00897B'`
   - `icon text NOT NULL DEFAULT 'savings'`
   - `archived_at timestamptz`
   - `deleted_at timestamptz`
   - `created_at timestamptz NOT NULL DEFAULT now()`
   - `updated_at timestamptz NOT NULL DEFAULT now()`
   - `CONSTRAINT uq_savings_goals_user UNIQUE (id, user_id)`
   - `CONSTRAINT fk_savings_goals_wallet FOREIGN KEY (wallet_id, user_id) REFERENCES public.wallets(id, user_id) ON DELETE SET NULL`
3. **Tabel `public.savings_contributions`**:
   - `id uuid PRIMARY KEY DEFAULT gen_random_uuid()`
   - `user_id uuid NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE`
   - `goal_id uuid NOT NULL`
   - `amount bigint NOT NULL CHECK (amount > 0)`
   - `contributed_at timestamptz NOT NULL DEFAULT now()`
   - `transaction_id uuid`
   - `note text`
   - `deleted_at timestamptz`
   - `created_at timestamptz NOT NULL DEFAULT now()`
   - `updated_at timestamptz NOT NULL DEFAULT now()`
   - `CONSTRAINT uq_savings_contributions_user UNIQUE (id, user_id)`
   - `CONSTRAINT fk_savings_contributions_goal FOREIGN KEY (goal_id, user_id) REFERENCES public.savings_goals(id, user_id) ON DELETE CASCADE`
   - `CONSTRAINT fk_savings_contributions_tx FOREIGN KEY (transaction_id, user_id) REFERENCES public.transactions(id, user_id) ON DELETE SET NULL`
4. **Tabel `public.debts`**:
   - `id uuid PRIMARY KEY DEFAULT gen_random_uuid()`
   - `user_id uuid NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE`
   - `person_name text NOT NULL`
   - `person_id uuid`
   - `direction text NOT NULL CHECK (direction IN ('owed_by_me', 'owed_to_me'))`
   - `principal bigint NOT NULL CHECK (principal > 0)`
   - `due_date date`
   - `note text`
   - `settled_at timestamptz`
   - `deleted_at timestamptz`
   - `created_at timestamptz NOT NULL DEFAULT now()`
   - `updated_at timestamptz NOT NULL DEFAULT now()`
   - `CONSTRAINT uq_debts_user UNIQUE (id, user_id)`
5. **Tabel `public.debt_payments`**:
   - `id uuid PRIMARY KEY DEFAULT gen_random_uuid()`
   - `user_id uuid NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE`
   - `debt_id uuid NOT NULL`
   - `amount bigint NOT NULL CHECK (amount > 0)`
   - `paid_at timestamptz NOT NULL DEFAULT now()`
   - `transaction_id uuid`
   - `note text`
   - `deleted_at timestamptz`
   - `created_at timestamptz NOT NULL DEFAULT now()`
   - `updated_at timestamptz NOT NULL DEFAULT now()`
   - `CONSTRAINT uq_debt_payments_user UNIQUE (id, user_id)`
   - `CONSTRAINT fk_debt_payments_debt FOREIGN KEY (debt_id, user_id) REFERENCES public.debts(id, user_id) ON DELETE CASCADE`
   - `CONSTRAINT fk_debt_payments_tx FOREIGN KEY (transaction_id, user_id) REFERENCES public.transactions(id, user_id) ON DELETE SET NULL`
6. **Keamanan RLS & Grants**:
   - Seluruh tabel mengaktifkan RLS 100% dengan policy `user_id = auth.uid()` untuk `SELECT`, `INSERT`, `UPDATE`, `DELETE`.
   - `REVOKE ALL ON ALL TABLES IN SCHEMA public FROM anon` dan `GRANT SELECT, INSERT, UPDATE, DELETE TO authenticated`.
   - Otomatisasi pemicu pembaruan `updated_at` melalui trigger `handle_updated_at`.

### Pengujian pgTAP: `supabase/tests/09_fase10_finance_advanced_test.sql`
- Memuat 13 assertion pengujian:
  - Struktur tabel `budgets`, `savings_goals`, `savings_contributions`, `debts`, dan `debt_payments`.
  - Isolasi RLS data finansial antarpengguna.
  - Foreign Key komposit `(id, user_id)` yang mencegah penambahan pembayaran ke utang milik pengguna lain.

---

## 4. Status Verifikasi

| Komponen Uji | Metode | Status | Catatan |
|---|---|---|---|
| Domain Models (`Budget`, `SavingsGoal`, `Debt`, `DebtPayment`) | `test/unit/finance_advanced_test.dart` | **LULUS** | Perhitungan ambang batas, target selesai, dan pelunasan |
| Suite Test Unit Penuh | `dart run test/all_tests.dart` | **LULUS** | 45/45 tests lulus |
| Analisis Statis Kode | `dart analyze lib test` | **LULUS** | 0 issues found |
| Skema Database & RLS | `supabase/migrations/0011_finance_advanced.sql` | **Siap Push** | Menunggu eksekusi migration via `supabase db push` atau SQL Editor di project Supabase |
| Pengujian Database pgTAP | `supabase/tests/09_fase10_finance_advanced_test.sql` | **Siap Test** | Menunggu eksekusi via `supabase test db` |
