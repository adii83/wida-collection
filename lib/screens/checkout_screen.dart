import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:uuid/uuid.dart';

import '../config/design_tokens.dart';
import '../utils/formatters.dart';
import '../config/layout_values.dart';
import '../models/user_address.dart';
import '../models/order_model.dart';
import '../models/cart_item.dart';
import '../controllers/auth_controller.dart';
import '../controllers/cart_controller.dart';
import '../controllers/user_orders_controller.dart';
import '../services/product_service.dart';
import '../services/supabase_service.dart';
import '../widgets/gradient_button.dart';
import '../widgets/rounded_icon_button.dart';
import '../widgets/address_form_sheet.dart';
import 'package:url_launcher/url_launcher.dart';
import '../services/midtrans_service.dart';
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

// Update enum
enum PaymentMethod { qris, cod }

class _CheckoutScreenState extends State<CheckoutScreen> {
  // defaulting to QRIS
  PaymentMethod _method = PaymentMethod.qris;

  late final TextEditingController _nameController;
  late final TextEditingController _addressController;
  late final TextEditingController _phoneController;
  // Removed Card Controllers

  bool _isSubmitting = false;
  final AuthController _auth = Get.find<AuthController>();
  final MidtransService _midtrans = MidtransService(); // Add service

  List<CartItem> _items = [];

  @override
  void initState() {
    super.initState();
    // Copy items to local state
    _items = List.from(widget.items);

    final profile = _auth.profile.value;

    // Auto-fill Name
    _nameController = TextEditingController(
      text: profile?.fullName ?? 'Putra Wida',
    );

    // Auto-fill Phone (Random if empty)
    String phone = profile?.phone ?? '';
    if (phone.isEmpty) {
      phone = _generateRandomPhone();
    }
    _phoneController = TextEditingController(text: phone);

    // Auto-fill Address
    final defAddr =
        _auth.addresses.firstWhereOrNull((a) => a.isDefault) ??
        _auth.addresses.firstOrNull;
    _addressController = TextEditingController(text: _formatAddress(defAddr));
  }

  // Calculate total dynamically from local items
  double get _currentTotal => _items.fold(0.0, (sum, i) => sum + i.total);

  void _updateQty(int index, int delta) {
    setState(() {
      final item = _items[index];
      final newQty = item.quantity + delta;
      if (newQty < 1) return;

      item.quantity = newQty;

      // Sync with CartController if this item is from Cart
      if (item.id != null) {
        Get.find<CartController>().updateQuantity(item.id!, newQty);
      }
    });
  }

  void _removeItem(int index) {
    final item = _items[index];
    setState(() {
      _items.removeAt(index);
    });

    // Sync with CartController if this item is from Cart
    if (item.id != null) {
      // Since removeItem in CartController also removes it from the list/db
      // We should toggle it off or remove it?
      // Logic: If user removes from checkout, they likely want to remove it from the purchase,
      // effectively "unselecting" it or removing it completely.
      // Given "Checkout" context, removing it means "I don't want to buy this now".
      // Ideally we just uncheck it in Cart? But we are not in CartScreen.
      // Let's just remove from CartController for now as requested "bisa di hapus produknya".
      // Or safer: Just remove from this temporary list.
      // User said "hapus produknya" which usually implies delete.
      Get.find<CartController>().removeItem(item.id!);
    }

    if (_items.isEmpty) {
      // If empty, maybe go back?
      Get.back();
    }
  }

  String _generateRandomPhone() {
    final rand = Random();
    String number = '08';
    for (int i = 0; i < 10; i++) {
      number += rand.nextInt(10).toString();
    }
    return number;
  }

  String _formatAddress(UserAddress? addr) {
    if (addr == null) return '';
    final parts = [
      addr.street,
      addr.district,
      addr.city,
      addr.province,
      addr.postalCode,
    ].whereType<String>().where((s) => s.isNotEmpty).toList();
    return parts.join(', ');
  }

  @override
  void dispose() {
    _nameController.dispose();
    _addressController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  String _formatPaymentMethod(PaymentMethod method) {
    switch (method) {
      case PaymentMethod.qris:
        return 'qris';
      case PaymentMethod.cod:
        return 'cod';
    }
  }

  Future<void> _payAndCreateOrder() async {
    if (_isSubmitting) return;

    if (_items.isEmpty) {
      Get.back();
      return;
    }

    if (_addressController.text.trim().isEmpty) {
      Get.snackbar(
        'Alamat Kosong',
        'Mohon pilih alamat pengiriman.',
        snackPosition: SnackPosition.BOTTOM,
      );
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      final supabase = Get.find<SupabaseService>();
      final auth = Get.find<AuthController>();

      if (!supabase.isReady) {
        throw Exception('Supabase belum siap');
      }
      if (!auth.isLoggedIn || auth.currentUser.value == null) {
        throw Exception('Silakan login dulu.');
      }

      final now = DateTime.now();
      final user = auth.currentUser.value!;
      final profile = auth.profile.value;
      final profileName = (profile?.fullName ?? _nameController.text.trim())
          .trim();
      final profilePhone = (profile?.phone ?? _phoneController.text.trim())
          .trim();

      // Ensure Products in DB
      try {
        final productService = Get.find<ProductService>();
        for (final ci in _items) {
          await productService.ensurePublicProductInSupabase(ci.product);
        }
      } catch (_) {}

      final orderItems = _items
          .map(
            (ci) => OrderItem(
              productId: ci.product.id,
              productName: ci.product.name,
              productImage: ci.product.image,
              price: ci.product.price,
              quantity: ci.quantity,
            ),
          )
          .toList();

      final orderId = const Uuid().v4();

      final order = OrderModel(
        id: orderId,
        userId: user.id,
        userName: profileName,
        userEmail: profile?.email ?? user.email ?? '',
        items: orderItems,
        totalAmount: _currentTotal, // Use calculated total
        status: 'pending',
        paymentMethod: _formatPaymentMethod(_method),
        paymentStatus: 'pending', // Pending initially
        shippingAddress: _addressController.text.trim(),
        createdAt: now,
        updatedAt: now,
        notes: 'Phone: $profilePhone',
      );

      // Save Order to Supabase first (status Pending)
      final saved = await supabase.createOrder(order);
      if (saved == null) {
        throw Exception('Gagal membuat order di database.');
      }

      // If QRIS, Call Midtrans
      if (_method == PaymentMethod.qris) {
        final redirectUrl = await _midtrans.createSnapTransaction(
          order: saved,
          items: _items,
          customerName: profileName,
          customerEmail: saved.userEmail,
          customerPhone: profilePhone,
        );

        if (redirectUrl != null) {
          // Launch URL
          final uri = Uri.parse(redirectUrl);
          if (await canLaunchUrl(uri)) {
            await launchUrl(
              uri,
              mode: LaunchMode.inAppWebView, // Open in-app browser
              webViewConfiguration: const WebViewConfiguration(
                enableJavaScript: true,
                enableDomStorage: true,
              ),
            );
          } else {
            throw Exception('Tidak bisa membuka halaman pembayaran.');
          }
        }
      }

      // Cleanup Cart
      if (Get.isRegistered<UserOrdersController>(tag: 'user-orders')) {
        unawaited(
          Get.find<UserOrdersController>(tag: 'user-orders').fetchMyOrders(),
        );
      }
      try {
        final cart = Get.find<CartController>();
        for (final it in _items) {
          if (it.id != null) await cart.removeItem(it.id!);
        }
      } catch (_) {}

      // Navigate to Success (or Waiting)
      // For QRIS, technically we are "waiting payment", but for UX let's show success "Order Created".
      Get.offAll(
        () => PaymentSuccessScreen(
          orderId: saved.id,
          total: _currentTotal,
          method: _method == PaymentMethod.qris
              ? 'QRIS (Menunggu Pembayaran)'
              : 'COD',
        ),
      );
    } catch (e) {
      Get.snackbar(
        'Error',
        e.toString(),
        snackPosition: SnackPosition.BOTTOM,
        duration: const Duration(seconds: 5),
      );
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  void _showAddressSelection() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _AddressSelectionSheet(
        onSelect: (addr) {
          setState(() {
            _addressController.text = _formatAddress(addr);
          });
        },
      ),
    );
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
                    onTapAddress: _showAddressSelection,
                  ),
                  AppSpacing.vSection,
                  const Text(
                    'Daftar Produk',
                    style: TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
                  ),
                  AppSpacing.vItem,
                  ListView.separated(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: _items.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 16),
                    itemBuilder: (context, index) {
                      final item = _items[index];
                      // Match CartScreen UI Style
                      return Container(
                        decoration: BoxDecoration(
                          color: Theme.of(context).cardColor,
                          borderRadius: BorderRadius.circular(20),
                          boxShadow:
                              Theme.of(context).brightness == Brightness.dark
                              ? null
                              : AppShadows.card,
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(12),
                          child: Row(
                            children: [
                              // Image
                              ClipRRect(
                                borderRadius: BorderRadius.circular(16),
                                child: Image.network(
                                  item.product.image,
                                  height: 80,
                                  width: 80,
                                  fit: BoxFit.cover,
                                  errorBuilder: (context, error, stackTrace) =>
                                      const Icon(
                                        Icons.broken_image,
                                        size: 40,
                                        color: AppColors.softGray,
                                      ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              // Content
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      item.product.name,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: const TextStyle(
                                        fontWeight: FontWeight.w600,
                                        fontSize: 15,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      AppFormatters.rupiah(item.product.price),
                                      style: const TextStyle(
                                        color: AppColors.primaryPink,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 15,
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceBetween,
                                      children: [
                                        Row(
                                          children: [
                                            _MiniStepper(
                                              icon: Icons.remove,
                                              onTap: () =>
                                                  _updateQty(index, -1),
                                            ),
                                            Padding(
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                    horizontal: 12,
                                                  ),
                                              child: Text(
                                                '${item.quantity}',
                                                style: const TextStyle(
                                                  fontWeight: FontWeight.bold,
                                                ),
                                              ),
                                            ),
                                            _MiniStepper(
                                              icon: Icons.add,
                                              onTap: () => _updateQty(index, 1),
                                            ),
                                          ],
                                        ),
                                        const SizedBox(width: 12),
                                        Text(
                                          AppFormatters.rupiah(item.total),
                                          style: const TextStyle(
                                            fontWeight: FontWeight.w700,
                                            fontSize: 14,
                                            color: AppColors.softGray,
                                          ),
                                        ),
                                        const SizedBox(width: 8),
                                        InkWell(
                                          onTap: () => _removeItem(index),
                                          child: const Padding(
                                            padding: EdgeInsets.all(4.0),
                                            child: Icon(
                                              Icons.delete_outline,
                                              color: AppColors.softGray,
                                              size: 20,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),

                  AppSpacing.vSection,
                  const Text(
                    'Metode Pembayaran',
                    style: TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
                  ),
                  AppSpacing.vItem,
                  _PaymentOption(
                    title: 'QRIS',
                    subtitle: 'Scan via QRIS',
                    icon: Icons.qr_code_scanner,
                    selected: _method == PaymentMethod.qris,
                    onTap: () => setState(() => _method = PaymentMethod.qris),
                  ),
                  AppSpacing.vItem,
                  _PaymentOption(
                    title: 'COD (Bayar di Tempat)',
                    subtitle: 'Bayar tunai saat kurir datang',
                    icon: Icons.local_shipping_outlined,
                    selected: _method == PaymentMethod.cod,
                    onTap: () => setState(() => _method = PaymentMethod.cod),
                  ),
                  const SizedBox(height: 24),
                  // Removed Detail Kartu fields
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
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          'Total Pembayaran',
                          style: TextStyle(
                            fontSize: 12,
                            color: AppColors.softGray,
                          ),
                        ),
                        Text(
                          AppFormatters.rupiah(_currentTotal),
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: AppColors.primaryPink,
                          ),
                        ),
                        Text(
                          '${_items.length} item',
                          style: const TextStyle(
                            fontSize: 12,
                            color: AppColors.softGray,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: GradientButton(
                      label: 'Bayar',
                      onPressed: _isSubmitting ? null : _payAndCreateOrder,
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

class _SummaryCard extends StatelessWidget {
  const _SummaryCard({
    required this.nameController,
    required this.addressController,
    required this.phoneController,
    required this.onTapAddress,
  });

  final TextEditingController nameController;
  final TextEditingController addressController;
  final TextEditingController phoneController;
  final VoidCallback onTapAddress;

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
            readOnly: true,
          ),
          AppSpacing.vItem,
          // Make address clearly interactive
          GestureDetector(
            onTap: onTapAddress,
            behavior: HitTestBehavior.opaque,
            child: AbsorbPointer(
              child: TextField(
                controller: addressController,
                decoration: const InputDecoration(
                  labelText: 'Alamat Lengkap',
                  suffixIcon: Icon(
                    Icons.arrow_forward_ios,
                    size: 16,
                    color: AppColors.primaryPink,
                  ),
                ),
                maxLines: 2,
              ),
            ),
          ),
          AppSpacing.vItem,
          TextField(
            controller: phoneController,
            decoration: const InputDecoration(labelText: 'Nomor Telepon'),
            keyboardType: TextInputType.phone,
            readOnly: true,
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

class _AddressSelectionSheet extends StatelessWidget {
  const _AddressSelectionSheet({required this.onSelect});

  final ValueChanged<UserAddress> onSelect;

  @override
  Widget build(BuildContext context) {
    final auth = Get.find<AuthController>();

    return Container(
      height: MediaQuery.of(context).size.height * 0.6,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 20, 24, 10),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Pilih Alamat',
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 16,
                    color: AppColors.charcoal,
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.of(context).pop(),
                  icon: const Icon(Icons.close, size: 20),
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          Expanded(
            child: Obx(() {
              if (auth.addresses.isEmpty) {
                return const Center(child: Text("Belum ada alamat tersimpan"));
              }
              return ListView.separated(
                padding: const EdgeInsets.all(24),
                itemCount: auth.addresses.length,
                separatorBuilder: (_, __) => const SizedBox(height: 12),
                itemBuilder: (context, index) {
                  final addr = auth.addresses[index];
                  final title = addr.label?.isNotEmpty == true
                      ? addr.label!
                      : (addr.city ?? 'Alamat');
                  final fullAddr = [
                    addr.street,
                    addr.city,
                    addr.province,
                  ].whereType<String>().join(', ');

                  return GestureDetector(
                    onTap: () {
                      onSelect(addr);
                      Navigator.pop(context);
                    },
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        border: Border.all(color: AppColors.primaryPinkLight),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.location_on_outlined,
                            color: AppColors.primaryPink,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  title,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                Text(
                                  fullAddr,
                                  style: const TextStyle(
                                    fontSize: 12,
                                    color: AppColors.softGray,
                                  ),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              );
            }),
          ),
          Padding(
            padding: const EdgeInsets.all(24),
            child: SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  side: const BorderSide(color: AppColors.primaryPink),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(999),
                  ),
                ),
                onPressed: () async {
                  Navigator.pop(context); // close selection
                  final result = await showModalBottomSheet<UserAddress?>(
                    context: context,
                    isScrollControlled: true,
                    backgroundColor: Colors.transparent,
                    builder: (_) => const AddressFormSheet(),
                  );
                  if (result != null) {
                    await auth.upsertAddress(result);
                    // Note: auth.addresses is reactive, so list updates automatically.
                    // But we might want to auto-select the new address?
                    onSelect(result); // Auto select the new address
                  }
                },
                icon: const Icon(Icons.add, color: AppColors.primaryPink),
                label: const Text(
                  'Tambah Alamat Baru',
                  style: TextStyle(color: AppColors.primaryPink),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _MiniStepper extends StatelessWidget {
  const _MiniStepper({required this.icon, required this.onTap});

  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.all(4),
        decoration: BoxDecoration(
          color: Theme.of(context).primaryColor.withOpacity(0.1),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: Theme.of(context).primaryColor.withOpacity(0.2),
          ),
        ),
        child: Icon(icon, size: 16, color: Theme.of(context).primaryColor),
      ),
    );
  }
}
