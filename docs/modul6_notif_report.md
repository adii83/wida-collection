# Modul 6 – Laporan Eksperimen Notifikasi

## Skenario Bisnis
- **Jenis aplikasi**: E-commerce (Wida Collection).
- **Notifikasi yang diuji**:
  - Promo Payday / voucher baru (`type=promo`, optional `productId`).
  - Status pesanan terbaru (`type=order_status`).
- **Integrasi**: Firebase Cloud Messaging (data-only), Flutter Local Notifications (heads-up, custom sound `promo_chime.wav`), GetX routing menuju halaman promo/riwayat notifikasi.

## Pra-syarat
1. Pasang `google-services.json` (Android) dan perbarui `lib/config/firebase_options.dart` dengan kredensial Firebase.
2. Jalankan `flutter pub get` lalu `flutterfire configure` (opsional) dan rebuild aplikasi.
3. Berikan izin notifikasi (Android 13+). Token FCM tersedia di **Pusat Notifikasi → Salin token**.
4. Kirim pesan dari Firebase Console sebagai **Data message** dengan payload contoh:
   ```json
   {
     "title": "Promo Payday 50%",
     "body": "Voucher loyal customer",
     "type": "promo",
     "productId": "p1"
   }
   ```
   Untuk status pesanan gunakan `"type": "order_status"`.

## Eksperimen Lifecycle
### 1. Foreground
1. Buka aplikasi dan diam di **Home**.
2. Kirim data message.
3. Observasi:
   - Banner heads-up muncul dengan suara khusus (`promo_chime.wav`).
   - Logcat / `flutter run` menampilkan `FCM Payload (foreground): ...`.
   - Catatan masuk di **Pusat Notifikasi** dengan origin `foreground`.

### 2. Background (app di-recent)
1. Tekan tombol Home, jangan tutup aplikasi.
2. Kirim notifikasi.
3. Observasi:
   - Notifikasi masuk ke system tray (custom sound tetap dimainkan).
   - Ketuk notifikasi → aplikasi kembali dan otomatis membuka promo terkait (jika `productId` valid) atau layar riwayat.
   - Log `FCM Payload (opened)` tercetak.

### 3. Terminated
1. Swipe aplikasi dari recent (kill).
2. Kirim notifikasi data-only.
3. Observasi:
   - Notifikasi tetap diterima oleh sistem (ditangani `firebaseMessagingBackgroundHandler`).
   - Ketuk notifikasi → aplikasi inisialisasi ulang, payload tetap tersedia sehingga navigasi otomatis tetap berjalan.
   - Log `FCM Payload (background)` muncul segera setelah handler dieksekusi.

## Bukti Implementasi
Lampirkan minimal:
- Screenshot banner heads-up + custom sound (rekaman/screen record bila perlu).
- Logcat/terminal yang menunjukkan payload pada tiga kondisi.
- Tampilan layar tujuan (contoh Product Detail atau Pusat Notifikasi) setelah menekan notifikasi.

## Analisis Perilaku OS
| Kondisi | Perilaku Android | Catatan |
| --- | --- | --- |
| Foreground | Heads-up + custom sound dari channel `promo_status_channel` | Local notification ditampilkan manual untuk kontrol penuh. |
| Background | System tray + tap menghidupkan kembali Flutter, payload diteruskan via `onDidReceiveNotificationResponse` | App tidak perlu notifikasi bawaan Firebase karena menggunakan data-only. |
| Terminated | Background handler menampilkan notifikasi lokal sebelum UI dibuat | Wajib init Firebase + `DartPluginRegistrant.ensureInitialized()` di handler. |

> Semua eksperimen menggunakan GetX sebagai state manager (`NotificationController`) dan struktur modular Controller–Service–View.
