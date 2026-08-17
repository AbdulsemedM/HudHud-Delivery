import 'package:flutter_test/flutter_test.dart';
import 'package:hudhud_delivery/features/courier/utils/delivery_history_filter.dart';

void main() {
  group('delivery history filter', () {
    test('treats out_for_delivery as active, not completed', () {
      expect(isActiveDeliveryStatus('out_for_delivery'), isTrue);
      expect(isCompletedDeliveryStatus('out_for_delivery'), isFalse);
      expect(
        matchesDeliveryHistoryFilter(
          'out_for_delivery',
          kDeliveryHistoryFilterActive,
        ),
        isTrue,
      );
      expect(
        matchesDeliveryHistoryFilter(
          'out_for_delivery',
          kDeliveryHistoryFilterCompleted,
        ),
        isFalse,
      );
    });

    test('completed statuses match only delivered/completed', () {
      expect(isCompletedDeliveryStatus('delivered'), isTrue);
      expect(isCompletedDeliveryStatus('Delivered'), isTrue);
      expect(isCompletedDeliveryStatus('completed'), isTrue);
      expect(isCompletedDeliveryStatus('ready_for_pickup'), isFalse);
      expect(isCompletedDeliveryStatus('in_transit'), isFalse);
    });

    test('cancelled statuses', () {
      expect(isCancelledDeliveryStatus('cancelled'), isTrue);
      expect(isCancelledDeliveryStatus('canceled'), isTrue);
      expect(isCancelledDeliveryStatus('Cancelled'), isTrue);
      expect(isCancelledDeliveryStatus('pending'), isFalse);
    });

    test('active includes in-progress courier statuses', () {
      for (final status in [
        'pending',
        'searching',
        'assigned',
        'accepted',
        'picked_up',
        'in_transit',
        'out_for_delivery',
        'on_the_way',
        'ready_for_pickup',
      ]) {
        expect(
          isActiveDeliveryStatus(status),
          isTrue,
          reason: '$status should be active',
        );
      }
    });

    test('filter all always matches', () {
      expect(
        matchesDeliveryHistoryFilter('anything', kDeliveryHistoryFilterAll),
        isTrue,
      );
    });
  });
}
