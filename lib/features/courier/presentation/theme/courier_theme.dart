import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:hudhud_delivery/features/home/presentation/theme/home_colors.dart';

/// Always-dark chrome for the courier flow (matches Home hub).
class CourierTheme {
  CourierTheme._();

  static ThemeData of(BuildContext context) =>
      HomeColors.darkTheme(Theme.of(context));

  /// Wraps a courier route/screen with Home dark tokens + light status icons.
  static Widget wrap(BuildContext context, {required Widget child}) {
    return Theme(
      data: of(context),
      child: AnnotatedRegion<SystemUiOverlayStyle>(
        value: const SystemUiOverlayStyle(
          statusBarColor: Colors.transparent,
          statusBarIconBrightness: Brightness.light,
          statusBarBrightness: Brightness.dark,
        ),
        child: child,
      ),
    );
  }
}
