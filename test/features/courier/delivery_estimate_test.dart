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
