import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hudhud_delivery/app/services/phone_sign_in_service.dart';
import 'package:hudhud_delivery/controllers/theme_controller.dart';
import 'package:hudhud_delivery/l10n/app_localizations.dart';
import 'package:provider/provider.dart';
import 'package:hudhud_delivery/features/phone_signin/presentation/screen/phone_sign_in_screen.dart';

/// The passwordless path has to be reachable in a RELEASE build.
///
/// It was not. `PhoneSignInService` and both screens existed and were tested,
/// but the only thing that reached the service was `PhoneSignInTestScreen`, a
/// debug harness behind `if (kDebugMode)` on the login screen. Every piece
/// worked and no customer could use any of it.
///
/// This holds the part a widget test can: the production screen builds,
/// renders the phone step, and takes the callback the login screen routes on.
/// The harness is deleted, so regressing to it would not compile.
void main() {
  testWidgets('the production phone screen builds and renders a phone input',
      (tester) async {
    PhoneSignInVerifyResult? received;

    // Two things the screen genuinely needs from its surroundings:
    //
    //  * localizations — it reads context.l10n, i.e.
    //    AppLocalizations.of(context)!, which throws on a bare MaterialApp;
    //  * a ThemeController — AuthDarkScaffold renders ThemeToggleIconButton,
    //    which reads it from a Provider.
    //
    // Both come from the app in production. Supplying them here is what makes
    // this a real render rather than a compile check, which `analyze` already
    // covers.
    await tester.pumpWidget(
      ChangeNotifierProvider<ThemeController>.value(
        value: ThemeController(),
        child: MaterialApp(
          locale: const Locale('en'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: PhoneSignInScreen(onSignedIn: (result) => received = result),
        ),
      ),
    );
    await tester.pump();

    expect(find.byType(PhoneSignInScreen), findsOneWidget);
    expect(
      find.byType(TextFormField),
      findsWidgets,
      reason: 'The phone step must render an input. If this screen changed '
          'shape, update the expectation rather than deleting the test — it is '
          'the only thing asserting the entry point is real.',
    );

    // Nothing has signed in yet; the callback is the login screen's only cue
    // to route, and the service has already stored the session before it fires.
    expect(received, isNull);
  });
}
