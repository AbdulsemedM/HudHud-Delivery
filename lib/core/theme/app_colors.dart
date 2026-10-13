import 'package:flutter/material.dart';

/// HudHud brand + UI tokens.
///
/// Palette is lifted straight from the logo: HudHud orange (#F55905) for
/// every primary action, HudHud indigo (#411486) for brand chrome and depth,
/// and an indigo-tinted ink for text. Keep one orange "do this" action per
/// screen so low-literacy users always know where to tap.
class AppColors {
  // Brand
  static const Color brandOrange = Color(0xFFF55905);
  static const Color brandIndigo = Color(0xFF411486);
  static const Color brandIndigoDeep = Color(0xFF250A52);
  static const Color brandIndigoBright = Color(0xFF8F6BEA);
  static const Color brandInk = Color(0xFF1B1530);

  /// Soft tints used behind icons, chips and selected states.
  static const Color orangeTint = Color(0xFFFFEEE4);
  static const Color indigoTint = Color(0xFFEFEAF9);
  static const Color orangeTintDark = Color(0xFF3A2016);
  static const Color indigoTintDark = Color(0xFF2A2045);

  // Primary Colors
  static const primaryColor = brandOrange;
  static const primaryDarkColor = Color(0xFFD94A00);
  static const Color primaryLightColor = Color(0xFFFF6A1A);

  // Secondary Colors
  static const secondaryColor = brandIndigo;
  static const Color secondaryDarkColor = brandIndigoDeep;
  static const Color secondaryLightColor = brandIndigoBright;

  // Error Colors
  static const Color errorColor = Color(0xFFE5484D);
  static const Color errorLightColor = Color(0xFFFF6B6F);
  static const Color errorDarkColor = Color(0xFFB4232A);

  // Warning Colors
  static const Color warningColor = Color(0xFFE59A00);
  static const Color warningLightColor = Color(0xFFFFB938);
  static const Color warningDarkColor = Color(0xFFB27600);

  // Success Colors
  static const Color successColor = Color(0xFF11A05A);
  static const Color successLightColor = Color(0xFF3CC57F);
  static const Color successDarkColor = Color(0xFF0A7A43);

  // Info Colors
  static const Color infoColor = Color(0xFF3366E8);
  static const Color infoLightColor = Color(0xFF6A90F2);
  static const Color infoDarkColor = Color(0xFF1E48B8);

  // Neutral Colors - Light Theme
  static const Color lightBackground = Color(0xFFF6F5F9);
  static const Color lightSurface = Color(0xFFFFFFFF);
  static const Color lightOnBackground = brandInk;
  static const Color lightOnSurface = brandInk;
  static const Color lightOnPrimary = Color(0xFFFFFFFF);
  static const Color lightOnSecondary = Color(0xFFFFFFFF);
  static const Color lightOnError = Color(0xFFFFFFFF);

  // Neutral Colors - Dark Theme
  static const Color darkBackground = Color(0xFF100B1C);
  static const Color darkSurface = Color(0xFF181226);
  static const Color darkSurfaceVariant = Color(0xFF221B35);
  static const Color darkOnBackground = Color(0xFFF5F3FA);
  static const Color darkOnSurface = Color(0xFFF5F3FA);
  static const Color darkBorder = Color(0xFF2D2642);
  static const Color darkOnPrimary = Color(0xFFFFFFFF);
  static const Color darkOnSecondary = Color(0xFFFFFFFF);
  static const Color darkOnError = Color(0xFFFFFFFF);

  // Text Colors - Light Theme
  static const Color lightTextPrimary = brandInk;
  static const Color lightTextSecondary = Color(0xFF625C75);
  static const Color lightTextDisabled = Color(0xFFBDB8CC);
  static const Color lightTextHint = Color(0xFF9A95AB);

  // Text Colors - Dark Theme
  static const Color darkTextPrimary = Color(0xFFF5F3FA);
  static const Color darkTextSecondary = Color(0xFFA9A3BC);
  static const Color darkTextDisabled = Color(0xFF5C5670);
  static const Color darkTextHint = Color(0xFF7E7893);

  // Border Colors
  static const Color lightBorder = Color(0xFFE8E5EF);

  // Divider Colors
  static const Color lightDivider = Color(0xFFECE9F2);
  static const Color darkDivider = Color(0xFF2A2340);

  // Shadow Colors
  static const Color lightShadow = Color(0x141B1530);
  static const Color darkShadow = Color(0x66000000);

  // Card Colors
  static const Color lightCard = Color(0xFFFFFFFF);
  static const Color darkCard = Color(0xFF1B152B);

  // Input Colors
  static const Color lightInputFill = Color(0xFFF1EFF5);
  static const Color darkInputFill = Color(0xFF1F1931);
  static const Color lightInputBorder = Color(0xFFE3E0EB);
  static const Color darkInputBorder = Color(0xFF2F2845);

  // Button Colors
  static const Color disabledButton = Color(0xFFE6E3EC);
  static const Color disabledButtonText = Color(0xFF9A95AB);

  // Status Colors
  static const Color online = successColor;
  static const Color offline = Color(0xFF9A95AB);
  static const Color busy = warningColor;
  static const Color away = Color(0xFFF2B705);

  // Delivery Status Colors
  static const Color pending = warningColor;
  static const Color confirmed = infoColor;
  static const Color preparing = brandOrange;
  static const Color onTheWay = Color(0xFF6A3FD0);
  static const Color delivered = successColor;
  static const Color cancelled = errorColor;

  // Rating Colors
  static const Color ratingFilled = Color(0xFFFFB800);
  static const Color ratingEmpty = Color(0xFFE3E0EB);

  // Transparent Colors
  static const Color transparent = Colors.transparent;
  static const Color semiTransparent = Color(0x80000000);

  // Gradient Colors
  static const List<Color> primaryGradient = [
    primaryLightColor,
    primaryColor,
  ];

  static const List<Color> secondaryGradient = [
    Color(0xFF5420A8),
    brandIndigo,
  ];

  /// Hero surfaces (home header, tracking banner): deep brand indigo.
  static const List<Color> brandHeroGradient = [
    Color(0xFF4A1A96),
    brandIndigoDeep,
  ];

  static const List<Color> backgroundGradient = [
    Color(0xFFF8F7FB),
    Color(0xFFEFEDF4),
  ];

  static const List<Color> darkBackgroundGradient = [
    Color(0xFF181226),
    Color(0xFF100B1C),
  ];

  // Spacing system
  static const double spaceXS = 4.0;
  static const double spaceSM = 8.0;
  static const double spaceMD = 16.0;
  static const double spaceLG = 24.0;
  static const double spaceXL = 32.0;
  static const double spaceXXL = 48.0;

  // Border radii
  static const double radiusSM = 10.0;
  static const double radiusMD = 14.0;
  static const double radiusLG = 18.0;
  static const double radiusXL = 24.0;
  static const double radiusFull = 999.0;

  // Button heights (large by default: big, easy targets)
  static const double buttonHeightSM = 44.0;
  static const double buttonHeightMD = 52.0;
  static const double buttonHeightLG = 58.0;

  // Glass/overlay surfaces
  static const Color lightGlass = Color(0x0F1B1530);
  static const Color darkGlass = Color(0x1AFFFFFF);

  /// Soft, layered card shadow used across the app.
  static List<BoxShadow> softShadow(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    if (dark) return const [];
    return const [
      BoxShadow(
        color: Color(0x0D1B1530),
        blurRadius: 2,
        offset: Offset(0, 1),
      ),
      BoxShadow(
        color: Color(0x0F1B1530),
        blurRadius: 18,
        offset: Offset(0, 8),
      ),
    ];
  }
}
