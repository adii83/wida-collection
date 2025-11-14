import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import '../models/product_model.dart';

class ProductServiceDio {
  final Dio _dio = Dio()
    ..interceptors.add(
      LogInterceptor(request: true, responseBody: false, error: true),
    )
    ..interceptors.add(
      InterceptorsWrapper(
        onError: (e, handler) {
          // Logging terpusat
          debugPrint('DIO onError: ${e.response?.statusCode} ${e.message}');
          return handler.next(e);
        },
      ),
    );
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
          debugPrint('DIO error: ${response.statusCode} at $url');
        }
      }

      stopwatch.stop();
      debugPrint('DIO Load Time: ${stopwatch.elapsedMilliseconds} ms');
      return allProducts;
    } catch (e) {
      debugPrint('DIO Exception: $e');
      return [];
    }
  }
}
