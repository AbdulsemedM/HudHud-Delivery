import 'package:hudhud_delivery/models/notification_model.dart';
import 'package:hudhud_delivery/features/courier/utils/delivery_notification.dart';
import 'package:hudhud_delivery/features/notifications/model/notifications_list_result.dart';

import '../data_provider/notifications_data_provider.dart';

class NotificationsFetchException implements Exception {
  final int? statusCode;
  final String message;

  const NotificationsFetchException({
    required this.message,
    this.statusCode,
  });

  bool get isUnavailable => statusCode == 503;
  bool get isForbidden => statusCode == 403;
  bool get isUnauthorized => statusCode == 401;

  @override
  String toString() => message;
}

class NotificationsRepository {
  final NotificationsDataProvider dataProvider;

  NotificationsRepository({required this.dataProvider});

  /// Fetches notifications from /api/notifications.
  /// Optionally filters by [userId] if the API returns all users' notifications.
  Future<NotificationsListResult> getNotifications({
    int? userId,
    int page = 1,
    int perPage = NotificationsDataProvider.defaultPerPage,
  }) async {
    final response = await dataProvider.getNotifications(
      page: page,
      perPage: perPage,
    );
    _ensureSuccess(response, 'Failed to fetch notifications');
    final data = response['data'];
    if (data == null) {
      return NotificationsListResult(
        notifications: const [],
        currentPage: page,
        perPage: perPage,
      );
    }
    var result = NotificationsListResult.fromResponse(data);
    var notifications = result.notifications;
    if (userId != null) {
      notifications =
          notifications.where((n) => n.userId == userId).toList();
    }
    notifications = _dedupeDeliveryNotifications(notifications);
    return NotificationsListResult(
      notifications: notifications,
      unreadCount: result.unreadCount,
      total: result.total,
      perPage: result.perPage,
      currentPage: result.currentPage,
      lastPage: result.lastPage,
    );
  }

  List<NotificationModel> _dedupeDeliveryNotifications(
    List<NotificationModel> notifications,
  ) {
    final deduped = dedupeDeliveryNotificationsByKey<NotificationModel>(
      items: notifications,
      routingDataFor: (item) => item.routingData,
      createdAtFor: (item) => item.createdAt,
    );
    return filterStaleDeliveryNotifications<NotificationModel>(
      items: deduped,
      routingDataFor: (item) => item.routingData,
    );
  }

  /// Fetches a single notification by id from /api/notifications/{id}.
  Future<NotificationModel?> getNotificationById(String id) async {
    final response = await dataProvider.getNotificationById(id);
    _ensureSuccess(response, 'Failed to fetch notification');
    final data = response['data'];
    if (data == null) return null;
    final payload = data is Map && data['data'] is Map ? data['data'] : data;
    if (payload is! Map) return null;
    return NotificationModel.fromJson(Map<String, dynamic>.from(payload));
  }

  Future<void> markRead(String notificationId) async {
    final response = await dataProvider.markRead(notificationId);
    _ensureSuccess(response, 'Failed to mark notification read');
  }

  Future<void> markAllRead() async {
    final response = await dataProvider.markAllRead();
    _ensureSuccess(response, 'Failed to mark notifications read');
  }

  void _ensureSuccess(Map<String, dynamic> response, String fallback) {
    final code = response['statusCode'] as int?;
    if (code != null && code >= 200 && code < 300) {
      final data = response['data'];
      if (data is Map && data['success'] == false) {
        throw NotificationsFetchException(
          statusCode: code,
          message: _messageFrom(data, fallback),
        );
      }
      return;
    }

    final data = response['data'];
    throw NotificationsFetchException(
      statusCode: code,
      message: _messageFrom(data, response['errorMessage']?.toString() ?? fallback),
    );
  }

  String _messageFrom(dynamic data, String fallback) {
    if (data is Map) {
      final message = data['message']?.toString();
      if (message != null && message.trim().isNotEmpty) return message.trim();
    }
    if (fallback.startsWith('ApiException: ')) {
      return fallback.substring(14);
    }
    if (fallback.startsWith('Exception: ')) {
      return fallback.substring(11);
    }
    return fallback;
  }
}
