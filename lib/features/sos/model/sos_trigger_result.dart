class SosTriggerResult {
  final int sosId;
  final String status;
  final String alertType;
  final String? message;

  const SosTriggerResult({
    required this.sosId,
    required this.status,
    required this.alertType,
    this.message,
  });

  factory SosTriggerResult.fromResponse(
    Map<String, dynamic> root, {
    String? message,
  }) {
    final data = root['data'];
    final map = data is Map
        ? Map<String, dynamic>.from(data)
        : <String, dynamic>{};
    return SosTriggerResult(
      sosId: _asInt(map['sos_id']) ?? 0,
      status: map['status']?.toString() ?? 'active',
      alertType: map['alert_type']?.toString() ?? 'emergency',
      message: message ?? root['message']?.toString(),
    );
  }

  static int? _asInt(dynamic value) {
    if (value == null) return null;
    if (value is int) return value;
    return int.tryParse(value.toString());
  }
}
