import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../config/design_tokens.dart';
import '../config/layout_values.dart';
import '../models/cart_item.dart';
import '../widgets/gradient_button.dart';
import '../widgets/rounded_icon_button.dart';
import 'payment_success_screen.dart';

class CheckoutScreen extends StatefulWidget {
  const CheckoutScreen({
    super.key,
    required this.items,
    required this.subtotal,
  });

  final List<CartItem> items;
  final double subtotal;

  @override
  State<CheckoutScreen> createState() => _CheckoutScreenState();
}

enum PaymentMethod { card, ewallet, bank }

class _CheckoutScreenState extends State<CheckoutScreen> {
  PaymentMethod _method = PaymentMethod.card;
  final _nameController = TextEditingController(text: 'Putra Wida');
  final _addressController = TextEditingController(
    text: 'Gondowangi, Malang, 65158',
  );
  final _phoneController = TextEditingController(text: '081234567890');
  final _cardNumberController = TextEditingController();
  final _cardHolderController = TextEditingController();
  final _expController = TextEditingController();
  final _cvvController = TextEditingController();

  double get total => widget.subtotal;

  @override
  void dispose() {
    _nameController.dispose();
    _addressController.dispose();
    _phoneController.dispose();
    _cardNumberController.dispose();
    _cardHolderController.dispose();
    _expController.dispose();
    _cvvController.dispose();
    super.dispose();
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
                  RoundedIconButton(
                    icon: Icons.arrow_back,
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                  const SizedBox(width: 12),
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
                  _SummaryCard(
                    nameController: _nameController,
                    addressController: _addressController,
                    phoneController: _phoneController,
                    total: total,
                    itemCount: widget.items.length,
                  ),
                  AppSpacing.vSection,
                  const Text(
                    'Metode Pembayaran',
                    style: TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
                  ),
                  AppSpacing.vItem,
                  _PaymentOption(
                    title: 'Kartu Kredit/Debit',
                    subtitle: 'Visa / Mastercard',
                    icon: Icons.credit_card,
                    selected: _method == PaymentMethod.card,
                    onTap: () => setState(() => _method = PaymentMethod.card),
                  ),
                  AppSpacing.vItem,
                  _PaymentOption(
                    title: 'E-Wallet',
                    subtitle: 'GoPay / OVO / Dana',
                    icon: Icons.account_balance_wallet,
                    selected: _method == PaymentMethod.ewallet,
                    onTap: () =>
                        setState(() => _method = PaymentMethod.ewallet),
                  ),
                  AppSpacing.vItem,
                  _PaymentOption(
                    title: 'Transfer Bank',
                    subtitle: 'BCA / Mandiri',
                    icon: Icons.account_balance,
                    selected: _method == PaymentMethod.bank,
                    onTap: () => setState(() => _method = PaymentMethod.bank),
                  ),
                  const SizedBox(height: 24),
                  const Text(
                    'Detail Kartu',
                    style: TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
                  ),
                  AppSpacing.vItem,
                  TextField(
                    controller: _cardNumberController,
                    decoration: const InputDecoration(labelText: 'Nomor Kartu'),
                    keyboardType: TextInputType.number,
                  ),
                  AppSpacing.vItem,
                  TextField(
                    controller: _cardHolderController,
                    decoration: const InputDecoration(labelText: 'Nama Anda'),
                  ),
                  AppSpacing.vItem,
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _expController,
                          decoration: const InputDecoration(
                            labelText: 'Exp. MM/YY',
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: TextField(
                          controller: _cvvController,
                          decoration: const InputDecoration(labelText: 'CVV'),
                          keyboardType: TextInputType.number,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.page,
                AppSpacing.section,
                AppSpacing.page,
                AppSpacing.section,
              ),
              decoration: const BoxDecoration(
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black12,
                    blurRadius: 20,
                    offset: Offset(0, -8),
                  ),
                ],
              ),
              child: GradientButton(
                label: 'Bayar',
                onPressed: () {
                  final orderId =
                      '#THF${DateTime.now().millisecondsSinceEpoch.toString().substring(7)}';
                  Get.to(
                    () => PaymentSuccessScreen(
                      orderId: orderId,
                      total: total,
                      method: _method.name,
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SummaryCard extends StatelessWidget {
  const _SummaryCard({
    required this.nameController,
    required this.addressController,
    required this.phoneController,
    required this.total,
    required this.itemCount,
  });

  final TextEditingController nameController;
  final TextEditingController addressController;
  final TextEditingController phoneController;
  final double total;
  final int itemCount;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.mint,
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TextField(
            controller: nameController,
            decoration: const InputDecoration(labelText: 'Nama Penerima'),
          ),
          AppSpacing.vItem,
          TextField(
            controller: addressController,
            decoration: const InputDecoration(labelText: 'Alamat Lengkap'),
            maxLines: 2,
          ),
          AppSpacing.vItem,
          TextField(
            controller: phoneController,
            decoration: const InputDecoration(labelText: 'Nomor Telepon'),
            keyboardType: TextInputType.phone,
          ),
          const SizedBox(height: 16),
          Text(
            'Pesanan: $itemCount item',
            style: const TextStyle(color: AppColors.softGray),
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Total Pembayaran',
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
              Text(
                'Rp ${total.toStringAsFixed(0)}',
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  color: AppColors.primaryPink,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _PaymentOption extends StatelessWidget {
  const _PaymentOption({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.selected,
    required this.onTap,
  });

  final String title;
  final String subtitle;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: selected ? AppColors.primaryPink : Colors.transparent,
            width: 1.5,
          ),
          boxShadow: AppShadows.card,
        ),
        child: Row(
          children: [
            Icon(icon, color: AppColors.primaryPink),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                  Text(
                    subtitle,
                    style: const TextStyle(color: AppColors.softGray),
                  ),
                ],
              ),
            ),
            Icon(
              selected ? Icons.radio_button_checked : Icons.radio_button_off,
              color: selected ? AppColors.primaryPink : AppColors.softGray,
            ),
          ],
        ),
      ),
    );
  }
}
