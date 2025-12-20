import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../config/layout_values.dart';
import '../models/product_model.dart';
import '../widgets/product_card.dart';
import 'product_detail_screen.dart';
import '../services/product_service.dart';

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key, this.initialCategory});

  final String? initialCategory;

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final TextEditingController _controller = TextEditingController();
  String _query = '';
  late final ProductService _productService;

  @override
  void initState() {
    super.initState();
    _productService = Get.find<ProductService>();
    final initial = (widget.initialCategory ?? '').trim();
    if (initial.isNotEmpty) {
      _query = initial;
      _controller.text = initial;
    }
  }

  List<Product> _filteredProducts(List<Product> source) {
    final lower = _query.toLowerCase();
    if (lower.trim().isEmpty) return source;
    return source.where((product) {
      final matchQuery =
          product.name.toLowerCase().contains(lower) ||
          product.resolvedCategory.toLowerCase().contains(lower);
      return matchQuery;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.page,
                AppSpacing.heroTop,
                AppSpacing.page,
                0,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Cari Koleksi',
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text('Temukan item thrift favoritmu dengan cepat'),
                  AppSpacing.vSection,
                  TextField(
                    controller: _controller,
                    decoration: const InputDecoration(
                      hintText: 'Cari nama produk atau kategori',
                      prefixIcon: Icon(Icons.search),
                    ),
                    onChanged: (value) => setState(() => _query = value),
                  ),
                  const SizedBox(height: 4),
                ],
              ),
            ),
            AppSpacing.vSection,
            Expanded(
              child: Padding(
                padding: AppSpacing.pagePadding,
                child: Obx(() {
                  final products = _productService.products;
                  final filtered = _filteredProducts(products);
                  if (_productService.isLoading.value && products.isEmpty) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  if (filtered.isEmpty) {
                    final message = _productService.lastError.value;
                    return Center(
                      child: Text(
                        message == null
                            ? 'Produk tidak ditemukan'
                            : 'Gagal memuat produk: $message',
                        textAlign: TextAlign.center,
                      ),
                    );
                  }
                  return GridView.builder(
                    itemCount: filtered.length,
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
                          mainAxisSpacing: 16,
                          crossAxisSpacing: 16,
                          childAspectRatio: 0.72,
                        ),
                    itemBuilder: (context, index) {
                      final product = filtered[index];
                      return ProductCard(
                        product: product,
                        onTap: () =>
                            Get.to(() => ProductDetailScreen(product: product)),
                      );
                    },
                  );
                }),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
