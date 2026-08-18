class NotificationModel {
  final String id;
  final int userId;
  final String title;
  final String message;
  final bool isRead;
  final DateTime createdAt;
  final DateTime updatedAt;
  /// Raw routing metadata from the server payload (event, screen, order_id, etc.).
  final Map<String, String> routingData;

  NotificationModel({
    required this.id,
    required this.userId,
    required this.title,
    required this.message,
    required this.isRead,
    required this.createdAt,
    required this.updatedAt,
    this.routingData = const {},
  });

  factory NotificationModel.fromJson(Map<String, dynamic> json) {
    final payload = json['data'];
    final payloadMap = payload is Map
        ? Map<String, dynamic>.from(payload)
        : const <String, dynamic>{};

    final titleFromPayload = payloadMap['title']?.toString();
    final messageFromPayload = payloadMap['message']?.toString();

    final readAt = json['read_at'];
    final hasReadAt = readAt != null && readAt.toString().trim().isNotEmpty;

    final routingData = <String, String>{};
    payloadMap.forEach((key, value) {
      if (value == null) return;
      routingData[key.toString()] = value.toString();
    });

    final id = json['id']?.toString().trim() ?? '';

    return NotificationModel(
      id: id,
      userId: _asInt(json['user_id'] ?? json['notifiable_id']),
      title: json['title']?.toString() ?? titleFromPayload ?? 'Notification',
      message: json['message']?.toString() ?? messageFromPayload ?? '',
      isRead: hasReadAt || _asBool(json['is_read']),
      createdAt: DateTime.tryParse(json['created_at'] as String? ?? '') ??
          DateTime.now(),
      updatedAt: DateTime.tryParse(json['updated_at'] as String? ?? '') ??
          DateTime.now(),
      routingData: routingData,
    );
  }

  static int _asInt(dynamic value) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    if (value is String) return int.tryParse(value) ?? 0;
    return 0;
  }

  static bool _asBool(dynamic value) {
    if (value == true || value == 1) return true;
    if (value is String) {
      final normalized = value.toLowerCase().trim();
      return normalized == 'true' || normalized == '1';
    }
    return false;
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'title': title,
      'message': message,
      'is_read': isRead,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
      'data': routingData,
    };
  }

  NotificationModel copyWith({
    String? id,
    int? userId,
    String? title,
    String? message,
    bool? isRead,
    DateTime? createdAt,
    DateTime? updatedAt,
    Map<String, String>? routingData,
  }) {
    return NotificationModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      title: title ?? this.title,
      message: message ?? this.message,
      isRead: isRead ?? this.isRead,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      routingData: routingData ?? this.routingData,
    );
  }
}
