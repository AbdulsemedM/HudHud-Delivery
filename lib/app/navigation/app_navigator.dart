import 'package:flutter/material.dart';

/// Holds the root [NavigatorState] key set during app startup.
class AppNavigator {
  AppNavigator._();

  static GlobalKey<NavigatorState>? key;

  static GlobalKey<NavigatorState>? get navigatorKey => key;
}
