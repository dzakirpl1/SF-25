# Dokumentasi Fase 2: Catatan dan Kategori

## 1. Ringkasan Fase & Tujuan
Fase 2 mengimplementasikan manajemen catatan teks dan kategori terstruktur. Fitur mencakup penangkapan cepat (*Quick Capture*), penyematan (*pin*), pengarsipan, pencarian kata kunci, serta penghapusan aman (*soft delete*) dengan proteksi integritas relasi kategori aktif.

## 2. Daftar Fitur & Komponen yang Dikerjakan
- **Fitur Catatan (`lib/features/notes/`)**:
  - `F-NOTE-01`: Daftar catatan interaktif (`NoteListScreen`) dengan pencarian instan (judul & isi) dan filter *chip* horizontal berdasarkan kategori.
  - `F-NOTE-02`: Editor catatan (`NoteEditorScreen`) untuk membuat dan mengubah catatan, dilengkapi pemilih kategori, *pin toggle*, dan pengecekan optimistik `updated_at`.
  - `F-NOTE-03`: *Quick Capture* modal dialog (`QuickCaptureDialog`) dari Floating Action Button global untuk mencatat ide tanpa kewajiban memberi judul.
  - `F-NOTE-04`: Pengarsipan (`archived_at`) dan pemindahan ke tempat sampah (`deleted_at`) dengan modal konfirmasi destruktif (`ConfirmDialog`).
- **Fitur Kategori (`lib/features/categories/`)**:
  - `F-CAT-01`: Pengelolaan kategori catatan (`CategoryScreen`) dengan validasi database yang menolak penghapusan kategori jika masih terkait dengan catatan aktif.

## 3. Perubahan Database & Keamanan
- **Berkas Migrasi**: `supabase/migrations/0003_notes_categories.sql`
  - Tabel `note_categories`: `id` (UUID v4), `user_id` (FK `auth.users`), `name`, `color`, `created_at`, dengan batasan unik komposit `uq_note_category_user UNIQUE (id, user_id)`.
  - Tabel `notes`: `id` (UUID v4), `user_id` (FK `auth.users`), `category_id`, `title`, `content`, `is_pinned`, `archived_at`, `deleted_at`, `created_at`, `updated_at`.
  - **Foreign Key Komposit**: `constraint fk_notes_category_user foreign key (category_id, user_id) references public.note_categories(id, user_id)` untuk mencegah kebocoran relasi silang antar pengguna.
  - **Indeks**: Indeks pada `(user_id, deleted_at, archived_at)`, `(user_id, category_id)`, dan `(user_id, is_pinned desc)`.
  - **Fungsi RPC**: `delete_note_category(category_uuid uuid)` yang memicu exception `P0001` jika kategori masih menaungi catatan yang `deleted_at IS NULL`.
  - **RLS & Hak Akses**: RLS `auth.uid() = user_id` diaktifkan untuk kedua tabel dan hak `GRANT ALL` diberikan kepada role `authenticated`.

## 4. Keputusan Teknis & Asumsi
- **Fallback Judul Quick Capture**: Jika judul kosong, sistem secara otomatis mengekstrak baris pertama dari konten teks sebagai representasi judul di daftar catatan (`displayTitle`).
- **Soft Delete**: Catatan yang dihapus tidak langsung hilang secara fisik, melainkan diisi stempel `deleted_at`. Kategori hanya dapat dihapus jika semua catatan terkait telah berstatus *soft deleted* atau dipindahkan.

## 5. Cakupan Pengujian
- **Unit Test**: `test/unit/note_model_test.dart`
  - Validasi penentuan `displayTitle` untuk catatan berformat normal vs *Quick Capture*.
  - Validasi status flag `isArchived` dan `isDeleted`.
  - Validasi integritas serialisasi dan deserialisasi JSON bolak-balik.
- **Pengujian Integrasi Live Supabase**:
  - Script `scratch/verify_e2e_live.py` berhasil menguji pembuatan kategori, pembuatan catatan, penangkapan *quick capture*, dan membuktikan fungsi database `delete_note_category` berhasil menolak penghapusan kategori aktif dengan kode `P0001`.
- **Pengujian Database pgTAP**:
  - Skrip pengujian `supabase/tests/01_fase1_fase2_rls_test.sql` siap dijalankan via Supabase CLI.

## 6. Status Verifikasi Jujur & Daftar Tindak Lanjut Manual
- **Status Otomatis**: **Terimplementasi & Lulus Tes Lokal & Lulus Verifikasi Live RPC**.
- **Tindak Lanjut Manual untuk Pengguna**:
  1. Jalankan pengujian database pgTAP jika Supabase CLI lokal terpasang:
     ```bash
     supabase test db
     ```
  2. Buka aplikasi di perangkat fisik, coba fitur *Quick Capture*, lalu buka tab Catatan untuk memastikan filter kategori dan pencarian berjalan responsif.
