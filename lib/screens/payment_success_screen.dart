import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../config/design_tokens.dart';
import '../config/layout_values.dart';
import '../widgets/gradient_button.dart';
import 'auth_gate.dart';

class PaymentSuccessScreen extends StatelessWidget {
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
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.arrow_back),
                  ),
                  const SizedBox(width: 8),
                  const Text(
                    'Pembayaran',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700),
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
                      color: AppColors.mint,
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
                          child: const Icon(
                            Icons.check_circle,
                            color: AppColors.success,
                            size: 48,
                          ),
                        ),
                        AppSpacing.vSection,
                        const Text(
                          'Pembayaran Berhasil!',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        AppSpacing.vItem,
                        const Text(
                          'Terima kasih telah berbelanja. Pesanan kamu akan segera diproses.',
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
                              _InfoRow(label: 'Order ID', value: orderId),
                              AppSpacing.vItem,
                              _InfoRow(
                                label: 'Total',
                                value: 'Rp ${total.toStringAsFixed(0)}',
                              ),
                              AppSpacing.vItem,
                              _InfoRow(
                                label: 'Status',
                                value: 'Dikonfirmasi',
                                valueColor: AppColors.success,
                              ),
                              const SizedBox(height: 8),
                              _InfoRow(label: 'Metode', value: method),
                            ],
                          ),
                        ),
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
                AppSpacing.section,
              ),
              child: GradientButton(
                label: 'Kembali ke Home',
                onPressed: () => Get.offAll(() => const AuthGate()),
              ),
            ),
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
