# 🎯 Quick Start - Admin Panel

## Login Credentials

### Admin
```
Email: admin@widacollection.com
Password: admin123
```

### Super Admin
```
Email: superadmin@widacollection.com
Password: superadmin123
```

## Akses Admin Panel

1. **Dari Profile Screen:**
   - Buka tab Profile (pojok kanan bawah)
   - Scroll ke bawah
   - Tap menu **"Admin Panel"** (icon 🛡️ ungu)
   - Login dengan credentials di atas

2. **Direct Navigation (untuk development):**
   ```dart
   Get.toNamed(AppRoutes.adminLogin);
   ```

## Fitur yang Tersedia

| Menu | Deskripsi | Akses |
|------|-----------|-------|
| 📦 Kelola Produk | Tambah, edit, hapus produk | Admin & Super Admin |
| 📋 Kelola Order | Update status order & pembayaran | Semua Admin |
| 💰 Kelola Pembayaran | Verifikasi & update payment | Semua Admin |
| 🔄 Kelola Refund | Approve/reject refund request | Semua Admin |
| 📢 Kirim Notifikasi | Broadcast notifikasi ke user | Semua Admin |

## Testing Checklist

- [ ] Login admin berhasil
- [ ] Dashboard menampilkan statistik
- [ ] Tambah produk baru
- [ ] Edit produk existing
- [ ] Hapus produk
- [ ] Lihat daftar order
- [ ] Update status order
- [ ] Update payment status
- [ ] Process refund request
- [ ] Kirim notifikasi test

## Notes

⚠️ **Penting:**
- Credentials ini untuk demo/testing saja
- Di production, gunakan proper authentication dengan Supabase Auth
- Setup database tables di Supabase (lihat `admin_panel_guide.md`)
- Configure Firebase untuk notifications

📚 **Dokumentasi Lengkap:** Lihat `docs/admin_panel_guide.md`
