import 'package:flutter_test/flutter_test.dart';
import 'package:hudhud_delivery/features/courier/data/models/delivery_live_tracking.dart';
import 'package:hudhud_delivery/features/courier/data/models/nearby_drivers_result.dart';

void main() {
  group('parseNearbyDriversResponse', () {
    test('parses anonymous markers and refresh interval', () {
      final result = parseNearbyDriversResponse({
        'success': true,
        'drivers': [
          {
            'marker_id': 'nearby_7f8a6b1d4c2e9a10',
            'label': 'Available motorbike',
            'vehicle_type': 'motorbike',
            'latitude': 8.982,
            'longitude': 38.764,
            'heading': 87.0,
            'distance_km': 0.2,
            'estimated_pickup_minutes': 3,
            'rank': 1,
          },
        ],
        'total': 1,
        'privacy': {
          'mode': 'nearby_anonymous',
          'message': 'Nearby markers are approximate and anonymous.',
        },
        'refresh_after_seconds': 15,
      });

      expect(result.drivers, hasLength(1));
      expect(result.drivers.first.markerId, 'nearby_7f8a6b1d4c2e9a10');
      expect(result.drivers.first.latitude, 8.982);
      expect(result.drivers.first.longitude, 38.764);
      expect(result.drivers.first.heading, 87.0);
      expect(result.drivers.first.vehicleType, 'motorbike');
      expect(result.refreshAfterSeconds, 15);
      expect(result.privacyMessage, contains('approximate'));
      expect(result.total, 1);
    });

    test('skips entries without marker_id or coordinates', () {
      final result = parseNearbyDriversResponse({
        'drivers': [
          {'latitude': 1.0, 'longitude': 2.0},
          {'marker_id': 'ok', 'latitude': 3.0, 'longitude': 4.0},
        ],
      });
      expect(result.drivers, hasLength(1));
      expect(result.drivers.first.markerId, 'ok');
    });
  });

  group('parseDeliveryLiveTrackingResponse', () {
    test('parses searching payload without driver identity', () {
      final tracking = parseDeliveryLiveTrackingResponse({
        'success': true,
        'tracking': {
          'kind': 'delivery',
          'job_id': 654,
          'status': 'searching',
          'tracking_available': false,
          'message': 'We are finding the nearest available driver.',
          'poll_after_seconds': 10,
        },
      });
      expect(tracking.trackingAvailable, isFalse);
      expect(tracking.status, 'searching');
      expect(tracking.pollAfterSeconds, 10);
      expect(tracking.driver, isNull);
      expect(tracking.driverLocation, isNull);
    });

    test('parses accepted live tracking with route and driver', () {
      final tracking = parseDeliveryLiveTrackingResponse({
        'success': true,
        'tracking': {
          'kind': 'delivery',
          'job_id': 654,
          'status': 'accepted',
          'tracking_available': true,
          'poll_after_seconds': 7,
          'driver': {
            'id': 92,
            'name': 'Driver Name',
            'phone': '2519xxxxxxxx',
            'vehicle_type': 'car',
            'vehicle_color': 'White',
            'vehicle_plate_number': 'AA-2-12345',
            'rating': 4.8,
          },
          'driver_location': {
            'latitude': 8.98185069,
            'longitude': 38.76324892,
            'heading': 87.0,
            'speed_kph': 24.0,
            'accuracy_meters': 12.0,
            'recorded_at': '2026-08-19T10:30:12.000000Z',
            'age_seconds': 5,
            'is_live': true,
          },
          'destination': {
            'label': 'pickup',
            'latitude': 8.99012,
            'longitude': 38.77021,
          },
          'route': {
            'origin': {'latitude': 8.98185069, 'longitude': 38.76324892},
            'destination': {'latitude': 8.99012, 'longitude': 38.77021},
          },
          'estimated_arrival_minutes': 4,
        },
      });

      expect(tracking.trackingAvailable, isTrue);
      expect(tracking.pollAfterSeconds, 7);
      expect(tracking.driver?.name, 'Driver Name');
      expect(tracking.driver?.vehiclePlateNumber, 'AA-2-12345');
      expect(tracking.driverLocation?.isLive, isTrue);
      expect(tracking.destinationLabel, 'pickup');
      expect(tracking.routeOrigin?.latitude, closeTo(8.98185069, 0.0000001));
      expect(tracking.estimatedArrivalMinutes, 4);
    });
  });

  group('destinationLabelForDeliveryStatus', () {
    test('maps pickup and dropoff lifecycle statuses', () {
      expect(destinationLabelForDeliveryStatus('pickup_assigned'), 'pickup');
      expect(destinationLabelForDeliveryStatus('en_route_pickup'), 'pickup');
      expect(destinationLabelForDeliveryStatus('at_pickup'), 'pickup');
      expect(destinationLabelForDeliveryStatus('en_route_dropoff'), 'dropoff');
      expect(destinationLabelForDeliveryStatus('at_dropoff'), 'dropoff');
      expect(destinationLabelForDeliveryStatus('rider_assigned'), 'pickup');
      expect(destinationLabelForDeliveryStatus('out_for_delivery'), 'dropoff');
    });

    test('prefers API destination label on tracking model', () {
      const tracking = DeliveryLiveTracking(
        status: 'en_route_dropoff',
        destinationLabel: 'pickup',
      );
      expect(tracking.effectiveDestinationLabel, 'pickup');
    });
  });

  group('retainDriverLocation', () {
    test('keeps last coordinates when incoming is not live and missing lat/lng', () {
      const previous = GeoPoint(latitude: 8.98, longitude: 38.76);
      const incoming = LiveTrackingDriverLocation(isLive: false);
      final retained = retainDriverLocation(
        previous: previous,
        incoming: incoming,
      );
      expect(retained, isNotNull);
      expect(retained!.latitude, 8.98);
      expect(retained.longitude, 38.76);
    });

    test('does not replace a valid location with null incoming', () {
      const previous = GeoPoint(latitude: 1, longitude: 2);
      final retained = retainDriverLocation(
        previous: previous,
        incoming: null,
      );
      expect(retained!.latitude, 1);
      expect(retained.longitude, 2);
    });

    test('updates when incoming has coordinates even if is_live is false', () {
      const previous = GeoPoint(latitude: 1, longitude: 2);
      const incoming = LiveTrackingDriverLocation(
        latitude: 9.0,
        longitude: 38.0,
        isLive: false,
      );
      final retained = retainDriverLocation(
        previous: previous,
        incoming: incoming,
      );
      expect(retained!.latitude, 9.0);
      expect(retained.longitude, 38.0);
    });
  });
}
