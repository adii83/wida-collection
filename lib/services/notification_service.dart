import 'dart:async';
import 'dart:convert';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:googleapis_auth/auth_io.dart';
import 'package:get/get.dart';

import '../config/design_tokens.dart';
import '../config/firebase_options.dart';
import '../models/app_notification.dart';

typedef RemoteMessageCallback =
    FutureOr<void> Function(RemoteMessage message, NotificationOrigin origin);
typedef PayloadCallback =
    FutureOr<void> Function(
      Map<String, dynamic> payload,
      NotificationOrigin origin,
    );

const AndroidNotificationChannel defaultChannel = AndroidNotificationChannel(
  'default_channel',
  'General Notifications',
  description: 'Saluran utama untuk semua notifikasi aplikasi.',
  importance: Importance.max,
  playSound: true,
  sound: RawResourceAndroidNotificationSound('notif'),
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
      await androidImpl.createNotificationChannel(defaultChannel);
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
      defaultChannel.id,
      defaultChannel.name,
      channelDescription: defaultChannel.description,
      importance: Importance.max,
      priority: Priority.high,
      playSound: true,
      sound: defaultChannel.sound,
      ticker: 'Wida Collection',
      icon: '@mipmap/ic_launcher',
      largeIcon: const DrawableResourceAndroidBitmap('@mipmap/ic_launcher'),
      color: AppColors.primaryPink,
    );

    final iosDetails = DarwinNotificationDetails(
      interruptionLevel: InterruptionLevel.timeSensitive,
      sound: 'notif.mp3',
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
      defaultChannel.id,
      defaultChannel.name,
      channelDescription: defaultChannel.description,
      importance: Importance.high,
      priority: Priority.high,
      playSound: true,
      sound: defaultChannel.sound,
      icon: '@mipmap/ic_launcher',
      largeIcon: const DrawableResourceAndroidBitmap('@mipmap/ic_launcher'),
      color: AppColors.primaryPink,
    );

    final iosDetails = const DarwinNotificationDetails(sound: 'notif.mp3');

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
      await androidImpl.createNotificationChannel(defaultChannel);
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
          defaultChannel.id,
          defaultChannel.name,
          channelDescription: defaultChannel.description,
          importance: Importance.max,
          priority: Priority.high,
          playSound: true,
          sound: defaultChannel.sound,
          icon: '@mipmap/ic_launcher',
          largeIcon: const DrawableResourceAndroidBitmap('@mipmap/ic_launcher'),
          color: AppColors.primaryPink,
        ),
        iOS: const DarwinNotificationDetails(sound: 'notif.mp3'),
      ),
      payload: jsonEncode(payload),
    );
  } // --- SENDER LOGIC (Admin Feature) ---
  // This essentially makes the app act as a Server/Backend.
  // Requires 'assets/config/service-account.json' to be present.

  Future<bool> sendFCMV1Message({
    required List<String>
    targetTokens, // If empty, sending to topic 'all' via condition if needed? Or just loop.
    required String title,
    required String body,
    Map<String, dynamic>? data,
    String? predefinedTopic, // e.g. 'all_users'
  }) async {
    try {
      final jsonString = await rootBundle.loadString(
        'assets/config/service-account.json',
      );
      final jsonMap = jsonDecode(jsonString);
      final credentials = ServiceAccountCredentials.fromJson(jsonString);
      final projectId = jsonMap['project_id']; // Manual extraction

      final client = await clientViaServiceAccount(credentials, [
        'https://www.googleapis.com/auth/firebase.messaging',
      ]);

      final fcmEndpoint =
          'https://fcm.googleapis.com/v1/projects/$projectId/messages:send';

      // FCM V1 unfortunately doesn't support "multicast" (array of tokens) natively in one HTTP call like Legacy.
      // We must loop or use topic.
      // Strategy:
      // - If topic is provided, send to topic.
      // - If tokens provided, loop and send.

      if (predefinedTopic != null) {
        await _sendSingleV1(
          client,
          fcmEndpoint,
          title,
          body,
          data,
          topic: predefinedTopic,
        );
      } else {
        // Send to each token
        // In production, this should be batched or queued. For < 100 users demo, simple loop is fine.
        for (final token in targetTokens) {
          await _sendSingleV1(
            client,
            fcmEndpoint,
            title,
            body,
            data,
            token: token,
          );
        }
      }

      client.close();
      return true;
    } catch (e) {
      debugPrint('FCM Sender Error: $e');
      return false;
    }
  }

  Future<void> _sendSingleV1(
    AuthClient client,
    String endpoint,
    String title,
    String body,
    Map<String, dynamic>? data, {
    String? token,
    String? topic,
  }) async {
    final message = {
      'message': {
        if (token != null) 'token': token,
        if (topic != null) 'topic': topic,
        // We use data-only payload so we can manually display the notification
        // with our custom sound and logic via onBackgroundMessage handler.
        'data': {
          'title': title,
          'body': body,
          ...?data, // spread any extra data
        },
      },
    };

    final response = await client.post(
      Uri.parse(endpoint),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(message),
    );

    if (response.statusCode == 200) {
      debugPrint('FCM Sent to ${token ?? topic}');
    } else {
      debugPrint('FCM Failed: ${response.statusCode} ${response.body}');
    }
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
