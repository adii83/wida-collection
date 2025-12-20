import 'package:flutter/material.dart';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:get/get.dart';

import '../config/design_tokens.dart';
import '../config/layout_values.dart';
import '../controllers/wishlist_controller.dart';
import '../controllers/auth_controller.dart';
import '../controllers/cart_controller.dart';
import '../models/cart_item.dart';
import '../models/product_model.dart';
import '../services/product_service.dart';
import '../widgets/gradient_button.dart';
import '../widgets/product_card.dart';
import '../widgets/rounded_icon_button.dart';
import 'checkout_screen.dart';

class ProductDetailScreen extends StatefulWidget {
  const ProductDetailScreen({super.key, required this.product});

  final Product product;

  @override
  State<ProductDetailScreen> createState() => _ProductDetailScreenState();
}

class _ProductDetailScreenState extends State<ProductDetailScreen> {
  final List<String> sizes = ['S', 'M', 'L'];
  int selectedSizeIndex = 0;
  int quantity = 1;
  late final WishlistController _wishlistController;

  void _changeQuantity(int delta) {
    setState(() {
      quantity = (quantity + delta).clamp(1, 10);
    });
  }

  @override
  void initState() {
    super.initState();
    _wishlistController = Get.find<WishlistController>();
  }

  @override
  Widget build(BuildContext context) {
    final productService = Get.find<ProductService>();
    final similarProducts = productService.products
        .where((p) => p.id != widget.product.id)
        .toList();

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Stack(
                      children: [
                        Hero(
                          tag: widget.product.id,
                          child: () {
                            final src = widget.product.image;
                            if (src.startsWith('http')) {
                              return Image.network(
                                src,
                                height: 360,
                                width: double.infinity,
                                fit: BoxFit.cover,
                              );
                            }
                            if (src.startsWith('assets/')) {
                              return Image.asset(
                                src,
                                height: 360,
                                width: double.infinity,
                                fit: BoxFit.cover,
                              );
                            }

                            final looksLikeLocalFile =
                                !kIsWeb &&
                                (src.startsWith('/') ||
                                    src.contains('\\') ||
                                    src.contains('/data/'));
                            if (looksLikeLocalFile) {
                              return Image.file(
                                File(src),
                                height: 360,
                                width: double.infinity,
                                fit: BoxFit.cover,
                              );
                            }

                            return Image.asset(
                              'assets/images/thrift1.jpg',
                              height: 360,
                              width: double.infinity,
                              fit: BoxFit.cover,
                            );
                          }(),
                        ),
                        Positioned(
                          top: 16,
                          left: 16,
                          child: RoundedIconButton(
                            icon: Icons.arrow_back,
                            onPressed: () => Navigator.of(context).maybePop(),
                          ),
                        ),
                        Positioned(
                          top: 16,
                          right: 16,
                          child: Row(
                            children: [
                              RoundedIconButton(
                                icon: Icons.share,
                                onPressed: () =>
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                        content: Text(
                                          'Link produk disalin ke clipboard!',
                                        ),
                                      ),
                                    ),
                              ),
                              AppSpacing.hItem,
                              Obx(() {
                                final isFavorite = _wishlistController
                                    .isFavorite(widget.product.id);
                                return RoundedIconButton(
                                  icon: isFavorite
                                      ? Icons.favorite
                                      : Icons.favorite_border,
                                  iconColor: isFavorite
                                      ? Colors.white
                                      : AppColors.primaryPink,
                                  backgroundColor: isFavorite
                                      ? AppColors.primaryPink
                                      : Colors.white,
                                  onPressed: () => _wishlistController
                                      .toggleWishlist(widget.product),
                                );
                              }),
                            ],
                          ),
                        ),
                      ],
                    ),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(
                        AppSpacing.page,
                        AppSpacing.section,
                        AppSpacing.page,
                        AppSpacing.section,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.primaryPinkLight.withValues(
                                alpha: 0.4,
                              ),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: const Text(
                              'Excellent',
                              style: TextStyle(
                                color: AppColors.primaryPink,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                          AppSpacing.vItem,
                          Text(
                            widget.product.name,
                            style: Theme.of(context).textTheme.headlineSmall
                                ?.copyWith(fontWeight: FontWeight.w700),
                          ),
                          const SizedBox(height: 4),
                          const Text(
                            'Brand: Vintage Collection',
                            style: TextStyle(color: AppColors.softGray),
                          ),
                          AppSpacing.vItem,
                          Row(
                            children: [
                              Text(
                                'Rp ${widget.product.price.toStringAsFixed(0)}',
                                style: const TextStyle(
                                  fontSize: 22,
                                  color: AppColors.primaryPink,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              AppSpacing.hItem,
                              const Icon(Icons.star, color: Color(0xFFFFC542)),
                              const SizedBox(width: 4),
                              const Text('4.8 (124)'),
                            ],
                          ),
                          const SizedBox(height: 16),
                          const Text(
                            'Dress vintage dengan motif floral yang cantik. Perfect untuk acara casual maupun semi-formal. Kondisi sangat bagus, tidak ada cacat.',
                          ),
                          AppSpacing.vSection,
                          const Text(
                            'Pilih Ukuran',
                            style: TextStyle(fontWeight: FontWeight.w600),
                          ),
                          AppSpacing.vItem,
                          Row(
                            children: List.generate(sizes.length, (index) {
                              final selected = selectedSizeIndex == index;
                              return Padding(
                                padding: EdgeInsets.only(
                                  right: index == sizes.length - 1 ? 0 : 12,
                                ),
                                child: ChoiceChip(
                                  label: Text(sizes[index]),
                                  selected: selected,
                                  onSelected: (_) =>
                                      setState(() => selectedSizeIndex = index),
                                  selectedColor: AppColors.primaryPink,
                                  labelStyle: TextStyle(
                                    color: selected
                                        ? Colors.white
                                        : AppColors.charcoal,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              );
                            }),
                          ),
                          AppSpacing.vSection,
                          const Text(
                            'Jumlah',
                            style: TextStyle(fontWeight: FontWeight.w600),
                          ),
                          AppSpacing.vItem,
                          Row(
                            children: [
                              _StepperButton(
                                icon: Icons.remove,
                                onTap: () => _changeQuantity(-1),
                              ),
                              Padding(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 24,
                                ),
                                child: Text(
                                  '$quantity',
                                  style: const TextStyle(
                                    fontSize: 20,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                              _StepperButton(
                                icon: Icons.add,
                                onTap: () => _changeQuantity(1),
                              ),
                            ],
                          ),
                          AppSpacing.vSection,
                          Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: AppColors.primaryPinkLight.withValues(
                                alpha: 0.3,
                              ),
                              borderRadius: BorderRadius.circular(24),
                            ),
                            child: const Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                _GuaranteeRow(
                                  icon: Icons.local_shipping,
                                  text: 'Free shipping min. Rp 200k',
                                ),
                                SizedBox(height: 8),
                                _GuaranteeRow(
                                  icon: Icons.refresh,
                                  text: '7 hari return guarantee',
                                ),
                                SizedBox(height: 8),
                                _GuaranteeRow(
                                  icon: Icons.verified,
                                  text: 'Quality checked',
                                ),
                              ],
                            ),
                          ),
                          AppSpacing.vSection,
                          Text(
                            'Produk Serupa',
                            style: Theme.of(context).textTheme.titleMedium
                                ?.copyWith(fontWeight: FontWeight.w600),
                          ),
                          AppSpacing.vItem,
                          SizedBox(
                            height: 260,
                            child: ListView.separated(
                              scrollDirection: Axis.horizontal,
                              itemCount: similarProducts.length,
                              padding: const EdgeInsets.only(right: 16),
                              separatorBuilder: (_, __) => AppSpacing.hItem,
                              itemBuilder: (context, index) {
                                final product = similarProducts[index];
                                return SizedBox(
                                  width: 180,
                                  child: ProductCard(
                                    product: product,
                                    badge: index.isEven
                                        ? 'Excellent'
                                        : 'Very Good',
                                    onTap: () =>
                                        Navigator.of(context).pushReplacement(
                                          MaterialPageRoute(
                                            builder: (_) => ProductDetailScreen(
                                              product: product,
                                            ),
                                          ),
                                        ),
                                  ),
                                );
                              },
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            Container(
              padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
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
                    child: OutlinedButton(
                      onPressed: _handleAddToCart,
                      style: OutlinedButton.styleFrom(
                        minimumSize: const Size.fromHeight(52),
                        side: const BorderSide(color: AppColors.primaryPink),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(32),
                        ),
                      ),
                      child: const Text('Add to Cart'),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: GradientButton(
                      label: 'Beli Sekarang',
                      onPressed: () => Get.to(
                        () => CheckoutScreen(
                          items: [
                            CartItem(
                              product: widget.product,
                              quantity: quantity,
                            ),
                          ],
                          subtotal: widget.product.price * quantity,
                        ),
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

  void _handleAddToCart() {
    final cart = Get.find<CartController>();
    final auth = Get.find<AuthController>();
    cart.addItem(widget.product, quantity: quantity);
    final userId = auth.currentUser.value?.id;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          userId != null
              ? 'Ditambahkan ke keranjang (tersinkronisasi bila online)'
              : 'Ditambahkan ke keranjang (disimpan lokal)',
        ),
      ),
    );
  }
}

class _StepperButton extends StatelessWidget {
  const _StepperButton({required this.icon, required this.onTap});

  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            border: Border.all(
              color: AppColors.primaryPinkLight.withValues(alpha: 0.5),
            ),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Icon(icon, color: AppColors.primaryPink),
        ),
      ),
    );
  }
}

class _GuaranteeRow extends StatelessWidget {
  const _GuaranteeRow({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, color: AppColors.primaryPink),
        AppSpacing.hItem,
        Expanded(child: Text(text)),
      ],
    );
  }
}
