import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controller/product_controller.dart';
import '../data/dummy_products.dart';
import '../models/product_model.dart';
import '../screens/product_detail_screen.dart';

class ResponsiveProductGrid extends StatelessWidget {
  const ResponsiveProductGrid({
    super.key,
    this.products,
    this.useController = true,
  });

  final List<Product>? products;
  final bool useController;

  @override
  Widget build(BuildContext context) {
    final ProductController? controller = useController
        ? (Get.isRegistered<ProductController>()
              ? Get.find<ProductController>()
              : Get.put(ProductController()))
        : null;
    final screenWidth = MediaQuery.of(context).size.width;
    final crossAxisCount = screenWidth < 600 ? 2 : 4;

    Widget buildGrid(List<Product> productsToShow, double itemWidth) {
      return GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: productsToShow.length,
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: crossAxisCount,
          mainAxisSpacing: 12,
          crossAxisSpacing: 12,
          childAspectRatio: itemWidth / 230,
        ),
        itemBuilder: (context, index) {
          final product = productsToShow[index];
          final isAsset = product.image.startsWith('assets/');

          return GestureDetector(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => ProductDetailScreen(product: product),
                ),
              );
            },
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Hero(
                  tag: product.id,
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: isAsset
                        ? Image.asset(
                            product.image,
                            width: double.infinity,
                            height: 140,
                            fit: BoxFit.cover,
                          )
                        : Image.network(
                            product.image,
                            width: double.infinity,
                            height: 140,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) =>
                                const Icon(Icons.broken_image, size: 80),
                          ),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  product.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                Text('Rp ${product.price.toStringAsFixed(0)}'),
              ],
            ),
          );
        },
      );
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final itemWidth = (constraints.maxWidth - 16) / crossAxisCount;

          if (!useController) {
            final data = products ?? dummyProducts;
            return buildGrid(data, itemWidth);
          }

          return Obx(() {
            final data = controller!.products.isEmpty
                ? dummyProducts
                : controller.products;
            return buildGrid(data, itemWidth);
          });
        },
      ),
    );
  }
}
