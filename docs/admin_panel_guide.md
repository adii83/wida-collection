# Admin Panel - Wida Collection

## 🔐 Fitur Admin Panel

Fitur Admin Panel telah berhasil ditambahkan ke aplikasi Wida Collection dengan kemampuan lengkap untuk mengelola operasional toko online.

---

## 📋 Daftar Fitur

### 1. **Login Admin**
- Autentikasi admin dengan email dan password
- Mendukung 2 level akses: Admin dan Super Admin
- Demo credentials:
  - Admin: `admin@widacollection.com` / `admin123`
  - Super Admin: `superadmin@widacollection.com` / `superadmin123`

### 2. **Dashboard Admin**
- Tampilan statistik real-time:
  - Total Order
  - Pending Order
  - Total Revenue
  - Pending Refund
- Quick access menu ke semua fitur manajemen

### 3. **Manajemen Produk**
- ✅ Tambah produk baru (nama, harga, gambar)
- ✅ Edit produk existing
- ✅ Hapus produk
- ✅ Lihat daftar semua produk

### 4. **Manajemen Order**
- ✅ Lihat semua order
- ✅ Filter order berdasarkan status (pending, processing, shipped, delivered, cancelled)
- ✅ Update status order
- ✅ Update status pembayaran (pending, paid, failed, refunded)
- ✅ Tambah nomor resi pengiriman
- ✅ Tambah catatan order

### 5. **Manajemen Pembayaran**
- ✅ Verifikasi pembayaran
- ✅ Update status pembayaran
- ✅ Integrasi dengan order status

### 6. **Manajemen Refund**
- ✅ Lihat semua permintaan refund
- ✅ Detail permintaan refund (customer, amount, alasan)
- ✅ Approve atau reject refund
- ✅ Tambah catatan admin untuk refund
- ✅ Otomatis update payment status saat refund disetujui

### 7. **Pengiriman Notifikasi**
- ✅ Kirim notifikasi custom ke pengguna
- ✅ Target: semua user atau user tertentu
- ✅ Preview notifikasi sebelum dikirim
- ✅ Template cepat (Flash Sale, Produk Baru, Pengiriman, dll)

---

## 🚀 Cara Mengakses Admin Panel

### Dari Aplikasi:
1. Buka aplikasi Wida Collection
2. Navigasi ke tab **Profile** (pojok kanan bawah)
3. Scroll ke bawah dan tap **"Admin Panel"** (icon ungu)
4. Login dengan credentials admin

### Struktur Menu:
```
Profile Screen
└── Admin Panel (Login)
    └── Admin Dashboard
        ├── Kelola Produk
        ├── Kelola Order
        ├── Kelola Pembayaran
        ├── Kelola Refund
        └── Kirim Notifikasi
```

---

## 🏗️ Struktur File yang Ditambahkan

### Models
```
lib/models/
├── admin_user.dart         # Model untuk data admin
├── order_model.dart        # Model untuk order & order items
└── refund_model.dart       # Model untuk refund
```

### Services
```
lib/services/
└── admin_service.dart      # Service untuk operasi admin (CRUD products, orders, refunds)
```

### Controllers
```
lib/controllers/
├── admin_controller.dart   # Controller untuk state management admin
└── order_controller.dart   # Controller untuk manajemen order & refund
```

### Screens
```
lib/screens/
├── admin_login_screen.dart                  # Login admin
├── admin_dashboard_screen.dart              # Dashboard utama
├── admin_product_management_screen.dart     # Manajemen produk
├── admin_order_management_screen.dart       # Manajemen order
├── admin_refund_management_screen.dart      # Manajemen refund
└── admin_notification_screen.dart           # Kirim notifikasi
```

### Routes
```
lib/routes/app_routes.dart   # Ditambahkan 6 routes baru untuk admin
```

---

## 🗄️ Database Schema (Supabase)

Untuk fully functional, buat tabel berikut di Supabase:

### Table: `products`
```sql
CREATE TABLE products (
  id TEXT PRIMARY KEY,
  name TEXT NOT NULL,
  image TEXT,
  price NUMERIC NOT NULL,
  created_at TIMESTAMP DEFAULT NOW(),
  updated_at TIMESTAMP DEFAULT NOW()
);
```

### Table: `orders`
```sql
CREATE TABLE orders (
  id TEXT PRIMARY KEY,
  user_id TEXT NOT NULL,
  user_name TEXT,
  user_email TEXT,
  items JSONB NOT NULL,
  total_amount NUMERIC NOT NULL,
  status TEXT DEFAULT 'pending',
  payment_method TEXT,
  payment_status TEXT DEFAULT 'pending',
  shipping_address TEXT,
  tracking_number TEXT,
  notes TEXT,
  created_at TIMESTAMP DEFAULT NOW(),
  updated_at TIMESTAMP DEFAULT NOW()
);
```

### Table: `refunds`
```sql
CREATE TABLE refunds (
  id TEXT PRIMARY KEY,
  order_id TEXT REFERENCES orders(id),
  user_id TEXT NOT NULL,
  user_name TEXT,
  refund_amount NUMERIC NOT NULL,
  reason TEXT NOT NULL,
  status TEXT DEFAULT 'pending',
  requested_at TIMESTAMP DEFAULT NOW(),
  processed_at TIMESTAMP,
  admin_notes TEXT,
  processed_by TEXT
);
```

### Table: `admin_notifications`
```sql
CREATE TABLE admin_notifications (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  title TEXT NOT NULL,
  body TEXT NOT NULL,
  target_user_id TEXT,
  data JSONB,
  created_at TIMESTAMP DEFAULT NOW()
);
```

---

## 💡 Cara Testing Fitur

### 1. Test Login Admin:
- Gunakan credentials demo
- Pastikan redirect ke dashboard setelah login

### 2. Test Manajemen Produk:
- Tambah produk dengan data dummy
- Edit produk
- Hapus produk

### 3. Test Manajemen Order:
- Buat order dari user side (checkout)
- Masuk admin panel
- Update status order dari pending → processing → shipped → delivered
- Update payment status

### 4. Test Refund:
- Buat permintaan refund (fitur ini perlu diimplementasi di user side)
- Admin approve/reject refund
- Check otomatis update payment status

### 5. Test Notifikasi:
- Kirim notifikasi broadcast
- Check notifikasi muncul di device user

---

## 🔧 Konfigurasi Tambahan

### Permissions (opsional)
Untuk keamanan lebih baik, tambahkan Row Level Security (RLS) di Supabase:

```sql
-- Only authenticated admins can access
ALTER TABLE products ENABLE ROW LEVEL SECURITY;
ALTER TABLE orders ENABLE ROW LEVEL SECURITY;
ALTER TABLE refunds ENABLE ROW LEVEL SECURITY;

-- Add policies for admin access
-- (Custom policy based on your admin authentication)
```

---

## 📱 Screenshots Path

Untuk dokumentasi, simpan screenshot di:
```
assets/images/report/
├── admin_login.png
├── admin_dashboard.png
├── admin_products.png
├── admin_orders.png
├── admin_refunds.png
└── admin_notifications.png
```

---

## 🎯 Status Implementasi

✅ **Completed Features:**
- Login Admin
- Dashboard dengan statistik
- CRUD Produk
- Manajemen Order (update status, payment, tracking)
- Manajemen Refund (approve/reject)
- Kirim Notifikasi Custom

⚠️ **Requires Backend Setup:**
- Supabase tables harus dibuat manual
- Firebase Cloud Messaging untuk notifikasi
- Row Level Security policies

🔜 **Future Enhancements:**
- User management dari admin panel
- Laporan penjualan & analytics
- Bulk operations (delete/update multiple items)
- Export data ke CSV/Excel
- Dashboard charts & graphs
- Admin activity logs

---

## 📞 Support

Untuk pertanyaan atau masalah terkait fitur admin, check:
1. Error logs di console
2. Supabase dashboard untuk database issues
3. Firebase console untuk notification issues

---

**Happy Managing! 🚀**
