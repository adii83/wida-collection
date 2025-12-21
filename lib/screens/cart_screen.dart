import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../config/design_tokens.dart';
import '../utils/formatters.dart';
import '../config/layout_values.dart';
import '../models/cart_item.dart';
import '../models/product_model.dart';
import '../models/cart_item_model.dart';
import '../controllers/cart_controller.dart';
import '../widgets/gradient_button.dart';
import '../widgets/rounded_icon_button.dart';
import 'checkout_screen.dart';

class CartScreen extends StatefulWidget {
  const CartScreen({super.key});

  @override
  State<CartScreen> createState() => _CartScreenState();
}

class _CartScreenState extends State<CartScreen> {
  late final CartController _cart;

  @override
  void initState() {
    super.initState();
    _cart = Get.find<CartController>();
    // Jika ada item tapi belum ada yang dipilih, pilih semua secara default
    if (_cart.items.isNotEmpty && _cart.selectedIds.isEmpty) {
      _cart.selectedIds.addAll(_cart.items.map((i) => i.id));
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: SafeArea(
        child: Column(
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.page,
                AppSpacing.heroTop,
                AppSpacing.page,
                0,
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Keranjang',
                    style: theme.textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  Obx(
                    () => RoundedIconButton(
                      icon: Icons.delete_outline,
                      onPressed: _cart.selectedIds.isEmpty
                          ? null
                          : () {
                              _cart.clearCart();
                              _cart.selectedIds.clear();
                            },
                    ),
                  ),
                ],
              ),
            ),

            // List Items
            Obx(() {
              // Force dependency on selection changes to ensure UI updates
              // ignore: unused_local_variable
              final _ = _cart.selectedIds.length;

              if (_cart.items.isEmpty) {
                return const Expanded(
                  child: Center(
                    child: Text(
                      'Keranjang masih kosong nih. Yuk tambah produk!',
                    ),
                  ),
                );
              }
              return Expanded(
                child: ListView.separated(
                  padding: const EdgeInsets.fromLTRB(
                    AppSpacing.page,
                    AppSpacing.section,
                    AppSpacing.page,
                    AppSpacing.section + 80,
                  ),
                  itemCount: _cart.items.length,
                  separatorBuilder: (context, index) => AppSpacing.vItem,
                  itemBuilder: (context, index) {
                    final item = _cart.items[index];
                    // Fix: Construct Product manually since fromCartItem doesn't exist
                    final product = Product(
                      id: item.productId,
                      name: item.name,
                      image: item.image,
                      price: item.price,
                    );
                    final isSelected = _cart.isSelected(item.id);

                    return Container(
                      key: ValueKey(item.id),
                      decoration: BoxDecoration(
                        color: scheme.surface,
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: isDark ? null : AppShadows.card,
                      ),
                      child: Row(
                        children: [
                          // Checkbox Section
                          Padding(
                            padding: const EdgeInsets.only(left: 4, right: 0),
                            child: Transform.scale(
                              scale: 1.1,
                              child: Checkbox(
                                value: isSelected,
                                activeColor: AppColors.primaryPink,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                side: const BorderSide(
                                  color: AppColors.softGray,
                                  width: 1.5,
                                ),
                                onChanged: (_) => _cart.toggleItem(item.id),
                              ),
                            ),
                          ),
                          // Vertical Divider
                          Container(
                            height: 60,
                            width: 1,
                            color: AppColors.softGray.withValues(alpha: 0.2),
                          ),
                          // Product Content
                          Expanded(
                            child: Padding(
                              padding: const EdgeInsets.all(12),
                              child: Row(
                                children: [
                                  ClipRRect(
                                    borderRadius: BorderRadius.circular(16),
                                    child: product.isAssetImage
                                        ? Image.asset(
                                            product.image,
                                            height: 80,
                                            width: 80,
                                            fit: BoxFit.cover,
                                          )
                                        : Image.network(
                                            product.image,
                                            height: 80,
                                            width: 80,
                                            fit: BoxFit.cover,
                                            errorBuilder:
                                                (context, error, stackTrace) =>
                                                    const Icon(
                                                      Icons.broken_image,
                                                    ),
                                          ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          product.name,
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                          style: theme.textTheme.titleMedium
                                              ?.copyWith(
                                                fontWeight: FontWeight.w600,
                                                fontSize: 15,
                                              ),
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          AppFormatters.rupiah(product.price),
                                          style: theme.textTheme.titleMedium
                                              ?.copyWith(
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
                                            _MiniStepper(
                                              onTap: () => _cart.updateQuantity(
                                                item.id,
                                                item.quantity - 1,
                                              ),
                                              icon: Icons.remove,
                                            ),
                                            Padding(
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                    horizontal: 8,
                                                  ),
                                              child: Text(
                                                '${item.quantity}',
                                                style: theme
                                                    .textTheme
                                                    .bodyMedium
                                                    ?.copyWith(
                                                      fontWeight:
                                                          FontWeight.bold,
                                                    ),
                                              ),
                                            ),
                                            _MiniStepper(
                                              onTap: () => _cart.updateQuantity(
                                                item.id,
                                                item.quantity + 1,
                                              ),
                                              icon: Icons.add,
                                            ),
                                            const Spacer(),
                                            InkWell(
                                              onTap: () =>
                                                  _cart.removeItem(item.id),
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
                          ),
                        ],
                      ),
                    );
                  },
                ),
              );
            }),

            // Bottom Bar Summary
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: scheme.surface,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 10,
                    offset: const Offset(0, -4),
                  ),
                ],
              ),
              child: SafeArea(
                top: false,
                child: Column(
                  children: [
                    // Select All Row
                    Obx(() {
                      // Force dependency
                      // ignore: unused_local_variable
                      final _ = _cart.selectedIds.length;

                      final allSelected =
                          _cart.items.isNotEmpty &&
                          _cart.selectedIds.length == _cart.items.length;
                      return Row(
                        children: [
                          Checkbox(
                            value: allSelected,
                            activeColor: AppColors.primaryPink,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(4),
                            ),
                            side: const BorderSide(
                              color: AppColors.softGray,
                              width: 1.5,
                            ),
                            onChanged: (_) => _cart.toggleAll(),
                          ),
                          Text(
                            'Pilih Semua',
                            style: theme.textTheme.titleSmall?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const Spacer(),
                          Text(
                            'Total',
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: AppColors.softGray,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            AppFormatters.rupiah(_cart.selectedSubtotal),
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.w700,
                              color: AppColors.primaryPink,
                              fontSize: 18,
                            ),
                          ),
                        ],
                      );
                    }),
                    const SizedBox(height: 16),
                    Obx(
                      () => GradientButton(
                        onPressed: _cart.selectedSubtotal > 0
                            ? () {
                                final selectedModels = _cart.items
                                    .where(
                                      (i) => _cart.selectedIds.contains(i.id),
                                    )
                                    .toList();

                                // Fix: Map CartItemModel to CartItem (for Checkout)
                                final checkoutItems = selectedModels.map((m) {
                                  return CartItem(
                                    id: m
                                        .id, // Pass the ID for interactivity in Checkout
                                    product: Product(
                                      id: m.productId,
                                      name: m.name,
                                      image: m.image,
                                      price: m.price,
                                    ),
                                    quantity: m.quantity,
                                  );
                                }).toList();

                                Get.to(
                                  () => CheckoutScreen(
                                    items: checkoutItems,
                                    subtotal: _cart.selectedSubtotal,
                                  ),
                                );
                              }
                            : null,
                        label:
                            'Checkout (${AppFormatters.rupiah(_cart.selectedSubtotal)})',
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MiniStepper extends StatelessWidget {
  const _MiniStepper({required this.onTap, required this.icon});

  final VoidCallback onTap;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 28,
        width: 28,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(8),
          color: AppColors.primaryPink.withOpacity(0.1),
        ),
        child: Icon(icon, size: 16, color: AppColors.primaryPink),
      ),
    );
  }
}
