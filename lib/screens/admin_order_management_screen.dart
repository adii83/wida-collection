import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/order_controller.dart';
import '../models/order_model.dart';

class AdminOrderManagementScreen extends StatefulWidget {
  const AdminOrderManagementScreen({super.key});

  @override
  State<AdminOrderManagementScreen> createState() =>
      _AdminOrderManagementScreenState();
}

class _AdminOrderManagementScreenState
    extends State<AdminOrderManagementScreen> {
  @override
  void initState() {
    super.initState();
    // Initialize OrderController if not exists
    if (!Get.isRegistered<OrderController>()) {
      Get.put(OrderController(Get.find()));
    }
    Get.find<OrderController>().fetchOrders();
  }

  void _showOrderDetailDialog(OrderModel order) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Order #${order.id.substring(0, 8)}'),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildInfoRow('Customer', order.userName),
              _buildInfoRow('Email', order.userEmail),
              _buildInfoRow(
                'Total',
                'Rp ${order.totalAmount.toStringAsFixed(0)}',
              ),
              _buildInfoRow('Status', order.status),
              _buildInfoRow('Payment', order.paymentStatus),
              _buildInfoRow('Method', order.paymentMethod),
              if (order.trackingNumber != null)
                _buildInfoRow('Tracking', order.trackingNumber!),
              const Divider(),
              const Text(
                'Items:',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              ...order.items.map(
                (item) => Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: Text('• ${item.productName} x${item.quantity}'),
                ),
              ),
              const Divider(),
              _buildInfoRow('Address', order.shippingAddress),
              if (order.notes != null) _buildInfoRow('Notes', order.notes!),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Tutup'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _showUpdateStatusDialog(order);
            },
            child: const Text('Update Status'),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              '$label:',
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
          ),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }

  void _showUpdateStatusDialog(OrderModel order) {
    final trackingController = TextEditingController(
      text: order.trackingNumber,
    );
    final notesController = TextEditingController(text: order.notes);
    String selectedStatus = order.status;
    String selectedPaymentStatus = order.paymentStatus;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Update Order Status'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                DropdownButtonFormField<String>(
                  value: selectedStatus,
                  decoration: const InputDecoration(
                    labelText: 'Status Order',
                    border: OutlineInputBorder(),
                  ),
                  items: const [
                    DropdownMenuItem(value: 'pending', child: Text('Dikemas')),
                    DropdownMenuItem(
                      value: 'processing',
                      child: Text('Dikirim'),
                    ),
                    DropdownMenuItem(value: 'shipped', child: Text('Diterima')),
                    DropdownMenuItem(
                      value: 'delivered',
                      child: Text('Delivered'),
                    ),
                    DropdownMenuItem(
                      value: 'cancelled',
                      child: Text('Cancelled'),
                    ),
                  ],
                  onChanged: (value) {
                    setDialogState(() => selectedStatus = value!);
                  },
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  value: selectedPaymentStatus,
                  decoration: const InputDecoration(
                    labelText: 'Status Pembayaran',
                    border: OutlineInputBorder(),
                  ),
                  items: const [
                    DropdownMenuItem(value: 'pending', child: Text('Pending')),
                    DropdownMenuItem(value: 'paid', child: Text('Paid')),
                    DropdownMenuItem(value: 'failed', child: Text('Failed')),
                    DropdownMenuItem(
                      value: 'refunded',
                      child: Text('Refunded'),
                    ),
                  ],
                  onChanged: (value) {
                    setDialogState(() => selectedPaymentStatus = value!);
                  },
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: trackingController,
                  decoration: const InputDecoration(
                    labelText: 'Nomor Resi (opsional)',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: notesController,
                  decoration: const InputDecoration(
                    labelText: 'Catatan (opsional)',
                    border: OutlineInputBorder(),
                  ),
                  maxLines: 2,
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Batal'),
            ),
            ElevatedButton(
              onPressed: () async {
                Navigator.pop(context);
                final controller = Get.find<OrderController>();

                // Update order status
                await controller.updateOrderStatus(
                  order.id,
                  selectedStatus,
                  trackingNumber: trackingController.text.isNotEmpty
                      ? trackingController.text
                      : null,
                  notes: notesController.text.isNotEmpty
                      ? notesController.text
                      : null,
                );

                // Update payment status if changed
                if (selectedPaymentStatus != order.paymentStatus) {
                  await controller.updatePaymentStatus(
                    order.id,
                    selectedPaymentStatus,
                  );
                }
              },
              child: const Text('Simpan'),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<OrderController>();

    return Scaffold(
      appBar: AppBar(title: const Text('Kelola Order')),
      body: Column(
        children: [
          // Filter tabs
          Container(
            padding: const EdgeInsets.all(8),
            child: Obx(
              () => SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    _buildFilterChip(controller, 'all', 'Semua'),
                    _buildFilterChip(controller, 'pending', 'Dikemas'),
                    _buildFilterChip(controller, 'processing', 'Dikirim'),
                    _buildFilterChip(controller, 'shipped', 'Diterima'),
                    _buildFilterChip(controller, 'delivered', 'Delivered'),
                    _buildFilterChip(controller, 'cancelled', 'Cancelled'),
                  ],
                ),
              ),
            ),
          ),
          Expanded(
            child: Obx(() {
              if (controller.isLoading.value) {
                return const Center(child: CircularProgressIndicator());
              }

              final orders = controller.filteredOrders;
              if (orders.isEmpty) {
                return const Center(child: Text('Tidak ada order'));
              }

              return RefreshIndicator(
                onRefresh: () => controller.fetchOrders(),
                child: ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: orders.length,
                  itemBuilder: (context, index) {
                    final order = orders[index];
                    return Card(
                      margin: const EdgeInsets.only(bottom: 12),
                      child: InkWell(
                        onTap: () => _showOrderDetailDialog(order),
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    'Order #${order.id.substring(0, 8)}',
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 16,
                                    ),
                                  ),
                                  _buildStatusChip(order.status),
                                ],
                              ),
                              const SizedBox(height: 8),
                              Text('Customer: ${order.userName}'),
                              Text(
                                'Total: Rp ${order.totalAmount.toStringAsFixed(0)}',
                                style: const TextStyle(
                                  color: Colors.green,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Row(
                                children: [
                                  Icon(
                                    _getPaymentIcon(order.paymentStatus),
                                    size: 16,
                                    color: _getPaymentColor(
                                      order.paymentStatus,
                                    ),
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    order.paymentStatus.toUpperCase(),
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: _getPaymentColor(
                                        order.paymentStatus,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                ),
              );
            }),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip(
    OrderController controller,
    String filter,
    String label,
  ) {
    final isSelected = controller.selectedFilter.value == filter;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: FilterChip(
        label: Text(label),
        selected: isSelected,
        onSelected: (selected) {
          if (selected) {
            controller.setFilter(filter);
          }
        },
      ),
    );
  }

  String _getStatusLabel(String status) {
    switch (status) {
      case 'pending':
        return 'Dikemas';
      case 'processing':
        return 'Dikirim';
      case 'shipped':
        return 'Diterima';
      case 'delivered':
        return 'Delivered';
      case 'cancelled':
        return 'Cancelled';
      default:
        return status.toUpperCase();
    }
  }

  Widget _buildStatusChip(String status) {
    Color color;
    switch (status) {
      case 'pending':
        color = Colors.orange;
        break;
      case 'processing':
        color = Colors.blue;
        break;
      case 'shipped':
        color = Colors.purple;
        break;
      case 'delivered':
        color = Colors.green;
        break;
      case 'cancelled':
        color = Colors.red;
        break;
      default:
        color = Colors.grey;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.2),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        _getStatusLabel(status),
        style: TextStyle(
          color: color,
          fontSize: 12,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  IconData _getPaymentIcon(String status) {
    switch (status) {
      case 'paid':
        return Icons.check_circle;
      case 'failed':
        return Icons.cancel;
      case 'refunded':
        return Icons.money_off;
      default:
        return Icons.pending;
    }
  }

  Color _getPaymentColor(String status) {
    switch (status) {
      case 'paid':
        return Colors.green;
      case 'failed':
        return Colors.red;
      case 'refunded':
        return Colors.orange;
      default:
        return Colors.grey;
    }
  }
}
