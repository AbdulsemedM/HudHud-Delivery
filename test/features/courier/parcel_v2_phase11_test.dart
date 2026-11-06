import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:hudhud_delivery/features/courier/parcel_v2/parcel_v2_models.dart';
import 'package:hudhud_delivery/features/courier/parcel_v2/parcel_v2_widgets.dart';
import 'package:hudhud_delivery/l10n/app_localizations.dart';

ParcelBookingDraft _draft({
  List<ParcelStopDraft> extraStops = const [],
  String paymentMethod = 'wallet',
  bool payAtPickup = false,
  bool recipientPays = false,
  double? sellerCodAmount,
}) {
  return ParcelBookingDraft(
    pickupLocation: 'Bole',
    pickupLat: 9.0,
    pickupLng: 38.76,
    dropoffLocation: 'Piassa',
    dropoffLat: 9.03,
    dropoffLng: 38.75,
    dropoffDetails: const ParcelAddressDetails(building: 'Taitu'),
    recipientName: 'Hana',
    recipientPhone: '+251933555661',
    paymentMethod: paymentMethod,
    payAtPickup: payAtPickup,
    recipientPays: recipientPays,
    sellerCodAmount: sellerCodAmount,
    dropoffNote: 'Gate 2',
    extraStops: extraStops,
  );
}

const _second = ParcelStopDraft(
  location: 'Kazanchis',
  lat: 9.02,
  lng: 38.77,
  recipientName: 'Dawit',
  recipientPhone: '+251933555662',
  note: 'Reception',
);

const _third = ParcelStopDraft(
  location: 'Megenagna',
  lat: 9.02,
  lng: 38.80,
  recipientIsMe: true,
);

void main() {
  group('Phase 11 config', () {
    test('parses drop-off limit, pay at pickup and outstanding dues', () {
      final config = ParcelV2Config.fromResponseBody({
        'success': true,
        'data': {
          'enabled': true,
          'max_dropoffs': 3,
          'pay_at_pickup_enabled': true,
          'cash_cancellation_fee_enabled': true,
          'outstanding_dues': {
            'count': 1,
            'amounts': [
              {'currency': 'etb', 'amount': 30},
            ],
          },
        },
      });
      expect(config.maxDropoffs, 3);
      expect(config.multiStopEnabled, isTrue);
      expect(config.payAtPickupEnabled, isTrue);
      expect(config.cashCancellationFeeEnabled, isTrue);
      expect(config.outstandingDues!.hasDues, isTrue);
      expect(config.outstandingDues!.amounts, {'ETB': 30.0});
    });

    test('older backends mean one drop-off and no pay at pickup', () {
      final config = ParcelV2Config.fromResponseBody({
        'data': {'enabled': true},
      });
      expect(config.maxDropoffs, 1);
      expect(config.multiStopEnabled, isFalse);
      expect(config.payAtPickupEnabled, isFalse);
      expect(config.outstandingDues, isNull);
      expect(
        ParcelV2Config.fromResponseBody({
          'data': {'max_dropoffs': 9},
        }).maxDropoffs,
        3,
      );
    });
  });

  group('Phase 11 booking bodies', () {
    test('single drop-off keeps the Phase 10 body', () {
      final draft = _draft();
      final quote = draft.quoteBody();
      expect(quote['dropoff_latitude'], 9.03);
      expect(quote.containsKey('stops'), isFalse);
      final book = draft.bookBody('pq_1');
      expect(book['dropoff_location'], 'Piassa');
      expect(book['recipient_phone'], '+251933555661');
      expect(book.containsKey('stops'), isFalse);
      expect(book.containsKey('payment_timing'), isFalse);
      expect(book['payer'], 'sender');
    });

    test('multi-stop quotes the stops in order and books each recipient', () {
      final draft = _draft(extraStops: const [_second, _third]);
      expect(draft.isMultiStop, isTrue);
      expect(draft.lastStop.location, 'Megenagna');

      final quote = draft.quoteBody();
      expect(quote.containsKey('dropoff_latitude'), isFalse);
      expect(quote['stops'], [
        {'latitude': 9.03, 'longitude': 38.75},
        {'latitude': 9.02, 'longitude': 38.77},
        {'latitude': 9.02, 'longitude': 38.80},
      ]);

      final book = draft.bookBody('pq_2');
      expect(book.containsKey('dropoff_location'), isFalse);
      expect(book.containsKey('recipient_phone'), isFalse);
      final stops = book['stops'] as List;
      expect(stops, hasLength(3));
      expect(stops[0]['location'], 'Piassa');
      expect(stops[0]['address']['building'], 'Taitu');
      expect(stops[0]['note'], 'Gate 2');
      expect(stops[1]['recipient_name'], 'Dawit');
      expect(stops[1]['note'], 'Reception');
      expect(stops[2]['recipient_is_me'], isTrue);
      expect((stops[2] as Map).containsKey('recipient_phone'), isFalse);
    });

    test('multi-stop is always sender paid; cash means cash at pickup', () {
      final draft = _draft(
        extraStops: const [_second],
        paymentMethod: 'cash',
        recipientPays: true,
        sellerCodAmount: 500,
      );
      final book = draft.bookBody('pq_3');
      expect(book['payer'], 'sender');
      expect(book['payment_method'], 'cash');
      expect(book['payment_timing'], 'pickup');
      expect(book.containsKey('seller_cod'), isFalse);
    });

    test('pay at pickup is only sent for a sender cash parcel', () {
      expect(
        _draft(paymentMethod: 'cash', payAtPickup: true)
            .bookBody('q')['payment_timing'],
        'pickup',
      );
      expect(
        _draft(paymentMethod: 'wallet', payAtPickup: true)
            .bookBody('q')
            .containsKey('payment_timing'),
        isFalse,
      );
      final recipient = _draft(
        paymentMethod: 'cash',
        payAtPickup: true,
        recipientPays: true,
      ).bookBody('q');
      expect(recipient.containsKey('payment_timing'), isFalse);
      expect(recipient['payer'], 'recipient');
    });
  });

  group('Phase 11 parcel detail', () {
    test('parses stops in sequence order, codes and pay at pickup', () {
      final parcel = ParcelV2Parcel.fromResponseBody({
        'data': {
          'id': 9,
          'version': 2,
          'status': 'picked_up',
          'price': {'amount': 240, 'currency': 'ETB', 'locked': true},
          'payment': {
            'method': 'cash',
            'timing': 'pickup',
            'collected_at_pickup': true,
          },
          'handover': {'code': null},
          'current_stop': 2,
          'stops': [
            {
              'sequence': 2,
              'status': 'arrived',
              'address': 'Kazanchis',
              'handover': {'code': '1234', 'verified': false},
              'tracking_url': 'https://hudhuddelivery.com/t/abc',
            },
            {
              'sequence': 1,
              'status': 'delivered',
              'handover': {'code': null, 'verified': true},
            },
          ],
          'cancellation': {
            'can_cancel': true,
            'fee': 50,
            'fee_charged_to': 'wallet_or_outstanding_balance',
          },
        },
      })!;
      expect(parcel.isMultiStop, isTrue);
      expect(parcel.stops.map((s) => s.sequence), [1, 2]);
      expect(parcel.stops.first.isDone, isTrue);
      expect(parcel.stops.last.handoverCode, '1234');
      expect(parcel.currentStop, 2);
      expect(parcel.paysAtPickup, isTrue);
      expect(parcel.collectedAtPickup, isTrue);
      expect(parcel.cancellation!.chargedToWalletOrBalance, isTrue);
    });

    test('server codes map to Phase 11 messages', () {
      expect(parcelErrorKind('PARCEL_MULTI_STOP_DISABLED'),
          ParcelErrorKind.multiStopDisabled);
      expect(parcelErrorKind('PARCEL_TOO_MANY_STOPS'),
          ParcelErrorKind.tooManyStops);
      expect(parcelErrorKind('PARCEL_MULTI_STOP_SENDER_PAYS'),
          ParcelErrorKind.multiStopSenderPays);
      expect(parcelErrorKind('PARCEL_MULTI_STOP_CASH_AT_PICKUP'),
          ParcelErrorKind.multiStopCashAtPickup);
      expect(parcelErrorKind('PARCEL_PAY_AT_PICKUP_DISABLED'),
          ParcelErrorKind.payAtPickupUnavailable);
    });
  });

  group('Phase 11 widgets', () {
    Widget wrap(Widget child) => MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: Scaffold(body: SingleChildScrollView(child: child)),
        );

    testWidgets('stops list shows each stop status and unused code',
        (tester) async {
      await tester.pumpWidget(wrap(const ParcelStopsList(
        currentStop: 2,
        stops: [
          ParcelV2Stop(
            sequence: 1,
            status: ParcelStopStatus.delivered,
            address: 'Piassa',
            handoverVerified: true,
            handoverCode: '9999',
          ),
          ParcelV2Stop(
            sequence: 2,
            status: ParcelStopStatus.arrived,
            address: 'Kazanchis',
            recipientName: 'Dawit',
            handoverCode: '1234',
            trackingUrl: 'https://hudhuddelivery.com/t/abc',
          ),
          ParcelV2Stop(sequence: 3, status: ParcelStopStatus.failed),
        ],
      )));
      expect(find.text('Drop-offs'), findsOneWidget);
      expect(find.text('Stop 1'), findsOneWidget);
      expect(find.text('Delivered'), findsOneWidget);
      expect(find.text('Courier is there'), findsOneWidget);
      expect(find.text('Not delivered'), findsOneWidget);
      expect(find.text('1234'), findsOneWidget);
      expect(find.text('9999'), findsNothing, reason: 'used code is hidden');
      expect(find.text('Share link'), findsOneWidget);
    });

    testWidgets('pay at pickup note and dues banner', (tester) async {
      await tester.pumpWidget(wrap(const Column(
        children: [
          ParcelPayAtPickupNote(amount: 240, currency: 'ETB'),
          ParcelPayAtPickupNote(amount: 240, currency: 'ETB', collected: true),
          ParcelDuesBanner(
            dues: ParcelDuesSummary(count: 1, amounts: {'ETB': 30}),
          ),
        ],
      )));
      expect(find.text('Pay ETB 240.00 cash to the courier at pickup'),
          findsOneWidget);
      expect(find.text('Paid to the courier at pickup'), findsOneWidget);
      expect(find.textContaining('You owe ETB 30.00'), findsOneWidget);
    });

    testWidgets('stop header exposes move and remove actions',
        (tester) async {
      final calls = <String>[];
      await tester.pumpWidget(wrap(ParcelStopHeader(
        number: 2,
        onMoveUp: () => calls.add('up'),
        onMoveDown: () => calls.add('down'),
        onRemove: () => calls.add('remove'),
      )));
      expect(find.text('Stop 2'), findsOneWidget);
      await tester.tap(find.byKey(const ValueKey('parcel_stop_2_up')));
      await tester.tap(find.byKey(const ValueKey('parcel_stop_2_down')));
      await tester.tap(find.byKey(const ValueKey('parcel_stop_2_remove')));
      expect(calls, ['up', 'down', 'remove']);
    });

    testWidgets('every locale has the Phase 11 strings', (tester) async {
      for (final locale in AppLocalizations.supportedLocales) {
        final l10n = lookupAppLocalizations(locale);
        expect(l10n.p11ParcelStopN('2'), contains('2'));
        expect(l10n.p11ParcelPayAtPickupDue('ETB 5.00'), contains('ETB 5.00'));
        expect(l10n.p11ParcelAddStop, isNotEmpty);
      }
    });
  });
}
