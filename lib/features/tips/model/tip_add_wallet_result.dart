class TipAddWalletResult {
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

  const TipAddWalletResult({
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
  });

  factory TipAddWalletResult.fromJson(Map<String, dynamic> json) {
    return TipAddWalletResult(
      id: _parseInt(json['id']) ?? 0,
      orderId: _parseInt(json['order_id']) ?? 0,
      amount: json['amount']?.toString() ?? '0',
      driverAmount: json['driver_amount']?.toString() ?? '0',
      vendorAmount: json['vendor_amount']?.toString() ?? '0',
      recipientType: json['recipient_type']?.toString() ?? 'driver',
      paymentMethod: json['payment_method']?.toString() ?? 'wallet',
      paymentStatus: json['payment_status']?.toString() ?? '',
      message: json['message']?.toString(),
      isAnonymous: json['is_anonymous'] == true,
      paidAt: json['paid_at'] != null
          ? DateTime.tryParse(json['paid_at'].toString())
          : null,
    );
  }

  static int? _parseInt(dynamic v) {
    if (v == null) return null;
    if (v is int) return v;
    return int.tryParse(v.toString());
  }
}
