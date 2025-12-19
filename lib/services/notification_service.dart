import 'dart:async';
import 'dart:convert';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:get/get.dart';

import '../config/firebase_options.dart';
import '../models/app_notification.dart';

typedef RemoteMessageCallback =
    FutureOr<void> Function(RemoteMessage message, NotificationOrigin origin);
typedef PayloadCallback =
    FutureOr<void> Function(
      Map<String, dynamic> payload,
      NotificationOrigin origin,
    );

const AndroidNotificationChannel promoStatusChannel =
    AndroidNotificationChannel(
      'promo_status_channel',
      'Promo & Order Alerts',
      description: 'Heads-up notifications for promos dan status pesanan.',
      importance: Importance.max,
      playSound: true,
      sound: RawResourceAndroidNotificationSound('natal'),
    );

const AndroidNotificationChannel customLabChannel = AndroidNotificationChannel(
  'custom_lab_channel',
  'Custom Notification',
  description: 'Notifikasi lokal dari Custom Notification.',
  importance: Importance.high,
  playSound: true,
  sound: RawResourceAndroidNotificationSound('gopgopgop'),
);

class NotificationService extends GetxService {
  NotificationService();

  final FlutterLocalNotificationsPlugin _localNotifications =
      FlutterLocalNotificationsPlugin();

  int _toSigned32(String source) {
    final hash = source.hashCode & 0x7fffffff;
    if (hash == 0) {
      return DateTime.now().millisecondsSinceEpoch ~/ 1000;
    }
    return hash;
  }

  RemoteMessageCallback? _onRemoteMessage;
  PayloadCallback? _onPayloadTap;
  bool _localReady = false;
  final List<_PendingTapPayload> _pendingTapPayloads = [];

  Future<NotificationService> init() async {
    await _ensureFirebase();
    await _configureLocalNotifications();
    await _configureFirebaseMessaging();
    return this;
  }

  void bindCallbacks({
    required RemoteMessageCallback onRemoteMessage,
    required PayloadCallback onPayloadTap,
  }) {
    _onRemoteMessage = onRemoteMessage;
    _onPayloadTap = onPayloadTap;
    _drainPendingTapPayloads();
  }

  Future<String?> fetchFcmToken() => FirebaseMessaging.instance.getToken();

  Future<void> _ensureFirebase() async {
    if (Firebase.apps.isNotEmpty) return;
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
  }

  Future<void> _configureLocalNotifications() async {
    if (_localReady) return;
    const androidSettings = AndroidInitializationSettings(
      '@mipmap/ic_launcher',
    );
    final iosSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
      notificationCategories: const [],
    );

    await _localNotifications.initialize(
      InitializationSettings(android: androidSettings, iOS: iosSettings),
      onDidReceiveNotificationResponse: _handleNotificationResponse,
      onDidReceiveBackgroundNotificationResponse: notificationTapBackground,
    );

    final androidImpl = _localNotifications
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >();
    if (androidImpl != null) {
      await androidImpl.createNotificationChannel(promoStatusChannel);
      await androidImpl.createNotificationChannel(customLabChannel);
    }
    _localReady = true;
  }

  Future<void> _configureFirebaseMessaging() async {
    FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);

    final messaging = FirebaseMessaging.instance;
    final settings = await messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
      provisional: false,
    );
    debugPrint(
      'Notification permission status: ${settings.authorizationStatus}',
    );

    await messaging.setForegroundNotificationPresentationOptions(
      alert: true,
      sound: true,
      badge: true,
    );

    FirebaseMessaging.onMessage.listen((RemoteMessage message) async {
      debugPrint('FCM Payload (foreground): ${jsonEncode(message.data)}');
      _onRemoteMessage?.call(message, NotificationOrigin.foreground);
      await _showLocalNotification(message);
    });

    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      debugPrint('FCM Payload (opened): ${jsonEncode(message.data)}');
      final payload = _buildPayload(message);
      _enqueueTapPayload(payload, NotificationOrigin.tap);
    });

    final initialMessage = await messaging.getInitialMessage();
    if (initialMessage != null) {
      debugPrint('FCM Payload (initial): ${jsonEncode(initialMessage.data)}');
      final payload = _buildPayload(initialMessage);
      _enqueueTapPayload(payload, NotificationOrigin.tap);
    }
  }

  Map<String, dynamic> _buildPayload(RemoteMessage message) {
    final payload = <String, dynamic>{
      ...message.data,
      if (message.notification?.title != null)
        'title': message.notification!.title,
      if (message.notification?.body != null)
        'body': message.notification!.body,
    };
    payload['id'] =
        message.messageId ??
        payload['id'] ??
        DateTime.now().millisecondsSinceEpoch.toString();
    return payload;
  }

  Future<void> _showLocalNotification(RemoteMessage message) async {
    if (!_localReady) {
      await _configureLocalNotifications();
    }
    final payload = jsonEncode(_buildPayload(message));
    final androidDetails = AndroidNotificationDetails(
      promoStatusChannel.id,
      promoStatusChannel.name,
      channelDescription: promoStatusChannel.description,
      importance: Importance.max,
      priority: Priority.high,
      playSound: true,
      sound: promoStatusChannel.sound,
      ticker: 'Promo Update',
      icon: '@mipmap/ic_launcher',
    );

    final iosDetails = DarwinNotificationDetails(
      interruptionLevel: InterruptionLevel.timeSensitive,
      sound: 'natal.mp3',
    );

    await _localNotifications.show(
      DateTime.now().millisecondsSinceEpoch ~/ 1000,
      message.notification?.title ?? message.data['title']?.toString(),
      message.notification?.body ?? message.data['body']?.toString(),
      NotificationDetails(android: androidDetails, iOS: iosDetails),
      payload: payload,
    );
  }

  Future<void> showCustomLocalNotification({
    required String id,
    required String title,
    required String body,
    Map<String, dynamic>? data,
  }) async {
    if (!_localReady) {
      await _configureLocalNotifications();
    }
    final mergedPayload = {...?data, 'id': id, 'title': title, 'body': body};
    final encodedPayload = jsonEncode(mergedPayload);

    final androidDetails = AndroidNotificationDetails(
      customLabChannel.id,
      customLabChannel.name,
      channelDescription: customLabChannel.description,
      importance: Importance.high,
      priority: Priority.high,
      playSound: true,
      sound: customLabChannel.sound,
      icon: '@mipmap/ic_launcher',
    );

    final iosDetails = const DarwinNotificationDetails(sound: 'gopgopgop.mp3');

    final notificationId = _toSigned32(id);

    await _localNotifications.show(
      notificationId,
      title,
      body,
      NotificationDetails(android: androidDetails, iOS: iosDetails),
      payload: encodedPayload,
    );
  }

  void _handleNotificationResponse(NotificationResponse response) {
    if (response.payload == null) return;
    final payload = AppNotification.decodePayload(response.payload);
    if (payload.isEmpty) return;
    _enqueueTapPayload(payload, NotificationOrigin.tap);
  }

  void _enqueueTapPayload(
    Map<String, dynamic> payload,
    NotificationOrigin origin,
  ) {
    if (_onPayloadTap != null) {
      Future.microtask(() => _onPayloadTap?.call(payload, origin));
    } else {
      _pendingTapPayloads.add(_PendingTapPayload(payload, origin));
    }
  }

  void _drainPendingTapPayloads() {
    if (_onPayloadTap == null || _pendingTapPayloads.isEmpty) return;
    final pending = List<_PendingTapPayload>.from(_pendingTapPayloads);
    _pendingTapPayloads.clear();
    for (final item in pending) {
      _onPayloadTap?.call(item.payload, item.origin);
    }
  }

  /// Entry point used by the background isolate to display local notifications.
  static Future<void> showBackgroundNotification(RemoteMessage message) async {
    final plugin = FlutterLocalNotificationsPlugin();
    const androidSettings = AndroidInitializationSettings(
      '@mipmap/ic_launcher',
    );
    final iosSettings = DarwinInitializationSettings();
    await plugin.initialize(
      InitializationSettings(android: androidSettings, iOS: iosSettings),
    );
    final androidImpl = plugin
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >();
    if (androidImpl != null) {
      await androidImpl.createNotificationChannel(promoStatusChannel);
      await androidImpl.createNotificationChannel(customLabChannel);
    }
    final payload = <String, dynamic>{
      ...message.data,
      if (message.notification?.title != null)
        'title': message.notification!.title,
      if (message.notification?.body != null)
        'body': message.notification!.body,
    };
    await plugin.show(
      DateTime.now().millisecondsSinceEpoch ~/ 1000,
      message.notification?.title ?? payload['title']?.toString(),
      message.notification?.body ?? payload['body']?.toString(),
      NotificationDetails(
        android: AndroidNotificationDetails(
          promoStatusChannel.id,
          promoStatusChannel.name,
          channelDescription: promoStatusChannel.description,
          importance: Importance.max,
          priority: Priority.high,
          playSound: true,
          sound: promoStatusChannel.sound,
          icon: '@mipmap/ic_launcher',
        ),
        iOS: const DarwinNotificationDetails(sound: 'natal.mp3'),
      ),
      payload: jsonEncode(payload),
    );
  }
}

class _PendingTapPayload {
  _PendingTapPayload(this.payload, this.origin);

  final Map<String, dynamic> payload;
  final NotificationOrigin origin;
}

@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  debugPrint('FCM Payload (background): ${jsonEncode(message.data)}');
  await NotificationService.showBackgroundNotification(message);
}

@pragma('vm:entry-point')
void notificationTapBackground(NotificationResponse response) {
  debugPrint(
    'Notification tapped in background with payload: ${response.payload}',
  );
}
