class RefundModel {
  final String id;
  final String orderId;
  final String userId;
  final String userName;
  final double refundAmount;
  final String reason;
  final String status; // 'pending', 'approved', 'rejected', 'processed'
  final DateTime requestedAt;
  final DateTime? processedAt;
  final String? adminNotes;
  final String? processedBy;

  RefundModel({
    required this.id,
    required this.orderId,
    required this.userId,
    required this.userName,
    required this.refundAmount,
    required this.reason,
    required this.status,
    required this.requestedAt,
    this.processedAt,
    this.adminNotes,
    this.processedBy,
  });

  factory RefundModel.fromJson(Map<String, dynamic> json) {
    return RefundModel(
      id: json['id'] as String,
      orderId: json['order_id'] as String,
      userId: json['user_id'] as String,
      userName: json['user_name'] as String? ?? 'Guest',
      refundAmount: (json['refund_amount'] as num).toDouble(),
      reason: json['reason'] as String,
      status: json['status'] as String? ?? 'pending',
      requestedAt: DateTime.parse(json['requested_at'] as String),
      processedAt: json['processed_at'] != null
          ? DateTime.parse(json['processed_at'] as String)
          : null,
      adminNotes: json['admin_notes'] as String?,
      processedBy: json['processed_by'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'order_id': orderId,
      'user_id': userId,
      'user_name': userName,
      'refund_amount': refundAmount,
      'reason': reason,
      'status': status,
      'requested_at': requestedAt.toIso8601String(),
      'processed_at': processedAt?.toIso8601String(),
      'admin_notes': adminNotes,
      'processed_by': processedBy,
    };
  }

  RefundModel copyWith({
    String? status,
    DateTime? processedAt,
    String? adminNotes,
    String? processedBy,
  }) {
    return RefundModel(
      id: id,
      orderId: orderId,
      userId: userId,
      userName: userName,
      refundAmount: refundAmount,
      reason: reason,
      status: status ?? this.status,
      requestedAt: requestedAt,
      processedAt: processedAt ?? this.processedAt,
      adminNotes: adminNotes ?? this.adminNotes,
      processedBy: processedBy ?? this.processedBy,
    );
  }
}
