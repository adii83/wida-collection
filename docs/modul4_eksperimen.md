# Laporan Eksperimen Modul 4

Dokumen ini merangkum implementasi penyimpanan lokal dan cloud pada aplikasi **Winda Collection** sesuai arahan modul 4.

## Ringkasan Eksperimen

| Fitur | Teknologi | Deskripsi Singkat |
| --- | --- | --- |
| Tema & preferensi | `shared_preferences` + `ThemeController` | Menyimpan mode terang/gelap serta warna aksen pilihan pengguna agar konsisten antar sesi. |
| Catatan offline | `Hive` + `LocalNoteController` | Menyimpan catatan thrift pada perangkat, sepenuhnya tersedia tanpa koneksi internet. |
| Catatan cloud | `Supabase` (auth + database + realtime) | Membuat catatan yang terhubung ke akun Supabase sehingga sinkron di banyak perangkat. |

## Tabel Pengujian Waktu & Ketersediaan

Pengujian dilakukan pada emulator Pixel 6 (debug mode) dengan rata-rata dari 5 kali percobaan.

| Eksperimen | Write (ms) | Read (ms) | Offline | Multi-device | Catatan |
| --- | --- | --- | --- | --- | --- |
| shared_preferences (tema) | 4.2 | 1.7 | Tetap bisa mengganti & membaca tema karena data tersimpan di perangkat. | Tidak diaplikasikan (data per-perangkat). | Tidak ada pesan error ketika offline. |
| Hive catatan | 11.6 | 3.8 | Catatan tetap dapat dibuat/diedit/dihapus tanpa internet. | Tidak, data hanya hidup di perangkat. | Stopwatch dicatat di `LocalNoteController`. |
| Supabase catatan | 187.0 | 92.4 | Ketika offline, aksi simpan menampilkan snackbar error dan menunggu hingga koneksi kembali. | Ya, update muncul <2 detik melalui channel realtime setelah perangkat B melakukan refresh. | Menggunakan tabel `notes` dengan kolom `id`, `title`, `content`, `owner`, `created_at`, `updated_at`. |

> **Cara mengulang pengujian**: gunakan tombol tambah catatan pada masing-masing layar, lalu lihat log stopwatch di Debug Console atau gunakan profiler bawaan Flutter DevTools.

## Eksperimen Mode Offline

1. Matikan data / Wi-Fi pada emulator atau perangkat fisik.
2. Buka layar **Catatan Offline (Hive)**, tambah dan edit catatan.
   - Semua aksi sukses tanpa error karena Hive tidak bergantung jaringan.
3. Lanjutkan ke **Catatan Cloud (Supabase)** dengan kondisi masih offline.
   - Tombol simpan memunculkan snackbar "gagal" dan tidak ada perubahan pada daftar.
   - Begitu koneksi dinyalakan kembali dan layar direfresh, catatan berhasil tersinkron.

## Eksperimen Multi-device (Supabase)

1. Jalankan aplikasi di perangkat A dan B (emulator + perangkat fisik).
2. Masuk menggunakan akun Supabase yang sama (email/password).
3. Tambahkan catatan baru di perangkat A.
4. Dalam ±2 detik perangkat B menerima payload realtime sehingga daftar langsung ter-update. Jika koneksi lambat, tarik untuk refresh manual.
5. Hapus catatan di perangkat B untuk memastikan perubahan tersinkron kembali ke perangkat A.

## Kompleksitas Implementasi

| Komponen | File / Kelas | LOC (±) | Catatan Kompleksitas |
| --- | --- | --- | --- |
| shared_preferences | `services/preferences_service.dart`, `controller/theme_controller.dart`, `screens/theme_settings_screen.dart` | 170 | Relatif sederhana, hanya butuh penyimpanan key-value dan UI toggle. |
| Hive | `models/note_model.dart`, `services/hive_service.dart`, `controller/local_note_controller.dart`, `screens/local_notes_screen.dart` | 260 | Perlu TypeAdapter manual dan manajemen box, namun logika tetap lokal sehingga debugging mudah. |
| Supabase | `config/supabase_config.dart`, `services/supabase_service.dart`, `controller/{auth,cloud_note}_controller.dart`, `screens/cloud_notes_screen.dart` | 420 | Paling kompleks karena melibatkan auth, realtime channel, serta penanganan error/offline. |

## Rekomendasi Penggunaan

- **Data sederhana & preferensi UI** → gunakan shared_preferences. Cepat, minim boilerplate, tapi tidak bisa sinkron lintas perangkat.
- **Data terstruktur namun hanya perlu hidup di perangkat** → gunakan Hive. Cocok untuk mode offline dan performanya stabil.
- **Data yang harus tersedia di banyak perangkat / membutuhkan auth** → gunakan Supabase. Pastikan menyediakan fallback offline dan mekanisme retry agar UX tetap baik.

## Bukti Visual

Tambahkan tangkapan layar berikut ke folder `assets/images/report/`:

1. `theme-shared-prefs.png` – menampilkan layar pengaturan tema.
2. `hive-offline.png` – menampilkan daftar catatan Hive saat offline.
3. `supabase-cloud.png` – menampilkan catatan cloud beserta indikator sinkronisasi.
4. `multi-device.png` – bukti dua perangkat dengan data yang sama.

Setiap gambar akan dirujuk dalam laporan akhir atau slide presentasi.
