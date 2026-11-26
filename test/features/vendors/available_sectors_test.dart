import 'package:flutter_test/flutter_test.dart';
import 'package:hudhud_delivery/core/api/api_service.dart';
import 'package:hudhud_delivery/features/vendors/data/data_provider/vendors_data_provider.dart';
import 'package:hudhud_delivery/features/vendors/data/repository/vendors_repository.dart';

/// Which sector chips the home screen is allowed to draw.
///
/// The chip row shipped as nine hardcoded sectors. Production has two
/// vendors, both restaurants, so seven of them opened an empty list with
/// nothing to explain it — which reads as a broken app rather than an empty
/// category. The server now says which sectors it can actually fill.
///
/// Everything below is about the parsing being UNABLE to throw. The chip row
/// is a decoration on the home screen; a home screen that fails to build
/// because a decoration could not load is a far worse bug than the one this
/// replaces. Every malformed shape here must come back as "no chips".
class _StubProvider extends VendorsDataProvider {
  _StubProvider(this.response) : super(apiService: ApiService.instance);

  final Map<String, dynamic> response;

  @override
  Future<Map<String, dynamic>> getVendorSectors() async => response;
}

VendorsRepository _repo(Map<String, dynamic> response) =>
    VendorsRepository(vendorsDataProvider: _StubProvider(response));

Map<String, dynamic> _ok(Object? data) =>
    {'statusCode': 200, 'data': data, 'errorMessage': null};

void main() {
  group('available sectors', () {
    test('reads the keys the server offers, in the order it sent them', () async {
      final sectors = await _repo(_ok({
        'success': true,
        'data': [
          {'key': 'restaurant', 'count': 2},
          {'key': 'pharmacy', 'count': 1},
        ],
      })).getAvailableSectors();

      expect(sectors, ['restaurant', 'pharmacy']);
    });

    test('an empty offer is a valid answer, not an error', () async {
      final sectors =
          await _repo(_ok({'success': true, 'data': []})).getAvailableSectors();

      expect(sectors, isEmpty);
    });

    test('a non-200 means no chips rather than a thrown home screen', () async {
      final sectors = await _repo({
        'statusCode': 500,
        'data': null,
        'errorMessage': 'boom',
      }).getAvailableSectors();

      expect(sectors, isEmpty);
    });

    /// The shapes that would throw if this parsed optimistically. Each is
    /// something a proxy, an error page or a half-written change could
    /// genuinely return.
    test('every malformed payload degrades to no chips', () async {
      final shapes = <Object?>[
        null,
        'not json at all',
        <String, dynamic>{},
        {'success': true},
        {'success': true, 'data': null},
        {'success': true, 'data': 'nope'},
        {'success': true, 'data': 42},
        {'success': true, 'data': [null, 7, 'x']},
        {'success': true, 'data': [{'count': 2}]},
        {'success': true, 'data': [{'key': null}]},
        {'success': true, 'data': [{'key': ''}]},
      ];

      for (final shape in shapes) {
        expect(
          await _repo(_ok(shape)).getAvailableSectors(),
          isEmpty,
          reason: 'payload $shape should yield no chips, not an exception',
        );
      }
    });

    test('good rows survive alongside junk ones', () async {
      final sectors = await _repo(_ok({
        'success': true,
        'data': [
          {'key': 'restaurant', 'count': 2},
          null,
          {'count': 9},
          {'key': ''},
          {'key': 'spare_parts', 'count': 1},
        ],
      })).getAvailableSectors();

      expect(sectors, ['restaurant', 'spare_parts']);
    });
  });
}
