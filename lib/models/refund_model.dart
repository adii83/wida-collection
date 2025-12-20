class RefundModel {
  final String id;
  final String orderId;
  final String userId;
  final double refundAmount;
  final String reason;
  final String status; // 'pending', 'approved', 'rejected', 'processed'
  final DateTime requestedAt;
  final DateTime? processedAt;
  final String? adminNotes;
  final String? processedBy;
  final String? imageProofUrl;

  RefundModel({
    required this.id,
    required this.orderId,
    required this.userId,
    required this.refundAmount,
    required this.reason,
    required this.status,
    required this.requestedAt,
    this.processedAt,
    this.adminNotes,
    this.processedBy,
    this.imageProofUrl,
  });

  factory RefundModel.fromJson(Map<String, dynamic> json) {
    final amountRaw = json['amount'];
    final amount = (amountRaw is num)
        ? amountRaw.toDouble()
        : double.tryParse(amountRaw?.toString() ?? '') ?? 0.0;

    return RefundModel(
      id: json['id'].toString(),
      orderId: json['order_id'].toString(),
      userId: json['user_id'].toString(),
      refundAmount: amount,
      reason: json['reason'] as String,
      status: (json['status'] as String?) ?? 'pending',
      requestedAt: DateTime.parse(json['requested_at'].toString()),
      processedAt: json['processed_at'] != null
          ? DateTime.tryParse(json['processed_at'].toString())
          : null,
      adminNotes: json['admin_notes'] as String?,
      processedBy: json['processed_by']?.toString(),
      imageProofUrl: json['image_proof_url'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'order_id': orderId,
      'user_id': userId,
      'amount': refundAmount,
      'reason': reason,
      'status': status,
      'requested_at': requestedAt.toIso8601String(),
      'processed_at': processedAt?.toIso8601String(),
      'admin_notes': adminNotes,
      'processed_by': processedBy,
      'image_proof_url': imageProofUrl,
    };
  }

  RefundModel copyWith({
    String? status,
    DateTime? processedAt,
    String? adminNotes,
    String? processedBy,
    String? imageProofUrl,
  }) {
    return RefundModel(
      id: id,
      orderId: orderId,
      userId: userId,
      refundAmount: refundAmount,
      reason: reason,
      status: status ?? this.status,
      requestedAt: requestedAt,
      processedAt: processedAt ?? this.processedAt,
      adminNotes: adminNotes ?? this.adminNotes,
      processedBy: processedBy ?? this.processedBy,
      imageProofUrl: imageProofUrl ?? this.imageProofUrl,
    );
  }
}
