class SosTriggerRequest {
  final int? orderId;
  final String alertType;
  final double latitude;
  final double longitude;
  final String locationAddress;
  final String description;
  final String priority;

  const SosTriggerRequest({
    this.orderId,
    this.alertType = 'emergency',
    required this.latitude,
    required this.longitude,
    required this.locationAddress,
    required this.description,
    this.priority = 'high',
  });

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{
      'alert_type': alertType,
      'latitude': latitude,
      'longitude': longitude,
      'location_address': locationAddress,
      'description': description,
      'priority': priority,
    };
    if (orderId != null) {
      map['order_id'] = orderId;
    }
    return map;
  }
}
