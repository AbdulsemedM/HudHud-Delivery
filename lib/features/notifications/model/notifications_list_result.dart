import 'package:hudhud_delivery/models/notification_model.dart';

class NotificationsListResult {
  final List<NotificationModel> notifications;
  final int unreadCount;
  final int total;
  final int perPage;
  final int currentPage;
  final int lastPage;

  const NotificationsListResult({
    required this.notifications,
    this.unreadCount = 0,
    this.total = 0,
    this.perPage = 20,
    this.currentPage = 1,
    this.lastPage = 1,
  });

  factory NotificationsListResult.fromResponse(dynamic root) {
    if (root is! Map) {
      return const NotificationsListResult(notifications: []);
    }
    final map = Map<String, dynamic>.from(root);
    final listRaw = map['data'];
    final notifications = <NotificationModel>[];
    if (listRaw is List) {
      for (final item in listRaw) {
        if (item is Map) {
          notifications.add(
            NotificationModel.fromJson(Map<String, dynamic>.from(item)),
          );
        }
      }
    }

    final metaRaw = map['meta'];
    final meta = metaRaw is Map
        ? Map<String, dynamic>.from(metaRaw)
        : const <String, dynamic>{};

    return NotificationsListResult(
      notifications: notifications,
      unreadCount: _asInt(meta['unread_count']),
      total: _asInt(meta['total'] ?? notifications.length),
      perPage: _asInt(meta['per_page'], fallback: 20),
      currentPage: _asInt(meta['current_page'], fallback: 1),
      lastPage: _asInt(meta['last_page'], fallback: 1),
    );
  }

  static int _asInt(dynamic value, {int fallback = 0}) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    if (value is String) return int.tryParse(value) ?? fallback;
    return fallback;
  }
}
