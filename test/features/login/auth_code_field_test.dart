import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hudhud_delivery/features/login/presentation/widgets/auth_ui.dart';

/// The six-box code field, and the one-line declaration that makes the phone
/// fill it.
///
/// Without `autofillHints: [AutofillHints.oneTimeCode]` and an enclosing
/// `AutofillGroup`, iOS has nothing to bind an arriving code to: it still
/// shows "From Messages 249914" above the keyboard, because that chip comes
/// from the OS reading the SMS, but tapping it has no declared target. The
/// field looked finished and was not, and nothing failed — which is why this
/// test exists.
void main() {
  Future<void> pumpField(WidgetTester tester, TextEditingController c) {
    return tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Form(child: AuthCodeField(controller: c)),
        ),
      ),
    );
  }

  testWidgets('declares itself to the OS as a one-time-code field',
      (tester) async {
    final controller = TextEditingController();
    addTearDown(controller.dispose);

    await pumpField(tester, controller);

    // TextFormField keeps its constructor arguments in a closure rather than
    // on the widget, so the assertion has to read the TextField it builds.
    final field = tester.widget<TextField>(find.byType(TextField));
    expect(
      field.autofillHints,
      contains(AutofillHints.oneTimeCode),
      reason: 'without this the keyboard has no field to fill',
    );
  });

  testWidgets('sits inside an AutofillGroup', (tester) async {
    final controller = TextEditingController();
    addTearDown(controller.dispose);

    await pumpField(tester, controller);

    // The hint alone is not enough: a field outside a group never has its
    // autofill context committed.
    expect(find.byType(AutofillGroup), findsOneWidget);
  });

  testWidgets('a filled code shows one digit per box', (tester) async {
    final controller = TextEditingController();
    addTearDown(controller.dispose);

    await pumpField(tester, controller);

    // What an autofill tap does: set the whole value at once, not keystroke by
    // keystroke. All six boxes must follow.
    controller.text = '249914';
    await tester.pump();

    for (final digit in ['2', '4', '9', '9', '1', '4']) {
      expect(find.text(digit), findsWidgets, reason: 'digit $digit missing');
    }
  });

  testWidgets('takes digits only and stops at six', (tester) async {
    final controller = TextEditingController();
    addTearDown(controller.dispose);

    await pumpField(tester, controller);

    await tester.enterText(find.byType(TextField), '12a34b5678');
    await tester.pump();

    expect(controller.text, '123456');
  });
}
