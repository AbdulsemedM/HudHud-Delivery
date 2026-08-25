import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hudhud_delivery/features/courier/presentation/widgets/driver_contact_card.dart';

void main() {
  testWidgets('DriverContactCard shows message action without phone button', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: DriverContactCard(
            driverName: 'Ahmed',
            borderColor: Colors.grey,
            onMessage: () {},
          ),
        ),
      ),
    );

    expect(find.byIcon(Icons.chat_bubble_outline), findsOneWidget);
    expect(find.byIcon(Icons.phone), findsNothing);
    expect(find.text('Ahmed'), findsOneWidget);
  });
}
