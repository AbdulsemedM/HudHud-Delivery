class SosAlertModel {
  final int id;
  final int? userId;
  final int? orderId;
  final String alertType;
  final String status;
  final String priority;
  final double? latitude;
  final double? longitude;
  final String? locationAddress;
  final String? description;
  final String? orderNumber;
  final DateTime? createdAt;
  final DateTime? resolvedAt;

  const SosAlertModel({
    required this.id,
    this.userId,
    this.orderId,
    required this.alertType,
    required this.status,
    required this.priority,
    this.latitude,
    this.longitude,
    this.locationAddress,
    this.description,
    this.orderNumber,
    this.createdAt,
    this.resolvedAt,
  });

  factory SosAlertModel.fromJson(Map<String, dynamic> json) {
    final order = json['order'];
    String? orderNumber;
    if (order is Map) {
      orderNumber = order['order_number']?.toString();
    }

    return SosAlertModel(
      id: _asInt(json['id']) ?? 0,
      userId: _asInt(json['user_id']),
      orderId: _asInt(json['order_id']),
      alertType: json['alert_type']?.toString() ?? 'emergency',
      status: json['status']?.toString() ?? 'active',
      priority: json['priority']?.toString() ?? 'high',
      latitude: _asDouble(json['latitude']),
      longitude: _asDouble(json['longitude']),
      locationAddress: json['location_address']?.toString(),
      description: json['description']?.toString(),
      orderNumber: orderNumber,
      createdAt: _parseDate(json['created_at']),
      resolvedAt: _parseDate(json['resolved_at']),
    );
  }

  static int? _asInt(dynamic value) {
    if (value == null) return null;
    if (value is int) return value;
    return int.tryParse(value.toString());
  }

  static double? _asDouble(dynamic value) {
    if (value == null) return null;
    if (value is num) return value.toDouble();
    return double.tryParse(value.toString());
  }

  static DateTime? _parseDate(dynamic value) {
    if (value == null) return null;
    return DateTime.tryParse(value.toString());
  }
}
