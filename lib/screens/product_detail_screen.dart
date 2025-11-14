import 'package:flutter/material.dart';
import '../models/product_model.dart';
import 'package:winda_collection/screens/home_screen.dart';

class ProductDetailScreen extends StatelessWidget {
  final Product product;

  const ProductDetailScreen({super.key, required this.product});

  /// 🔙 Fungsi helper untuk navigasi kembali dengan fallback ke Home
  void _goBack(BuildContext context) {
    if (Navigator.of(context).canPop()) {
      Navigator.of(context).pop();
    } else {
      Navigator.of(
        context,
      ).pushReplacement(MaterialPageRoute(builder: (_) => const HomeScreen()));
    }
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
        _goBack(context);
      },
      child: Scaffold(
        appBar: AppBar(
          automaticallyImplyLeading: false, // kita pakai custom BackButton
          leading: BackButton(onPressed: () => _goBack(context)),
          title: Text(product.name),
        ),
        body: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Hero(
              tag: product.id,
              child: product.image.startsWith('http')
                  ? Image.network(
                      product.image,
                      height: 300,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stack) => const Icon(
                        Icons.broken_image,
                        size: 120,
                        color: Colors.grey,
                      ),
                    )
                  : Image.asset(product.image, height: 300, fit: BoxFit.cover),
            ),
            const SizedBox(height: 16),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    product.name,
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    'Rp ${product.price.toStringAsFixed(0)}',
                    style: const TextStyle(fontSize: 18, color: Colors.pink),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Deskripsi produk thrift ini sangat unik, bahan masih bagus, '
                    'cocok untuk tampilan vintage dan casual!',
                    style: TextStyle(fontSize: 16),
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
