import 'package:flutter/material.dart';

class AppColors {
  // Primary Colors
  static const primaryColor = Color(0xFFF55905);
  static const primaryDarkColor = Color.fromARGB(255, 196, 71, 4);
  // static const Color primaryColor = Color(0xFF2E7D32); // Green
  static const Color primaryLightColor = Color.fromARGB(255, 246, 113, 42);

  // Secondary Colors
  static const secondaryColor = Color(0xFF00adef);
  static const Color secondaryDarkColor =
      Color.fromARGB(255, 1, 109, 151); // Orange
  static const Color secondaryLightColor = Color.fromARGB(255, 63, 193, 244);
  // static const Color secondaryDarkColor = Color(0xFFC43E00);

  // Error Colors
  static const Color errorColor = Color(0xFFD32F2F);
  static const Color errorLightColor = Color(0xFFFF6659);
  static const Color errorDarkColor = Color(0xFF9A0007);

  // Warning Colors
  static const Color warningColor = Color(0xFFF57C00);
  static const Color warningLightColor = Color(0xFFFFAD42);
  static const Color warningDarkColor = Color(0xFFBB4D00);

  // Success Colors
  static const Color successColor = Color(0xFF388E3C);
  static const Color successLightColor = Color(0xFF6ABF69);
  static const Color successDarkColor = Color(0xFF00600F);

  // Info Colors
  static const Color infoColor = Color(0xFF1976D2);
  static const Color infoLightColor = Color(0xFF63A4FF);
  static const Color infoDarkColor = Color(0xFF004BA0);

  // Neutral Colors - Light Theme
  static const Color lightBackground = Color(0xFFFAFAFA);
  static const Color lightSurface = Color(0xFFFFFFFF);
  static const Color lightOnBackground = Color(0xFF1C1B1F);
  static const Color lightOnSurface = Color(0xFF1C1B1F);
  static const Color lightOnPrimary = Color(0xFFFFFFFF);
  static const Color lightOnSecondary = Color(0xFFFFFFFF);
  static const Color lightOnError = Color(0xFFFFFFFF);

  // Neutral Colors - Dark Theme
  static const Color darkBackground = Color(0xFF0A0A0A); // Darker background
  static const Color darkSurface = Color(0xFF121212); // Darker surface
  static const Color darkSurfaceVariant = Color(0xFF1A1A1A); // Darker surface variant
  static const Color darkOnBackground = Color(0xFFE6E1E5);
  static const Color darkOnSurface = Color(0xFFE6E1E5);
  static const Color darkBorder = Color(0xFF3D3D3D);
  static const Color darkOnPrimary = Color(0xFF003300);
  static const Color darkOnSecondary = Color(0xFF4A2800);
  static const Color darkOnError = Color(0xFF690005);

  // Text Colors - Light Theme
  static const Color lightTextPrimary = Color(0xFF212121);
  static const Color lightTextSecondary = Color(0xFF757575);
  static const Color lightTextDisabled = Color(0xFFBDBDBD);
  static const Color lightTextHint = Color(0xFF9E9E9E);

  // Text Colors - Dark Theme
  static const Color darkTextPrimary = Color(0xFFFFFFFF);
  static const Color darkTextSecondary = Color(0xFFB3B3B3);
  static const Color darkTextDisabled = Color(0xFF616161);
  static const Color darkTextHint = Color(0xFF757575);

  // Border Colors
  static const Color lightBorder = Color(0xFFE0E0E0);

  // Divider Colors
  static const Color lightDivider = Color(0xFFBDBDBD);
  static const Color darkDivider = Color(0xFF424242);

  // Shadow Colors
  static const Color lightShadow = Color(0x1F000000);
  static const Color darkShadow = Color(0x3F000000);

  // Card Colors
  static const Color lightCard = Color(0xFFFFFFFF);
  static const Color darkCard = Color(0xFF151515); // Darker card color

  // Input Colors
  static const Color lightInputFill = Color(0xFFF5F5F5);
  static const Color darkInputFill = Color(0xFF151515); // Darker input fill
  static const Color lightInputBorder = Color(0xFFE0E0E0);
  static const Color darkInputBorder = Color(0xFF303030); // Darker input border

  // Button Colors
  static const Color disabledButton = Color(0xFFE0E0E0);
  static const Color disabledButtonText = Color(0xFF9E9E9E);

  // Status Colors
  static const Color online = Color(0xFF4CAF50);
  static const Color offline = Color(0xFF9E9E9E);
  static const Color busy = Color(0xFFFF9800);
  static const Color away = Color(0xFFFFC107);

  // Delivery Status Colors
  static const Color pending = Color(0xFFFF9800);
  static const Color confirmed = Color(0xFF2196F3);
  static const Color preparing = Color(0xFFFF5722);
  static const Color onTheWay = Color(0xFF9C27B0);
  static const Color delivered = Color(0xFF4CAF50);
  static const Color cancelled = Color(0xFFF44336);

  // Rating Colors
  static const Color ratingFilled = Color(0xFFFFC107);
  static const Color ratingEmpty = Color(0xFFE0E0E0);

  // Transparent Colors
  static const Color transparent = Colors.transparent;
  static const Color semiTransparent = Color(0x80000000);

  // Gradient Colors
  static const List<Color> primaryGradient = [
    primaryColor,
    primaryLightColor,
  ];

  static const List<Color> secondaryGradient = [
    secondaryColor,
    secondaryLightColor,
  ];

  static const List<Color> backgroundGradient = [
    Color(0xFFF8F9FA),
    Color(0xFFE9ECEF),
  ];

  static const List<Color> darkBackgroundGradient = [
    Color(0xFF1A1A1A),
    Color(0xFF2D2D2D),
  ];

  // Spacing
  static const double sp4 = 4.0;
  static const double sp8 = 8.0;
  static const double sp12 = 12.0;
  static const double sp16 = 16.0;
  static const double sp20 = 20.0;
  static const double sp24 = 24.0;
  static const double sp32 = 32.0;
  static const double sp48 = 48.0;

  // Radius
  static const double r8 = 8.0;
  static const double r10 = 10.0;
  static const double r12 = 12.0;
  static const double r16 = 16.0;
  static const double r20 = 20.0;
  static const double r24 = 24.0;
  static const double r32 = 32.0;
  static const double rFull = 999.0;

  // Subtle surface tones
  static const Color surfaceLight = Color(0xFFF7F7F7);
  static const Color surfaceDark = Color(0xFF141414);
  static const Color borderLight = Color(0xFFEEEEEE);
  static const Color borderDark = Color(0xFF2A2A2A);
  static const Color mutedLight = Color(0xFF888888);
  static const Color mutedDark = Color(0xFF777777);
}
