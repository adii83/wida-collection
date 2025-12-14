import 'dart:convert';

import 'package:firebase_messaging/firebase_messaging.dart';

enum NotificationType {
  promo,
  orderStatus,
  unknown;

  static NotificationType from(String? raw) {
    switch (raw?.toLowerCase()) {
      case 'promo':
      case 'promotion':
        return NotificationType.promo;
      case 'order':
      case 'order_status':
      case 'status':
        return NotificationType.orderStatus;
      default:
        return NotificationType.unknown;
    }
  }
}

enum NotificationOrigin { foreground, background, tap }

class AppNotification {
  AppNotification({
    required this.id,
    required this.title,
    required this.body,
    required this.type,
    required this.receivedAt,
    required this.data,
    required this.origin,
    this.productId,
  });

  final String id;
  final String title;
  final String body;
  final NotificationType type;
  final DateTime receivedAt;
  final Map<String, dynamic> data;
  final NotificationOrigin origin;
  final String? productId;

  factory AppNotification.fromRemoteMessage(
    RemoteMessage message,
    NotificationOrigin origin,
  ) {
    final payload = <String, dynamic>{
      ...message.data,
      if (message.notification?.title != null)
        'title': message.notification!.title,
      if (message.notification?.body != null)
        'body': message.notification!.body,
    };
    return AppNotification.fromPayload(
      payload,
      origin,
      idOverride: message.messageId,
    );
  }

  factory AppNotification.fromPayload(
    Map<String, dynamic> data,
    NotificationOrigin origin, {
    String? idOverride,
  }) {
    final normalized = Map<String, dynamic>.from(data);
    final type = NotificationType.from(normalized['type']?.toString());
    final productId = (normalized['productId'] ?? normalized['product_id'])
        ?.toString();
    final title = normalized['title']?.toString() ?? 'Promo spesial';
    final body =
        normalized['body']?.toString() ??
        'Cek detail promo terbaru di Wida Collection.';
    final id =
        idOverride ??
        normalized['id']?.toString() ??
        DateTime.now().millisecondsSinceEpoch.toString();
    return AppNotification(
      id: id,
      title: title,
      body: body,
      type: type,
      productId: productId?.isEmpty == true ? null : productId,
      receivedAt: DateTime.now(),
      data: normalized,
      origin: origin,
    );
  }

  String encodePayload() => jsonEncode({
    'id': id,
    'title': title,
    'body': body,
    'type': type.name,
    'productId': productId,
    'data': data,
  });

  static Map<String, dynamic> decodePayload(String? payload) {
    if (payload == null || payload.isEmpty) return <String, dynamic>{};
    return jsonDecode(payload) as Map<String, dynamic>;
  }
}
