import 'package:get/get.dart';
import '../models/order_model.dart';
import '../services/supabase_service.dart';
import 'auth_controller.dart';

class OrderController extends GetxController {
  OrderController(this._supabaseService, this._authController);

  final SupabaseService _supabaseService;
  final AuthController _authController;

  final orders = <OrderModel>[].obs;
  final isLoading = false.obs;

  bool get canUseCloud =>
      _supabaseService.isReady && _authController.isLoggedIn;

  @override
  void onInit() {
    super.onInit();
    ever(_authController.currentUser, (_) => loadOrders());
    if (canUseCloud) {
      loadOrders();
    }
  }

  Future<void> loadOrders() async {
    if (!canUseCloud) {
      orders.clear();
      return;
    }
    try {
      isLoading.value = true;
      final data = await _supabaseService.fetchOrders(
        _authController.currentUser.value!.id,
      );
      orders.assignAll(data);
    } finally {
      isLoading.value = false;
    }
  }
}
