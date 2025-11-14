class OrderModel {
  OrderModel({
    required this.id,
    required this.invoice,
    required this.status,
    required this.trackingNumber,
    required this.paymentStatus,
    required this.eta,
    required this.updatedAt,
  });

  final String id;
  final String invoice;
  final String status;
  final String trackingNumber;
  final String paymentStatus;
  final DateTime? eta;
  final DateTime updatedAt;

  factory OrderModel.fromMap(Map<String, dynamic> map) {
    return OrderModel(
      id: map['id']?.toString() ?? '',
      invoice: map['invoice']?.toString() ?? '-',
      status: map['status']?.toString() ?? 'unknown',
      trackingNumber: map['tracking_number']?.toString() ?? '-',
      paymentStatus: map['payment_status']?.toString() ?? 'pending',
      eta: map['eta'] != null ? DateTime.tryParse(map['eta'].toString()) : null,
      updatedAt:
          DateTime.tryParse(map['updated_at']?.toString() ?? '') ??
          DateTime.now(),
    );
  }
}
