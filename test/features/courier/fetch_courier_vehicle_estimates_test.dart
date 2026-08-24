import 'package:flutter_test/flutter_test.dart';
import 'package:hudhud_delivery/features/courier/utils/delivery_estimate.dart';
import 'package:hudhud_delivery/features/courier/utils/fetch_courier_vehicle_estimates.dart';

DeliveryEstimate _quote({required double cost, int duration = 6}) {
  return DeliveryEstimate(
    estimatedCost: cost,
    estimatedDuration: duration,
    currency: 'ETB',
  );
}

Map<String, dynamic> _success({required double cost, int duration = 6}) {
  return {
    'success': true,
    'estimatedCost': cost,
    'estimatedDuration': duration,
    'estimatedDistance': 2.0,
    'currency': 'ETB',
  };
}

void main() {
  group('deliveryEstimateFromRepositoryResult', () {
    test('returns estimate when success and cost are present', () {
      final estimate = deliveryEstimateFromRepositoryResult(_success(cost: 87));
      expect(estimate, isNotNull);
      expect(estimate!.isValid, isTrue);
      expect(estimate.estimatedCost, 87);
    });

    test('returns null when success is false', () {
      expect(
        deliveryEstimateFromRepositoryResult({'success': false}),
        isNull,
      );
    });

    test('returns null when cost is missing', () {
      expect(
        deliveryEstimateFromRepositoryResult({
          'success': true,
          'estimatedDuration': 6,
          'currency': 'ETB',
        }),
        isNull,
      );
    });
  });

  group('mergeCourierVehicleEstimates', () {
    test('keeps only requested ids with valid quotes by default', () {
      final merged = mergeCourierVehicleEstimates(
        requestedIds: const ['motorbike', 'bajaj', 'pickup'],
        quotes: {
          'motorbike': null,
          'bajaj': null,
          'pickup': null,
        },
      );

      expect(merged.visibleIds, isEmpty);
      expect(merged.byVehicle, isEmpty);
    });

    test('keeps successful quotes for mixed API vehicle ids', () {
      final merged = mergeCourierVehicleEstimates(
        requestedIds: const ['motorbike', 'car', 'bajaj', 'pickup'],
        quotes: {
          'motorbike': _quote(cost: 87),
          'car': _quote(cost: 131, duration: 3),
          'bajaj': _quote(cost: 95),
          'pickup': _quote(cost: 220, duration: 12),
        },
      );

      expect(merged.visibleIds, ['motorbike', 'car', 'bajaj', 'pickup']);
      expect(merged.byVehicle['car']?.estimatedCost, 131);
      expect(merged.byVehicle['pickup']?.estimatedCost, 220);
    });

    test('drops invalid quotes unless alwaysVisible', () {
      final merged = mergeCourierVehicleEstimates(
        requestedIds: const ['motorbike', 'car'],
        quotes: {
          'motorbike': _quote(cost: 87),
          'car': const DeliveryEstimate(estimatedDuration: 3),
        },
        alwaysVisible: const {'motorbike'},
      );

      expect(merged.visibleIds, ['motorbike']);
      expect(merged.byVehicle.containsKey('car'), isFalse);
      expect(merged.byVehicle['motorbike']?.estimatedCost, 87);
    });
  });

  group('fetchCourierEstimatesForVehicles', () {
    test('does not invent vehicles when quotes fail', () async {
      final result = await fetchCourierEstimatesForVehicles(
        vehicleIds: const ['motorbike', 'car'],
        estimateForVehicle: (id) async {
          if (id == 'motorbike') return _success(cost: 87);
          throw Exception('unsupported vehicle');
        },
      );

      expect(result.visibleIds, ['motorbike']);
      expect(result.byVehicle['motorbike']?.estimatedCost, 87);
    });

    test('keeps all successful API vehicle quotes', () async {
      final result = await fetchCourierEstimatesForVehicles(
        vehicleIds: const ['motorbike', 'car', 'bajaj'],
        estimateForVehicle: (id) async {
          switch (id) {
            case 'car':
              return _success(cost: 131, duration: 3);
            case 'bajaj':
              return _success(cost: 95);
            default:
              return _success(cost: 87);
          }
        },
      );

      expect(result.visibleIds, ['motorbike', 'car', 'bajaj']);
      expect(result.byVehicle['car']?.estimatedCost, 131);
      expect(result.byVehicle['bajaj']?.estimatedCost, 95);
    });
  });
}
