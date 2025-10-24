import 'package:get/get.dart';
import '../models/product_model.dart';
import '../services/product_service_http.dart';
import '../services/product_service_dio.dart';

class ProductController extends GetxController {
  final products = <Product>[].obs;
  final isLoading = false.obs;
  final useDio = false.obs; // ganti ke true untuk pakai Dio

  final _httpService = ProductServiceHttp();
  final _dioService = ProductServiceDio();

  Future<void> fetchProducts() async {
    try {
      isLoading.value = true;
      List<Product> result = [];

      if (useDio.value) {
        result = await _dioService.fetchProducts();
      } else {
        result = await _httpService.fetchProducts();
      }

      products.assignAll(result);
    } finally {
      isLoading.value = false;
    }
  }
}
