import 'package:flutter_test/flutter_test.dart';
import 'package:hudhud_delivery/core/utils/localized_date.dart';
import 'package:intl/date_symbol_data_local.dart';

void main() {
  setUpAll(() async {
    await initializeDateFormatting();
  });

  // Local time, so the expected hour does not depend on the test machine's zone.
  final dt = DateTime(2026, 11, 10, 8, 23);

  test('English uses the intl long date', () {
    expect(formatLocalizedDateTime(dt, 'en'), 'November 10, 2026, 08:23');
  });

  test('Somali and Oromo use their own month names (no intl data)', () {
    expect(formatLocalizedDateTime(dt, 'so'), '10 Nofembar 2026, 08:23');
    expect(formatLocalizedDateTime(dt, 'om'), '10 Sadaasa 2026, 08:23');
  });

  test('Amharic and Arabic are not English', () {
    expect(formatLocalizedDateTime(dt, 'am'), isNot(contains('November')));
    expect(formatLocalizedDateTime(dt, 'ar'), isNot(contains('November')));
  });

  test('null and non-dates', () {
    expect(formatLocalizedDateTime(null, 'en'), '—');
    expect(formatLocalizedDateTime('', 'en'), '—');
    expect(formatLocalizedDateTime('not a date', 'en'), 'not a date');
  });
}
