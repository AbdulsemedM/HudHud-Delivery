import 'package:hudhud_delivery/app/models/place_result.dart';
import 'package:hudhud_delivery/app/utils/human_readable_address.dart';
import 'package:hudhud_delivery/features/addresses/model/address_payload.dart';

/// Maps Google Places / geocode results to API address fields.
class AddressFieldsMapper {
  static Map<String, dynamic> fromPlaceResult(PlaceResult place) {
    final line1 = HumanReadableAddress.line1FromPlace(place);
    final label = HumanReadableAddress.labelFromPlace(place);

    return {
      'address_line_1': line1,
      'city': place.city ?? '',
      'state': place.state,
      'postal_code': AddressPayload.defaultPostalCode,
      'country': place.country ?? '',
      'latitude': place.coordinates.latitude,
      'longitude': place.coordinates.longitude,
      'label': label,
    };
  }
}
