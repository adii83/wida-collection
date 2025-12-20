import 'package:get/get.dart';
import '../models/admin_user.dart';
import '../models/product_model.dart';
import '../services/admin_service.dart';
import '../services/supabase_service.dart';

class AdminController extends GetxController {
  AdminController(this._adminService);

  final AdminService _adminService;

  final Rxn<AdminUser> currentAdmin = Rxn<AdminUser>();
  final isLoading = false.obs;
  final RxnString lastError = RxnString();

  bool get isLoggedIn => currentAdmin.value != null;
  bool get canManageProducts => currentAdmin.value?.canManageProducts ?? false;
  bool get isSuperAdmin => currentAdmin.value?.isSuperAdmin ?? false;

  @override
  void onInit() {
    super.onInit();
    _syncFromSession();

    // Keep in sync if sign-in/out happens elsewhere (e.g. AuthScreen/AuthController)
    if (Get.isRegistered<SupabaseService>()) {
      final supabase = Get.find<SupabaseService>();
      supabase.authStateChanges.listen((_) {
        _syncFromSession();
      });
    }
  }

  Future<void> _syncFromSession() async {
    final admin = await _adminService.getCurrentAdmin();
    currentAdmin.value = admin;
  }

  Future<bool> login(String email, String password) async {
    try {
      isLoading.value = true;
      lastError.value = null;

      final admin = await _adminService.adminLogin(email, password);
      if (admin != null) {
        currentAdmin.value = admin;
        Get.snackbar(
          'Login Berhasil',
          'Selamat datang, ${admin.name}!',
          snackPosition: SnackPosition.BOTTOM,
        );
        return true;
      } else {
        lastError.value = 'Email atau password salah';
        Get.snackbar(
          'Login Gagal',
          'Email atau password salah',
          snackPosition: SnackPosition.BOTTOM,
        );
        return false;
      }
    } catch (e) {
      lastError.value = e.toString();
      Get.snackbar(
        'Error',
        'Terjadi kesalahan: $e',
        snackPosition: SnackPosition.BOTTOM,
      );
      return false;
    } finally {
      isLoading.value = false;
    }
  }

  void logout() {
    currentAdmin.value = null;
    _adminService.adminLogout();
    Get.snackbar(
      'Logout',
      'Anda telah keluar dari admin panel',
      snackPosition: SnackPosition.BOTTOM,
    );
  }

  // Product Management
  Future<bool> addProduct(Product product) async {
    if (!canManageProducts) {
      Get.snackbar(
        'Akses Ditolak',
        'Anda tidak memiliki izin untuk menambah produk',
      );
      return false;
    }

    try {
      isLoading.value = true;
      final success = await _adminService.addProduct(product);
      if (success) {
        Get.snackbar('Sukses', 'Produk berhasil ditambahkan');
        return true;
      }
      Get.snackbar('Gagal', 'Gagal menambahkan produk');
      return false;
    } catch (e) {
      Get.snackbar('Gagal', e.toString());
      return false;
    } finally {
      isLoading.value = false;
    }
  }

  Future<bool> updateProduct(Product product) async {
    if (!canManageProducts) {
      Get.snackbar(
        'Akses Ditolak',
        'Anda tidak memiliki izin untuk mengupdate produk',
      );
      return false;
    }

    try {
      isLoading.value = true;
      final success = await _adminService.updateProduct(product);
      if (success) {
        Get.snackbar('Sukses', 'Produk berhasil diupdate');
        return true;
      }
      Get.snackbar('Gagal', 'Gagal mengupdate produk');
      return false;
    } catch (e) {
      Get.snackbar('Gagal', e.toString());
      return false;
    } finally {
      isLoading.value = false;
    }
  }

  Future<bool> deleteProduct(String productId) async {
    if (!canManageProducts) {
      Get.snackbar(
        'Akses Ditolak',
        'Anda tidak memiliki izin untuk menghapus produk',
      );
      return false;
    }

    try {
      isLoading.value = true;
      final success = await _adminService.deleteProduct(productId);
      if (success) {
        Get.snackbar('Sukses', 'Produk berhasil dihapus');
        return true;
      } else {
        Get.snackbar('Gagal', 'Gagal menghapus produk');
        return false;
      }
    } finally {
      isLoading.value = false;
    }
  }

  // Notification Management
  Future<bool> sendNotification({
    required String title,
    required String body,
    String? targetUserId,
    Map<String, dynamic>? data,
  }) async {
    try {
      isLoading.value = true;
      final success = await _adminService.sendCustomNotification(
        title: title,
        body: body,
        targetUserId: targetUserId,
        data: data,
      );
      if (success) {
        Get.snackbar('Sukses', 'Notifikasi berhasil dikirim');
        return true;
      } else {
        Get.snackbar('Gagal', 'Gagal mengirim notifikasi');
        return false;
      }
    } finally {
      isLoading.value = false;
    }
  }

  // Statistics
  Future<Map<String, dynamic>> getStatistics() async {
    return await _adminService.getAdminStatistics();
  }
}
