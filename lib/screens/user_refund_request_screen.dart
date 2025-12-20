import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';

import '../models/order_model.dart';
import '../services/supabase_service.dart';

class UserRefundRequestScreen extends StatefulWidget {
  const UserRefundRequestScreen({super.key, required this.order});

  final OrderModel order;

  @override
  State<UserRefundRequestScreen> createState() =>
      _UserRefundRequestScreenState();
}

class _UserRefundRequestScreenState extends State<UserRefundRequestScreen> {
  final _formKey = GlobalKey<FormState>();

  late final TextEditingController _reasonController;
  late final TextEditingController _amountController;

  final _isSubmitting = false.obs;

  File? _proofFile;

  @override
  void initState() {
    super.initState();
    _reasonController = TextEditingController();
    _amountController = TextEditingController(
      text: widget.order.totalAmount.toStringAsFixed(0),
    );
  }

  @override
  void dispose() {
    _reasonController.dispose();
    _amountController.dispose();
    super.dispose();
  }

  Future<void> _pickProofImage() async {
    if (kIsWeb) {
      Get.snackbar(
        'Tidak didukung',
        'Upload bukti refund belum didukung di web.',
        snackPosition: SnackPosition.BOTTOM,
      );
      return;
    }

    final picker = ImagePicker();
    final xfile = await picker.pickImage(source: ImageSource.gallery);
    if (xfile == null) return;

    setState(() => _proofFile = File(xfile.path));
  }

  double? _parseAmount() {
    final raw = _amountController.text.trim();
    final normalized = raw.replaceAll('.', '').replaceAll(',', '.');
    return double.tryParse(normalized);
  }

  Future<void> _submit() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;

    final supabase = Get.find<SupabaseService>();
    final userId = supabase.currentUserId;
    if (userId == null || userId.isEmpty) {
      Get.snackbar(
        'Gagal',
        'Silakan login ulang untuk mengajukan refund.',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
      return;
    }

    final amount = _parseAmount() ?? widget.order.totalAmount;
    final reason = _reasonController.text.trim();

    _isSubmitting.value = true;
    try {
      String? proofUrl;
      if (_proofFile != null) {
        proofUrl = await supabase.uploadRefundProof(
          _proofFile!,
          userId: userId,
          orderId: widget.order.id,
        );

        if (proofUrl == null) {
          Get.snackbar(
            'Upload bukti gagal',
            'Bucket storage belum ada atau policy Storage belum mengizinkan. Buat bucket `refund-proofs` di Supabase Storage (Public atau with policy), lalu coba lagi.',
            snackPosition: SnackPosition.BOTTOM,
            backgroundColor: Colors.orange,
            colorText: Colors.white,
          );
        }
      }

      final created = await supabase.createRefundRequest(
        orderId: widget.order.id,
        userId: userId,
        amount: amount,
        reason: reason,
        imageProofUrl: proofUrl,
      );

      if (created == null) {
        Get.snackbar(
          'Gagal',
          'Gagal mengajukan refund. Cek koneksi atau policy Supabase.',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.red,
          colorText: Colors.white,
        );
        return;
      }

      Get.back(result: true);
      Get.snackbar(
        'Terkirim',
        'Permintaan refund berhasil diajukan (status: pending).',
        snackPosition: SnackPosition.BOTTOM,
      );
    } catch (e) {
      Get.snackbar(
        'Error',
        e.toString(),
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    } finally {
      _isSubmitting.value = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    final order = widget.order;

    return Scaffold(
      appBar: AppBar(title: const Text('Ajukan Refund')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              Card(
                child: ListTile(
                  title: Text(
                    'Order #${order.id.length > 8 ? order.id.substring(0, 8).toUpperCase() : order.id}',
                  ),
                  subtitle: Text(
                    'Total: Rp ${order.totalAmount.toStringAsFixed(0)}',
                  ),
                ),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _reasonController,
                decoration: const InputDecoration(
                  labelText: 'Alasan Refund',
                  hintText:
                      'Contoh: barang rusak / tidak sesuai / salah ukuran',
                  border: OutlineInputBorder(),
                ),
                maxLines: 4,
                validator: (v) {
                  final value = (v ?? '').trim();
                  if (value.isEmpty) return 'Alasan wajib diisi';
                  if (value.length < 5) return 'Alasan terlalu singkat';
                  return null;
                },
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _amountController,
                decoration: const InputDecoration(
                  labelText: 'Nominal Refund (Rp)',
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.number,
                validator: (v) {
                  final amount = _parseAmount();
                  if (amount == null) return 'Nominal tidak valid';
                  if (amount <= 0) return 'Nominal harus > 0';
                  if (amount > order.totalAmount) {
                    return 'Nominal tidak boleh melebihi total order';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 12),
              OutlinedButton.icon(
                onPressed: _pickProofImage,
                icon: const Icon(Icons.image),
                label: Text(
                  _proofFile == null
                      ? 'Tambah Bukti (Opsional)'
                      : 'Ganti Bukti',
                ),
              ),
              if (_proofFile != null) ...[
                const SizedBox(height: 8),
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Image.file(
                    _proofFile!,
                    height: 180,
                    fit: BoxFit.cover,
                  ),
                ),
              ],
              const SizedBox(height: 16),
              Obx(() {
                return ElevatedButton(
                  onPressed: _isSubmitting.value ? null : _submit,
                  child: Text(
                    _isSubmitting.value ? 'Mengirim...' : 'Kirim Permintaan',
                  ),
                );
              }),
              const SizedBox(height: 8),
              const Text(
                'Catatan: Refund hanya bisa diajukan setelah pesanan diterima. Admin akan memproses dan memberi status.',
                style: TextStyle(fontSize: 12, color: Colors.grey),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
