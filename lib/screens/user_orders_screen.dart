import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../controllers/user_orders_controller.dart';
import '../models/order_model.dart';
import '../models/refund_model.dart';
import '../services/supabase_service.dart';
import 'user_refund_request_screen.dart';

class UserOrdersScreen extends StatelessWidget {
  const UserOrdersScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final controller =
        Get.isRegistered<UserOrdersController>(tag: 'user-orders')
        ? Get.find<UserOrdersController>(tag: 'user-orders')
        : Get.put(
            UserOrdersController(Get.find<SupabaseService>()),
            tag: 'user-orders',
          );

    return Scaffold(
      appBar: AppBar(title: const Text('Pesanan Saya')),
      body: Obx(() {
        if (controller.isLoading.value) {
          return const Center(child: CircularProgressIndicator());
        }

        final err = controller.error.value;
        if (err != null && controller.orders.isEmpty) {
          return _EmptyState(message: err, onRetry: controller.fetchMyOrders);
        }

        if (controller.orders.isEmpty) {
          return _EmptyState(
            message: 'Belum ada pesanan.',
            onRetry: controller.fetchMyOrders,
          );
        }

        return RefreshIndicator(
          onRefresh: controller.fetchMyOrders,
          child: ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: controller.orders.length,
            separatorBuilder: (_, __) => const SizedBox(height: 12),
            itemBuilder: (context, index) {
              final order = controller.orders[index];
              return _OrderCard(order: order);
            },
          ),
        );
      }),
    );
  }
}

class _OrderCard extends StatelessWidget {
  const _OrderCard({required this.order});

  final OrderModel order;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final statusColor = _statusColor(order.status);
    final created = order.createdAt.toLocal();
    final dateLabel =
        '${created.year}-${created.month.toString().padLeft(2, '0')}-${created.day.toString().padLeft(2, '0')}';

    final itemCount = order.items.fold<int>(
      0,
      (sum, item) => sum + item.quantity,
    );

    return Card(
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: statusColor.withOpacity(0.15),
          child: Icon(_statusIcon(order.status), color: statusColor),
        ),
        title: Text(
          'Order #${_shortId(order.id)}',
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w700,
          ),
        ),
        subtitle: Text(
          '$dateLabel • $itemCount item • ${_statusLabel(order.status)}',
        ),
        trailing: Text(
          'Rp ${order.totalAmount.toStringAsFixed(0)}',
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w700,
          ),
        ),
        onTap: () => _showOrderDetail(context, order),
      ),
    );
  }

  void _showOrderDetail(BuildContext context, OrderModel order) {
    final supabase = Get.find<SupabaseService>();
    final ordersController =
        Get.isRegistered<UserOrdersController>(tag: 'user-orders')
        ? Get.find<UserOrdersController>(tag: 'user-orders')
        : null;

    var refreshToken = 0;
    var currentOrder = order;

    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (context) {
        return SafeArea(
          child: DraggableScrollableSheet(
            expand: false,
            initialChildSize: 0.75,
            minChildSize: 0.4,
            maxChildSize: 0.95,
            builder: (context, scrollController) {
              return StatefulBuilder(
                builder: (context, setModalState) {
                  Future<RefundModel?> loadRefund() async {
                    final userId = supabase.currentUserId;
                    if (userId == null || userId.isEmpty) return null;
                    return supabase.fetchRefundByOrderId(
                      orderId: currentOrder.id,
                      userId: userId,
                    );
                  }

                  Future<void> confirmReceived() async {
                    if (ordersController == null) return;
                    final ok = await ordersController.confirmOrderReceived(
                      currentOrder.id,
                    );
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

                    setModalState(() {
                      currentOrder = currentOrder.copyWith(status: 'delivered');
                      refreshToken++;
                    });
                  }

                  Future<void> openRefundForm() async {
                    final ok = await Get.to<bool>(
                      () => UserRefundRequestScreen(order: order),
                      transition: Transition.rightToLeft,
                    );
                    if (ok == true) {
                      setModalState(() {
                        refreshToken++;
                      });
                    }
                  }

                  return Padding(
                    padding: const EdgeInsets.all(16),
                    child: ListView(
                      controller: scrollController,
                      children: [
                        Text(
                          'Order #${_shortId(order.id)}',
                          style: Theme.of(context).textTheme.titleLarge
                              ?.copyWith(fontWeight: FontWeight.w800),
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
                          style: Theme.of(context).textTheme.titleMedium
                              ?.copyWith(fontWeight: FontWeight.w700),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          order.shippingAddress.isEmpty
                              ? '-'
                              : order.shippingAddress,
                        ),
                        const SizedBox(height: 12),
                        Text(
                          'Item',
                          style: Theme.of(context).textTheme.titleMedium
                              ?.copyWith(fontWeight: FontWeight.w700),
                        ),
                        const SizedBox(height: 8),
                        ...currentOrder.items.map(
                          (item) => ListTile(
                            contentPadding: EdgeInsets.zero,
                            title: Text(item.productName),
                            subtitle: Text(
                              'x${item.quantity} • Rp ${item.price.toStringAsFixed(0)}',
                            ),
                            trailing: Text(
                              'Rp ${item.subtotal.toStringAsFixed(0)}',
                              style: const TextStyle(
                                fontWeight: FontWeight.w600,
                              ),
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
                              'Rp ${currentOrder.totalAmount.toStringAsFixed(0)}',
                              style: const TextStyle(
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: 16),
                        Text(
                          'Refund',
                          style: Theme.of(context).textTheme.titleMedium
                              ?.copyWith(fontWeight: FontWeight.w800),
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
                              if (snapshot.connectionState ==
                                  ConnectionState.waiting) {
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
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'Status: $statusLabel',
                                        style: const TextStyle(
                                          fontWeight: FontWeight.w700,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        'Nominal: Rp ${refund.refundAmount.toStringAsFixed(0)}',
                                      ),
                                      const SizedBox(height: 4),
                                      Text('Alasan: ${refund.reason}'),
                                      if ((refund.adminNotes ?? '').isNotEmpty)
                                        Padding(
                                          padding: const EdgeInsets.only(
                                            top: 8,
                                          ),
                                          child: Text(
                                            'Catatan Admin: ${refund.adminNotes}',
                                            style: const TextStyle(
                                              color: Colors.black87,
                                            ),
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
                },
              );
            },
          ),
        );
      },
    );
  }

  String _shortId(String id) {
    if (id.length <= 8) return id;
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

  Color _statusColor(String status) {
    switch (status.toLowerCase()) {
      case 'pending':
        return Colors.orange;
      case 'processing':
        return Colors.blue;
      case 'shipped':
        return Colors.purple;
      case 'delivered':
        return Colors.green;
      case 'cancelled':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  IconData _statusIcon(String status) {
    switch (status.toLowerCase()) {
      case 'pending':
        return Icons.schedule;
      case 'processing':
        return Icons.sync;
      case 'shipped':
        return Icons.local_shipping;
      case 'delivered':
        return Icons.check_circle;
      case 'cancelled':
        return Icons.cancel;
      default:
        return Icons.receipt_long;
    }
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.message, required this.onRetry});

  final String message;
  final Future<void> Function() onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.receipt_long, size: 48),
            const SizedBox(height: 12),
            Text(message, textAlign: TextAlign.center),
            const SizedBox(height: 12),
            ElevatedButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh),
              label: const Text('Muat ulang'),
            ),
          ],
        ),
      ),
    );
  }
}
