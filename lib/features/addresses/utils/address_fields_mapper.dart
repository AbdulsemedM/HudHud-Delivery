import 'package:hudhud_delivery/app/models/place_result.dart';

/// Maps Google Places / geocode results to API address fields.
class AddressFieldsMapper {
  static Map<String, dynamic> fromPlaceResult(PlaceResult place) {
    final line1 = (place.street != null && place.street!.isNotEmpty)
        ? place.street!
        : place.displayName.split(',').first.trim();

    return {
      'address_line_1': line1,
      'city': place.city ?? '',
      'state': place.state,
      'postal_code': place.postcode,
      'country': place.country ?? '',
      'latitude': place.coordinates.latitude,
      'longitude': place.coordinates.longitude,
      'label': place.shortAddress.isNotEmpty ? place.shortAddress : line1,
    };
  }
}
