import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hudhud_delivery/features/courier/presentation/widgets/fare_summary_line.dart';
import 'package:hudhud_delivery/features/courier/utils/fare_summary.dart';
import 'package:hudhud_delivery/l10n/app_localizations.dart';

/// Tester report: distance was not clearly presented. Customers see the
/// route distance and the "estimate" note - never the calculation.
void main() {
  final estimate = {
    'estimated_cost': 153.0,
    'estimated_distance': 6.24,
    'final_price_basis': 'actual_route',
  };

  test('reads a flat or nested estimate', () {
    expect(FareSummary.fromEstimateResponse(estimate)?.distanceKm, 6.24);
    expect(FareSummary.fromEstimateResponse({'data': estimate})?.isEstimate,
        isTrue);
    expect(FareSummary.fromEstimateResponse({'estimated_cost': 1}), isNull);
  });

  test('an older server (no basis) still gets the distance, no note', () {
    final s = FareSummary.fromEstimateResponse({'estimated_distance': 3})!;
    expect(s.distanceKm, 3);
    expect(s.isEstimate, isFalse);
  });

  test('km without trailing zeros', () {
    expect(formatFareKm(3), '3');
    expect(formatFareKm(6.24), '6.2');
  });

  testWidgets('shows the distance and that it is an estimate, nothing more',
      (tester) async {
    await tester.pumpWidget(MaterialApp(
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      locale: const Locale('en'),
      home: Scaffold(
        body: FareSummaryLine(
          summary: FareSummary.fromEstimateResponse(estimate)!,
        ),
      ),
    ));
    await tester.pumpAndSettle();

    expect(find.textContaining('6.2 km'), findsOneWidget);
    expect(find.textContaining('actual route'), findsOneWidget);
    expect(find.textContaining('Base fee'), findsNothing);
    expect(find.textContaining('×'), findsNothing);
  });
}
