# Dokumen Fase 9: Money Tracker Inti (Dompet, Kategori, & Transaksi)

Dokumen ini mencatat arsitektur, implementasi teknis, dan verifikasi untuk **Fase 9** sistem **SF-25**, mengacu langsung pada spesifikasi `personal-os-master-blueprint-v2.json` (fitur `F-FIN-01`, `F-FIN-02`, dan `F-FIN-03`).

---

## 1. Ringkasan Fase & Tujuan
Fase 9 menyediakan pondasi pelacak keuangan pribadi (Money Tracker) yang aman dan presisi:
1. **Multi-Dompet (Wallets)**: Manajemen rekening bank, e-wallet, dompet tunai (cash), kartu kredit, atau investasi dengan saldo awal dan saldo dinamis terkini.
2. **Kategori Finansial Berjenjang (Fin Categories)**: Kategori pemasukan (*income*) dan pengeluaran (*expense*) dengan ikon dan warna kustom, serta dukungan subkategori hierarkis (`parent_id`).
3. **Pencatatan Transaksi Komprehensif (Transactions)**: Pemasukan (*income*), pengeluaran (*expense*), dan transfer antardompet (*transfer*) dengan validasi ketat bahwa dompet asal dan tujuan tidak boleh sama.
4. **Presisi Nominal Uang**: Seluruh nilai uang disimpan dalam tipe data `bigint` rupiah penuh (bukan float) untuk mencegah masalah pembulatan desimal, dengan utilitas format mata uang Rupiah [lib/core/utils/currency_utils.dart](file:///d:/Codee/self-management/lib/core/utils/currency_utils.dart).
5. **Kalkulasi Saldo Dinamis**: Saldo dompet dihitung secara reaktif di sisi aplikasi: `initial_balance + sum(income) + sum(transfer_in) - sum(expense) - sum(transfer_out)`.

---

## 2. Daftar Fitur & Komponen yang Dikerjakan

### A. Rute & Layar (Navigation)
- `/finance`: [lib/features/finance/presentation/finance_screen.dart](file:///d:/Codee/self-management/lib/features/finance/presentation/finance_screen.dart) — Dashboard finansial dengan ringkasan total saldo, arus kas bulanan (pemasukan, pengeluaran, saldo bersih), daftar dompet horizontal, dan riwayat transaksi terbaru beserta aksi hapus.
- `/finance/wallet/edit`: [lib/features/finance/presentation/wallet_editor_screen.dart](file:///d:/Codee/self-management/lib/features/finance/presentation/wallet_editor_screen.dart) — Formulir pembuatan & penyuntingan dompet, pemilihan jenis dompet (cash, bank, e-wallet, kartu kredit, investasi), saldo awal, dan warna.
- `/finance/transaction/edit`: [lib/features/finance/presentation/transaction_editor_screen.dart](file:///d:/Codee/self-management/lib/features/finance/presentation/transaction_editor_screen.dart) — Formulir pencatatan transaksi dengan toggle tipe (Pengeluaran, Pemasukan, Transfer), pemilihan dompet sumber & tujuan, kategori, nominal dengan kalkulator/input angka, stempel waktu, dan catatan.

### B. Controller & State Management (Riverpod)
- [lib/features/finance/presentation/finance_controller.dart](file:///d:/Codee/self-management/lib/features/finance/presentation/finance_controller.dart):
  - `rawWalletsProvider`: Mengambil daftar dompet aktif dari Supabase.
  - `allTransactionsProvider`: Mengambil seluruh riwayat transaksi pengguna yang belum dihapus.
  - `finCategoriesProvider`: Mengambil kategori pengeluaran dan pemasukan.
  - `computedWalletsProvider`: Menghitung saldo berjalan setiap dompet secara reaktif dari riwayat mutasi transaksi.
  - `financialSummaryProvider`: Menghitung total kekayaan bersih, total pemasukan bulan berjalan, dan total pengeluaran bulan berjalan.
  - `financeActionsProvider`: Notifier untuk operasi CRUD dompet dan transaksi dengan penanganan error ramah Bahasa Indonesia.

### C. Repository Layer
- [lib/features/finance/data/finance_repository.dart](file:///d:/Codee/self-management/lib/features/finance/data/finance_repository.dart): Menangani seluruh kueri database Supabase untuk tabel `public.wallets`, `public.fin_categories`, dan `public.transactions`, termasuk filter `deleted_at IS NULL` dan optimistic concurrency check.

### D. Domain Models
- [lib/features/finance/domain/wallet.dart](file:///d:/Codee/self-management/lib/features/finance/domain/wallet.dart): Entitas dompet dengan tipe saldo `BigInt`.
- [lib/features/finance/domain/fin_category.dart](file:///d:/Codee/self-management/lib/features/finance/domain/fin_category.dart): Entitas kategori transaksi dengan pemisahan `kind` (income / expense).
- [lib/features/finance/domain/transaction.dart](file:///d:/Codee/self-management/lib/features/finance/domain/transaction.dart): Entitas transaksi mutasi uang dengan validasi transfer antardompet.
- [lib/features/finance/domain/financial_summary.dart](file:///d:/Codee/self-management/lib/features/finance/domain/financial_summary.dart): DTO kalkulasi ringkasan keuangan dan arus kas bersih.

---

## 3. Perubahan Database & Keamanan

### Berkas Migrasi: `supabase/migrations/0010_finance_core.sql`
1. **Tabel `public.wallets`**:
   - `id uuid PRIMARY KEY DEFAULT gen_random_uuid()`
   - `user_id uuid NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE`
   - `name text NOT NULL`
   - `type text NOT NULL DEFAULT 'cash' CHECK (type IN ('cash', 'bank', 'ewallet', 'credit_card', 'investment', 'other'))`
   - `initial_balance bigint NOT NULL DEFAULT 0`
   - `color text NOT NULL DEFAULT '#00796B'`
   - `icon text NOT NULL DEFAULT 'account_balance_wallet'`
   - `archived_at timestamptz`
   - `deleted_at timestamptz`
   - `created_at timestamptz NOT NULL DEFAULT now()`
   - `updated_at timestamptz NOT NULL DEFAULT now()`
   - `CONSTRAINT uq_wallets_user UNIQUE (id, user_id)`
2. **Tabel `public.fin_categories`**:
   - `id uuid PRIMARY KEY DEFAULT gen_random_uuid()`
   - `user_id uuid NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE`
   - `parent_id uuid`
   - `name text NOT NULL`
   - `kind text NOT NULL CHECK (kind IN ('income', 'expense'))`
   - `icon text NOT NULL DEFAULT 'category'`
   - `color text NOT NULL DEFAULT '#E53935'`
   - `deleted_at timestamptz`
   - `created_at timestamptz NOT NULL DEFAULT now()`
   - `updated_at timestamptz NOT NULL DEFAULT now()`
   - `CONSTRAINT uq_fin_categories_user UNIQUE (id, user_id)`
   - `CONSTRAINT fk_fin_categories_parent FOREIGN KEY (parent_id, user_id) REFERENCES public.fin_categories(id, user_id) ON DELETE SET NULL`
3. **Tabel `public.transactions`**:
   - `id uuid PRIMARY KEY DEFAULT gen_random_uuid()`
   - `user_id uuid NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE`
   - `wallet_id uuid NOT NULL`
   - `to_wallet_id uuid`
   - `category_id uuid`
   - `type text NOT NULL CHECK (type IN ('income', 'expense', 'transfer'))`
   - `amount bigint NOT NULL CHECK (amount > 0)`
   - `occurred_at timestamptz NOT NULL DEFAULT now()`
   - `note text`
   - `deleted_at timestamptz`
   - `created_at timestamptz NOT NULL DEFAULT now()`
   - `updated_at timestamptz NOT NULL DEFAULT now()`
   - `CONSTRAINT uq_transactions_user UNIQUE (id, user_id)`
   - `CONSTRAINT fk_transactions_wallet FOREIGN KEY (wallet_id, user_id) REFERENCES public.wallets(id, user_id) ON DELETE RESTRICT`
   - `CONSTRAINT fk_transactions_to_wallet FOREIGN KEY (to_wallet_id, user_id) REFERENCES public.wallets(id, user_id) ON DELETE RESTRICT`
   - `CONSTRAINT fk_transactions_category FOREIGN KEY (category_id, user_id) REFERENCES public.fin_categories(id, user_id) ON DELETE SET NULL`
   - `CONSTRAINT chk_transfer_wallet CHECK ((type = 'transfer' AND to_wallet_id IS NOT NULL AND to_wallet_id <> wallet_id) OR (type <> 'transfer' AND to_wallet_id IS NULL))`
4. **Keamanan RLS & Grants**:
   - Seluruh tabel (`wallets`, `fin_categories`, `transactions`) mengaktifkan RLS 100% dengan policy `user_id = auth.uid()` untuk `SELECT`, `INSERT`, `UPDATE`, `DELETE`.
   - `REVOKE ALL ON ALL TABLES IN SCHEMA public FROM anon` dan `GRANT SELECT, INSERT, UPDATE, DELETE TO authenticated`.
   - Otomatisasi pemicu pembaruan `updated_at` melalui trigger `handle_updated_at`.

### Pengujian pgTAP: `supabase/tests/08_fase9_finance_core_test.sql`
- Memuat 12 assertion pengujian:
  - Struktur tabel `wallets`, `fin_categories`, dan `transactions`.
  - Isolasi RLS data finansial antarpengguna.
  - Foreign Key komposit `(id, user_id)`.
  - Constraint transfer antardompet valid vs tidak valid (sumber == tujuan ditolak).
  - Soft delete `deleted_at`.

---

## 4. Status Verifikasi

| Komponen Uji | Metode | Status | Catatan |
|---|---|---|---|
| Domain Models (`Wallet`, `FinCategory`, `TransactionItem`) | `test/unit/finance_core_test.dart` | **LULUS** | 5 assertion model, serialisasi, kalkulasi summary |
| Utilitas Rupiah BigInt | `test/unit/currency_utils_test.dart` | **LULUS** | BigInt parsing & format mata uang rupiah |
| Suite Test Unit Penuh | `dart run test/all_tests.dart` | **LULUS** | 42/42 tests lulus |
| Analisis Statis Kode | `dart analyze lib test` | **LULUS** | 0 issues found |
| Skema Database & RLS | `supabase/migrations/0010_finance_core.sql` | **Siap Push** | Menunggu eksekusi migration via `supabase db push` atau SQL Editor di project Supabase |
| Pengujian Database pgTAP | `supabase/tests/08_fase9_finance_core_test.sql` | **Siap Test** | Menunggu eksekusi via `supabase test db` |
