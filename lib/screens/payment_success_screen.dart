import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../config/design_tokens.dart';
import '../utils/formatters.dart';
import '../config/layout_values.dart';
import '../widgets/gradient_button.dart';
import '../services/supabase_service.dart';
import 'auth_gate.dart';

class PaymentSuccessScreen extends StatefulWidget {
  const PaymentSuccessScreen({
    super.key,
    required this.orderId,
    required this.total,
    required this.method,
  });

  final String orderId;
  final double total;
  final String method;

  @override
  State<PaymentSuccessScreen> createState() => _PaymentSuccessScreenState();
}

class _PaymentSuccessScreenState extends State<PaymentSuccessScreen> {
  late bool _isSuccess;
  late String _displayMethod;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _displayMethod = widget.method;
    // Jika QRIS, defaultnya Pending (kecuali user konfirmasi).
    // Jika COD, langsung Success.
    _isSuccess = !widget.method.toLowerCase().contains('qris');
  }

  Future<void> _checkStatus() async {
    setState(() => _isLoading = true);
    // Simulasi cek status ke server
    await Future.delayed(const Duration(seconds: 2));
    if (mounted) {
      // Update status di Supabase (Best effort)
      try {
        final supabase = Get.find<SupabaseService>();
        await supabase.client!
            .from('orders')
            .update({'payment_status': 'paid', 'status': 'processed'})
            .eq('id', widget.orderId);

        Get.snackbar(
          'Sukses',
          'Status pembayaran berhasil diperbarui!',
          backgroundColor: AppColors.success,
          colorText: Colors.white,
          snackPosition: SnackPosition.TOP,
        );
      } catch (e) {
        debugPrint('Error updating order status: $e');
        // Still proceed to show success UI for demo purposes,
        // or show error snackbar if critical.
      }

      setState(() {
        _isLoading = false;
        // Di Sandbox/Demo, kita anggap selalu sukses setelah user klik cek
        _isSuccess = true;
        // Bersihkan teks status di method jika ada
        if (_displayMethod.contains('Menunggu')) {
          _displayMethod = 'QRIS';
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.page,
                AppSpacing.heroTop,
                AppSpacing.page,
                0,
              ),
              child: Row(
                children: [
                  // Disable back if success to force use "Back to Home"
                  if (!_isSuccess)
                    IconButton(
                      onPressed: () => Navigator.of(context).pop(),
                      icon: const Icon(Icons.close),
                    ),
                  const SizedBox(width: 8),
                  Text(
                    _isSuccess ? 'Pembayaran Berhasil' : 'Menunggu Pembayaran',
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.page,
                  AppSpacing.section,
                  AppSpacing.page,
                  AppSpacing.section,
                ),
                children: [
                  Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: _isSuccess
                          ? AppColors.mint
                          : AppColors.warning.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(24),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(18),
                          decoration: const BoxDecoration(
                            shape: BoxShape.circle,
                            color: Colors.white,
                          ),
                          child: _isLoading
                              ? const CircularProgressIndicator()
                              : Icon(
                                  _isSuccess
                                      ? Icons.check_circle
                                      : Icons.hourglass_top,
                                  color: _isSuccess
                                      ? AppColors.success
                                      : Colors.orange,
                                  size: 48,
                                ),
                        ),
                        AppSpacing.vSection,
                        Text(
                          _isSuccess
                              ? 'Pembayaran Berhasil!'
                              : 'Selesaikan Pembayaran',
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        AppSpacing.vItem,
                        Text(
                          _isSuccess
                              ? 'Terima kasih telah berbelanja. Pesanan kamu akan segera diproses.'
                              : 'Mohon selesaikan pembayaran Anda via $_displayMethod.',
                          textAlign: TextAlign.center,
                        ),
                        AppSpacing.vSection,
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _InfoRow(
                                label: 'Order ID',
                                value: widget.orderId,
                              ),
                              AppSpacing.vItem,
                              _InfoRow(
                                label: 'Total',
                                value: AppFormatters.rupiah(widget.total),
                              ),
                              AppSpacing.vItem,
                              _InfoRow(
                                label: 'Status',
                                value: _isSuccess ? 'Dikonfirmasi' : 'Menunggu',
                                valueColor: _isSuccess
                                    ? AppColors.success
                                    : Colors.orange,
                              ),
                              const SizedBox(height: 8),
                              _InfoRow(label: 'Metode', value: _displayMethod),
                            ],
                          ),
                        ),
                        // Add Button for Pending QRIS
                        if (!_isSuccess &&
                            !widget.method.toLowerCase().contains('cod')) ...[
                          AppSpacing.vSection,
                          SizedBox(
                            width: double.infinity,
                            child: OutlinedButton(
                              onPressed: _checkStatus,
                              style: OutlinedButton.styleFrom(
                                side: const BorderSide(
                                  color: AppColors.primaryPink,
                                ),
                              ),
                              child: const Text(
                                'Saya Sudah Bayar',
                                style: TextStyle(color: AppColors.primaryPink),
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.page,
                AppSpacing.section,
                AppSpacing.page,
                0, // Remove bottom padding here if needed or keep standard
              ),
              child: GradientButton(
                label: 'Kembali ke Home',
                onPressed: () => Get.offAll(() => const AuthGate()),
              ),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({required this.label, required this.value, this.valueColor});

  final String label;
  final String value;
  final Color? valueColor;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: const TextStyle(color: AppColors.softGray)),
        Text(
          value,
          style: TextStyle(
            fontWeight: FontWeight.w600,
            color: valueColor ?? AppColors.charcoal,
          ),
        ),
      ],
    );
  }
}
