import 'package:flutter_test/flutter_test.dart';
import 'package:hudhud_delivery/features/growth/data/growth_data_provider.dart';
import 'package:hudhud_delivery/features/growth/data/growth_repository.dart';
import 'package:hudhud_delivery/features/growth/data/models/city_coverage.dart';

/// Returns a canned `GET /api/coverage` response instead of calling the API.
class _FakeProvider implements GrowthDataProvider {
  _FakeProvider(this.response);
  final Map<String, dynamic> response;

  int calls = 0;

  @override
  Future<Map<String, dynamic>> getCoverage({
    required double lat,
    required double lng,
  }) async {
    calls++;
    return response;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

Map<String, dynamic> _ok(Map<String, dynamic> data) => {
      'statusCode': 200,
      'data': {'success': true, 'data': data},
      'errorMessage': null,
      'code': null,
    };

void main() {
  /// `GET /api/coverage` shipped with the city-pricing work and was verified
  /// on production. Nothing in the app ever called it: the only check in the
  /// pin flow was `CityScope.allowsPin`, which returns true whenever city
  /// enforcement is off - the default. So a customer could confirm a pin in a
  /// town we do not serve and meet the refusal at checkout instead.
  group('CityCoverage parsing', () {
    test('a served city reads as served', () {
      final c = CityCoverage.fromResponseBody(_ok({
        'served': true,
        'status': 'served',
        'message': 'We deliver in Addis Ababa.',
        'city': 'Addis Ababa',
        'launching': false,
        'open_cities': [
          {'code': 'addis', 'name': 'Addis Ababa'},
          {'code': 'jigjiga', 'name': 'Jigjiga'},
        ],
      })['data']);

      expect(c, isNotNull);
      expect(c!.served, isTrue);
      expect(c.isComingSoon, isFalse);
      expect(c.openCities, ['Addis Ababa', 'Jigjiga']);
    });

    /// An active market with no price list is NOT open: every quote throws.
    /// The server already treats that as coming soon, which is the whole
    /// reason the device cannot answer this question for itself.
    test('coming soon is not served, and is flagged as launching', () {
      final c = CityCoverage.fromResponseBody(_ok({
        'served': false,
        'status': 'coming_soon',
        'message': 'We are not delivering in Bishoftu yet. We are coming soon.',
        'city': 'Bishoftu',
        'launching': true,
      })['data']);

      expect(c!.served, isFalse);
      expect(c.isComingSoon, isTrue);
      expect(c.launching, isTrue);
      expect(c.message, contains('Bishoftu'));
    });

    test('nowhere near a market is not served and not launching', () {
      final c = CityCoverage.fromResponseBody(_ok({
        'served': false,
        'status': 'not_served',
        'message': 'We do not operate in this area yet. We are coming soon.',
        'launching': false,
      })['data']);

      expect(c!.served, isFalse);
      expect(c.isComingSoon, isFalse);
      expect(c.city, isNull);
    });

    /// A payload with no status or no message cannot be shown to anybody, and
    /// must read as "could not find out" rather than as a refusal.
    test('a payload with nothing to display is null, not a refusal', () {
      expect(CityCoverage.fromJson(const {'served': false}), isNull);
      expect(
        CityCoverage.fromJson(const {'status': 'not_served'}),
        isNull,
        reason: 'no message to show',
      );
      expect(CityCoverage.fromJson(null), isNull);
      expect(CityCoverage.fromResponseBody('nonsense'), isNull);
    });
  });

  group('GrowthRepository.coverageAt', () {
    test('returns the verdict on success', () async {
      final repo = GrowthRepository(
        dataProvider: _FakeProvider(_ok({
          'served': false,
          'status': 'coming_soon',
          'message': 'We are not delivering in Bishoftu yet.',
          'launching': true,
        })),
      );

      final c = await repo.coverageAt(lat: 8.752, lng: 38.98);
      expect(c!.served, isFalse);
    });

    /// THE POINT: a coverage check that cannot reach the server must never be
    /// what stops a customer ordering. Null means "could not find out", and
    /// every caller carries on. The quote still refuses with CITY_NOT_SERVED
    /// if it comes to that, so failing open costs a late message while
    /// failing closed would cost an order every time the network blinked.
    test('any failure is null, which callers read as unknown', () async {
      for (final failure in [
        {'statusCode': 500, 'data': null, 'errorMessage': 'server error'},
        {'statusCode': 0, 'data': null, 'errorMessage': 'timeout'},
        {'statusCode': 422, 'data': {'message': 'bad coords'}},
        {'statusCode': 200, 'data': {'success': true, 'data': null}},
        {'statusCode': 200, 'data': 'not json'},
      ]) {
        final repo = GrowthRepository(
          dataProvider: _FakeProvider(Map<String, dynamic>.from(failure)),
        );
        expect(
          await repo.coverageAt(lat: 9.0, lng: 38.7),
          isNull,
          reason: 'failure $failure must not read as "not served"',
        );
      }
    });

    test('it asks the server exactly once per check', () async {
      final provider = _FakeProvider(_ok({
        'served': true,
        'status': 'served',
        'message': 'We deliver in Addis Ababa.',
      }));

      await GrowthRepository(dataProvider: provider)
          .coverageAt(lat: 9.0, lng: 38.7);

      expect(provider.calls, 1);
    });
  });
}
