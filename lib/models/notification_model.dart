class NotificationModel {
  final int id;
  final int userId;
  final String title;
  final String message;
  final bool isRead;
  final DateTime createdAt;
  final DateTime updatedAt;

  NotificationModel({
    required this.id,
    required this.userId,
    required this.title,
    required this.message,
    required this.isRead,
    required this.createdAt,
    required this.updatedAt,
  });

  factory NotificationModel.fromJson(Map<String, dynamic> json) {
    final payload = json['data'];
    final payloadMap = payload is Map
        ? Map<String, dynamic>.from(payload)
        : const <String, dynamic>{};

    final titleFromPayload = payloadMap['title']?.toString();
    final messageFromPayload = payloadMap['message']?.toString();

    final readAt = json['read_at'];

    return NotificationModel(
      id: _asInt(json['id']),
      userId: _asInt(json['user_id'] ?? json['notifiable_id']),
      title: json['title']?.toString() ?? titleFromPayload ?? 'Notification',
      message: json['message']?.toString() ?? messageFromPayload ?? '',
      isRead: readAt != null || (json['is_read'] ?? 0) == 1,
      createdAt: DateTime.tryParse(json['created_at'] as String? ?? '') ??
          DateTime.now(),
      updatedAt: DateTime.tryParse(json['updated_at'] as String? ?? '') ??
          DateTime.now(),
    );
  }

  static int _asInt(dynamic value) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    if (value is String) return int.tryParse(value) ?? 0;
    return 0;
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'title': title,
      'message': message,
      'is_read': isRead ? 1 : 0,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  NotificationModel copyWith({
    int? id,
    int? userId,
    String? title,
    String? message,
    bool? isRead,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return NotificationModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      title: title ?? this.title,
      message: message ?? this.message,
      isRead: isRead ?? this.isRead,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
