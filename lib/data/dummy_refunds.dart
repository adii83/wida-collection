import '../models/refund_model.dart';

// Dummy refund data
final List<RefundModel> dummyRefunds = [
  RefundModel(
    id: 'REF001',
    orderId: 'ORD001',
    userId: 'user1',
    refundAmount: 97000,
    reason:
        'Produk tidak sesuai deskripsi. Warna yang diterima berbeda dengan yang ditampilkan di foto.',
    status: 'pending',
    requestedAt: DateTime.now().subtract(const Duration(hours: 2)),
  ),
  RefundModel(
    id: 'REF002',
    orderId: 'ORD002',
    userId: 'user2',
    refundAmount: 78000,
    reason:
        'Barang rusak saat diterima. Kemasan sudah penyok dan produk tidak berfungsi dengan baik.',
    status: 'approved',
    requestedAt: DateTime.now().subtract(const Duration(days: 1)),
    processedAt: DateTime.now().subtract(const Duration(hours: 12)),
    adminNotes: 'Refund disetujui. Proses pengembalian dana sedang dilakukan.',
    processedBy: 'Admin Wida',
  ),
  RefundModel(
    id: 'REF003',
    orderId: 'ORD003',
    userId: 'user3',
    refundAmount: 81000,
    reason:
        'Pesanan tidak sesuai. Saya memesan 3 item tapi hanya diterima 2 item saja.',
    status: 'pending',
    requestedAt: DateTime.now().subtract(const Duration(hours: 6)),
  ),
  RefundModel(
    id: 'REF004',
    orderId: 'ORD007',
    userId: 'user7',
    refundAmount: 136000,
    reason:
        'Produk tidak berfungsi dengan baik. Laptop sering restart sendiri dan headphone suaranya kecil.',
    status: 'rejected',
    requestedAt: DateTime.now().subtract(const Duration(days: 2)),
    processedAt: DateTime.now().subtract(const Duration(days: 1)),
    adminNotes:
        'Refund ditolak karena produk sudah melebihi masa garansi 7 hari dan tidak ada bukti kerusakan saat diterima.',
    processedBy: 'Admin Wida',
  ),
  RefundModel(
    id: 'REF005',
    orderId: 'ORD005',
    userId: 'user5',
    refundAmount: 53000,
    reason:
        'Salah pesan warna. Saya ingin warna coklat tapi yang datang warna hitam.',
    status: 'processed',
    requestedAt: DateTime.now().subtract(const Duration(days: 3)),
    processedAt: DateTime.now().subtract(const Duration(days: 2)),
    adminNotes:
        'Refund telah diproses dan dana sudah dikembalikan ke rekening pelanggan.',
    processedBy: 'Admin Wida',
  ),
  RefundModel(
    id: 'REF006',
    orderId: 'ORD004',
    userId: 'user4',
    refundAmount: 16000,
    reason: 'Barang tidak sampai tepat waktu dan sudah tidak diperlukan lagi.',
    status: 'pending',
    requestedAt: DateTime.now().subtract(const Duration(hours: 3)),
  ),
  RefundModel(
    id: 'REF007',
    orderId: 'ORD006',
    userId: 'user6',
    refundAmount: 24000,
    reason:
        'Kualitas produk tidak sesuai harga. Material terasa murahan dan mudah rusak.',
    status: 'approved',
    requestedAt: DateTime.now().subtract(const Duration(hours: 8)),
    processedAt: DateTime.now().subtract(const Duration(hours: 4)),
    adminNotes:
        'Refund disetujui. Menunggu konfirmasi pengembalian barang dari pelanggan.',
    processedBy: 'Admin Wida',
  ),
];
