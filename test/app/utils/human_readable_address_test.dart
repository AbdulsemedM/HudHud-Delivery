import 'package:flutter_test/flutter_test.dart';
import 'package:hudhud_delivery/app/models/place_result.dart';
import 'package:hudhud_delivery/app/utils/human_readable_address.dart';
import 'package:latlong2/latlong.dart';

void main() {
  group('isUnnamedRoad', () {
    test('matches Google placeholders in English, Amharic and romanized', () {
      expect(HumanReadableAddress.isUnnamedRoad('Unnamed Road'), isTrue);
      expect(HumanReadableAddress.isUnnamedRoad('ያልተሰየመ መንገድ'), isTrue);
      expect(HumanReadableAddress.isUnnamedRoad(' Yaliteseyeme  Menigedi '),
          isTrue);
    });

    test('does not match real names', () {
      expect(HumanReadableAddress.isUnnamedRoad('Bole Road'), isFalse);
      expect(HumanReadableAddress.isUnnamedRoad(null), isFalse);
      expect(HumanReadableAddress.isUnnamedRoad(''), isFalse);
    });
  });

  test('stripPlusCodesFromAddress drops the unnamed-road segment', () {
    expect(
      HumanReadableAddress.stripPlusCodesFromAddress(
          'Yaliteseyeme Menigedi, Bole, Addis Ababa, Ethiopia'),
      'Bole, Addis Ababa, Ethiopia',
    );
  });

  test('a place whose only detail was an unnamed road has no local detail',
      () {
    final place = PlaceResult(
      displayName: 'Yaliteseyeme Menigedi, Addis Ababa, Ethiopia',
      coordinates: const LatLng(9.0, 38.75),
      city: 'Addis Ababa',
      country: 'Ethiopia',
    );
    expect(place.formattedAddress, 'Addis Ababa, Ethiopia');
    expect(place.hasLocalDetail, isFalse);
  });

  test('a neighborhood counts as local detail', () {
    final place = PlaceResult(
      displayName: 'Bole, Addis Ababa, Ethiopia',
      coordinates: const LatLng(9.0, 38.75),
      neighborhood: 'Bole',
      city: 'Addis Ababa',
    );
    expect(place.hasLocalDetail, isTrue);
  });
}
