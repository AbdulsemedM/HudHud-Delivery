import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:latlong2/latlong.dart';

import 'package:hudhud_delivery/app/models/city_service_area.dart';
import 'package:hudhud_delivery/app/models/place_result.dart';
import 'package:hudhud_delivery/app/services/city_scope.dart';
import 'package:hudhud_delivery/app/services/google_places_service.dart';
import 'package:hudhud_delivery/core/widgets/city_outside_area_banner.dart';
import 'package:hudhud_delivery/features/courier/parcel_v2/parcel_v2_models.dart';
import 'package:hudhud_delivery/features/courier/parcel_v2/parcel_v2_widgets.dart';
import 'package:hudhud_delivery/features/growth/data/models/market.dart';
import 'package:hudhud_delivery/l10n/app_localizations.dart';

const _addisArea = CityServiceArea(
  marketCode: 'addis_ababa',
  marketName: 'Addis Ababa',
  centerLat: 9.03,
  centerLng: 38.74,
  radiusKm: 60,
  bounds: CityBounds(south: 8.49, west: 38.19, north: 9.57, east: 39.29),
  countryCode: 'ET',
  enforced: true,
);

const _hargeisaArea = CityServiceArea(
  marketCode: 'hargeisa',
  marketName: 'Hargeisa',
  centerLat: 9.56,
  centerLng: 44.065,
  shape: 'bounds',
  bounds: CityBounds(south: 9.45, west: 43.95, north: 9.65, east: 44.15),
  countryCode: 'SO',
  enforced: true,
);

void main() {
  tearDown(CityScope.reset);

  group('CityServiceArea', () {
    test('parses the markets service_area payload', () {
      final market = Market.fromJson({
        'code': 'hargeisa',
        'name': 'Hargeisa',
        'currency': 'USD',
        'service_area': {
          'center': {'lat': 9.56, 'lng': 44.065},
          'radius_km': 60,
          'bounds': {'south': 9.45, 'west': 43.95, 'north': 9.65, 'east': 44.15},
          'polygon': [],
          'shape': 'bounds',
          'country_code': 'SO',
          'enforced': true,
        },
      });
      final area = market.serviceArea!;
      expect(area.marketCode, 'hargeisa');
      expect(area.shape, 'bounds');
      expect(area.enforced, isTrue);
      expect(area.countryComponent, 'country:so');
      expect(area.autocompleteRestriction, 'rectangle:9.45,43.95|9.65,44.15');
      expect(area.contains(9.56, 44.06), isTrue);
      expect(area.contains(9.03, 38.74), isFalse);
    });

    test('older backends without service_area keep a null area', () {
      final market = Market.fromJson({'code': 'addis_ababa', 'name': 'Addis'});
      expect(market.serviceArea, isNull);
    });

    test('radius and polygon shapes', () {
      expect(_addisArea.contains(9.0, 38.76), isTrue);
      // ~100 km north of the centre.
      const radiusOnly = CityServiceArea(
        marketCode: 'addis_ababa',
        marketName: 'Addis Ababa',
        centerLat: 9.03,
        centerLng: 38.74,
        radiusKm: 60,
      );
      expect(radiusOnly.contains(9.93, 38.74), isFalse);

      const square = CityServiceArea(
        marketCode: 'x',
        marketName: 'X',
        shape: 'polygon',
        polygon: [
          [9.5, 44.0],
          [9.5, 44.1],
          [9.6, 44.1],
          [9.6, 44.0],
        ],
      );
      expect(square.contains(9.55, 44.05), isTrue);
      expect(square.contains(9.65, 44.05), isFalse);
    });
  });

  group('CityScope one-city rule', () {
    test('no areas means no restriction (pre-Phase-10 backend)', () {
      expect(CityScope.check([
        [9.0, 38.7],
        [9.56, 44.06],
      ]), CityCheck.ok);
      expect(CityScope.allowsPin(9.56, 44.06), isTrue);
    });

    test('same city ok, cross-city, outside and other-city are blocked', () {
      CityScope.update(areas: [_addisArea, _hargeisaArea], current: _addisArea);
      expect(CityScope.check([
        [9.0, 38.76],
        [9.03, 38.75],
      ]), CityCheck.ok);
      expect(CityScope.check([
        [9.0, 38.76],
        [9.56, 44.06],
      ]), CityCheck.crossCity);
      expect(CityScope.check([
        [9.0, 38.76],
        [9.6, 41.85], // Dire Dawa
      ]), CityCheck.outside);
      expect(CityScope.check([
        [9.56, 44.06],
        [9.57, 44.07],
      ]), CityCheck.otherCity);
      expect(CityScope.allowsPin(9.56, 44.06), isFalse);
      expect(CityScope.allowsPin(9.01, 38.75), isTrue);
    });

    test('pins are allowed anywhere while the server does not enforce', () {
      const relaxed = CityServiceArea(
        marketCode: 'addis_ababa',
        marketName: 'Addis Ababa',
        centerLat: 9.03,
        centerLng: 38.74,
      );
      CityScope.update(areas: [relaxed], current: relaxed);
      expect(CityScope.allowsPin(9.56, 44.06), isTrue);
    });
  });

  group('GooglePlacesService city scope', () {
    test('without a city the search stays in Ethiopia', () {
      expect(GooglePlacesService.autocompleteScope(null), {'components': 'country:et'});
      expect(GooglePlacesService.textSearchScope(null), {'region': 'et'});
    });

    test('enforced city restricts autocomplete and filters results', () {
      final scope = GooglePlacesService.autocompleteScope(_hargeisaArea);
      expect(scope['components'], 'country:so');
      expect(scope['locationrestriction'], 'rectangle:9.45,43.95|9.65,44.15');
      expect(scope.containsKey('locationbias'), isFalse);

      final text = GooglePlacesService.textSearchScope(_hargeisaArea);
      expect(text['region'], 'so');
      expect(text['location'], '9.56,44.065');

      final places = [
        PlaceResult(displayName: 'Maroodi Jeex', coordinates: const LatLng(9.56, 44.06)),
        PlaceResult(displayName: 'Bole', coordinates: const LatLng(9.0, 38.76)),
      ];
      final filtered = GooglePlacesService.filterToCity(places, _hargeisaArea);
      expect(filtered.map((p) => p.displayName), ['Maroodi Jeex']);
    });

    test('a city that is not enforced only biases the search', () {
      const relaxed = CityServiceArea(
        marketCode: 'hargeisa',
        marketName: 'Hargeisa',
        centerLat: 9.56,
        centerLng: 44.065,
        bounds: CityBounds(south: 9.45, west: 43.95, north: 9.65, east: 44.15),
        countryCode: 'SO',
      );
      final scope = GooglePlacesService.autocompleteScope(relaxed);
      expect(scope['locationbias'], 'rectangle:9.45,43.95|9.65,44.15');
      expect(scope.containsKey('locationrestriction'), isFalse);
      final places = [
        PlaceResult(displayName: 'Bole', coordinates: const LatLng(9.0, 38.76)),
      ];
      expect(GooglePlacesService.filterToCity(places, relaxed), hasLength(1));
    });
  });

  group('Parcel v2 models', () {
    test('config parses sizes, methods and flags; disabled on bad payloads', () {
      final config = ParcelV2Config.fromResponseBody({
        'success': true,
        'data': {
          'enabled': true,
          'market': 'hargeisa',
          'currency': 'usd',
          'quote_ttl_minutes': 7,
          'handover_code_digits': 4,
          'sizes': [
            {'size': 'small', 'vehicle_type': 'motorbike', 'available': true},
            {'size': 'large', 'vehicle_type': null, 'available': false},
          ],
          'categories': ['document', 'parcel'],
          'payment_methods': ['wallet', 'waafi', 'cash'],
          'recipient_pays_enabled': true,
          'seller_cod_enabled': false,
          'cancellation_fee_after_assign': '0.5',
        },
      });
      expect(config.enabled, isTrue);
      expect(config.currency, 'USD');
      expect(config.quoteTtlMinutes, 7);
      expect(config.sizeOption('small')!.vehicleType, 'motorbike');
      expect(config.sizeOption('large')!.available, isFalse);
      expect(config.paymentMethods, ['wallet', 'waafi', 'cash']);
      expect(config.recipientPaysEnabled, isTrue);
      expect(config.cancellationFeeAfterAssign, 0.5);

      expect(ParcelV2Config.fromResponseBody(null).enabled, isFalse);
      expect(ParcelV2Config.fromResponseBody('oops').enabled, isFalse);
    });

    test('quote countdown uses the server seconds, not the phone clock', () {
      final now = DateTime(2026, 11, 6, 10);
      final quote = ParcelQuote.fromResponseBody({
        'success': true,
        'data': {
          'quote_id': 'pq_abc',
          'amount': 240,
          'currency': 'ETB',
          'vehicle_type': 'motorbike',
          'expires_at': '2030-01-01T00:00:00Z',
          'expires_in_seconds': 600,
        },
      }, receivedAt: now)!;
      expect(quote.amount, 240);
      expect(quote.remaining(now), const Duration(minutes: 10));
      expect(formatQuoteCountdown(quote.remaining(now.add(const Duration(seconds: 61)))), '8:59');
      expect(quote.isExpired(now.add(const Duration(minutes: 11))), isTrue);
      expect(ParcelQuote.fromResponseBody({'data': {'amount': 1}}), isNull);
    });

    test('booking body: recipient defaults, address details, payer rules', () {
      const draft = ParcelBookingDraft(
        pickupLocation: 'Bole, Addis Ababa',
        pickupLat: 9.0,
        pickupLng: 38.76,
        pickupDetails: ParcelAddressDetails(building: 'Edna Mall', floor: '3'),
        dropoffLocation: 'Piassa',
        dropoffLat: 9.03,
        dropoffLng: 38.75,
        recipientName: ' Hana ',
        recipientPhone: '+251933555666',
        category: 'document',
        size: 'small',
        courierNote: '  ',
        paymentMethod: 'wallet',
        marketCode: 'addis_ababa',
      );
      final body = draft.bookBody('pq_1');
      expect(body['quote_id'], 'pq_1');
      expect(body['recipient_name'], 'Hana');
      expect(body['pickup_address'], {
        'formatted_address': 'Bole, Addis Ababa',
        'building': 'Edna Mall',
        'floor': '3',
      });
      expect(body['payer'], 'sender');
      expect(body['payment_method'], 'wallet');
      expect(body.containsKey('courier_note'), isFalse);
      expect(body['market_code'], 'addis_ababa');

      const toSelf = ParcelBookingDraft(
        pickupLocation: 'A',
        pickupLat: 1,
        pickupLng: 2,
        dropoffLocation: 'B',
        dropoffLat: 3,
        dropoffLng: 4,
        recipientIsMe: true,
        recipientPhone: 'ignored',
      );
      expect(toSelf.bookBody('q').containsKey('recipient_phone'), isFalse);

      const cod = ParcelBookingDraft(
        pickupLocation: 'A',
        pickupLat: 1,
        pickupLng: 2,
        dropoffLocation: 'B',
        dropoffLat: 3,
        dropoffLng: 4,
        paymentMethod: 'waafi',
        sellerCodAmount: 800,
      );
      final codBody = cod.bookBody('q');
      expect(codBody['payment_method'], 'cash');
      expect(codBody['payer'], 'recipient');
      expect(codBody['seller_cod'], {'enabled': true, 'amount': 800.0});

      expect(draft.quoteBody(), {
        'pickup_location': 'Bole, Addis Ababa',
        'pickup_latitude': 9.0,
        'pickup_longitude': 38.76,
        'dropoff_latitude': 9.03,
        'dropoff_longitude': 38.75,
        'item_size': 'small',
        'market_code': 'addis_ababa',
      });
    });

    test('parcel detail parses handover code, link and cancel fee', () {
      final parcel = ParcelV2Parcel.fromResponseBody({
        'success': true,
        'data': {
          'id': 12,
          'version': 2,
          'status': 'courier_assigned',
          'step': 1,
          'tracking_number': 'PKG1',
          'price': {'amount': 240, 'currency': 'ETB', 'locked': true},
          'handover': {'code': '0427', 'digits': 4, 'verified': false},
          'tracking_url': 'https://api.test/t/abc',
          'eta_minutes': 18,
          'cancellation': {'can_cancel': true, 'fee': 50, 'currency': 'ETB', 'refund': 190},
        },
      })!;
      expect(parcel.isV2, isTrue);
      expect(parcel.handoverCode, '0427');
      expect(parcel.cancellation!.hasFee, isTrue);
      expect(parcel.isTerminal, isFalse);
      final legacy = parcel.toLegacyDeliveryMap(
        pickupLat: 9,
        pickupLng: 38,
        dropoffLat: 9.1,
        dropoffLng: 38.1,
        pickupLocation: 'A',
        dropoffLocation: 'B',
      );
      expect(legacy['id'], 12);
      expect(legacy['status'], 'courier_assigned');
    });

    test('server codes map to the right message kind', () {
      expect(parcelErrorKind('CITY_CROSS_MARKET'), ParcelErrorKind.crossCity);
      expect(parcelErrorKind('CITY_OUTSIDE_SERVICE_AREA'), ParcelErrorKind.outsideArea);
      expect(parcelErrorKind('CITY_MARKET_MISMATCH'), ParcelErrorKind.otherCity);
      expect(parcelErrorKind('PARCEL_QUOTE_EXPIRED'), ParcelErrorKind.quoteExpired);
      expect(parcelErrorKind('PARCEL_SIZE_NOT_SUPPORTED'), ParcelErrorKind.sizeNotSupported);
      expect(parcelErrorKind(null, message: 'Insufficient wallet balance'), ParcelErrorKind.insufficientWallet);
      expect(parcelErrorKind('SOMETHING'), ParcelErrorKind.other);
    });

    test('money always shows the server currency', () {
      expect(formatParcelMoney(2.4, 'usd'), 'USD 2.40');
      expect(formatParcelMoney(10, null), '10.00');
    });
  });

  group('Parcel v2 widgets', () {
    Widget wrap(Widget child) => MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: Scaffold(body: SingleChildScrollView(child: child)),
        );

    testWidgets('size selector disables sizes the city cannot carry',
        (tester) async {
      final picked = <String>[];
      const config = ParcelV2Config(
        enabled: true,
        sizes: [
          ParcelSizeOption(size: 'small', vehicleType: 'motorbike'),
          ParcelSizeOption(size: 'medium', vehicleType: 'car'),
          ParcelSizeOption(size: 'large', available: false),
        ],
      );
      await tester.pumpWidget(wrap(ParcelSizeSelector(
        config: config,
        selected: 'small',
        onSelected: picked.add,
      )));
      expect(find.text('Small'), findsOneWidget);
      expect(find.text('Not available here yet'), findsOneWidget);

      await tester.tap(find.byKey(const ValueKey('parcel_size_large')));
      await tester.tap(find.byKey(const ValueKey('parcel_size_medium')));
      expect(picked, ['medium']);
    });

    testWidgets('handover code and city banner render', (tester) async {
      await tester.pumpWidget(wrap(const Column(
        children: [
          ParcelHandoverCodeView(code: '0427', hint: 'Give it to the courier'),
          CityOutsideAreaBanner(message: "We don't serve this area yet"),
        ],
      )));
      expect(find.text('0427'), findsOneWidget);
      expect(find.text('Handover code'), findsOneWidget);
      expect(find.text("We don't serve this area yet"), findsOneWidget);
    });

    testWidgets('quote card shows the locked price and countdown',
        (tester) async {
      final quote = ParcelQuote(
        quoteId: 'pq',
        amount: 2.4,
        currency: 'USD',
        expiresAt: DateTime.now().add(const Duration(minutes: 5)),
      );
      await tester.pumpWidget(wrap(ParcelQuoteCard(
        quote: quote,
        loading: false,
        error: null,
        waitingForRoute: false,
        onRefresh: () {},
      )));
      expect(find.text('USD 2.40'), findsOneWidget);
      expect(find.textContaining('Price held for'), findsOneWidget);
    });
  });
}
