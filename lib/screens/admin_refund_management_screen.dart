import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/order_controller.dart';
import '../models/refund_model.dart';

class AdminRefundManagementScreen extends StatefulWidget {
  const AdminRefundManagementScreen({super.key});

  @override
  State<AdminRefundManagementScreen> createState() =>
      _AdminRefundManagementScreenState();
}

class _AdminRefundManagementScreenState
    extends State<AdminRefundManagementScreen> {
  @override
  void initState() {
    super.initState();
    if (!Get.isRegistered<OrderController>()) {
      Get.put(OrderController(Get.find()));
    }
    Get.find<OrderController>().fetchRefunds();
  }

  void _showRefundDetailDialog(RefundModel refund) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Refund #${refund.id.substring(0, 8)}'),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildInfoRow('Customer', refund.userName),
              _buildInfoRow('Order ID', refund.orderId.substring(0, 8)),
              _buildInfoRow(
                'Amount',
                'Rp ${refund.refundAmount.toStringAsFixed(0)}',
              ),
              _buildInfoRow('Status', refund.status.toUpperCase()),
              const Divider(),
              const Text(
                'Alasan:',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 4),
              Text(refund.reason),
              if (refund.adminNotes != null) ...[
                const Divider(),
                const Text(
                  'Catatan Admin:',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 4),
                Text(refund.adminNotes!),
              ],
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Tutup'),
          ),
          if (refund.status == 'pending') ...[
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                _showProcessRefundDialog(refund, 'rejected');
              },
              style: TextButton.styleFrom(foregroundColor: Colors.red),
              child: const Text('Tolak'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                _showProcessRefundDialog(refund, 'approved');
              },
              child: const Text('Setujui'),
            ),
          ],
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

  void _showProcessRefundDialog(RefundModel refund, String action) {
    final notesController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(action == 'approved' ? 'Setujui Refund' : 'Tolak Refund'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Yakin ingin ${action == 'approved' ? 'menyetujui' : 'menolak'} refund sebesar Rp ${refund.refundAmount.toStringAsFixed(0)}?',
            ),
            const SizedBox(height: 16),
            TextField(
              controller: notesController,
              decoration: const InputDecoration(
                labelText: 'Catatan Admin (opsional)',
                border: OutlineInputBorder(),
              ),
              maxLines: 3,
            ),
          ],
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
              await controller.processRefund(
                refund.id,
                action,
                adminNotes: notesController.text.isNotEmpty
                    ? notesController.text
                    : null,
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: action == 'approved' ? Colors.green : Colors.red,
            ),
            child: Text(action == 'approved' ? 'Setujui' : 'Tolak'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<OrderController>();

    return Scaffold(
      appBar: AppBar(title: const Text('Kelola Refund')),
      body: Obx(() {
        if (controller.isLoading.value) {
          return const Center(child: CircularProgressIndicator());
        }

        final refunds = controller.refunds;
        if (refunds.isEmpty) {
          return const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.money_off, size: 64, color: Colors.grey),
                SizedBox(height: 16),
                Text('Tidak ada permintaan refund'),
              ],
            ),
          );
        }

        return RefreshIndicator(
          onRefresh: () => controller.fetchRefunds(),
          child: ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: refunds.length,
            itemBuilder: (context, index) {
              final refund = refunds[index];
              return Card(
                margin: const EdgeInsets.only(bottom: 12),
                child: InkWell(
                  onTap: () => _showRefundDetailDialog(refund),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Refund #${refund.id.substring(0, 8)}',
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                            _buildStatusChip(refund.status),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text('Customer: ${refund.userName}'),
                        const SizedBox(height: 4),
                        Text(
                          'Rp ${refund.refundAmount.toStringAsFixed(0)}',
                          style: const TextStyle(
                            color: Colors.red,
                            fontWeight: FontWeight.bold,
                            fontSize: 18,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          refund.reason,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontSize: 13,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Icon(
                              Icons.calendar_today,
                              size: 14,
                              color: Colors.grey[600],
                            ),
                            const SizedBox(width: 4),
                            Text(
                              _formatDate(refund.requestedAt),
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey[600],
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
    );
  }

  Widget _buildStatusChip(String status) {
    Color color;
    String label;
    switch (status) {
      case 'pending':
        color = Colors.orange;
        label = 'PENDING';
        break;
      case 'approved':
        color = Colors.green;
        label = 'DISETUJUI';
        break;
      case 'rejected':
        color = Colors.red;
        label = 'DITOLAK';
        break;
      case 'processed':
        color = Colors.blue;
        label = 'DIPROSES';
        break;
      default:
        color = Colors.grey;
        label = status.toUpperCase();
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.2),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 12,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year} ${date.hour}:${date.minute.toString().padLeft(2, '0')}';
  }
}
