import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/product_model.dart';

class ProductServiceHttp {
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
        final response = await http.get(Uri.parse(url));

        if (response.statusCode == 200) {
          final data = jsonDecode(response.body)['products'] as List;
          final products = data.map((json) => Product.fromJson(json)).toList();
          allProducts.addAll(products);
        } else {
          print('HTTP error: ${response.statusCode} at $url');
        }
      }

      stopwatch.stop();
      print('HTTP Load Time: ${stopwatch.elapsedMilliseconds} ms');
      return allProducts;
    } catch (e) {
      print('HTTP Exception: $e');
      return [];
    }
  }
}
