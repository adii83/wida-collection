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
    final productIdRaw = (normalized['productId'] ?? normalized['product_id'])
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
      productId: (productIdRaw?.isEmpty ?? true) ? null : productIdRaw,
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

  Map<String, dynamic> toJson() => {
    'id': id,
    'title': title,
    'body': body,
    'type': type.name,
    'productId': productId,
    'receivedAt': receivedAt.toIso8601String(),
    'origin': origin.name,
    'data': data,
  };

  String toStorageString() => jsonEncode(toJson());

  factory AppNotification.fromJson(Map<String, dynamic> json) {
    final type = NotificationType.from(json['type']?.toString());
    final originName = json['origin']?.toString();
    final origin = NotificationOrigin.values.firstWhere(
      (item) => item.name == originName,
      orElse: () => NotificationOrigin.foreground,
    );
    final receivedAtRaw = json['receivedAt']?.toString();
    final receivedAt = receivedAtRaw == null
        ? DateTime.now()
        : DateTime.tryParse(receivedAtRaw) ?? DateTime.now();
    final rawData = json['data'];
    final normalizedData = rawData is Map
        ? rawData.map((key, value) => MapEntry(key.toString(), value))
        : <String, dynamic>{};
    final productIdRaw = json['productId']?.toString();
    return AppNotification(
      id:
          json['id']?.toString() ??
          DateTime.now().millisecondsSinceEpoch.toString(),
      title: json['title']?.toString() ?? 'Promo spesial',
      body:
          json['body']?.toString() ??
          'Cek detail promo terbaru di Wida Collection.',
      type: type,
      productId: (productIdRaw?.isEmpty ?? true) ? null : productIdRaw,
      receivedAt: receivedAt,
      data: normalizedData,
      origin: origin,
    );
  }

  factory AppNotification.fromStorageString(String raw) {
    final jsonMap = jsonDecode(raw) as Map<String, dynamic>;
    return AppNotification.fromJson(jsonMap);
  }
}
