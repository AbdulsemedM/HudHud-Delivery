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

  /*
   * A customer picked a pickup in Jeddah, photographed the parcel, named a
   * recipient, and was told at step five of five that we do not deliver from
   * there. The check existed - it ran on the confirm screen - so the work was
   * wasted by WHERE it ran, not by whether it ran.
   *
   * The pickup step now refuses immediately, and names the cities we do serve
   * so the refusal is something a customer can act on. This covers which
   * names that sentence is allowed to contain.
   */
  group('servedAreaNames', () {
    DeliveryServiceAreaLookup lookupWithAreas(List<Map<String, dynamic>> areas) {
      return parseDeliveryServiceAreaLookup({
        'success': true,
        'data': {'supported_vehicle_types': <String>[], 'areas': areas},
      });
    }

    test('names the enabled cities, sorted so they can be scanned', () {
      final names = servedAreaNames(lookupWithAreas([
        {'id': 'jijiga', 'name': 'Jijiga', 'enabled': true},
        {'id': 'addis', 'name': 'Addis Ababa', 'enabled': true},
        {'id': 'hargeisa', 'name': 'Hargeisa', 'enabled': true},
      ]));

      expect(names, ['Addis Ababa', 'Hargeisa', 'Jijiga']);
    });

    /// THE ONE THAT MATTERS: a configured-but-off city is not somewhere we
    /// deliver from today, and naming it sends the customer to re-pick an
    /// address that fails exactly the same way.
    test('leaves out a city that is configured but switched off', () {
      final names = servedAreaNames(lookupWithAreas([
        {'id': 'addis', 'name': 'Addis Ababa', 'enabled': true},
        {'id': 'jijiga', 'name': 'Jijiga', 'enabled': false},
      ]));

      expect(names, ['Addis Ababa']);
    });

    test('drops blank names rather than leaving a gap in the sentence', () {
      final names = servedAreaNames(lookupWithAreas([
        {'id': 'addis', 'name': 'Addis Ababa', 'enabled': true},
        {'id': 'blank', 'name': '   ', 'enabled': true},
        {'id': 'missing', 'enabled': true},
      ]));

      expect(names, ['Addis Ababa']);
    });

    /// Then the screen falls back to the plain refusal. Saying "choose a
    /// pickup in: " with nothing after it is worse than saying less.
    test('is empty when there is nothing to name', () {
      expect(servedAreaNames(null), isEmpty);
      expect(servedAreaNames(lookupWithAreas(const [])), isEmpty);
    });
  });
}
