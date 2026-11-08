import 'package:flutter_test/flutter_test.dart';
import 'package:hudhud_delivery/features/courier/utils/delivery_cancel.dart';

void main() {
  group('canCancelCourierDelivery', () {
    test('allows statuses before a courier is assigned', () {
      expect(canCancelCourierDelivery(null), isTrue);
      expect(canCancelCourierDelivery(''), isTrue);
      expect(canCancelCourierDelivery('pending'), isTrue);
      expect(canCancelCourierDelivery('pending_payment'), isTrue);
      expect(canCancelCourierDelivery('searching'), isTrue);
    });

    // Product rule (see canCancelCourierDelivery doc): once a courier is
    // assigned the customer can no longer cancel from the app.
    test('blocks once a courier is assigned', () {
      expect(canCancelCourierDelivery('pickup_assigned'), isFalse);
      expect(canCancelCourierDelivery('assigned'), isFalse);
      expect(canCancelCourierDelivery('driver_assigned'), isFalse);
      expect(canCancelCourierDelivery('en_route_pickup'), isFalse);
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
