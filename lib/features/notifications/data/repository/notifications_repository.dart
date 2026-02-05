import 'package:hudhud_delivery/models/notification_model.dart';

import '../data_provider/notifications_data_provider.dart';

class NotificationsRepository {
  final NotificationsDataProvider dataProvider;

  NotificationsRepository({required this.dataProvider});

  /// Fetches notifications from /api/notifications.
  /// Optionally filters by [userId] if the API returns all users' notifications.
  Future<List<NotificationModel>> getNotifications({int? userId}) async {
    final response = await dataProvider.getNotifications();
    if (response['statusCode'] != 200) {
      throw Exception(
        response['errorMessage'] ?? 'Failed to fetch notifications',
      );
    }
    final data = response['data'];
    if (data == null) return [];
    final list = data is List ? data : (data is Map ? data['data'] : null);
    if (list is! List) return [];
    var notifications = (list)
        .map((e) =>
            NotificationModel.fromJson(Map<String, dynamic>.from(e as Map)))
        .toList();
    if (userId != null) {
      notifications = notifications.where((n) => n.userId == userId).toList();
    }
    return notifications;
  }

  /// Fetches a single notification by id from /api/notifications/{id}.
  Future<NotificationModel?> getNotificationById(int id) async {
    final response = await dataProvider.getNotificationById(id);
    if (response['statusCode'] != 200) {
      throw Exception(
        response['errorMessage'] ?? 'Failed to fetch notification',
      );
    }
    final data = response['data'];
    if (data == null) return null;
    return NotificationModel.fromJson(
      Map<String, dynamic>.from(data as Map),
    );
  }
}
