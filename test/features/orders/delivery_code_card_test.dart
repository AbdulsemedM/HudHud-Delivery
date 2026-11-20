import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hudhud_delivery/features/orders/presentation/widgets/delivery_code_card.dart';
import 'package:hudhud_delivery/l10n/app_localizations.dart';

void main() {
  /// Counts calls so "renders nothing" is distinguishable from "never asked".
  ({Future<Map<String, dynamic>> Function(int) fetch, List<int> calls}) stub(
    Map<String, dynamic> payload,
  ) {
    final calls = <int>[];
    return (
      fetch: (int orderId) async {
        calls.add(orderId);
        return {'statusCode': 200, 'data': payload, 'errorMessage': null};
      },
      calls: calls,
    );
  }

  Future<void> pump(
    WidgetTester tester,
    Future<Map<String, dynamic>> Function(int) fetch,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(
          body: DeliveryCodeCard(
            orderId: 92,
            fetchCode: fetch,
            // Long enough that the periodic timer never fires in a test.
            pollInterval: const Duration(minutes: 5),
          ),
        ),
      ),
    );
    await tester.pump();
  }

  /// The normal state for most of a delivery: the driver has not asked for a
  /// code yet. An empty card, or worse an error, would be wrong - there is
  /// nothing for the customer to do about it.
  testWidgets('renders nothing until a code has been issued', (tester) async {
    final s = stub({
      'success': true,
      'data': {'code': null, 'state': 'not_issued'},
    });

    await pump(tester, s.fetch);

    expect(s.calls, [92]);
    expect(find.text('4   8   2   1'), findsNothing);
  });

  testWidgets('shows the four digits once the driver has asked',
      (tester) async {
    final s = stub({
      'success': true,
      'data': {'code': '4821', 'state': 'ready'},
    });

    await pump(tester, s.fetch);

    // Spaced out so it can be read aloud a digit at a time, at a door.
    expect(find.text('4   8   2   1'), findsOneWidget);
  });

  /// A failed poll is silent: the next tick retries, and there is nothing the
  /// customer could do. An error box on the tracking screen would be alarming
  /// and useless.
  testWidgets('a failure shows nothing rather than an error', (tester) async {
    await pump(tester, (int orderId) async => throw Exception('offline'));

    expect(tester.takeException(), isNull);
    expect(find.text('4   8   2   1'), findsNothing);
  });
}
