import 'package:flutter_test/flutter_test.dart';
import 'package:hudhud_delivery/features/courier/easy_mode/package_item_catalog.dart';
import 'package:hudhud_delivery/features/courier/utils/package_type_mapping.dart';

/// Locks the customer-facing item catalogue to the API's `package_type` enum.
///
/// `RideMessengerController@requestMessenger` validates
/// `in:document,parcel,food,grocery,electronics,other`. Three catalogue
/// entries — Clothing, Books and Fragile — used to pass straight through as
/// 'clothing', 'books' and 'fragile', so choosing any of them produced a 422
/// at the final step of booking. Two of the three are on Easy Mode's first
/// screen.
///
/// Nothing caught it: the required fields were all present, so the app's own
/// tests passed and the API's own tests passed. Only the pair together is
/// wrong. This test is that pair.
void main() {
  group('package_type contract', () {
    test('every catalogue item maps into the API enum', () {
      for (final id in PackageItemCatalog.allIds) {
        final mapped = mapPackageTypeForApi(id);
        expect(
          apiPackageTypes,
          contains(mapped),
          reason: 'PackageItemCatalog "$id" maps to "$mapped", which '
              'RideMessengerController@requestMessenger rejects. Allowed: '
              '${apiPackageTypes.toList()..sort()}. Add a mapping in '
              'mapPackageTypeForApi rather than a new API value, unless the '
              'API enum is widened to match.',
        );
      }
    });

    test('every Easy Mode item maps into the API enum', () {
      // Called out separately because Easy Mode is the low-literacy flow:
      // a 422 there is worse than anywhere else in the app.
      for (final id in PackageItemCatalog.easyModeIds) {
        expect(apiPackageTypes, contains(mapPackageTypeForApi(id)),
            reason: 'Easy Mode offers "$id", which the API would reject.');
      }
    });

    test('the three that used to 422 now map to parcel', () {
      expect(mapPackageTypeForApi(PackageItemCatalog.clothing), 'parcel');
      expect(mapPackageTypeForApi(PackageItemCatalog.books), 'parcel');
      expect(mapPackageTypeForApi(PackageItemCatalog.fragile), 'parcel');
    });

    test('the ones that already worked are unchanged', () {
      expect(mapPackageTypeForApi(PackageItemCatalog.documents), 'document');
      expect(mapPackageTypeForApi(PackageItemCatalog.electronics), 'electronics');
      expect(mapPackageTypeForApi(PackageItemCatalog.food), 'food');
      expect(mapPackageTypeForApi(PackageItemCatalog.other), 'other');
    });

    test('an unknown label falls back to a value the API accepts', () {
      expect(apiPackageTypes, contains(mapPackageTypeForApi('Not In Catalogue')));
    });
  });
}
