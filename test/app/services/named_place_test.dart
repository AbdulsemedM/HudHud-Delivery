import 'package:flutter_test/flutter_test.dart';
import 'package:hudhud_delivery/app/models/place_result.dart';
import 'package:hudhud_delivery/app/services/google_places_service.dart';
import 'package:latlong2/latlong.dart';

Map<String, dynamic> _hit(String name, double lat, double lng,
        {List<String> types = const ['point_of_interest', 'establishment'],
        String? status}) =>
    {
      'name': name,
      'place_id': 'id-$name',
      'types': types,
      'vicinity': 'Bole',
      if (status != null) 'business_status': status,
      'geometry': {
        'location': {'lat': lat, 'lng': lng},
      },
    };

void main() {
  const pin = LatLng(8.99500, 38.78900);

  test('picks the closest named place within the radius', () {
    final hit = GooglePlacesService.nearestNamedPlaceFrom([
      _hit('Far Cafe', 8.99530, 38.78900), // ~33 m
      _hit('Edna Mall', 8.99510, 38.78900), // ~11 m
    ], pin);
    expect(hit?.name, 'Edna Mall');
  });

  test('ignores areas, roads, closed places and anything too far', () {
    final hit = GooglePlacesService.nearestNamedPlaceFrom([
      _hit('Bole', 8.99500, 38.78900, types: ['sublocality', 'political']),
      _hit('Africa Ave', 8.99500, 38.78900, types: ['route']),
      _hit('Old Shop', 8.99501, 38.78900, status: 'CLOSED_PERMANENTLY'),
      _hit('Unnamed Road', 8.99502, 38.78900),
      _hit('Distant Hotel', 9.00000, 38.78900), // ~550 m
    ], pin);
    expect(hit, isNull);
  });

  test('short address leads with the place name', () {
    final place = PlaceResult(
      displayName: 'Edna Mall, Bole, Addis Ababa',
      coordinates: pin,
      establishment: 'Edna Mall',
      sublocality: 'Bole',
      city: 'Addis Ababa',
    );
    expect(place.shortAddress, 'Edna Mall, Bole, Addis Ababa');
  });
}
