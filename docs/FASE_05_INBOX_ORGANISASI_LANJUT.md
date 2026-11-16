# Dokumentasi Fase 5: Inbox, Template, Tempat Sampah, Tag, & Tautan Antar-Item

## 1. Ringkasan Fase & Tujuan
Fase 5 memperluas kapabilitas pengorganisasian personal OS: menyediakan alur penangkapan cepat dan triase Inbox (`inbox_items`), sistem template generik berbasis payload `jsonb` (`templates`), penyematan (*pin*) catatan, manajemen Tempat Sampah terpusat (`trash`) dengan pemulihan dan penghapusan permanen, format teks kaya Markdown beserta checklist, serta relasi dua arah polimorfik antar item lintas modul (`links`).

## 2. Daftar Fitur & Komponen yang Dikerjakan
- **Inbox & Triase Cepat (`lib/features/inbox/`)**:
  - `F-INBX-01`: Penangkapan instan via Quick Capture atau layar Inbox (`InboxScreen`).
  - `F-INBX-02`: Alur triase satu ketukan untuk memilah item mentah menjadi **Catatan** (dengan kategori) atau **Tugas** (dengan tenggat & proyek).
- **Template Berulang (`lib/features/templates/`)**:
  - `F-TPL-01`: Modal pemilih template (`TemplatePickerDialog`) saat membuat catatan (tersedia template standar: Catatan Rapat, Jurnal Refleksi, Rencana Proyek) serta dukungan template kustom berbasis `jsonb`.
- **Tempat Sampah Terpusat (`lib/features/trash/`)**:
  - `F-NOTE-06`: Layar tempat sampah (`TrashScreen`) dengan dua tab (Catatan Terhapus & Tugas Terhapus).
  - Aksi pemulihan (*restore*) mengembalikan `deleted_at = null`.
  - Aksi penghapusan permanen (*hard delete*) serta tombol "Kosongkan Tempat Sampah" yang dilindungi dialog konfirmasi ketat.
- **Dukungan Markdown (`lib/shared/widgets/markdown_view.dart`)**:
  - `F-NOTE-07`: Renderer markdown ramah mobile yang mendukung heading (`#`, `##`, `###`), quote (`>`), bullet list (`-`), dan checklist interaktif (`- [ ]` dan `- [x]`).
  - Toggle pratinjau instan pada editor catatan (`NoteEditorScreen`).
- **Tautan Polimorfik Lintas Modul (`lib/features/links/`)**:
  - `F-NOTE-08`: Relasi generik dua arah antarmodul via tabel `links` (`source_type`, `source_id`, `target_type`, `target_id`).

## 3. Perubahan Database & Keamanan
- **Berkas Migrasi**: `supabase/migrations/0006_inbox_tags_templates_links.sql`
  - Tabel `inbox_items`: `id`, `user_id`, `content`, `source`, `processed_at`, `converted_type`, `converted_id`, `created_at`, `updated_at`, `deleted_at`.
  - Tabel `templates`: `id`, `user_id`, `type`, `name`, `payload jsonb`, `created_at`, `updated_at`.
  - Tabel `tags`: `id`, `user_id`, `name`, `color`, `created_at`.
  - Tabel `note_tags`: `note_id`, `tag_id`, `user_id` dengan Foreign Key komposit ganda ke `notes(id, user_id)` dan `tags(id, user_id)`.
  - Tabel `links`: `id`, `user_id`, `source_type`, `source_id`, `target_type`, `target_id`, `created_at`.
  - **RLS & Hak Akses**: RLS `auth.uid() = user_id` diaktifkan 100% pada ke-5 tabel baru dan hak `GRANT` diberikan kepada role `authenticated`.

## 4. Keputusan Teknis & Asumsi
- **Zero Inbox Principle**: Item di inbox yang telah dipilah diberi stempel waktu `processed_at`, dicatat referensi hasil konversinya (`converted_type`, `converted_id`), dan disembunyikan dari antrean aktif.
- **Pembersihan Tempat Sampah**: Penghapusan permanen benar-benar menjalankan perintah SQL `DELETE` fisik, sedangkan penghapusan biasa dari layar daftar tetap merupakan `soft delete` (`deleted_at = now()`).

## 5. Cakupan Pengujian
- **Unit Test**: `test/unit/inbox_and_template_test.dart`
  - Pengujian serialisasi dan flag `isProcessed` pada `InboxItem`.
  - Pengujian deserialisasi payload `jsonb` pada `TemplateItem`.
  - Pengujian relasi polimorfik `ItemLink`.
- **Pengujian Database pgTAP**:
  - `supabase/tests/04_fase5_inbox_templates_links_test.sql` memverifikasi isolasi akun dan integritas Foreign Key komposit.

## 6. Status Verifikasi Jujur & Daftar Tindak Lanjut Manual
- **Status Otomatis**: **Terimplementasi & Lulus Tes Lokal (`dart analyze` 0 issues, 20/20 tests passed)**.
- **Tindak Lanjut Manual untuk Pengguna**:
  1. Jalankan migrasi SQL `0006_inbox_tags_templates_links.sql` di Supabase SQL Editor.
  2. Buka aplikasi, ketuk Quick Capture, pilih opsi 'Ke Inbox (Triase)', dan simpan teks ide.
  3. Buka menu Modul $\rightarrow$ 'Inbox & Triase', pilih item tersebut, lalu ketuk 'Pilah' untuk mengubahnya menjadi Catatan atau Tugas.
  4. Hapus sebuah catatan, lalu buka 'Tempat Sampah' untuk menguji tombol 'Pulihkan' atau 'Hapus Permanen'.
