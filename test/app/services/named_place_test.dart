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

  // A map tap is not a GPS fix. The radius was 50 m - right for "am I in
  // this shop", wrong for a pin the customer placed by eye - so most pins
  // found no venue and the address fell back to "Bole, Addis Ababa" when
  // "Edna Mall, Bole, Addis Ababa" was sitting there.
  test('a landmark beyond the old 50 m radius still names the pin', () {
    final hit = GooglePlacesService.nearestNamedPlaceFrom([
      _hit('Edna Mall', 8.99590, 38.78900), // ~100 m
    ], pin);
    expect(hit?.name, 'Edna Mall');
  });

  // Past the certainty band the label is a landmark, not an address, and
  // Google's prominence order judges that better than raw distance.
  test('beyond the certainty band prominence beats distance', () {
    final hit = GooglePlacesService.nearestNamedPlaceFrom([
      _hit('Edna Mall', 8.99600, 38.78900), // ~111 m, listed first
      _hit('Mini Kiosk', 8.99570, 38.78900), // ~78 m, nearer
    ], pin);
    expect(hit?.name, 'Edna Mall');
  });

  // Inside the band the pin really is at the place, so distance decides and
  // a prominent neighbour does not get to speak for it.
  test('inside the certainty band the nearest place still wins', () {
    final hit = GooglePlacesService.nearestNamedPlaceFrom([
      _hit('Edna Mall', 8.99540, 38.78900), // ~45 m, listed first
      _hit('Kaldis Coffee', 8.99510, 38.78900), // ~11 m
    ], pin);
    expect(hit?.name, 'Kaldis Coffee');
  });

  test('a place past the new radius is still ignored', () {
    final hit = GooglePlacesService.nearestNamedPlaceFrom([
      _hit('Distant Hotel', 8.99700, 38.78900), // ~222 m
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
