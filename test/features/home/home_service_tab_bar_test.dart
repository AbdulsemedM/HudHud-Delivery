import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hudhud_delivery/features/courier/utils/courier_send_request.dart';
import 'package:hudhud_delivery/features/home/presentation/widgets/home_service_tab_bar.dart';
import 'package:hudhud_delivery/l10n/app_localizations.dart';

/// Tester report item 5: "Send a package" looked like a choice on a form
/// (tick / empty circle) and only selected itself.
void main() {
  Widget subject(ValueChanged<HomeServiceMode> onSelected) => MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        locale: const Locale('en'),
        home: Scaffold(
          body: HomeServiceTabBar(
            selected: HomeServiceMode.courier,
            onSelected: onSelected,
          ),
        ),
      );

  testWidgets('no tick on the tiles', (tester) async {
    await tester.pumpWidget(subject((_) {}));
    await tester.pumpAndSettle();
    expect(find.byIcon(Icons.check_rounded), findsNothing);
  });

  testWidgets('tapping Send a package reports the courier tab, even when it '
      'is already the selected one', (tester) async {
    final taps = <HomeServiceMode>[];
    await tester.pumpWidget(subject(taps.add));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Send a package'));
    await tester.pump();
    expect(taps, [HomeServiceMode.courier]);
  });

  test('a send request reaches every listener', () {
    var calls = 0;
    void listener() => calls++;
    CourierSendRequest.instance.addListener(listener);
    CourierSendRequest.instance.request();
    CourierSendRequest.instance.removeListener(listener);
    CourierSendRequest.instance.request();
    expect(calls, 1);
  });
}
