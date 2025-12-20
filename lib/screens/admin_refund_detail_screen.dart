import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/order_controller.dart';
import '../models/refund_model.dart';

class AdminRefundDetailScreen extends StatefulWidget {
  final RefundModel refund;

  const AdminRefundDetailScreen({super.key, required this.refund});

  @override
  State<AdminRefundDetailScreen> createState() =>
      _AdminRefundDetailScreenState();
}

class _AdminRefundDetailScreenState extends State<AdminRefundDetailScreen> {
  late RefundModel refund;
  late String selectedStatus;
  late TextEditingController adminNotesController;

  @override
  void initState() {
    super.initState();
    refund = widget.refund;
    selectedStatus = refund.status;
    adminNotesController = TextEditingController(text: refund.adminNotes ?? '');
  }

  @override
  void dispose() {
    adminNotesController.dispose();
    super.dispose();
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'pending':
        return Colors.orange.shade400;
      case 'approved':
        return Colors.blue.shade400;
      case 'rejected':
        return Colors.red.shade400;
      case 'processed':
        return Colors.green.shade400;
      default:
        return Colors.grey.shade400;
    }
  }

  String _getStatusLabel(String status) {
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
        return status.toUpperCase();
    }
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              '$label:',
              style: const TextStyle(
                fontWeight: FontWeight.w600,
                color: Colors.black87,
              ),
            ),
          ),
          Expanded(
            child: Text(value, style: const TextStyle(color: Colors.black54)),
          ),
        ],
      ),
    );
  }

  String _formatDateTime(DateTime dateTime) {
    return '${dateTime.day}/${dateTime.month}/${dateTime.year} ${dateTime.hour}:${dateTime.minute.toString().padLeft(2, '0')}';
  }

  void _saveRefundStatus() async {
    final controller = Get.find<OrderController>();

    final updatedRefund = refund.copyWith(
      status: selectedStatus,
      processedAt: DateTime.now(),
      adminNotes: adminNotesController.text.isNotEmpty
          ? adminNotesController.text
          : null,
      processedBy: 'Admin Wida',
    );

    // Update refund di list
    final index = controller.refunds.indexWhere((r) => r.id == refund.id);
    if (index != -1) {
      controller.refunds[index] = updatedRefund;
      controller.refunds.refresh();
    }

    Get.snackbar(
      'Berhasil',
      'Status refund #${refund.id} telah diperbarui',
      snackPosition: SnackPosition.BOTTOM,
      backgroundColor: Colors.green,
      colorText: Colors.white,
      duration: const Duration(seconds: 2),
    );

    await Future.delayed(const Duration(milliseconds: 800));
    Get.back();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Refund #${refund.id}'),
        elevation: 0,
        backgroundColor: _getStatusColor(selectedStatus),
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Status header
            Container(
              color: _getStatusColor(selectedStatus),
              padding: const EdgeInsets.all(16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Status Refund',
                        style: TextStyle(color: Colors.white70, fontSize: 12),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _getStatusLabel(selectedStatus),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white24,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      'Rp ${refund.refundAmount.toStringAsFixed(0)}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Customer Info Section
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Informasi Pelanggan',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.grey[100],
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildInfoRow('Nama', refund.userName),
                        _buildInfoRow('Order ID', refund.orderId),
                        _buildInfoRow(
                          'Jumlah Refund',
                          'Rp ${refund.refundAmount.toStringAsFixed(0)}',
                        ),
                        _buildInfoRow(
                          'Diajukan',
                          _formatDateTime(refund.requestedAt),
                        ),
                        if (refund.processedAt != null)
                          _buildInfoRow(
                            'Diproses',
                            _formatDateTime(refund.processedAt!),
                          ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // Reason Section
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Alasan Refund',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 12),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.grey[100],
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      refund.reason,
                      style: const TextStyle(
                        fontSize: 14,
                        color: Colors.black87,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Update Status Section (hanya jika status pending)
            if (refund.status == 'pending')
              Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Update Status Refund',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<String>(
                      initialValue: selectedStatus,
                      decoration: InputDecoration(
                        labelText: 'Status Refund',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      items: const [
                        DropdownMenuItem(
                          value: 'pending',
                          child: Text('Pending'),
                        ),
                        DropdownMenuItem(
                          value: 'approved',
                          child: Text('Disetujui'),
                        ),
                        DropdownMenuItem(
                          value: 'rejected',
                          child: Text('Ditolak'),
                        ),
                        DropdownMenuItem(
                          value: 'processed',
                          child: Text('Selesai'),
                        ),
                      ],
                      onChanged: (value) {
                        setState(() => selectedStatus = value!);
                      },
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: adminNotesController,
                      decoration: InputDecoration(
                        labelText: 'Catatan Admin',
                        hintText: 'Masukkan catatan untuk pelanggan...',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        prefixIcon: const Icon(Icons.note),
                        alignLabelWithHint: true,
                      ),
                      maxLines: 4,
                    ),
                  ],
                ),
              ),

            // Admin Notes Section (jika sudah diproses)
            if (refund.adminNotes != null)
              Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Catatan Admin',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.blue[50],
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.blue[200]!),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            refund.adminNotes!,
                            style: const TextStyle(
                              fontSize: 14,
                              color: Colors.black87,
                            ),
                          ),
                          if (refund.processedBy != null) ...[
                            const SizedBox(height: 8),
                            Text(
                              'Diproses oleh: ${refund.processedBy}',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey[600],
                                fontStyle: FontStyle.italic,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ],
                ),
              ),

            // Action Buttons
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  if (refund.status == 'pending')
                    ElevatedButton.icon(
                      onPressed: _saveRefundStatus,
                      icon: const Icon(Icons.save),
                      label: const Text('Simpan Perubahan'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                    ),
                  if (refund.status == 'pending') const SizedBox(height: 8),
                  ElevatedButton.icon(
                    onPressed: () => Get.back(),
                    icon: const Icon(Icons.arrow_back),
                    label: const Text('Kembali'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.grey,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
