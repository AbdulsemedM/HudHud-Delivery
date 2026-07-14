import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hudhud_delivery/core/utils/phone_util.dart';
import 'package:hudhud_delivery/core/widgets/phone_number_field.dart';
import 'package:hudhud_delivery/features/login/presentation/widgets/auth_phone_number_field.dart';
import 'package:hudhud_delivery/features/login/presentation/widgets/login_method_tabs.dart';
import 'package:hudhud_delivery/l10n/app_localizations.dart';

void main() {
  testWidgets('LoginMethodTabs switches between email and phone',
      (tester) async {
    LoginMethod selected = LoginMethod.email;

    await tester.pumpWidget(
      MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: StatefulBuilder(
          builder: (context, setState) {
            return Scaffold(
              body: LoginMethodTabs(
                selected: selected,
                authStyle: true,
                onChanged: (m) => setState(() => selected = m),
              ),
            );
          },
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Email'), findsOneWidget);
    expect(find.text('Phone'), findsOneWidget);
    expect(find.byIcon(Icons.phone_outlined), findsOneWidget);
    expect(find.byIcon(Icons.mail_outline_rounded), findsOneWidget);

    await tester.tap(find.text('Phone'));
    await tester.pumpAndSettle();
    expect(selected, LoginMethod.phone);
  });

  testWidgets('PhoneNumberField defaults to +251 Ethiopia', (tester) async {
    final controller = TextEditingController();

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: PhoneNumberField(
            countryCode: kDefaultPhoneDialCode,
            numberController: controller,
            onCountryChanged: (_) {},
          ),
        ),
      ),
    );

    expect(find.text('+251'), findsOneWidget);
    expect(find.text('🇪🇹'), findsOneWidget);

    controller.dispose();
  });

  testWidgets('AuthPhoneNumberField shows ET +251 chip', (tester) async {
    final controller = TextEditingController();

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: AuthPhoneNumberField(
            countryCode: kDefaultPhoneDialCode,
            countryIsoCode: 'ET',
            numberController: controller,
            onCountryChanged: (_) {},
            hintText: '912 345 678',
          ),
        ),
      ),
    );

    expect(find.text('ET +251'), findsOneWidget);
    expect(find.text('912 345 678'), findsOneWidget);

    controller.dispose();
  });
}
