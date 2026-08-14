import 'package:flutter_test/flutter_test.dart';
import 'package:hudhud_delivery/features/courier/utils/delivery_cancel.dart';

void main() {
  group('canCancelCourierDelivery', () {
    test('allows early statuses', () {
      expect(canCancelCourierDelivery(null), isTrue);
      expect(canCancelCourierDelivery(''), isTrue);
      expect(canCancelCourierDelivery('pending_payment'), isTrue);
      expect(canCancelCourierDelivery('searching'), isTrue);
      expect(canCancelCourierDelivery('assigned'), isTrue);
      expect(canCancelCourierDelivery('accepted'), isTrue);
      expect(canCancelCourierDelivery('driver_assigned'), isTrue);
    });

    test('blocks picked up and later statuses', () {
      expect(canCancelCourierDelivery('picked_up'), isFalse);
      expect(canCancelCourierDelivery('Picked Up'), isFalse);
      expect(canCancelCourierDelivery('in_transit'), isFalse);
      expect(canCancelCourierDelivery('out_for_delivery'), isFalse);
      expect(canCancelCourierDelivery('delivered'), isFalse);
      expect(canCancelCourierDelivery('completed'), isFalse);
      expect(canCancelCourierDelivery('cancelled'), isFalse);
      expect(canCancelCourierDelivery('canceled'), isFalse);
    });
  });
}
