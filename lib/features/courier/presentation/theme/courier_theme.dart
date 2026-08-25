import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:hudhud_delivery/core/theme/system_ui_style.dart';
import 'package:hudhud_delivery/features/home/presentation/theme/home_colors.dart';

/// Theme-aware chrome for the courier flow (matches Home hub).
class CourierTheme {
  CourierTheme._();

  static ThemeData of(BuildContext context) => HomeColors.themeFor(context);

  /// Wraps a courier route/screen with Home tokens + brightness-aware status bar.
  static Widget wrap(BuildContext context, {required Widget child}) {
    return Theme(
      data: of(context),
      child: AnnotatedRegion<SystemUiOverlayStyle>(
        value: systemUiOverlayFor(context),
        child: child,
      ),
    );
  }
}
