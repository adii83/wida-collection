# Winda Collection – Modul 4

A Flutter + GetX playground that mengeksplorasi penyimpanan lokal (shared_preferences & Hive) serta cloud (Supabase) untuk studi kasus e-commerce thrift.

## Fitur Utama

- **Tema Dinamis** – pilihan mode terang/gelap dan warna aksen disimpan menggunakan `shared_preferences` agar konsisten antar sesi.
- **Catatan Offline** – catatan produk/ide tersimpan di Hive, aman saat perangkat offline.
- **Catatan Cloud** – integrasi Supabase (auth, database, realtime) untuk sinkronisasi multi-device.
- **HTTP vs Dio Produk** – layar eksperimen performa API tetap tersedia seperti modul sebelumnya.

## Menjalankan Proyek

```powershell
cd "c:\Users\acer\Documents\File Praktikum\Pemrograman Mobile\Modul 4\Demo\Program\wida-collection"
flutter pub get
# Jalankan tanpa Supabase (hanya fitur offline)
flutter run
# Atau sertakan kredensial Supabase
flutter run --dart-define SUPABASE_URL=https://xxx.supabase.co --dart-define SUPABASE_ANON_KEY=public-anon-key
```

## Konfigurasi Supabase

1. Buat project Supabase → catat `Project URL` dan `anon public key`.
2. Tambahkan tabel `notes` dengan kolom: `id uuid primary key`, `title text`, `content text`, `owner uuid references auth.users`, `created_at timestamptz`, `updated_at timestamptz`.
3. Aktifkan Row Level Security dan tambahkan policy sederhana (owner = auth.uid()).
4. Jalankan aplikasi dengan `--dart-define` seperti di atas atau ubah nilai default pada `lib/config/supabase_config.dart` (hindari commit kredensial asli).

## Panduan Eksperimen

- **Mode Offline**: matikan internet, buka layar *Catatan Offline (Hive)* dan buktikan semua aksi tetap berjalan. Setelah itu buka *Catatan Cloud*, lakukan simpan dan lihat snackbar error karena offline.
- **Mode Multi-device**: jalankan aplikasi di dua perangkat dengan akun Supabase yang sama. Tambah catatan di perangkat A dan amati perangkat B menerima update melalui channel realtime.
- **Kompleksitas Kode**: struktur modular berada pada folder `controller`, `screens`, `services`, `models`, serta dokumentasi eksperimen di `docs/modul4_eksperimen.md`.

## Dokumentasi

- `docs/modul4_eksperimen.md` – hasil uji kecepatan baca/tulis, mode offline, multi-device, serta refleksi kompleksitas.
- Sertakan tangkapan layar yang disebutkan di dokumen tersebut pada `assets/images/report/` sebelum melakukan presentasi.
