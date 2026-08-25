import 'package:flutter_test/flutter_test.dart';
import 'package:hudhud_delivery/features/courier/utils/delivery_estimate.dart';

void main() {
  group('deliveryServiceType', () {
    test('maps instant delivery to same_day', () {
      expect(deliveryServiceType(isInstantDelivery: true), 'same_day');
    });

    test('maps scheduled delivery to standard', () {
      expect(deliveryServiceType(isInstantDelivery: false), 'standard');
    });
  });

  group('courier estimate placeholders', () {
    test('placeholder weight is min weight times min quantity', () {
      expect(kCourierEstimatePlaceholderWeightKg, 1.0);
      expect(
        kCourierEstimatePlaceholderWeightKg,
        kCourierEstimateMinWeightKg * kCourierEstimateMinQuantity,
      );
    });

    test('placeholder package type is other', () {
      expect(kCourierEstimatePlaceholderPackageType, 'other');
    });
  });

  group('mapCourierVehicleType', () {
    test('maps motorcycle to motorbike', () {
      expect(mapCourierVehicleType('motorcycle'), 'motorbike');
    });

    test('passes through API vehicle types', () {
      expect(mapCourierVehicleType('motorbike'), 'motorbike');
      expect(mapCourierVehicleType('car'), 'car');
      expect(mapCourierVehicleType('bajaj'), 'bajaj');
      expect(mapCourierVehicleType('pickup'), 'pickup');
    });

    test('passes through unknown values', () {
      expect(mapCourierVehicleType('truck'), 'truck');
    });
  });

  group('applyCourierSupportedVehicleTypes', () {
    test('keeps current selection when still supported', () {
      final result = applyCourierSupportedVehicleTypes(
        supportedVehicleTypes: const ['motorbike', 'car'],
        selectedVehicleType: 'car',
      );
      expect(result.types, ['motorbike', 'car']);
      expect(result.selected, 'car');
    });

    test('selects first type when current is unsupported', () {
      final result = applyCourierSupportedVehicleTypes(
        supportedVehicleTypes: const ['bajaj', 'pickup'],
        selectedVehicleType: 'motorbike',
      );
      expect(result.selected, 'bajaj');
    });

    test('returns null selection when types are empty', () {
      final result = applyCourierSupportedVehicleTypes(
        supportedVehicleTypes: const [],
        selectedVehicleType: 'motorbike',
      );
      expect(result.types, isEmpty);
      expect(result.selected, isNull);
    });

    test('normalizes legacy motorcycle UI id', () {
      final result = applyCourierSupportedVehicleTypes(
        supportedVehicleTypes: const ['motorbike', 'car'],
        selectedVehicleType: 'motorcycle',
      );
      expect(result.selected, 'motorbike');
    });
  });

  group('buildDeliveryEstimateRequestBody', () {
    test('includes pickup_location when provided', () {
      final body = buildDeliveryEstimateRequestBody(
        packageType: 'parcel',
        packageWeight: 1.0,
        pickupLatitude: 8.9806,
        pickupLongitude: 38.7578,
        dropoffLatitude: 8.9956,
        dropoffLongitude: 38.7894,
        vehicleType: 'bajaj',
        serviceType: 'standard',
        pickupLocation: 'Bole, Addis Ababa',
      );

      expect(body['pickup_location'], 'Bole, Addis Ababa');
      expect(body['vehicle_type'], 'bajaj');
      expect(body.containsKey('scheduled_pickup'), isFalse);
    });

    test('omits pickup_location when blank', () {
      final body = buildDeliveryEstimateRequestBody(
        packageType: 'other',
        packageWeight: 1.0,
        pickupLatitude: 1,
        pickupLongitude: 2,
        dropoffLatitude: 3,
        dropoffLongitude: 4,
        vehicleType: 'motorbike',
        serviceType: 'same_day',
        pickupLocation: '   ',
      );

      expect(body.containsKey('pickup_location'), isFalse);
    });
  });

  group('formatDeliveryScheduledPickup', () {
    test('formats wall clock as Addis Ababa with +03:00', () {
      expect(
        formatDeliveryScheduledPickup(DateTime(2026, 8, 23, 20, 0, 0)),
        '2026-08-23T20:00:00+03:00',
      );
    });

    test('pads single-digit fields', () {
      expect(
        formatDeliveryScheduledPickup(DateTime(2026, 1, 5, 9, 5, 7)),
        '2026-01-05T09:05:07+03:00',
      );
    });
  });

  group('parseDeliveryEstimate', () {
    test('parses flat estimate payload from the API', () {
      final estimate = parseDeliveryEstimate({
        'estimated_distance': 1.14,
        'estimated_duration': 3,
        'estimated_cost': 96,
        'base_delivery_fee': 50,
        'distance_rate': 20,
        'free_distance': 2,
        'weight_charge': 6,
        'package_type': 'document',
        'service_type': 'express',
        'currency': 'ETB',
        'vehicle_type': 'bicycle',
      });

      expect(estimate.isValid, isTrue);
      expect(estimate.estimatedCost, 96.0);
      expect(estimate.estimatedDistance, 1.14);
      expect(estimate.estimatedDuration, 3);
      expect(estimate.currency, 'ETB');
      expect(estimate.baseDeliveryFee, 50.0);
      expect(estimate.distanceRate, 20.0);
      expect(estimate.freeDistance, 2.0);
      expect(estimate.weightCharge, 6.0);
      expect(estimate.timeBandName, isNull);
      expect(estimate.hasTimeBandSurcharge, isFalse);
      expect(estimate.vehicleType, 'bicycle');
    });

    test('parses night time-band pricing from the handoff sample', () {
      final estimate = parseDeliveryEstimate({
        'estimated_distance': 10.9,
        'estimated_duration': 31,
        'estimated_cost': 172.8,
        'currency': 'ETB',
        'pricing': {
          'time_band': {
            'name': 'night',
            'multiplier': 1.2,
            'surcharge_rate': 0.2,
            'evaluated_pickup_at': '2026-08-23T20:00:00+03:00',
            'timezone': 'Africa/Addis_Ababa',
            'night_hours': {
              'start': 20,
              'end': 6,
            },
          },
          'time_band_surcharge': 28.8,
        },
        'route': {
          'source': 'google_routes',
          'distance_meters': 10900,
          'duration_seconds': 1860,
        },
      });

      expect(estimate.isValid, isTrue);
      expect(estimate.estimatedCost, 172.8);
      expect(estimate.estimatedDistance, 10.9);
      expect(estimate.estimatedDuration, 31);
      expect(estimate.timeBandName, 'night');
      expect(estimate.timeBandMultiplier, 1.2);
      expect(estimate.timeBandSurchargeRate, 0.2);
      expect(estimate.timeBandSurcharge, 28.8);
      expect(estimate.hasTimeBandSurcharge, isTrue);
      expect(estimate.evaluatedPickupAt, '2026-08-23T20:00:00+03:00');
      expect(estimate.timezone, 'Africa/Addis_Ababa');
      expect(estimate.nightHoursStart, 20);
      expect(estimate.nightHoursEnd, 6);
    });

    test('parses nested data wrapper', () {
      final estimate = parseDeliveryEstimate({
        'success': true,
        'data': {
          'estimated_distance': 2.5,
          'estimated_duration': 8,
          'estimated_cost': 83.60,
          'currency': 'ETB',
          'base_delivery_fee': 50,
          'weight_charge': 6,
        },
      });

      expect(estimate.estimatedCost, 83.60);
      expect(estimate.estimatedDistance, 2.5);
      expect(estimate.estimatedDuration, 8);
      expect(estimate.baseDeliveryFee, 50.0);
      expect(estimate.weightCharge, 6.0);
    });

    test('coerces generic Map items from Dio', () {
      final estimate = parseDeliveryEstimate(
        Map<Object?, Object?>.from({
          'estimated_distance': '1.14',
          'estimated_duration': '3',
          'estimated_cost': '83.60',
          'base_delivery_fee': '50',
          'weight_charge': '6',
          'currency': 'ETB',
        }),
      );

      expect(estimate.estimatedCost, 83.60);
      expect(estimate.estimatedDistance, 1.14);
      expect(estimate.estimatedDuration, 3);
      expect(estimate.baseDeliveryFee, 50.0);
      expect(estimate.weightCharge, 6.0);
    });

    test('returns invalid estimate for missing payload', () {
      expect(parseDeliveryEstimate(null).isValid, isFalse);
      expect(parseDeliveryEstimate('bad').isValid, isFalse);
      expect(parseDeliveryEstimate({}).isValid, isFalse);
    });
  });
}
