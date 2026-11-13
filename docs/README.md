# Personal OS

> *Satu aplikasi untuk mengelola catatan, tugas, waktu, uang, kesehatan, belajar, dan kehidupan sehari-hari.*

Dokumen acuan utama sistem ini adalah `personal-os-master-blueprint-v2.json`.

---

## Prinsip Desain Kunci
1. **Capture Cepat**: Tombol Quick Capture (FAB) tersedia global untuk menampung ide/catatan secara instan.
2. **Online-First (Supabase)**: Database PostgreSQL Supabase adalah sumber kebenaran tunggal (*single source of truth*).
3. **Keamanan RLS Penuh**: Semua tabel menerapkan Row Level Security berbasis `auth.uid() = user_id`.
4. **Presisi Finansial**: Uang dicatat dalam tipe `bigint` rupiah penuh (bukan float).
5. **Zona Waktu UTC**: Waktu disimpan sebagai UTC (`timestamptz`), tanggal logis dihitung dari zona waktu lokal dan jam awal hari (`day_start_hour`).

---

## Menjalankan Aplikasi
Build dan jalankan aplikasi dengan menyertakan konfigurasi Supabase melalui `--dart-define`:

```bash
flutter run --dart-define=SUPABASE_URL=https://your-project.supabase.co --dart-define=SUPABASE_ANON_KEY=your-anon-key
```

## Menjalankan Pengujian
```bash
flutter test
```
