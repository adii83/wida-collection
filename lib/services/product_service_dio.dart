import 'package:dio/dio.dart';
import '../models/product_model.dart';

class ProductServiceDio {
  final Dio _dio = Dio();
  final List<String> endpoints = [
    'https://dummyjson.com/products/category/mens-shirts',
    'https://dummyjson.com/products/category/womens-dresses',
    'https://dummyjson.com/products/category/womens-shoes',
  ];

  Future<List<Product>> fetchProducts() async {
    final stopwatch = Stopwatch()..start();
    final List<Product> allProducts = [];

    try {
      for (final url in endpoints) {
        final response = await _dio.get(url);
        if (response.statusCode == 200) {
          final data = response.data['products'] as List;
          final products = data.map((json) => Product.fromJson(json)).toList();
          allProducts.addAll(products);
        } else {
          print('Dio Error: ${response.statusCode} at $url');
        }
      }

      stopwatch.stop();
      print('DIO Load Time: ${stopwatch.elapsedMilliseconds} ms');
      return allProducts;
    } catch (e) {
      print('DIO Exception: $e');
      return [];
    }
  }
}
