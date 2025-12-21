import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../models/order_model.dart';
import '../models/refund_model.dart';
import '../controllers/user_orders_controller.dart';
import '../services/supabase_service.dart';
import '../utils/formatters.dart';
import '../screens/user_refund_request_screen.dart';

class OrderDetailSheet extends StatefulWidget {
  const OrderDetailSheet({super.key, required this.order});

  final OrderModel order;

  @override
  State<OrderDetailSheet> createState() => _OrderDetailSheetState();
}

class _OrderDetailSheetState extends State<OrderDetailSheet> {
  late OrderModel currentOrder;
  int refreshToken = 0;

  @override
  void initState() {
    super.initState();
    currentOrder = widget.order;
  }

  String _shortId(String id) {
    if (id.length <= 8) return id.toUpperCase();
    return id.substring(0, 8).toUpperCase();
  }

  String _statusLabel(String status) {
    switch (status.toLowerCase()) {
      case 'pending':
        return 'Menunggu';
      case 'processing':
        return 'Diproses';
      case 'shipped':
        return 'Dikirim';
      case 'delivered':
        return 'Diterima';
      case 'cancelled':
        return 'Dibatalkan';
      default:
        return status;
    }
  }

  Future<RefundModel?> loadRefund() async {
    final supabase = Get.find<SupabaseService>();
    final userId = supabase.currentUserId;
    if (userId == null || userId.isEmpty) return null;
    return supabase.fetchRefundByOrderId(
      orderId: currentOrder.id,
      userId: userId,
    );
  }

  Future<void> confirmReceived() async {
    final ordersController =
        Get.isRegistered<UserOrdersController>(tag: 'user-orders')
        ? Get.find<UserOrdersController>(tag: 'user-orders')
        : null;

    if (ordersController == null) return;

    final ok = await ordersController.confirmOrderReceived(currentOrder.id);
    if (!ok) {
      Get.snackbar(
        'Gagal',
        'Gagal konfirmasi pesanan diterima. Pastikan sudah login dan policy Supabase mengizinkan update.',
        snackPosition: SnackPosition.BOTTOM,
      );
      return;
    }

    Get.snackbar(
      'Sukses',
      'Pesanan ditandai sebagai diterima.',
      snackPosition: SnackPosition.BOTTOM,
    );

    setState(() {
      currentOrder = currentOrder.copyWith(status: 'delivered');
      refreshToken++;
    });
  }

  Future<void> openRefundForm() async {
    final ok = await Get.to<bool>(
      () => UserRefundRequestScreen(order: currentOrder),
      transition: Transition.rightToLeft,
    );
    if (ok == true) {
      setState(() {
        refreshToken++;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final ordersController =
        Get.isRegistered<UserOrdersController>(tag: 'user-orders')
        ? Get.find<UserOrdersController>(tag: 'user-orders')
        : null;

    return Padding(
      padding: const EdgeInsets.all(16),
      child: ListView(
        children: [
          Text(
            'Order #${_shortId(currentOrder.id)}',
            style: Theme.of(
              context,
            ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 8),
          Text('Status: ${_statusLabel(currentOrder.status)}'),
          Text(
            'Pembayaran: ${currentOrder.paymentStatus} (${currentOrder.paymentMethod})',
          ),
          if ((currentOrder.trackingNumber ?? '').isNotEmpty)
            Text('Resi: ${currentOrder.trackingNumber}'),

          if (currentOrder.status.toLowerCase() == 'shipped' &&
              ordersController != null)
            Padding(
              padding: const EdgeInsets.only(top: 12),
              child: Align(
                alignment: Alignment.centerLeft,
                child: ElevatedButton.icon(
                  onPressed: confirmReceived,
                  icon: const Icon(Icons.check_circle_outline),
                  label: const Text('Terima Pesanan'),
                ),
              ),
            ),
          const SizedBox(height: 12),
          Text(
            'Alamat Pengiriman',
            style: Theme.of(
              context,
            ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 6),
          Text(
            currentOrder.shippingAddress.isEmpty
                ? '-'
                : currentOrder.shippingAddress,
          ),
          const SizedBox(height: 12),
          Text(
            'Item',
            style: Theme.of(
              context,
            ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 8),
          ...currentOrder.items.map(
            (item) => ListTile(
              contentPadding: EdgeInsets.zero,
              title: Text(item.productName),
              subtitle: Text(
                'x${item.quantity} • ${AppFormatters.rupiah(item.price)}',
              ),
              trailing: Text(
                AppFormatters.rupiah(item.subtotal),
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
            ),
          ),
          const Divider(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Total',
                style: TextStyle(fontWeight: FontWeight.w700),
              ),
              Text(
                AppFormatters.rupiah(currentOrder.totalAmount),
                style: const TextStyle(fontWeight: FontWeight.w800),
              ),
            ],
          ),

          const SizedBox(height: 16),
          Text(
            'Refund',
            style: Theme.of(
              context,
            ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 8),

          if (currentOrder.status.toLowerCase() != 'delivered')
            const Text(
              'Refund bisa diajukan setelah pesanan diterima.',
              style: TextStyle(color: Colors.grey),
            )
          else
            FutureBuilder<RefundModel?>(
              key: ValueKey(refreshToken),
              future: loadRefund(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Padding(
                    padding: EdgeInsets.symmetric(vertical: 8),
                    child: LinearProgressIndicator(),
                  );
                }

                final refund = snapshot.data;
                if (refund == null) {
                  return Align(
                    alignment: Alignment.centerLeft,
                    child: ElevatedButton.icon(
                      onPressed: openRefundForm,
                      icon: const Icon(Icons.money_off),
                      label: const Text('Ajukan Refund'),
                    ),
                  );
                }

                final status = refund.status.toLowerCase();
                final statusLabel = () {
                  switch (status) {
                    case 'pending':
                      return 'Pending';
                    case 'approved':
                      return 'Disetujui';
                    case 'rejected':
                      return 'Ditolak';
                    case 'processed':
                      return 'Selesai';
                    default:
                      return refund.status;
                  }
                }();

                return Card(
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Status: $statusLabel',
                          style: const TextStyle(fontWeight: FontWeight.w700),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Nominal: ${AppFormatters.rupiah(refund.refundAmount)}',
                        ),
                        const SizedBox(height: 4),
                        Text('Alasan: ${refund.reason}'),
                        if ((refund.adminNotes ?? '').isNotEmpty)
                          Padding(
                            padding: const EdgeInsets.only(top: 8),
                            child: Text(
                              'Catatan Admin: ${refund.adminNotes}',
                              style: const TextStyle(color: Colors.black87),
                            ),
                          ),
                      ],
                    ),
                  ),
                );
              },
            ),
        ],
      ),
    );
  }
}
