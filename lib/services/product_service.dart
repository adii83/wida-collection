import 'dart:convert';

import 'package:get/get.dart';
import 'package:http/http.dart' as http;

import '../data/dummy_products.dart';
import '../models/product_model.dart';

class ProductService extends GetxService {
  static const _endpoint =
      'https://api.escuelajs.co/api/v1/products?offset=0&limit=40';

  final products = <Product>[].obs;
  final isLoading = false.obs;
  final RxnString lastError = RxnString();

  Future<void>? _inFlight;

  Future<ProductService> init() async {
    await fetchProducts();
    return this;
  }

  Future<List<Product>> fetchProducts({bool forceRefresh = false}) async {
    if (_inFlight != null) {
      await _inFlight;
      return products;
    }
    if (products.isNotEmpty && !forceRefresh) {
      return products;
    }
    _inFlight = _loadFromApi();
    await _inFlight;
    _inFlight = null;
    return products;
  }

  Future<void> refresh() => fetchProducts(forceRefresh: true);

  Product? findById(String id) {
    try {
      return products.firstWhere((product) => product.id == id);
    } catch (_) {
      return null;
    }
  }

  Future<void> _loadFromApi() async {
    if (isLoading.value) return;
    isLoading.value = true;
    lastError.value = null;
    try {
      final uri = Uri.parse(_endpoint);
      final response = await http.get(uri);
      if (response.statusCode >= 200 && response.statusCode < 300) {
        final decoded = jsonDecode(response.body);
        if (decoded is List) {
          final parsed = decoded
              .map<Product?>((item) {
                if (item is Map<String, dynamic>) {
                  return Product.fromJson(item);
                }
                return null;
              })
              .whereType<Product>()
              .where((product) => product.id.isNotEmpty)
              .toList();
          if (parsed.isNotEmpty) {
            products.assignAll(parsed);
            return;
          }
        }
        throw Exception('Format respons tidak sesuai.');
      } else {
        throw Exception('Gagal memuat produk (${response.statusCode}).');
      }
    } catch (e) {
      lastError.value = e.toString();
      if (products.isEmpty) {
        products.assignAll(dummyProducts);
      }
    } finally {
      isLoading.value = false;
    }
  }
}
