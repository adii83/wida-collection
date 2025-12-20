import 'package:get/get.dart';
import '../models/order_model.dart';
import '../models/refund_model.dart';
import '../services/admin_service.dart';
import 'admin_controller.dart';

class OrderController extends GetxController {
  OrderController(this._adminService);

  final AdminService _adminService;

  final orders = <OrderModel>[].obs;
  final refunds = <RefundModel>[].obs;
  final isLoading = false.obs;
  final lastOrdersError = RxnString();
  final lastRefundsError = RxnString();
  final selectedFilter =
      'all'.obs; // all, pending, processing, shipped, delivered

  @override
  void onInit() {
    super.onInit();
    fetchOrders();
    fetchRefunds();
  }

  List<OrderModel> get filteredOrders {
    if (selectedFilter.value == 'all') return orders;
    return orders.where((o) => o.status == selectedFilter.value).toList();
  }

  Future<void> fetchOrders() async {
    try {
      isLoading.value = true;
      lastOrdersError.value = null;
      final data = await _adminService.fetchAllOrders();
      orders.assignAll(data);
    } catch (e) {
      lastOrdersError.value = e.toString();
      orders.clear();
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> fetchRefunds() async {
    try {
      isLoading.value = true;
      lastRefundsError.value = null;
      final data = await _adminService.fetchAllRefunds();
      refunds.assignAll(data);
    } catch (e) {
      lastRefundsError.value = e.toString();
      refunds.clear();
    } finally {
      isLoading.value = false;
    }
  }

  Future<bool> updateOrderStatus(
    String orderId,
    String status, {
    String? trackingNumber,
    String? notes,
  }) async {
    try {
      isLoading.value = true;
      final success = await _adminService.updateOrderStatus(
        orderId,
        status,
        trackingNumber: trackingNumber,
        notes: notes,
      );

      if (success) {
        await fetchOrders();
        Get.snackbar(
          'Sukses',
          'Status order berhasil diupdate',
          snackPosition: SnackPosition.BOTTOM,
        );
        return true;
      } else {
        Get.snackbar(
          'Gagal',
          'Gagal mengupdate status order',
          snackPosition: SnackPosition.BOTTOM,
        );
        return false;
      }
    } finally {
      isLoading.value = false;
    }
  }

  Future<bool> updatePaymentStatus(String orderId, String paymentStatus) async {
    try {
      isLoading.value = true;
      final success = await _adminService.updatePaymentStatus(
        orderId,
        paymentStatus,
      );

      if (success) {
        await fetchOrders();
        Get.snackbar(
          'Sukses',
          'Status pembayaran berhasil diupdate',
          snackPosition: SnackPosition.BOTTOM,
        );
        return true;
      } else {
        Get.snackbar(
          'Gagal',
          'Gagal mengupdate status pembayaran',
          snackPosition: SnackPosition.BOTTOM,
        );
        return false;
      }
    } finally {
      isLoading.value = false;
    }
  }

  Future<bool> processRefund(
    String refundId,
    String status, {
    String? adminNotes,
  }) async {
    final adminController = Get.find<AdminController>();
    final adminId = adminController.currentAdmin.value?.id ?? '';

    try {
      isLoading.value = true;
      final success = await _adminService.processRefund(
        refundId,
        status,
        adminId,
        adminNotes: adminNotes,
      );

      if (success) {
        await fetchRefunds();
        await fetchOrders();
        Get.snackbar(
          'Sukses',
          'Refund berhasil diproses',
          snackPosition: SnackPosition.BOTTOM,
        );
        return true;
      } else {
        Get.snackbar(
          'Gagal',
          'Gagal memproses refund',
          snackPosition: SnackPosition.BOTTOM,
        );
        return false;
      }
    } finally {
      isLoading.value = false;
    }
  }

  void setFilter(String filter) {
    selectedFilter.value = filter;
  }
}
