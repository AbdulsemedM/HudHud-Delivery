import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hudhud_delivery/l10n/app_localizations.dart';
import 'package:hudhud_delivery/features/courier/data/models/delivery_live_tracking.dart';
import 'package:hudhud_delivery/features/courier/data/models/delivery_stop.dart';
import 'package:hudhud_delivery/features/courier/parcel_v2/parcel_v2_models.dart';
import 'package:hudhud_delivery/features/courier/presentation/widgets/delivery_stops_timeline.dart';

void main() {
  testWidgets('timeline renders stops, progress, current code and call',
      (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(
          body: SingleChildScrollView(
            child: DeliveryStopsTimeline.fromDelivery(const {
              'pickup_location': 'Megenagna',
              'stops': [
                {'sequence': 1, 'status': 'delivered', 'location': 'Bole'},
                {
                  'sequence': 2,
                  'status': 'en_route',
                  'location': 'Piassa',
                  'receiver_name': 'Sara',
                  'receiver_phone': '251911000000',
                  'delivery_code': '4821',
                },
              ],
            }),
          ),
        ),
      ),
    );
    expect(find.text('Megenagna'), findsOneWidget);
    expect(find.text('Stop 1'), findsOneWidget);
    expect(find.text('Stop 2'), findsOneWidget);
    expect(find.text('1 of 2 stops done'), findsOneWidget);
    expect(find.text('Code: 4821'), findsOneWidget);
    expect(find.byIcon(Icons.call_rounded), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  group('parseDeliveryStops', () {
    test('empty for single-drop deliveries', () {
      expect(parseDeliveryStops({'id': 1}), isEmpty);
      expect(parseDeliveryStops(null), isEmpty);
      expect(isMultiStopDelivery({'stops': [{'sequence': 1}]}), isFalse);
      expect(multiStopRowAddress({'stops': [{'sequence': 1}]}), isNull);
    });

    test('parses and sorts stops, tolerating alias keys', () {
      final stops = parseDeliveryStops({
        'stops': [
          {
            'sequence': '2',
            'status': 'DELIVERED',
            'address': 'Bole',
            'recipient_name': 'Abebe',
            'otp': '1234',
            'latitude': '9.01',
            'longitude': 38.7,
          },
          {'sequence': 1, 'location': 'Piassa', 'receiver_phone': '2519'},
          {'status': 'pending'}, // no sequence → dropped
        ],
      });
      expect(stops.map((s) => s.sequence), [1, 2]);
      expect(stops[0].location, 'Piassa');
      expect(stops[0].status, DeliveryStopStatus.pending);
      expect(stops[1].isDelivered, isTrue);
      expect(stops[1].location, 'Bole');
      expect(stops[1].receiverName, 'Abebe');
      expect(stops[1].deliveryCode, '1234');
      expect(stops[1].position?.latitude, 9.01);
    });

    test('reads nested data.stops', () {
      final stops = parseDeliveryStops({
        'data': {
          'stops': [
            {'sequence': 1},
            {'sequence': 2},
          ],
        },
      });
      expect(stops, hasLength(2));
    });
  });

  group('currentDeliveryStop', () {
    final delivery = <String, dynamic>{
      'stops': [
        {'sequence': 1, 'status': 'delivered', 'location': 'A'},
        {'sequence': 2, 'status': 'en_route', 'location': 'B'},
        {'sequence': 3, 'status': 'pending', 'location': 'C'},
      ],
    };

    test('first stop not done when the server gives no sequence', () {
      expect(currentDeliveryStop(delivery)?.sequence, 2);
      expect(multiStopRowAddress(delivery), 'B');
    });

    test('server current_stop_sequence wins', () {
      expect(
        currentDeliveryStop({...delivery, 'current_stop_sequence': 3})
            ?.sequence,
        3,
      );
    });

    test('null when every stop is done; row address falls back to last', () {
      final done = <String, dynamic>{
        'stops': [
          {'sequence': 1, 'status': 'delivered', 'location': 'A'},
          {'sequence': 2, 'status': 'failed', 'location': 'B'},
        ],
      };
      expect(currentDeliveryStop(done), isNull);
      expect(multiStopRowAddress(done), 'B');
    });
  });

  test('live tracking parses destination_stop_sequence and stops', () {
    final live = parseDeliveryLiveTrackingResponse({
      'data': {
        'tracking': {
          'status': 'en_route_dropoff',
          'destination_stop_sequence': 2,
          'stops': [
            {'sequence': 1},
            {'sequence': 2},
          ],
        },
      },
    });
    expect(live.destinationStopSequence, 2);
    expect(live.stops, hasLength(2));
  });

  group('ParcelV2Parcel.toLegacyDeliveryMap stops', () {
    Map<String, dynamic> legacy(Map<String, dynamic> parcelJson) {
      final parcel = ParcelV2Parcel.fromJson(parcelJson)!;
      return parcel.toLegacyDeliveryMap(
        pickupLat: 9,
        pickupLng: 38,
        dropoffLat: 9.1,
        dropoffLng: 38.1,
        pickupLocation: 'P',
        dropoffLocation: 'D',
        stopCoordinates: const [
          [9.05, 38.05],
          [9.1, 38.1],
        ],
      );
    }

    test('single-drop parcel has no stops key', () {
      final map = legacy({'id': 5, 'status': 'searching'});
      expect(map.containsKey('stops'), isFalse);
    });

    test('multi-drop maps statuses, codes and coordinates', () {
      final map = legacy({
        'id': 5,
        'status': 'picked_up',
        'current_stop': 2,
        'stops': [
          {
            'sequence': 1,
            'status': 'returned',
            'address': 'Bole',
            'recipient_name': 'A',
            'handover': {'code': '1111', 'verified': true},
          },
          {
            'sequence': 2,
            'status': 'arrived',
            'address': 'Piassa',
            'recipient_phone': '2519',
            'handover': {'code': '2222', 'verified': false},
          },
        ],
      });
      expect(map['current_stop_sequence'], 2);
      final stops = parseDeliveryStops(map);
      expect(stops, hasLength(2));
      expect(stops[0].status, DeliveryStopStatus.failed);
      expect(stops[0].deliveryCode, isNull); // already verified
      expect(stops[0].position?.latitude, 9.05);
      expect(stops[1].status, DeliveryStopStatus.arrived);
      expect(stops[1].deliveryCode, '2222');
      expect(stops[1].location, 'Piassa');
      expect(currentDeliveryStop(map)?.sequence, 2);
    });
  });
  group('parcel-shaped stops (backend package_delivery_stops)', () {
    test('reads lat/lng, recipient, nested handover code and current_stop', () {
      final map = <String, dynamic>{
        'current_stop': 2,
        'stops': [
          {
            'sequence': 1,
            'status': 'returned',
            'address': 'Kazanchis',
            'lat': 9.01,
            'lng': 38.76,
            'recipient_name': 'Abebe',
            'recipient_phone': '251911000001',
            'handover': {'code': '4821', 'verified': true},
          },
          {
            'sequence': 2,
            'status': 'pending',
            'address': 'Piassa',
            'lat': '9.03',
            'lng': '38.75',
            'recipient_name': 'Sara',
            'handover': {'code': '1234', 'verified': false},
            'is_current': true,
          },
        ],
      };
      final stops = parseDeliveryStops(map);
      expect(stops, hasLength(2));
      expect(stops[0].status, DeliveryStopStatus.failed);
      expect(stops[0].isDone, isTrue);
      expect(stops[0].deliveryCode, isNull); // verified: nothing to share
      expect(stops[0].position, isNotNull);
      expect(stops[1].latitude, 9.03);
      expect(stops[1].receiverName, 'Sara');
      expect(stops[1].deliveryCode, '1234');
      expect(stops[1].isCurrent, isTrue);
      expect(currentDeliveryStop(map)?.sequence, 2);
      expect(
        currentDeliveryStop({'stops': map['stops']})?.sequence,
        2, // falls back to is_current
      );
    });

    test('live tracking accepts current_stop', () {
      final t = parseDeliveryLiveTrackingResponse({
        'data': {
          'tracking': {'status': 'en_route_dropoff', 'current_stop': 3},
        },
      });
      expect(t.destinationStopSequence, 3);
    });
  });
}
