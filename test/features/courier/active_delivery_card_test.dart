import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hudhud_delivery/features/courier/presentation/widgets/active_delivery_card.dart';
import 'package:hudhud_delivery/l10n/app_localizations.dart';

void main() {
  late AppLocalizations l10n;

  setUpAll(() async {
    l10n = await AppLocalizations.delegate.load(const Locale('en'));
  });

  group('activeDeliveryStatusMessage', () {
    test('maps common delivery statuses to readable copy', () {
      expect(
        activeDeliveryStatusMessage(l10n, 'picked_up'),
        l10n.orderStatusTextPickedUp,
      );
      expect(
        activeDeliveryStatusMessage(l10n, 'out_for_delivery'),
        l10n.orderStatusOutForDelivery,
      );
      expect(
        activeDeliveryStatusMessage(l10n, 'pending_payment'),
        l10n.orderStatusPending,
      );
      expect(
        activeDeliveryStatusMessage(l10n, 'courier_assigned'),
        'Courier on the way to pickup',
      );
    });

    test('falls back for empty status', () {
      expect(
        activeDeliveryStatusMessage(l10n, null),
        l10n.courierDeliveryStatusInProgress,
      );
    });
  });

  group('parseDeliveryGLatLng', () {
    test('parses valid coords and rejects invalid', () {
      expect(parseDeliveryGLatLng(9.0, 38.7), isNotNull);
      expect(parseDeliveryGLatLng('9.02', '38.75'), isNotNull);
      expect(parseDeliveryGLatLng(null, 38.7), isNull);
      expect(parseDeliveryGLatLng('x', 'y'), isNull);
    });
  });
}
