import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../config/design_tokens.dart';
import '../config/layout_values.dart';
import '../data/dummy_products.dart';
import '../models/product_model.dart';
import '../widgets/product_card.dart';
import 'product_detail_screen.dart';

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final TextEditingController _controller = TextEditingController();
  String _query = '';
  String _selectedFilter = 'All';

  List<Product> get _filteredProducts {
    final lower = _query.toLowerCase();
    return dummyProducts.where((product) {
      final matchQuery = product.name.toLowerCase().contains(lower);
      final matchFilter = _selectedFilter == 'All'
          ? true
          : product.name.toLowerCase().contains(_selectedFilter.toLowerCase());
      return matchQuery && matchFilter;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final filters = ['All', 'Dress', 'Jacket', 'Sweater', 'Jeans'];

    return SafeArea(
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
                AppSpacing.vSection,
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: filters.map((filter) {
                      final selected = _selectedFilter == filter;
                      return Padding(
                        padding: const EdgeInsets.only(right: 12),
                        child: ChoiceChip(
                          label: Text(filter),
                          selected: selected,
                          onSelected: (_) =>
                              setState(() => _selectedFilter = filter),
                          selectedColor: AppColors.primaryPink,
                          labelStyle: TextStyle(
                            color: selected ? Colors.white : AppColors.charcoal,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ],
            ),
          ),
          AppSpacing.vSection,
          Expanded(
            child: Padding(
              padding: AppSpacing.pagePadding,
              child: GridView.builder(
                itemCount: _filteredProducts.length,
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  mainAxisSpacing: 16,
                  crossAxisSpacing: 16,
                  childAspectRatio: 0.72,
                ),
                itemBuilder: (context, index) {
                  final product = _filteredProducts[index];
                  return ProductCard(
                    product: product,
                    onTap: () =>
                        Get.to(() => ProductDetailScreen(product: product)),
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}
