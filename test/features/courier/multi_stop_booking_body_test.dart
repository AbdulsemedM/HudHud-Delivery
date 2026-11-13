import 'package:flutter_test/flutter_test.dart';
import 'package:hudhud_delivery/features/courier/data/models/delivery_stop.dart';
import 'package:hudhud_delivery/features/courier/presentation/widgets/extra_stops_editor.dart';
import 'package:hudhud_delivery/features/courier/utils/delivery_estimate.dart';
import 'package:hudhud_delivery/features/courier/utils/multi_stop_body.dart';
import 'package:latlong2/latlong.dart';

void main() {
  const pickup = LatLng(9.0, 38.7);
  const first = LatLng(9.01, 38.71);
  const second = LatLng(9.02, 38.72);
  const third = LatLng(9.03, 38.73);

  List<DeliveryStopDraft> stops({bool multi = true}) => allDeliveryStops(
        firstLocation: 'Bole',
        firstPosition: first,
        firstReceiverName: 'Abebe',
        firstReceiverPhone: '251911111111',
        extraStops: multi
            ? const [
                DeliveryStopDraft(
                  location: 'Piassa',
                  position: second,
                  receiverName: 'Sara',
                  receiverPhone: '0922222222',
                  note: 'Blue gate',
                ),
                DeliveryStopDraft(
                  location: 'Kazanchis',
                  position: third,
                  receiverName: 'Hana',
                  receiverPhone: '251933333333',
                ),
              ]
            : const [],
      );

  group('estimate body', () {
    Map<String, dynamic> build(List<Map<String, dynamic>>? s) =>
        buildDeliveryEstimateRequestBody(
          packageType: 'other',
          packageWeight: 1,
          pickupLatitude: pickup.latitude,
          pickupLongitude: pickup.longitude,
          dropoffLatitude: third.latitude,
          dropoffLongitude: third.longitude,
          vehicleType: 'motorbike',
          serviceType: 'same_day',
          stops: s,
        );

    test('single drop-off sends no stops (body unchanged)', () {
      expect(estimateStopsJson(stops(multi: false)), isNull);
      final body = build(estimateStopsJson(stops(multi: false)));
      expect(body.containsKey('stops'), isFalse);
    });

    test('multi-stop sends every drop-off in order', () {
      final body = build(estimateStopsJson(stops()));
      expect(body['stops'], [
        {'sequence': 1, 'latitude': 9.01, 'longitude': 38.71},
        {'sequence': 2, 'latitude': 9.02, 'longitude': 38.72},
        {'sequence': 3, 'latitude': 9.03, 'longitude': 38.73},
      ]);
      expect(body['dropoff_latitude'], 9.03);
    });
  });

  group('request body', () {
    Map<String, dynamic> base() => {
          'dropoff_location': 'Bole',
          'dropoff_latitude': 9.01,
          'dropoff_longitude': 38.71,
          'receiver_name': 'Abebe',
          'receiver_phone': '251911111111',
          'delivery_address': {
            'latitude': 9.01,
            'longitude': 38.71,
            'address': 'Bole',
          },
        };

    test('single drop-off leaves the body untouched', () {
      final body = base();
      applyMultiStopToRequestBody(body, stops(multi: false));
      expect(body, base());
    });

    test('multi-stop adds stops and moves dropoff to the route end', () {
      final body = base();
      applyMultiStopToRequestBody(
        body,
        stops(),
        normalizePhone: (p) => p.startsWith('0') ? '251${p.substring(1)}' : p,
      );
      expect(body['receiver_name'], 'Abebe');
      expect(body['dropoff_location'], 'Kazanchis');
      expect(body['dropoff_latitude'], 9.03);
      expect(body['delivery_address'], {
        'latitude': 9.03,
        'longitude': 38.73,
        'address': 'Kazanchis',
      });
      expect(body['stops'], [
        {
          'sequence': 1,
          'location': 'Bole',
          'latitude': 9.01,
          'longitude': 38.71,
          'receiver_name': 'Abebe',
          'receiver_phone': '251911111111',
        },
        {
          'sequence': 2,
          'location': 'Piassa',
          'latitude': 9.02,
          'longitude': 38.72,
          'receiver_name': 'Sara',
          'receiver_phone': '251922222222',
          'note': 'Blue gate',
        },
        {
          'sequence': 3,
          'location': 'Kazanchis',
          'latitude': 9.03,
          'longitude': 38.73,
          'receiver_name': 'Hana',
          'receiver_phone': '251933333333',
        },
      ]);
    });
  });

  group('editor helpers', () {
    test('movedListItem moves within bounds only', () {
      expect(movedListItem([1, 2, 3], 0, 1), [2, 1, 3]);
      expect(movedListItem([1, 2, 3], 2, -1), [1, 3, 2]);
      expect(movedListItem([1, 2, 3], 0, -1), [1, 2, 3]);
      expect(movedListItem([1, 2, 3], 2, 1), [1, 2, 3]);
    });

    test('boundsForPoints spans all points', () {
      final b = boundsForPoints([pickup, first, third])!;
      expect(b.southwest.latitude, 9.0);
      expect(b.northeast.longitude, 38.73);
      expect(boundsForPoints([pickup]), isNull);
      expect(boundsForPoints([pickup, pickup]), isNull);
    });
  });
}
