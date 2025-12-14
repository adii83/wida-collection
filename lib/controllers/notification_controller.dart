import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:get/get.dart';

import '../data/dummy_products.dart';
import '../models/app_notification.dart';
import '../models/product_model.dart';
import '../routes/app_routes.dart';
import '../screens/product_detail_screen.dart';
import '../services/notification_service.dart';

class NotificationController extends GetxController {
  NotificationController(this._service);

  final NotificationService _service;
  final notifications = <AppNotification>[].obs;
  final RxBool permissionGranted = false.obs;
  final RxnString fcmToken = RxnString();
  final RxBool isCustomNotifying = false.obs;

  @override
  void onInit() {
    super.onInit();
    _service.bindCallbacks(
      onRemoteMessage: _handleRemoteMessage,
      onPayloadTap: _handlePayloadTap,
    );
    _refreshPermissionStatus();
    refreshFcmToken();
  }

  Future<void> refreshFcmToken() async {
    final token = await _service.fetchFcmToken();
    fcmToken.value = token;
  }

  Future<void> _refreshPermissionStatus() async {
    final settings = await FirebaseMessaging.instance.getNotificationSettings();
    permissionGranted.value =
        settings.authorizationStatus == AuthorizationStatus.authorized ||
        settings.authorizationStatus == AuthorizationStatus.provisional;
  }

  void _handleRemoteMessage(RemoteMessage message, NotificationOrigin origin) {
    final entry = AppNotification.fromRemoteMessage(message, origin);
    _insert(entry);
  }

  void _handlePayloadTap(
    Map<String, dynamic> payload,
    NotificationOrigin origin,
  ) {
    final entry = AppNotification.fromPayload(payload, origin);
    _insert(entry);
    _navigate(entry);
  }

  void _insert(AppNotification entry) {
    final existingIndex = notifications.indexWhere(
      (item) => item.id == entry.id,
    );
    if (existingIndex >= 0) {
      notifications[existingIndex] = entry;
      notifications.refresh();
    } else {
      notifications.insert(0, entry);
    }
  }

  void openEntry(AppNotification entry) => _navigate(entry);

  void _navigate(AppNotification entry) {
    if (entry.type == NotificationType.promo && entry.productId != null) {
      final product = _findProduct(entry.productId!);
      if (product != null) {
        Get.to(() => ProductDetailScreen(product: product));
        return;
      }
    }

    if (entry.type == NotificationType.orderStatus) {
      Get.snackbar(
        'Status Pesanan',
        entry.body,
        snackPosition: SnackPosition.BOTTOM,
      );
    }
    Get.toNamed(AppRoutes.notificationCenter);
  }

  Future<void> triggerCustomNotification() async {
    if (isCustomNotifying.value) return;
    const title = 'Custom Notification';
    const body = 'Ini custom notification dengan suara khusus 💫.';
    const customType = NotificationType.unknown;
    final id = DateTime.now().millisecondsSinceEpoch.toString();
    final payload = <String, dynamic>{
      'id': id,
      'title': title,
      'body': body,
      'type': customType.name,
      'origin': 'local',
      'channel': 'custom_lab',
    };

    try {
      isCustomNotifying.value = true;
      await _service.showCustomLocalNotification(
        id: id,
        title: title,
        body: body,
        data: payload,
      );
      final entry = AppNotification(
        id: id,
        title: title,
        body: body,
        type: customType,
        productId: null,
        receivedAt: DateTime.now(),
        data: payload,
        origin: NotificationOrigin.foreground,
      );
      _insert(entry);
    } catch (e) {
      Get.snackbar(
        'Gagal mengirim notifikasi',
        e.toString(),
        snackPosition: SnackPosition.BOTTOM,
      );
    } finally {
      isCustomNotifying.value = false;
    }
  }

  Product? _findProduct(String id) {
    for (final product in dummyProducts) {
      if (product.id == id) return product;
    }
    return null;
  }
}
