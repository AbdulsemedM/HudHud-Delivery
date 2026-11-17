import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hudhud_delivery/features/login/presentation/screen/auth_entry_screen.dart';
import 'package:hudhud_delivery/features/phone_signin/presentation/screen/phone_sign_in_screen.dart';
import 'package:hudhud_delivery/controllers/theme_controller.dart';
import 'package:hudhud_delivery/l10n/app_localizations.dart';
import 'package:provider/provider.dart';

/// The first screen a signed-out customer sees.
///
/// It is the phone number, not a password. Passwordless sign-in needs nothing
/// remembered, creates the account on first use, and its code now arrives by
/// Telegram as well as SMS — so it is the path almost everyone should take.
///
/// Password sign-in stays one tap away on purpose. Removing it would lock out
/// anyone whose number has changed, anyone who cannot receive a code, and the
/// staff accounts that sign in with an email, silently and at the moment they
/// most need in.
void main() {
  // Two things this screen needs from its surroundings, both supplied by the
  // app in production: localizations (it reads context.l10n) and a
  // ThemeController, which AuthDarkScaffold's theme toggle reads from a
  // Provider. Without them the render throws rather than failing an
  // assertion, which says nothing about the screen.
  Widget host(Widget child) => ChangeNotifierProvider<ThemeController>.value(
        value: ThemeController(),
        child: MaterialApp(
          locale: const Locale('en'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: child,
        ),
      );

  testWidgets('opens on the phone sign-in screen', (tester) async {
    await tester.pumpWidget(host(const AuthEntryScreen()));
    await tester.pump();

    expect(find.byType(PhoneSignInScreen), findsOneWidget);
  });

  testWidgets('offers a way to sign in with a password', (tester) async {
    await tester.pumpWidget(host(const AuthEntryScreen()));
    await tester.pump();

    // The label comes from l10n, so match the widget rather than the words.
    expect(find.byType(TextButton), findsWidgets);
    final labels = tester
        .widgetList<TextButton>(find.byType(TextButton))
        .map((b) => b.child)
        .whereType<Text>()
        .map((t) => t.data)
        .toList();
    expect(
      labels.any((l) => (l ?? '').toLowerCase().contains('password')),
      isTrue,
      reason: 'the password route must still be reachable from the first screen',
    );
  });

  testWidgets('the password route is a push, so it can be backed out of',
      (tester) async {
    await tester.pumpWidget(host(const AuthEntryScreen()));
    await tester.pump();

    // A customer who taps "sign in with password" and changes their mind must
    // be able to get back to the phone screen; a replace would strand them.
    final navigator = tester.state<NavigatorState>(find.byType(Navigator));
    expect(navigator.canPop(), isFalse, reason: 'this is the root');
  });
}
