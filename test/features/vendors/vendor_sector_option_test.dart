import 'package:flutter_test/flutter_test.dart';
import 'package:hudhud_delivery/core/api/api_service.dart';
import 'package:hudhud_delivery/features/vendors/data/data_provider/vendors_data_provider.dart';
import 'package:hudhud_delivery/features/vendors/data/models/vendor_sector_option.dart';
import 'package:hudhud_delivery/features/vendors/data/repository/vendors_repository.dart';

/// Vendor types are admin-managed now: added, renamed, reordered, switched
/// off. The chip row must draw whatever the server sends - including a type
/// the app has never heard of - and must keep working against an API that
/// still sends only `{key, count}`.
class _StubProvider extends VendorsDataProvider {
  _StubProvider(this.body) : super(apiService: ApiService.instance);

  final Object? body;

  @override
  Future<Map<String, dynamic>> getVendorSectors() async =>
      {'statusCode': 200, 'data': body, 'errorMessage': null};
}

const _builtIns = {
  'restaurant': 'Restaurants',
  'pharmacy': 'Pharmacy',
  'spare_parts': 'Auto parts',
};

void main() {
  group('parsing', () {
    test('reads the richer shape: names, order, count', () async {
      final options = await VendorsRepository(
        vendorsDataProvider: _StubProvider({
          'success': true,
          'data': [
            {
              'key': 'flowers',
              'count': 3,
              'name': 'Flower shops',
              'names': {'en': 'Flower shops', 'am': 'የአበባ ሱቆች', 'so': null},
              'sort_order': 5,
            },
          ],
        }),
      ).getSectorOptions();

      expect(options, hasLength(1));
      final o = options.single;
      expect(o.key, 'flowers');
      expect(o.count, 3);
      expect(o.name, 'Flower shops');
      expect(o.names, {'en': 'Flower shops', 'am': 'የአበባ ሱቆች'});
      expect(o.sortOrder, 5);
    });

    test('still reads the old {key, count} shape', () async {
      final repo = VendorsRepository(
        vendorsDataProvider: _StubProvider({
          'success': true,
          'data': [
            {'key': 'pharmacy', 'count': 1},
            {'key': 'restaurant', 'count': 2},
          ],
        }),
      );

      final options = await repo.getSectorOptions();
      expect(options.map((o) => o.key), ['pharmacy', 'restaurant']);
      expect(
          options.every((o) => o.sortOrder == null && o.names.isEmpty), isTrue);
      // The key list other screens use is unchanged.
      expect(await repo.getAvailableSectors(), ['pharmacy', 'restaurant']);
    });

    test('malformed rows are dropped, a malformed body is no chips', () {
      expect(VendorSectorOption.listFromResponse({'data': 'nope'}), isEmpty);
      expect(VendorSectorOption.listFromResponse(null), isEmpty);
      expect(
        VendorSectorOption.listFromResponse({
          'data': [
            42,
            {'count': 1},
            {'key': ''},
            {'key': 'market'}
          ],
        }).map((o) => o.key),
        ['market'],
      );
    });
  });

  group('labels', () {
    const flowers = VendorSectorOption(
      key: 'flowers',
      name: 'Flower shops',
      names: {'en': 'Flower shops', 'am': 'የአበባ ሱቆች'},
    );

    test('the server name in the customer language wins', () {
      expect(sectorChipLabel(flowers, languageCode: 'am'), 'የአበባ ሱቆች');
      // Even over the app's built-in label: an admin renamed it.
      const renamed = VendorSectorOption(
        key: 'restaurant',
        names: {'en': 'Restaurants & cafés'},
      );
      expect(
        sectorChipLabel(renamed, languageCode: 'en', builtInLabels: _builtIns),
        'Restaurants & cafés',
      );
    });

    test('a built-in type falls back to the app translation', () {
      const pharmacy = VendorSectorOption(
        key: 'pharmacy',
        names: {'en': 'Pharmacy'},
      );
      expect(
        sectorChipLabel(pharmacy, languageCode: 'so', builtInLabels: {
          'pharmacy': 'Farmashiye',
        }),
        'Farmashiye',
      );
    });

    test('a new type falls back to its English name', () {
      expect(sectorChipLabel(flowers, languageCode: 'so'), 'Flower shops');
      const nameOnly = VendorSectorOption(key: 'books', name: 'Bookshops');
      expect(sectorChipLabel(nameOnly, languageCode: 'ar'), 'Bookshops');
    });

    test('a type with no name at all gets a readable humanised key', () {
      const bare = VendorSectorOption(key: 'home_and_garden');
      expect(sectorChipLabel(bare, languageCode: 'en'), 'Home and garden');
      expect(humaniseSectorKey('spare_parts'), 'Spare parts');
    });
  });

  group('chips', () {
    test('an unknown type is drawn rather than crashing', () {
      final chips = resolveSectorChips(
        const [
          VendorSectorOption(key: 'restaurant'),
          VendorSectorOption(key: 'flowers', name: 'Flower shops'),
        ],
        languageCode: 'en',
        builtInLabels: _builtIns,
      );
      expect(chips.map((c) => c.label), ['Restaurants', 'Flower shops']);
    });

    test('server sort_order decides the order when present', () {
      final chips = resolveSectorChips(
        const [
          VendorSectorOption(key: 'restaurant', sortOrder: 20),
          VendorSectorOption(key: 'flowers', name: 'Flowers', sortOrder: 10),
          VendorSectorOption(key: 'pharmacy', sortOrder: 20),
        ],
        languageCode: 'en',
        builtInLabels: _builtIns,
      );
      // Ties keep the order the server sent.
      expect(chips.map((c) => c.key), ['flowers', 'restaurant', 'pharmacy']);
    });

    test('an old API without sort_order keeps the built-in order', () {
      final chips = resolveSectorChips(
        const [
          VendorSectorOption(key: 'spare_parts'),
          VendorSectorOption(key: 'pharmacy'),
          VendorSectorOption(key: 'restaurant'),
        ],
        languageCode: 'en',
        builtInLabels: _builtIns,
      );
      expect(
          chips.map((c) => c.key), ['restaurant', 'pharmacy', 'spare_parts']);
    });

    test('one type is the same as none: no chips', () {
      expect(
        resolveSectorChips(
          const [VendorSectorOption(key: 'restaurant')],
          languageCode: 'en',
        ),
        isEmpty,
      );
      expect(resolveSectorChips(const [], languageCode: 'en'), isEmpty);
    });

    test('a duplicated key is drawn once', () {
      final chips = resolveSectorChips(
        const [
          VendorSectorOption(key: 'restaurant'),
          VendorSectorOption(key: 'restaurant'),
          VendorSectorOption(key: 'pharmacy'),
        ],
        languageCode: 'en',
        builtInLabels: _builtIns,
      );
      expect(chips.map((c) => c.key), ['restaurant', 'pharmacy']);
    });
  });
}
