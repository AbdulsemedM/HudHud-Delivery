import 'package:flutter_test/flutter_test.dart';
import 'package:hudhud_delivery/features/notifications/model/notifications_list_result.dart';
import 'package:hudhud_delivery/models/notification_model.dart';

void main() {
  test('parses uuid id, boolean is_read, and payload data', () {
    final notification = NotificationModel.fromJson({
      'id': 'a1b2c3d4-e5f6-7890-abcd-ef1234567890',
      'type': 'OrderStatusChanged',
      'title': 'Order delivered',
      'message': 'Your order has been delivered.',
      'data': {
        'event': 'order_status',
        'order_id': '42',
      },
      'read_at': null,
      'is_read': true,
      'created_at': '2026-08-17T10:42:46.000000Z',
    });

    expect(notification.id, 'a1b2c3d4-e5f6-7890-abcd-ef1234567890');
    expect(notification.isRead, isTrue);
    expect(notification.title, 'Order delivered');
    expect(notification.routingData['order_id'], '42');
  });

  test('treats missing is_read as unread when read_at is null', () {
    final notification = NotificationModel.fromJson({
      'id': 'unread-1',
      'title': 'Hello',
      'message': 'World',
      'is_read': false,
      'read_at': null,
      'created_at': '2026-08-17T10:42:46.000000Z',
    });

    expect(notification.isRead, isFalse);
  });

  test('parses list meta unread_count', () {
    final result = NotificationsListResult.fromResponse({
      'data': [
        {
          'id': 'a1b2c3d4-e5f6-7890-abcd-ef1234567890',
          'title': 'Order delivered',
          'message': 'Your order has been delivered.',
          'data': {},
          'read_at': null,
          'is_read': false,
          'created_at': '2026-08-17T10:42:46.000000Z',
        },
      ],
      'meta': {
        'unread_count': 3,
        'total': 15,
        'per_page': 20,
        'current_page': 1,
        'last_page': 1,
      },
    });

    expect(result.notifications, hasLength(1));
    expect(result.notifications.first.id, startsWith('a1b2c3d4'));
    expect(result.unreadCount, 3);
    expect(result.total, 15);
    expect(result.perPage, 20);
    expect(result.currentPage, 1);
  });
}
