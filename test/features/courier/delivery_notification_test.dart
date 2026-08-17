import 'package:flutter_test/flutter_test.dart';
import 'package:hudhud_delivery/app/notifications/notification_events.dart';
import 'package:hudhud_delivery/features/courier/utils/delivery_notification.dart';
import 'package:hudhud_delivery/models/notification_model.dart';

void main() {
  group('delivery notification helpers', () {
    test('parseDeliveryIdFromPayload reads delivery_id', () {
      expect(
        parseDeliveryIdFromPayload({'delivery_id': '42'}),
        42,
      );
    });

    test('normalizeDeliveryStatus resolves legacy aliases', () {
      expect(normalizeDeliveryStatus('rider_assigned'), 'pickup_assigned');
      expect(normalizeDeliveryStatus('delivery_completed'), 'delivered');
    });

    test('isStaleDeliveryStatus compares lifecycle rank', () {
      expect(
        isStaleDeliveryStatus('pickup_assigned', 'at_dropoff'),
        isTrue,
      );
      expect(
        isStaleDeliveryStatus('at_dropoff', 'pickup_assigned'),
        isFalse,
      );
    });

    test('dedupeDeliveryNotificationsByKey keeps newest per delivery/status', () {
      final older = NotificationModel(
        id: 1,
        userId: 1,
        title: 'Older',
        message: 'Assigned',
        isRead: false,
        createdAt: DateTime(2026, 8, 17, 10, 0),
        updatedAt: DateTime(2026, 8, 17, 10, 0),
        routingData: const {
          'delivery_id': '9',
          'new_status': 'pickup_assigned',
        },
      );
      final newer = NotificationModel(
        id: 2,
        userId: 1,
        title: 'Newer',
        message: 'At dropoff',
        isRead: false,
        createdAt: DateTime(2026, 8, 17, 10, 5),
        updatedAt: DateTime(2026, 8, 17, 10, 5),
        routingData: const {
          'delivery_id': '9',
          'new_status': 'pickup_assigned',
        },
      );

      final deduped = dedupeDeliveryNotificationsByKey<NotificationModel>(
        items: [older, newer],
        routingDataFor: (item) => item.routingData,
        createdAtFor: (item) => item.createdAt,
      );

      expect(deduped.length, 1);
      expect(deduped.first.id, 2);
    });

    test('filterStaleDeliveryNotifications drops older lifecycle statuses', () {
      final assigned = NotificationModel(
        id: 1,
        userId: 1,
        title: 'Assigned',
        message: '',
        isRead: false,
        createdAt: DateTime(2026, 8, 17, 10, 0),
        updatedAt: DateTime(2026, 8, 17, 10, 0),
        routingData: const {
          'delivery_id': '9',
          'new_status': 'pickup_assigned',
        },
      );
      final dropoff = NotificationModel(
        id: 2,
        userId: 1,
        title: 'At dropoff',
        message: '',
        isRead: false,
        createdAt: DateTime(2026, 8, 17, 10, 5),
        updatedAt: DateTime(2026, 8, 17, 10, 5),
        routingData: const {
          'delivery_id': '9',
          'new_status': 'at_dropoff',
        },
      );

      final filtered = filterStaleDeliveryNotifications<NotificationModel>(
        items: [assigned, dropoff],
        routingDataFor: (item) => item.routingData,
      );

      expect(filtered.length, 1);
      expect(filtered.first.id, 2);
    });

    test('isOtpRequiredPayload detects otp_required type', () {
      expect(
        isOtpRequiredPayload(const {'type': 'otp_required'}),
        isTrue,
      );
      expect(
        isOtpRequiredPayload(const {'screen': 'verify_delivery'}),
        isFalse,
      );
    });

    test('isDeliveryTerminalStatus detects closed deliveries', () {
      expect(isDeliveryTerminalStatus('delivered'), isTrue);
      expect(isDeliveryTerminalStatus('cancelled'), isTrue);
      expect(isDeliveryTerminalStatus('failed'), isTrue);
      expect(isDeliveryTerminalStatus('returned'), isTrue);
      expect(isDeliveryTerminalStatus('at_dropoff'), isFalse);
      expect(isDeliveryTerminalStatus('pickup_assigned'), isFalse);
    });
  });
}
