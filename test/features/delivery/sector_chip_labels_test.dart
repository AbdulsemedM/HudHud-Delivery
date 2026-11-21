import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hudhud_delivery/l10n/app_localizations.dart';

/// The sector chip row has to be readable in all five locales.
///
/// The chips were added as hardcoded English so they could ship as a
/// Dart-only Shorebird patch the same day. This suite covers the follow-up:
/// forty translations written by hand in one pass, which is exactly the kind
/// of change where one cell goes empty or two cells end up identical and
/// nothing notices until a customer in Hargeisa sees two chips called the
/// same thing.
///
/// What is NOT tested here, because the language already guarantees it:
/// a locale cannot be missing a key. `AppLocalizations` declares each one as
/// an abstract getter, so a subclass that skips one fails to compile. That is
/// a stronger guard than any assertion, and it is why there is no
/// "every locale defines sectorPharmacy" test below.
void main() {
  const locales = ['en', 'am', 'ar', 'om', 'so'];

  /// The nine chips in row order, as `_sectorChipSpecs` resolves them.
  ///
  /// Grocery deliberately reads `categoryGrocery` rather than a sector key of
  /// its own: that key already carried the word in all five locales before
  /// this screen existed, and duplicating it would give two strings to keep
  /// in step. If the screen ever stops reusing it, this list is the place the
  /// mismatch shows up.
  List<String> labelsFor(AppLocalizations l) => [
        l.sectorAll,
        l.sectorRestaurants,
        l.sectorBakery,
        l.sectorSupermarket,
        l.categoryGrocery,
        l.sectorMarket,
        l.sectorPharmacy,
        l.sectorSpareParts,
        l.sectorGeneral,
      ];

  for (final code in locales) {
    group('sector chips in $code', () {
      final l10n = lookupAppLocalizations(Locale(code));

      test('every chip has a visible label', () {
        for (final label in labelsFor(l10n)) {
          expect(
            label.trim(),
            isNotEmpty,
            reason: 'An empty chip renders as a tappable blank pill.',
          );
          expect(
            label,
            label.trim(),
            reason: 'Padding is the chip\'s job, not the string\'s.',
          );
        }
      });

      test('no two chips read the same', () {
        final labels = labelsFor(l10n);

        expect(
          labels.toSet().length,
          labels.length,
          reason:
              'Two chips with one label are indistinguishable, and the second '
              'one looks broken: tapping it changes the list but nothing '
              'explains why. Found: $labels',
        );
      });
    });
  }

  test('a non-English locale is really translated', () {
    // Guards the failure mode of this particular change: an .arb edited for
    // one locale and copy-pasted into the rest. Checked against Somali and
    // Amharic rather than all four, because a legitimate translation CAN
    // coincide with the English word, and asserting otherwise would be wrong
    // the first time it does.
    final en = lookupAppLocalizations(const Locale('en'));
    final so = lookupAppLocalizations(const Locale('so'));
    final am = lookupAppLocalizations(const Locale('am'));

    expect(so.sectorPharmacy, isNot(en.sectorPharmacy));
    expect(am.sectorPharmacy, isNot(en.sectorPharmacy));
    expect(so.sectorSpareParts, isNot(en.sectorSpareParts));
    expect(am.sectorSpareParts, isNot(en.sectorSpareParts));
  });
}
