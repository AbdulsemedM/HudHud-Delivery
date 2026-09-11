import 'package:flutter_test/flutter_test.dart';
import 'package:hudhud_delivery/features/checkout/data/models/delivery_fee_quote.dart';
import 'package:hudhud_delivery/features/checkout/utils/nearest_branch.dart';
import 'package:hudhud_delivery/features/guest/model/branch_model.dart';

void main() {
  group('DeliveryFeeQuote.fromJson', () {
    test('parses success payload fields', () {
      final quote = DeliveryFeeQuote.fromJson({
        'delivery_fee': 7.02,
        'currency': 'ETB',
        'currency_symbol': 'Br',
        'formatted_delivery_fee': 'Br7.02',
        'distance_km': 3.0,
        'distance_source': 'haversine_estimate',
        'estimated_duration_minutes': 24,
        'quoted_at': DateTime.now().toUtc().toIso8601String(),
        'valid_until':
            DateTime.now().toUtc().add(const Duration(minutes: 10)).toIso8601String(),
        'restaurant': {
          'branch_id': 8,
          'name': 'QR Test Branch',
          'address': 'Bole Atlas, Addis Ababa',
          'latitude': 8.9821,
          'longitude': 38.7812,
        },
        'delivery_address': {
          'address': 'Bole Atlas, Addis Ababa, Ethiopia',
          'latitude': 8.9958672,
          'longitude': 38.7899086,
        },
        'breakdown': {
          'base_fee': 5.0,
          'distance_charge': 2.02,
          'distance_rate': 2.02,
          'free_distance_km': 2,
          'surge_multiplier': 1.0,
          'surge_applied': false,
          'night_surcharge': 0.2,
          'night_surcharge_applied': false,
        },
      });

      expect(quote.deliveryFee, 7.02);
      expect(quote.currency, 'ETB');
      expect(quote.currencySymbol, 'Br');
      expect(quote.formattedDeliveryFee, 'Br7.02');
      expect(quote.distanceKm, 3.0);
      expect(quote.distanceSource, 'haversine_estimate');
      expect(quote.estimatedDurationMinutes, 24);
      expect(quote.restaurant?.branchId, 8);
      expect(quote.breakdown?.baseFee, 5.0);
      expect(quote.isUsable, isTrue);
    });
  });

  group('deliveryFeeQuoteCacheKey', () {
    test('stable for same inputs', () {
      final a = deliveryFeeQuoteCacheKey(
        branchId: 8,
        latitude: 8.9958672,
        longitude: 38.7899086,
        address: ' Bole Atlas ',
      );
      final b = deliveryFeeQuoteCacheKey(
        branchId: 8,
        latitude: 8.9958672,
        longitude: 38.7899086,
        address: 'Bole Atlas',
      );
      expect(a, b);
    });
  });

  group('pickNearestActiveBranch', () {
    test('selects closest active branch with coordinates', () {
      final branches = [
        const BranchModel(
          id: 1,
          name: 'Far',
          isActive: true,
          locationLatitude: 9.1,
          locationLongitude: 38.9,
        ),
        const BranchModel(
          id: 2,
          name: 'Near',
          isActive: true,
          locationLatitude: 8.996,
          locationLongitude: 38.79,
        ),
        const BranchModel(
          id: 3,
          name: 'Inactive near',
          isActive: false,
          locationLatitude: 8.9959,
          locationLongitude: 38.7899,
        ),
      ];

      final picked = pickNearestActiveBranch(
        branches: branches,
        latitude: 8.9958672,
        longitude: 38.7899086,
      );

      expect(picked?.id, 2);
    });

    test('falls back to first active without coords', () {
      final branches = [
        const BranchModel(id: 4, name: 'No coords', isActive: true),
        const BranchModel(id: 5, name: 'Also none', isActive: true),
      ];

      final picked = pickNearestActiveBranch(
        branches: branches,
        latitude: 8.99,
        longitude: 38.78,
      );

      expect(picked?.id, 4);
    });
  });

  group('haversineDistanceKm', () {
    test('is roughly zero for same point', () {
      expect(haversineDistanceKm(8.99, 38.78, 8.99, 38.78), closeTo(0, 0.001));
    });
  });
}
