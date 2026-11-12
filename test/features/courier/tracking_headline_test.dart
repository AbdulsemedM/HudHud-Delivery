import 'package:flutter_test/flutter_test.dart';
import 'package:hudhud_delivery/core/widgets/status_chip.dart';
import 'package:hudhud_delivery/features/courier/utils/delivery_status.dart';
import 'package:hudhud_delivery/l10n/app_localizations_am.dart';
import 'package:hudhud_delivery/l10n/app_localizations_en.dart';

void main() {
  final en = AppLocalizationsEn();

  group('trackingHeadline (test report issue 7)', () {
    test('accepted / pickup_assigned is "on the way", not "has arrived"', () {
      expect(trackingHeadline(en, 'pickup_assigned'), en.trackingStatusOnTheWay);
      expect(trackingHeadline(en, 'accepted'), en.trackingStatusOnTheWay);
      expect(trackingHeadline(en, 'en_route_pickup'), en.trackingStatusOnTheWay);
    });

    test('arrived only at a stop', () {
      expect(trackingHeadline(en, 'arrived_at_pickup'), en.trackingStatusArrived);
      expect(trackingHeadline(en, 'at_pickup'), en.trackingStatusArrived);
      expect(trackingHeadline(en, 'at_dropoff'), en.trackingStatusArrived);
    });

    test('after pickup the package is on its way', () {
      expect(trackingHeadline(en, 'picked_up'), en.trackingStatusDelivering);
      expect(trackingHeadline(en, 'en_route_dropoff'), en.trackingStatusDelivering);
      expect(trackingHeadline(en, 'in_transit'), en.trackingStatusDelivering);
    });

    test('cancelled no longer says "Courier is coming"', () {
      expect(trackingHeadline(en, 'cancelled'), en.trackingStatusCancelled);
      expect(trackingHeadline(en, 'canceled'), en.trackingStatusCancelled);
      expect(trackingHeadline(en, 'failed'), en.trackingStatusCancelled);
    });

    test('searching and delivered', () {
      expect(trackingHeadline(en, 'searching'), en.trackingStatusSearching);
      expect(trackingHeadline(en, 'pending'), en.trackingStatusSearching);
      expect(trackingHeadline(en, 'delivered'), en.trackingStatusDone);
      expect(trackingHeadline(en, 'completed'), en.trackingStatusDone);
    });
  });

  group('StatusChip.localizedLabelFor (test report issue 3)', () {
    test('uses translations instead of the raw API status', () {
      final am = AppLocalizationsAm();
      expect(StatusChip.localizedLabelFor(am, 'cancelled'), am.orderStatusCancelled);
      expect(StatusChip.localizedLabelFor(am, 'cancelled'), isNot('Cancelled'));
      expect(StatusChip.localizedLabelFor(am, 'pickup_assigned'), am.deliveryStatusAssigned);
    });

    test('unknown statuses fall back to a readable label', () {
      expect(StatusChip.localizedLabelFor(en, 'some_new_state'), 'Some new state');
    });
  });
}
