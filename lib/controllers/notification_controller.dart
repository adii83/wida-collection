import 'dart:async';

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:get/get.dart';
import 'package:hive/hive.dart';

import '../models/app_notification.dart';
import '../models/product_model.dart';
import '../routes/app_routes.dart';
import '../screens/product_detail_screen.dart';
import '../services/notification_service.dart';
import '../services/product_service.dart';

class NotificationController extends GetxController {
  NotificationController(this._service, this._productService);

  final NotificationService _service;
  final ProductService _productService;
  final notifications = <AppNotification>[].obs;
  final RxBool permissionGranted = false.obs;
  final RxnString fcmToken = RxnString();
  final RxBool isCustomNotifying = false.obs;
  static const _historyBoxName = 'notification_history';
  Box<String>? _historyBox;
  bool _historyReady = false;
  final List<AppNotification> _pendingHistoryWrites = [];

  @override
  void onInit() {
    super.onInit();
    _initHistory();
    _service.bindCallbacks(
      onRemoteMessage: _handleRemoteMessage,
      onPayloadTap: _handlePayloadTap,
    );
    _refreshPermissionStatus();
    refreshFcmToken();
  }

  Future<void> _initHistory() async {
    _historyBox = await Hive.openBox<String>(_historyBoxName);
    _historyReady = true;
    final cached = _historyBox!.values
        .map(AppNotification.fromStorageString)
        .toList();
    final merged = <AppNotification>[];
    final seenIds = <String>{};
    void addEntry(AppNotification entry) {
      if (seenIds.add(entry.id)) {
        merged.add(entry);
      }
    }

    for (final entry in cached) {
      addEntry(entry);
    }
    for (final entry in notifications) {
      addEntry(entry);
    }
    merged.sort((a, b) => b.receivedAt.compareTo(a.receivedAt));
    notifications.assignAll(merged);
    if (_pendingHistoryWrites.isNotEmpty) {
      for (final entry in List<AppNotification>.from(_pendingHistoryWrites)) {
        await _persist(entry);
      }
      _pendingHistoryWrites.clear();
    }
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
    if (_historyReady) {
      unawaited(_persist(entry));
    } else {
      _pendingHistoryWrites
        ..removeWhere((pending) => pending.id == entry.id)
        ..add(entry);
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

  Future<void> clearAllNotifications() async {
    notifications.clear();
    await _historyBox?.clear();
    Get.snackbar(
      'Riwayat dibersihkan',
      'Semua notifikasi telah dihapus.',
      snackPosition: SnackPosition.BOTTOM,
    );
  }

  Future<void> _persist(AppNotification entry) async {
    await _historyBox?.put(entry.id, entry.toStorageString());
  }

  Product? _findProduct(String id) {
    return _productService.findById(id);
  }
}
