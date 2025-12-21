import 'dart:async';

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:get/get.dart';
import 'package:hive/hive.dart';
import 'auth_controller.dart';

import '../models/app_notification.dart';
import '../models/product_model.dart';
import '../screens/auth_gate.dart';
import '../screens/product_detail_screen.dart';
import '../services/notification_service.dart';
import '../services/product_service.dart';

class NotificationController extends GetxController {
  NotificationController(this._service, this._productService);

  final NotificationService _service;
  final ProductService _productService;
  // Inject AuthController lazily to avoid circular dependency issues during init if not careful,
  // but Get.find is usually safe if AuthController is initialized before.
  AuthController get _auth => Get.find<AuthController>();

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

    // Work: Sync token when user logs in
    ever(_auth.currentUser, (user) {
      if (user != null && fcmToken.value != null) {
        _auth.syncFcmToken(fcmToken.value!);
      }
    });

    // Work: Sync token when token refreshes
    ever(fcmToken, (token) {
      if (token != null && _auth.isLoggedIn) {
        _auth.syncFcmToken(token);
      }
    });
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

  int get unreadCount => notifications.where((n) => !n.isRead).length;

  void markAsRead(String notificationId) {
    final index = notifications.indexWhere((n) => n.id == notificationId);
    if (index != -1) {
      final entry = notifications[index];
      if (!entry.isRead) {
        final updated = entry.copyWith(isRead: true);
        notifications[index] = updated;
        notifications.refresh();
        _persist(updated);
      }
    }
  }

  void markAllAsRead() {
    for (var i = 0; i < notifications.length; i++) {
      if (!notifications[i].isRead) {
        notifications[i] = notifications[i].copyWith(isRead: true);
      }
    }
    notifications.refresh();
    // Re-persist all (optimization: could be smarter, but simple for now)
    for (var entry in notifications) {
      _persist(entry);
    }
  }

  void _insert(AppNotification entry) {
    final existingIndex = notifications.indexWhere(
      (item) => item.id == entry.id,
    );
    if (existingIndex >= 0) {
      // If updating, preserve isRead status unless explicitly new
      // But typically an update means "new info", so maybe mark unread?
      // For now, let's assume valid updates are "new" -> unread.
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

  AppNotification? _deferredNotification;

  void _navigate(AppNotification entry) {
    if (Get.context == null) {
      // App not ready (e.g. terminated state launch), defer navigation
      _deferredNotification = entry;
      return;
    }

    // Mark as read immediately when actioned
    markAsRead(entry.id);

    // Navigate to product detail if productId is present, regardless of type
    if (entry.productId != null) {
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
    // Default fallback: Go to Home (AuthGate handles redirection to Home or Admin Dashboard)
    // User requested "langsung ke home jangan halaman notif"
    Get.offAll(() => const AuthGate());
  }

  void consumeDeferredNotification() {
    if (_deferredNotification != null) {
      final entry = _deferredNotification!;
      _deferredNotification = null;
      // Small delay to ensure route stability if called from init
      Future.delayed(const Duration(milliseconds: 500), () {
        _navigate(entry);
      });
    }
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
