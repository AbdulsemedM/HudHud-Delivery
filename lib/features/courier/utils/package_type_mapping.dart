import '../easy_mode/package_item_catalog.dart';

/// The exact set `RideMessengerController@requestMessenger` accepts for
/// `package_type`:
///
///   'package_type' => 'required|string|in:document,parcel,food,grocery,electronics,other'
///
/// Anything outside this set is a 422 at the final step of booking.
const Set<String> apiPackageTypes = {
  'document',
  'parcel',
  'food',
  'grocery',
  'electronics',
  'other',
};

/// Catalogue label -> API `package_type`.
///
/// Clothing, Books and Fragile previously passed through unmapped as
/// 'clothing', 'books' and 'fragile', which the API rejects. They are physical
/// goods, so they map to 'parcel'. Fragility travels on `requires_signature`
/// and `insurance_required`, not on the package type.
String mapPackageTypeForApi(String itemType) {
  const mapping = <String, String>{
    PackageItemCatalog.documents: 'document',
    PackageItemCatalog.electronics: 'electronics',
    PackageItemCatalog.food: 'food',
    PackageItemCatalog.clothing: 'parcel',
    PackageItemCatalog.books: 'parcel',
    PackageItemCatalog.fragile: 'parcel',
    PackageItemCatalog.other: 'other',
  };
  return mapping[itemType] ?? 'other';
}
