# Dokumen Fase 8: Pengingat & Notifikasi (Reminders & FCM)

Dokumen ini mencatat arsitektur, implementasi teknis, dan verifikasi untuk **Fase 8** sistem **SF-25**, mengacu langsung pada spesifikasi `personal-os-master-blueprint-v2.json` (fitur `F-REM-01` s.d. `F-REM-04`).

---

## 1. Ringkasan Fase & Tujuan
Fase 8 menyediakan infrastruktur pengingat andal dan saluran komunikasi waktu nyata:
1. **Pengingat Terjadwal (Reminders)**: Pengingat untuk tugas, event, obat, dokumen penting, atau keperluan kustom dengan stempel waktu UTC.
2. **Aksi Cepat (Snooze & Dismiss)**: Aksi menunda pengingat (10 menit / kustom) atau menandai selesai langsung dari aplikasi/notifikasi.
3. **Penyimpanan Token Perangkat (Device Tokens)**: Skema registrasi token push (FCM / MCP) di tabel `device_tokens` untuk pengiriman push notification jarak jauh.
4. **Layanan Notifikasi Terpusat**: [lib/core/services/notification_service.dart](file:///d:/Codee/self-management/lib/core/services/notification_service.dart) dengan fungsi `registerDeviceToken` yang siap menerima token FCM dari pengguna kapan pun disediakan.

---

## 2. Daftar Fitur & Komponen yang Dikerjakan

### A. Rute & Layar (Navigation)
- `/reminders` : [lib/features/reminders/presentation/reminders_screen.dart](file:///d:/Codee/self-management/lib/features/reminders/presentation/reminders_screen.dart) — Layar pengingat dengan dialog pembuatan pengingat, penandaan status (terjadwal, ditunda, selesai, lewat waktu), dan tombol tunda/selesai.

### B. Controller & State Management (Riverpod)
- [lib/features/reminders/presentation/reminder_controller.dart](file:///d:/Codee/self-management/lib/features/reminders/presentation/reminder_controller.dart):
  - `reminderListProvider`: Mengambil semua pengingat pengguna dari database Supabase.
  - `reminderActionsProvider`: Notifier untuk menjadwalkan, menunda (snooze), menyelesaikan (dismiss), dan menghapus pengingat.

### C. Repository & Service Layer
- [lib/features/reminders/data/reminder_repository.dart](file:///d:/Codee/self-management/lib/features/reminders/data/reminder_repository.dart): Menangani CRUD langsung ke tabel `public.reminders`.
- [lib/core/services/notification_service.dart](file:///d:/Codee/self-management/lib/core/services/notification_service.dart): Layar terpusat untuk pendaftaran `device_tokens` dan manajemen pengingat.

### D. Domain Models
- [lib/features/reminders/domain/reminder.dart](file:///d:/Codee/self-management/lib/features/reminders/domain/reminder.dart): Entitas pengingat dengan dukungan target polimorfik (`task`, `event`, `medicine`, `document`, `custom`).

---

## 3. Perubahan Database & Keamanan

### Berkas Migrasi: `supabase/migrations/0009_reminders.sql`
1. **Tabel `public.reminders`**:
   - `id uuid PRIMARY KEY DEFAULT gen_random_uuid()`
   - `user_id uuid NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE`
   - `title text NOT NULL`
   - `body text`
   - `target_type text NOT NULL DEFAULT 'custom'`
   - `target_id uuid`
   - `remind_at timestamptz NOT NULL`
   - `status text NOT NULL DEFAULT 'scheduled'`
   - `snoozed_until timestamptz`
   - `deleted_at timestamptz`
   - `created_at timestamptz NOT NULL DEFAULT now()`
   - `updated_at timestamptz NOT NULL DEFAULT now()`
   - `CONSTRAINT uq_reminders_user UNIQUE (id, user_id)`
2. **Tabel `public.device_tokens`**:
   - `id uuid PRIMARY KEY DEFAULT gen_random_uuid()`
   - `user_id uuid NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE`
   - `fcm_token text NOT NULL`
   - `platform text NOT NULL DEFAULT 'android'`
   - `last_seen_at timestamptz NOT NULL DEFAULT now()`
   - `CONSTRAINT uq_device_tokens_user UNIQUE (id, user_id)`
   - `CONSTRAINT uq_device_token_val UNIQUE (user_id, fcm_token)`
3. **Keamanan RLS & Grants**:
   - RLS aktif di `reminders` dan `device_tokens`.
   - Kebijakan `auth.uid() = user_id` untuk 4 operasi database.
   - Hak akses eksplisit `GRANT ... TO authenticated; REVOKE ALL FROM anon;`.
   - Trigger otomatis `handle_updated_at()`.

---

## 4. Status Verifikasi Jujur & Tindak Lanjut Manual

| Kategori Pengujian | Status | Bukti / Catatan |
| :--- | :---: | :--- |
| **Dart Analyzer (`dart analyze`)** | ✅ **Lulus (0 Issues)** | Bersih dari segala error/warning |
| **Unit Testing Dart** | ✅ **Lulus (100%)** | Seluruh unit test di `test/unit/reminder_test.dart` lulus |
| **Eksekusi SQL di Supabase** | ⚠️ **Menunggu Tindak Lanjut** | Jalankan skrip [supabase/migrations/0009_reminders.sql](file:///d:/Codee/self-management/supabase/migrations/0009_reminders.sql) di SQL Editor dashboard Supabase |
| **Setup Token FCM / Push** | ⏳ **Siap Menerima Token** | Metode `registerDeviceToken` siap menerima token FCM nyata kapan pun pengguna memberikannya |
