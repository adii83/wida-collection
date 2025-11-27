import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../config/design_tokens.dart';
import '../config/layout_values.dart';
import '../data/dummy_products.dart';
import '../models/cart_item.dart';
import '../widgets/gradient_button.dart';
import '../widgets/rounded_icon_button.dart';
import 'checkout_screen.dart';

class CartScreen extends StatefulWidget {
  const CartScreen({super.key});

  @override
  State<CartScreen> createState() => _CartScreenState();
}

class _CartScreenState extends State<CartScreen> {
  final List<CartItem> _items = [
    CartItem(product: dummyProducts[0], quantity: 1),
    CartItem(product: dummyProducts[1], quantity: 2),
    CartItem(product: dummyProducts[2], quantity: 1),
  ];

  double get subtotal => _items.fold(0, (sum, item) => sum + item.total);

  void _updateQuantity(int index, int delta) {
    setState(() {
      _items[index].quantity = (_items[index].quantity + delta).clamp(1, 10);
    });
  }

  void _removeItem(int index) {
    setState(() => _items.removeAt(index));
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;
    return SafeArea(
      child: Container(
        color: theme.scaffoldBackgroundColor,
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
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Keranjang',
                    style: theme.textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  RoundedIconButton(
                    icon: Icons.delete_outline,
                    onPressed: _items.isEmpty
                        ? null
                        : () => setState(() => _items.clear()),
                  ),
                ],
              ),
            ),
            if (_items.isEmpty)
              const Expanded(
                child: Center(
                  child: Text('Keranjang masih kosong nih. Yuk tambah produk!'),
                ),
              )
            else
              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.fromLTRB(
                    AppSpacing.page,
                    AppSpacing.section,
                    AppSpacing.page,
                    AppSpacing.section,
                  ),
                  itemCount: _items.length,
                  itemBuilder: (context, index) {
                    final item = _items[index];
                    return Container(
                      margin: const EdgeInsets.only(bottom: 16),
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: scheme.surface,
                        borderRadius: BorderRadius.circular(24),
                        boxShadow: isDark ? null : AppShadows.card,
                      ),
                      child: Row(
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(18),
                            child: item.product.isAssetImage
                                ? Image.asset(
                                    item.product.image,
                                    height: 90,
                                    width: 90,
                                    fit: BoxFit.cover,
                                  )
                                : Image.network(
                                    item.product.image,
                                    height: 90,
                                    width: 90,
                                    fit: BoxFit.cover,
                                    errorBuilder:
                                        (context, error, stackTrace) =>
                                            const Icon(Icons.broken_image),
                                  ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  item.product.name,
                                  style: theme.textTheme.titleMedium?.copyWith(
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'Rp ${item.product.price.toStringAsFixed(0)}',
                                  style: theme.textTheme.titleMedium?.copyWith(
                                    color: AppColors.primaryPink,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                AppSpacing.vItem,
                                Row(
                                  children: [
                                    _MiniStepper(
                                      onTap: () => _updateQuantity(index, -1),
                                      icon: Icons.remove,
                                    ),
                                    Padding(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 12,
                                      ),
                                      child: Text(
                                        '${item.quantity}',
                                        style: theme.textTheme.bodyMedium
                                            ?.copyWith(
                                              fontWeight: FontWeight.bold,
                                            ),
                                      ),
                                    ),
                                    _MiniStepper(
                                      onTap: () => _updateQuantity(index, 1),
                                      icon: Icons.add,
                                    ),
                                    const Spacer(),
                                    IconButton(
                                      onPressed: () => _removeItem(index),
                                      icon: const Icon(
                                        Icons.close,
                                        color: AppColors.softGray,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
            Container(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.page,
                AppSpacing.section,
                AppSpacing.page,
                AppSpacing.section,
              ),
              decoration: BoxDecoration(
                color: scheme.surface,
                boxShadow: [
                  BoxShadow(
                    color: (isDark ? Colors.black : Colors.black).withValues(
                      alpha: isDark ? 0.35 : 0.12,
                    ),
                    blurRadius: 20,
                    offset: const Offset(0, -8),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Subtotal',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: AppColors.softGray,
                        ),
                      ),
                      Text(
                        'Rp ${subtotal.toStringAsFixed(0)}',
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Biaya Pengiriman',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: AppColors.softGray,
                        ),
                      ),
                      Text(
                        'Free',
                        style: theme.textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w700,
                          color: AppColors.primaryPink,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  GradientButton(
                    label: 'Checkout',
                    onPressed: _items.isEmpty
                        ? null
                        : () => Get.to(
                            () => CheckoutScreen(
                              items: _items,
                              subtotal: subtotal,
                            ),
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

class _MiniStepper extends StatelessWidget {
  const _MiniStepper({required this.onTap, required this.icon});

  final VoidCallback onTap;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 32,
        width: 32,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: AppColors.primaryPinkLight.withValues(alpha: 0.6),
          ),
        ),
        child: Icon(icon, size: 18, color: AppColors.primaryPink),
      ),
    );
  }
}
