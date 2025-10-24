import 'package:flutter/material.dart';
import '../widgets/animated_banner_implicit.dart';
import '../widgets/animated_banner_explicit.dart';
import '../widgets/responsive_product_grid.dart';
import 'http_product_screen.dart';
import 'dio_product_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        backgroundColor: Colors.white,
        elevation: 2,
        title: Image.asset('assets/images/logo.png', height: 40),
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
                      backgroundColor: Colors.pink.shade100,
                      minimumSize: const Size(double.infinity, 48),
                    ),
                    icon: const Icon(Icons.cloud_download),
                    label: const Text('Lihat Produk (HTTP API)'),
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const HttpProductScreen(),
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 8),
                  ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.pink.shade200,
                      minimumSize: const Size(double.infinity, 48),
                    ),
                    icon: const Icon(Icons.flash_on),
                    label: const Text('Lihat Produk (Dio API)'),
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const DioProductScreen(),
                        ),
                      );
                    },
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
          ],
        ),
      ),
    );
  }
}
