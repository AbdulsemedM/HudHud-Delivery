// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:hudhud_delivery/main.dart';
import 'package:hudhud_delivery/controllers/theme_controller.dart';
import 'package:hudhud_delivery/app/services/auth_service.dart';

void main() {
  testWidgets('App initialization test', (WidgetTester tester) async {
    // Initialize required services for testing
    final themeController = ThemeController();
    final authService = AuthService();
    
    // Build our app and trigger a frame.
    await tester.pumpWidget(MyApp(
      themeController: themeController,
      authService: authService,
    ));

    // Verify that the app loads without errors
    expect(find.byType(MaterialApp), findsOneWidget);
  });
}
