import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'app_colors.dart';

/// Builds a [SystemUiOverlayStyle] that matches the current theme brightness.
SystemUiOverlayStyle systemUiOverlayFor(BuildContext context) {
  final isDark = Theme.of(context).brightness == Brightness.dark;
  final background = isDark
      ? AppColors.darkBackground
      : AppColors.lightBackground;

  return SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    statusBarIconBrightness: isDark ? Brightness.light : Brightness.dark,
    statusBarBrightness: isDark ? Brightness.dark : Brightness.light,
    systemNavigationBarColor: background,
    systemNavigationBarIconBrightness:
        isDark ? Brightness.light : Brightness.dark,
  );
}
