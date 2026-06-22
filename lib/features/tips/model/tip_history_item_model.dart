class TipHistoryOrderSummary {
  final int id;
  final String orderNumber;
  final String totalAmount;
  final String status;

  const TipHistoryOrderSummary({
    required this.id,
    required this.orderNumber,
    required this.totalAmount,
    required this.status,
  });

  factory TipHistoryOrderSummary.fromJson(Map<String, dynamic> json) {
    return TipHistoryOrderSummary(
      id: _parseInt(json['id']) ?? 0,
      orderNumber: json['order_number']?.toString() ?? '',
      totalAmount: json['total_amount']?.toString() ?? '0',
      status: json['status']?.toString() ?? '',
    );
  }

  static int? _parseInt(dynamic v) {
    if (v == null) return null;
    if (v is int) return v;
    return int.tryParse(v.toString());
  }
}

class TipHistoryItemModel {
  final int id;
  final int orderId;
  final String amount;
  final String driverAmount;
  final String vendorAmount;
  final String recipientType;
  final String paymentMethod;
  final String paymentStatus;
  final String? message;
  final bool isAnonymous;
  final DateTime? paidAt;
  final DateTime? createdAt;
  final TipHistoryOrderSummary? order;

  const TipHistoryItemModel({
    required this.id,
    required this.orderId,
    required this.amount,
    required this.driverAmount,
    required this.vendorAmount,
    required this.recipientType,
    required this.paymentMethod,
    required this.paymentStatus,
    this.message,
    this.isAnonymous = false,
    this.paidAt,
    this.createdAt,
    this.order,
  });

  factory TipHistoryItemModel.fromJson(Map<String, dynamic> json) {
    final orderJson = json['order'];
    return TipHistoryItemModel(
      id: _parseInt(json['id']) ?? 0,
      orderId: _parseInt(json['order_id']) ?? 0,
      amount: json['amount']?.toString() ?? '0',
      driverAmount: json['driver_amount']?.toString() ?? '0',
      vendorAmount: json['vendor_amount']?.toString() ?? '0',
      recipientType: json['recipient_type']?.toString() ?? 'driver',
      paymentMethod: json['payment_method']?.toString() ?? '',
      paymentStatus: json['payment_status']?.toString() ?? '',
      message: json['message']?.toString(),
      isAnonymous: json['is_anonymous'] == true,
      paidAt: json['paid_at'] != null
          ? DateTime.tryParse(json['paid_at'].toString())
          : null,
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'].toString())
          : null,
      order: orderJson is Map
          ? TipHistoryOrderSummary.fromJson(
              Map<String, dynamic>.from(orderJson),
            )
          : null,
    );
  }

  static int? _parseInt(dynamic v) {
    if (v == null) return null;
    if (v is int) return v;
    return int.tryParse(v.toString());
  }
}
