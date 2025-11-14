import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controller/wishlist_controller.dart';
import '../controller/auth_controller.dart';
import '../models/product_model.dart';
import 'auth_screen.dart';

class WishlistScreen extends GetView<WishlistController> {
  const WishlistScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = Get.find<AuthController>();
    return Scaffold(
      appBar: AppBar(
        title: const Text('Wishlist & Notifikasi Restock'),
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
                  'Belum ada produk favorit.\nSentuh ikon hati untuk menambahkan.\nLogin/Signup Supabase dulu supaya wishlist Anda tersimpan per akun dan tersinkron.',
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
            return Card(
              child: ListTile(
                leading: item.image.startsWith('assets/')
                    ? Image.asset(item.image, width: 56, fit: BoxFit.cover)
                    : Image.network(item.image, width: 56, fit: BoxFit.cover),
                title: Text(item.name),
                subtitle: Text('Rp ${item.price.toStringAsFixed(0)}'),
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
            );
          },
          separatorBuilder: (_, __) => const SizedBox(height: 12),
          itemCount: controller.wishlist.length,
        );
      }),
    );
  }
}
