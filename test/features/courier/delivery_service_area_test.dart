import 'package:flutter_test/flutter_test.dart';
import 'package:hudhud_delivery/features/courier/data/models/delivery_service_area.dart';

void main() {
  group('parseDeliveryServiceAreaLookup', () {
    test('parses Jijiga pickup lookup with top-level vehicle types', () {
      final lookup = parseDeliveryServiceAreaLookup({
        'success': true,
        'data': {
          'pickup_location': 'Fafan, Jijiga',
          'service_area': {
            'id': 'jijiga',
            'name': 'Jijiga',
            'enabled': true,
            'city_aliases': ['Jijiga', 'Fafan', 'Fafa'],
            'supported_vehicle_types': ['motorbike', 'bajaj', 'pickup'],
          },
          'supported_vehicle_types': ['motorbike', 'bajaj', 'pickup'],
          'areas': [],
        },
      });

      expect(lookup.pickupLocation, 'Fafan, Jijiga');
      expect(lookup.supportedVehicleTypes, ['motorbike', 'bajaj', 'pickup']);
      expect(lookup.serviceArea?.id, 'jijiga');
      expect(lookup.serviceArea?.enabled, isTrue);
      expect(lookup.areas, isEmpty);
    });

    test('parses Addis-style motorbike and car without hardcoding city', () {
      final lookup = parseDeliveryServiceAreaLookup({
        'success': true,
        'data': {
          'pickup_location': 'Bole, Addis Ababa',
          'supported_vehicle_types': ['motorbike', 'car'],
          'service_area': {
            'id': 'addis-ababa',
            'name': 'Addis Ababa',
            'enabled': true,
            'city_aliases': ['Addis Ababa', 'Addis', 'Bole'],
            'supported_vehicle_types': ['motorbike', 'car'],
            'vehicle_pricing': {
              'motorbike': <String, dynamic>{},
              'car': <String, dynamic>{},
            },
          },
        },
      });

      expect(lookup.supportedVehicleTypes, ['motorbike', 'car']);
      expect(lookup.serviceArea?.name, 'Addis Ababa');
    });

    test('clears vehicles when the matched city is disabled', () {
      final lookup = parseDeliveryServiceAreaLookup({
        'success': true,
        'data': {
          'pickup_location': 'Unknown Town',
          'supported_vehicle_types': ['motorbike'],
          'service_area': {
            'id': 'unknown',
            'name': 'Unknown',
            'enabled': false,
            'supported_vehicle_types': ['motorbike'],
          },
        },
      });

      expect(lookup.supportedVehicleTypes, isEmpty);
      expect(lookup.serviceArea?.enabled, isFalse);
    });

    test('returns empty types when pickup is outside configured area', () {
      final lookup = parseDeliveryServiceAreaLookup({
        'success': true,
        'data': {
          'pickup_location': 'Somewhere else',
          'supported_vehicle_types': <String>[],
          'service_area': null,
          'areas': [],
        },
      });

      expect(lookup.supportedVehicleTypes, isEmpty);
      expect(lookup.serviceArea, isNull);
    });

    test('parses areas catalog when pickup_location is omitted', () {
      final lookup = parseDeliveryServiceAreaLookup({
        'success': true,
        'data': {
          'supported_vehicle_types': <String>[],
          'areas': [
            {
              'id': 'jijiga',
              'name': 'Jijiga',
              'enabled': true,
              'supported_vehicle_types': ['motorbike', 'bajaj', 'pickup'],
            },
            {
              'id': 'addis_ababa',
              'name': 'Addis Ababa',
              'enabled': true,
              'supported_vehicle_types': ['motorbike', 'car'],
            },
          ],
        },
      });

      expect(lookup.supportedVehicleTypes, isEmpty);
      expect(lookup.areas, hasLength(2));
      expect(lookup.areas.first.id, 'jijiga');
      expect(lookup.areas.last.supportedVehicleTypes, ['motorbike', 'car']);
    });

    test('falls back to nested service_area vehicle types', () {
      final lookup = parseDeliveryServiceAreaLookup({
        'data': {
          'service_area': {
            'id': 'jijiga',
            'supported_vehicle_types': ['bajaj', 'pickup'],
          },
        },
      });

      expect(lookup.supportedVehicleTypes, ['bajaj', 'pickup']);
    });
  });
}
