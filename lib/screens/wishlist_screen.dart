import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/wishlist_controller.dart';
import '../utils/formatters.dart';
import '../controllers/auth_controller.dart';
import '../models/product_model.dart';
import 'auth_screen.dart';
import 'product_detail_screen.dart';

class WishlistScreen extends GetView<WishlistController> {
  const WishlistScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = Get.find<AuthController>();
    return Scaffold(
      appBar: AppBar(
        title: const Text('Wishlist'),
        actions: [
          Obx(
            () => auth.isLoggedIn
                ? IconButton(
                    tooltip: 'Sinkron Ulang',
                    onPressed: controller.canSync
                        ? () => controller.syncFromCloud()
                        : null,
                    icon: controller.isSyncing.value
                        ? const SizedBox(
                            height: 16,
                            width: 16,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.refresh),
                  )
                : IconButton(
                    tooltip: 'Masuk untuk sinkronisasi',
                    onPressed: () => Get.to(() => const AuthScreen()),
                    icon: const Icon(Icons.lock_outline),
                  ),
          ),
        ],
      ),
      body: Obx(() {
        if (controller.wishlist.isEmpty) {
          return Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: const [
                Icon(Icons.favorite_border, size: 64),
                SizedBox(height: 12),
                Text(
                  'Belum ada produk favorit.\nSentuh ikon hati untuk menambahkan.',
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          );
        }

        return ListView.separated(
          padding: const EdgeInsets.all(16),
          itemBuilder: (context, index) {
            final item = controller.wishlist[index];
            return GestureDetector(
              onTap: () {
                // Construct a temporary Product object for detail screen
                final product = Product(
                  id: item.productId,
                  name: item.name,
                  image: item.image,
                  price: item.price,
                  description: '', // Will load or default in detail screen
                  category: '', // Unknown
                );
                Get.to(() => ProductDetailScreen(product: product));
              },
              child: Card(
                child: ListTile(
                  leading: item.image.startsWith('assets/')
                      ? Image.asset(item.image, width: 56, fit: BoxFit.cover)
                      : Image.network(item.image, width: 56, fit: BoxFit.cover),
                  title: Text(item.name),
                  subtitle: Text(AppFormatters.rupiah(item.price)),
                  trailing: IconButton(
                    icon: const Icon(Icons.delete_outline),
                    onPressed: () => controller.toggleWishlist(
                      Product(
                        id: item.productId,
                        name: item.name,
                        image: item.image,
                        price: item.price,
                      ),
                    ),
                  ),
                ),
              ),
            );
          },
          separatorBuilder: (_, __) => const SizedBox(height: 12),
          itemCount: controller.wishlist.length,
        );
      }),
    );
  }
}
