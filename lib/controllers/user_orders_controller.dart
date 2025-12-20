import 'package:get/get.dart';

import '../models/order_model.dart';
import '../services/supabase_service.dart';

class UserOrdersController extends GetxController {
  UserOrdersController(this._supabase);

  final SupabaseService _supabase;

  final orders = <OrderModel>[].obs;
  final isLoading = false.obs;
  final error = RxnString();

  @override
  void onInit() {
    super.onInit();
    fetchMyOrders();
  }

  Future<void> fetchMyOrders() async {
    final userId = _supabase.currentUserId;
    if (userId == null) {
      orders.clear();
      error.value = 'Harus login untuk melihat pesanan.';
      return;
    }

    try {
      isLoading.value = true;
      error.value = null;
      final data = await _supabase.fetchMyOrders(userId: userId);
      orders.assignAll(data);
    } catch (e) {
      orders.clear();
      error.value = e.toString();
    } finally {
      isLoading.value = false;
    }
  }

  Future<bool> confirmOrderReceived(String orderId) async {
    final userId = _supabase.currentUserId;
    if (userId == null || userId.isEmpty) {
      error.value = 'Harus login untuk konfirmasi pesanan.';
      return false;
    }

    try {
      isLoading.value = true;
      error.value = null;

      final ok = await _supabase.confirmOrderReceived(
        orderId: orderId,
        userId: userId,
      );

      if (ok) {
        await fetchMyOrders();
      }
      return ok;
    } catch (e) {
      error.value = e.toString();
      return false;
    } finally {
      isLoading.value = false;
    }
  }
}
