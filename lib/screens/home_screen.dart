import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controller/theme_controller.dart';
import '../widgets/animated_banner_implicit.dart';
import '../widgets/animated_banner_explicit.dart';
import '../widgets/responsive_product_grid.dart';
import 'http_product_screen.dart';
import 'dio_product_screen.dart';
import 'theme_settings_screen.dart';
import 'wishlist_screen.dart';
import 'lookbook_screen.dart';
import 'order_tracker_screen.dart';
import 'capsule_planner_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final themeController = Get.find<ThemeController>();

    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        backgroundColor: Theme.of(context).colorScheme.surface,
        elevation: 2,
        title: Image.asset('assets/images/logo.png', height: 40),
        actions: [
          Obx(
            () => IconButton(
              tooltip: 'Pengaturan Tema',
              icon: Icon(
                themeController.themeMode.value == ThemeMode.dark
                    ? Icons.dark_mode
                    : Icons.light_mode,
              ),
              onPressed: () => Get.to(() => const ThemeSettingsScreen()),
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            const SizedBox(height: 8),
            const AnimatedBannerImplicit(),
            const SizedBox(height: 12),
            const AnimatedBannerExplicit(),
            const SizedBox(height: 16),

            // 🔸 Tombol navigasi ke API pages
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                children: [
                  ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      minimumSize: const Size(double.infinity, 48),
                    ),
                    icon: const Icon(Icons.cloud_download),
                    label: const Text('Lihat Produk (HTTP API)'),
                    onPressed: () => Get.to(() => const HttpProductScreen()),
                  ),
                  const SizedBox(height: 8),
                  ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      minimumSize: const Size(double.infinity, 48),
                    ),
                    icon: const Icon(Icons.flash_on),
                    label: const Text('Lihat Produk (Dio API)'),
                    onPressed: () => Get.to(() => const DioProductScreen()),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Koleksi Pilihan',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  Icon(Icons.filter_list),
                ],
              ),
            ),
            const SizedBox(height: 8),

            // 🔸 Home tetap pakai dummy products
            const ResponsiveProductGrid(useController: false),

            const SizedBox(height: 24),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Fitur Penunjang Koleksi',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 12),
                  _ExperimentCard(
                    icon: Icons.favorite_border,
                    title: 'Wishlist & Restock',
                    description:
                        'Simpan produk favorit secara offline via Hive lalu sinkronkan ke Supabase untuk pengingat restock multi-device.',
                    actionLabel: 'Kelola Wishlist',
                    onTap: () => Get.to(() => const WishlistScreen()),
                  ),
                  const SizedBox(height: 12),
                  _ExperimentCard(
                    icon: Icons.style,
                    title: 'Lookbook / Jurnal Gaya',
                    description:
                        'Catat outfit favorit lengkap foto, mood, dan acara menggunakan Hive sehingga tetap tersedia saat offline.',
                    actionLabel: 'Buka Lookbook',
                    onTap: () => Get.to(() => const LookbookScreen()),
                  ),
                  const SizedBox(height: 12),
                  _ExperimentCard(
                    icon: Icons.local_shipping_outlined,
                    title: 'Pelacak Pesanan Cloud',
                    description:
                        'Pantau status order, pembayaran, dan nomor resi yang disimpan di Supabase, cocok untuk simulasi multi-device.',
                    actionLabel: 'Lihat Pesanan',
                    onTap: () => Get.to(() => const OrderTrackerScreen()),
                  ),
                  const SizedBox(height: 12),
                  _ExperimentCard(
                    icon: Icons.event_note,
                    title: 'Perencana Capsule Wardrobe',
                    description:
                        'Rancang mix-and-match mingguan. Data rencana disimpan di Hive sedangkan warna aksen mengikuti shared_preferences.',
                    actionLabel: 'Atur Capsule',
                    onTap: () => Get.to(() => const CapsulePlannerScreen()),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}

class _ExperimentCard extends StatelessWidget {
  const _ExperimentCard({
    required this.icon,
    required this.title,
    required this.description,
    required this.actionLabel,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String description;
  final String actionLabel;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, size: 28),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    title,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(description),
            const SizedBox(height: 12),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton.icon(
                onPressed: onTap,
                icon: const Icon(Icons.arrow_forward),
                label: Text(actionLabel),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
