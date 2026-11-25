import 'package:flutter_test/flutter_test.dart';
import 'package:hudhud_delivery/features/courier/utils/cross_border.dart';

/// A delivery was booked from King Abdulaziz International Airport, Jeddah,
/// to Addis Ababa. The pickup is now refused at step one because Jeddah is
/// outside every configured service area — but the reverse, Addis Ababa to
/// Jeddah, was still accepted all the way to courier search, because only the
/// pickup is checked against those areas.
///
/// The tempting fix is to require the drop-off to resolve to a service area
/// too. It is wrong: area resolution matches city aliases as substrings of
/// the address, so a genuine drop-off in a village outside any configured
/// city resolves to nothing, and refusing those blocks deliveries we make
/// every day.
///
/// Country is the signal that separates the two cases.
void main() {
  group('isCrossBorder', () {
    /// THE ONE THAT MATTERS: no rider rides from Addis to Jeddah.
    test('a delivery between two countries cannot be covered', () {
      expect(isCrossBorder('Ethiopia', 'Saudi Arabia'), isTrue);
      expect(isCrossBorder('Saudi Arabia', 'Ethiopia'), isTrue);
    });

    /// AND THE ONE THAT PROTECTS REAL WORK: a village outside every
    /// configured city is still a delivery we make. Checking the country
    /// rather than the service area is what keeps it bookable.
    test('a drop-off outside any configured city is still the same country',
        () {
      expect(isCrossBorder('Ethiopia', 'Ethiopia'), isFalse);
    });

    test('spelling and spacing do not create a border', () {
      expect(isCrossBorder('Ethiopia', ' ethiopia '), isFalse);
      expect(isCrossBorder('ETHIOPIA', 'Ethiopia'), isFalse);
    });

    /// An unknown country is not evidence of anything. Google returns none
    /// for a plus-code hit and for some reverse geocodes, and refusing on a
    /// missing field would block ordinary deliveries.
    test('an unknown country never refuses', () {
      expect(isCrossBorder(null, 'Ethiopia'), isFalse);
      expect(isCrossBorder('Ethiopia', null), isFalse);
      expect(isCrossBorder(null, null), isFalse);
      expect(isCrossBorder('', 'Ethiopia'), isFalse);
      expect(isCrossBorder('Ethiopia', '   '), isFalse);
    });

    /// Somaliland addresses come back as Somalia, and Hargeisa is a
    /// configured market — so a Hargeisa-to-Hargeisa delivery must not be
    /// read as crossing anything.
    test('a delivery within one country is allowed wherever it is', () {
      expect(isCrossBorder('Somalia', 'Somalia'), isFalse);
    });
  });
}
