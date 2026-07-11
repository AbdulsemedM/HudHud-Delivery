import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'app_colors.dart';

class AppTheme {
  // Light Theme
  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      colorScheme: const ColorScheme.light(
        primary: AppColors.primaryColor,
        onPrimary: AppColors.lightOnPrimary,
        secondary: AppColors.secondaryColor,
        onSecondary: AppColors.lightOnSecondary,
        error: AppColors.errorColor,
        onError: AppColors.lightOnError,
        surface: AppColors.lightSurface,
        onSurface: AppColors.lightOnSurface,
      ),
      scaffoldBackgroundColor: AppColors.lightBackground,
      appBarTheme: _lightAppBarTheme,
      textTheme: _textTheme,
      elevatedButtonTheme: _lightElevatedButtonTheme,
      outlinedButtonTheme: _lightOutlinedButtonTheme,
      textButtonTheme: _lightTextButtonTheme,
      inputDecorationTheme: _lightInputDecorationTheme,
      cardTheme: _lightCardTheme,
      bottomNavigationBarTheme: _lightBottomNavigationBarTheme,
      tabBarTheme: _lightTabBarTheme,
      dividerTheme: _lightDividerTheme,
      chipTheme: _lightChipTheme,
      snackBarTheme: _lightSnackBarTheme,
      dialogTheme: _lightDialogTheme,
      floatingActionButtonTheme: _lightFABTheme,
      iconTheme: _lightIconTheme,
      listTileTheme: _lightListTileTheme,
    );
  }

  // Dark Theme
  static ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      colorScheme: const ColorScheme.dark(
        primary: AppColors.primaryLightColor,
        onPrimary: AppColors.darkOnPrimary,
        secondary: AppColors.secondaryLightColor,
        onSecondary: AppColors.darkOnSecondary,
        error: AppColors.errorLightColor,
        onError: AppColors.darkOnError,
        surface: AppColors.darkSurface,
        onSurface: AppColors.darkOnSurface,
      ),
      scaffoldBackgroundColor: AppColors.darkBackground,
      appBarTheme: _darkAppBarTheme,
      textTheme: _textTheme,
      elevatedButtonTheme: _darkElevatedButtonTheme,
      outlinedButtonTheme: _darkOutlinedButtonTheme,
      textButtonTheme: _darkTextButtonTheme,
      inputDecorationTheme: _darkInputDecorationTheme,
      cardTheme: _darkCardTheme,
      bottomNavigationBarTheme: _darkBottomNavigationBarTheme,
      tabBarTheme: _darkTabBarTheme,
      dividerTheme: _darkDividerTheme,
      chipTheme: _darkChipTheme,
      snackBarTheme: _darkSnackBarTheme,
      dialogTheme: _darkDialogTheme,
      floatingActionButtonTheme: _darkFABTheme,
      iconTheme: _darkIconTheme,
      listTileTheme: _darkListTileTheme,
    );
  }

  // Text Theme
  static const TextTheme _textTheme = TextTheme(
    displayLarge: TextStyle(
      fontSize: 57,
      fontWeight: FontWeight.w400,
      letterSpacing: -0.25,
    ),
    displayMedium: TextStyle(
      fontSize: 45,
      fontWeight: FontWeight.w400,
    ),
    displaySmall: TextStyle(
      fontSize: 36,
      fontWeight: FontWeight.w400,
    ),
    headlineLarge: TextStyle(
      fontSize: 32,
      fontWeight: FontWeight.w400,
    ),
    headlineMedium: TextStyle(
      fontSize: 28,
      fontWeight: FontWeight.w400,
    ),
    headlineSmall: TextStyle(
      fontSize: 24,
      fontWeight: FontWeight.w400,
    ),
    titleLarge: TextStyle(
      fontSize: 22,
      fontWeight: FontWeight.w500,
    ),
    titleMedium: TextStyle(
      fontSize: 16,
      fontWeight: FontWeight.w500,
      letterSpacing: 0.15,
    ),
    titleSmall: TextStyle(
      fontSize: 14,
      fontWeight: FontWeight.w500,
      letterSpacing: 0.1,
    ),
    bodyLarge: TextStyle(
      fontSize: 16,
      fontWeight: FontWeight.w400,
      letterSpacing: 0.5,
    ),
    bodyMedium: TextStyle(
      fontSize: 14,
      fontWeight: FontWeight.w400,
      letterSpacing: 0.25,
    ),
    bodySmall: TextStyle(
      fontSize: 12,
      fontWeight: FontWeight.w400,
      letterSpacing: 0.4,
    ),
    labelLarge: TextStyle(
      fontSize: 14,
      fontWeight: FontWeight.w500,
      letterSpacing: 0.1,
    ),
    labelMedium: TextStyle(
      fontSize: 12,
      fontWeight: FontWeight.w500,
      letterSpacing: 0.5,
    ),
    labelSmall: TextStyle(
      fontSize: 11,
      fontWeight: FontWeight.w500,
      letterSpacing: 0.5,
    ),
  );

  // Light Theme Components
  static const AppBarTheme _lightAppBarTheme = AppBarTheme(
    backgroundColor: AppColors.primaryColor,
    foregroundColor: AppColors.lightOnPrimary,
    elevation: 0,
    centerTitle: true,
    systemOverlayStyle: SystemUiOverlayStyle.light,
  );

  static final ElevatedButtonThemeData _lightElevatedButtonTheme =
      ElevatedButtonThemeData(
    style: ElevatedButton.styleFrom(
      backgroundColor: AppColors.primaryColor,
      foregroundColor: AppColors.lightOnPrimary,
      elevation: 2,
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
      ),
    ),
  );

  static final OutlinedButtonThemeData _lightOutlinedButtonTheme =
      OutlinedButtonThemeData(
    style: OutlinedButton.styleFrom(
      foregroundColor: AppColors.primaryColor,
      side: const BorderSide(color: AppColors.primaryColor),
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
      ),
    ),
  );

  static final TextButtonThemeData _lightTextButtonTheme = TextButtonThemeData(
    style: TextButton.styleFrom(
      foregroundColor: AppColors.primaryColor,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
    ),
  );

  static final InputDecorationTheme _lightInputDecorationTheme =
      InputDecorationTheme(
    filled: true,
    fillColor: AppColors.lightInputFill,
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(8),
      borderSide: const BorderSide(color: AppColors.lightInputBorder),
    ),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(8),
      borderSide: const BorderSide(color: AppColors.lightInputBorder),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(8),
      borderSide: const BorderSide(color: AppColors.primaryColor, width: 2),
    ),
    errorBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(8),
      borderSide: const BorderSide(color: AppColors.errorColor),
    ),
    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
  );

  static const CardThemeData _lightCardTheme = CardThemeData(
    color: AppColors.lightCard,
    elevation: 2,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.all(Radius.circular(12)),
    ),
  );

  // Dark Theme Components
  static const AppBarTheme _darkAppBarTheme = AppBarTheme(
    backgroundColor: AppColors.darkSurface,
    foregroundColor: AppColors.darkTextPrimary,
    elevation: 0,
    centerTitle: true,
    systemOverlayStyle: SystemUiOverlayStyle.dark,
  );

  static final ElevatedButtonThemeData _darkElevatedButtonTheme =
      ElevatedButtonThemeData(
    style: ElevatedButton.styleFrom(
      backgroundColor: AppColors.primaryLightColor,
      foregroundColor: AppColors.darkOnPrimary,
      elevation: 2,
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
      ),
    ),
  );

  static final OutlinedButtonThemeData _darkOutlinedButtonTheme =
      OutlinedButtonThemeData(
    style: OutlinedButton.styleFrom(
      foregroundColor: AppColors.primaryLightColor,
      side: const BorderSide(color: AppColors.primaryLightColor),
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
      ),
    ),
  );

  static final TextButtonThemeData _darkTextButtonTheme = TextButtonThemeData(
    style: TextButton.styleFrom(
      foregroundColor: AppColors.primaryLightColor,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
    ),
  );

  static final InputDecorationTheme _darkInputDecorationTheme =
      InputDecorationTheme(
    filled: true,
    fillColor: AppColors.darkInputFill,
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(8),
      borderSide: const BorderSide(color: AppColors.darkInputBorder),
    ),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(8),
      borderSide: const BorderSide(color: AppColors.darkInputBorder),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(8),
      borderSide:
          const BorderSide(color: AppColors.primaryLightColor, width: 2),
    ),
    errorBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(8),
      borderSide: const BorderSide(color: AppColors.errorLightColor),
    ),
    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
  );

  static const CardThemeData _darkCardTheme = CardThemeData(
    color: AppColors.darkCard,
    elevation: 2,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.all(Radius.circular(12)),
    ),
  );

  // Common Theme Components
  static const BottomNavigationBarThemeData _lightBottomNavigationBarTheme =
      BottomNavigationBarThemeData(
    backgroundColor: AppColors.lightSurface,
    selectedItemColor: AppColors.primaryColor,
    unselectedItemColor: AppColors.lightTextSecondary,
    type: BottomNavigationBarType.fixed,
  );

  static const BottomNavigationBarThemeData _darkBottomNavigationBarTheme =
      BottomNavigationBarThemeData(
    backgroundColor: AppColors.darkSurface,
    selectedItemColor: AppColors.primaryLightColor,
    unselectedItemColor: AppColors.darkTextSecondary,
    type: BottomNavigationBarType.fixed,
  );

  static const TabBarThemeData _lightTabBarTheme = TabBarThemeData(
    labelColor: AppColors.primaryColor,
    unselectedLabelColor: AppColors.lightTextSecondary,
    indicator: UnderlineTabIndicator(
      borderSide: BorderSide(color: AppColors.primaryColor, width: 2),
    ),
  );

  static const TabBarThemeData _darkTabBarTheme = TabBarThemeData(
    labelColor: AppColors.primaryLightColor,
    unselectedLabelColor: AppColors.darkTextSecondary,
    indicator: UnderlineTabIndicator(
      borderSide: BorderSide(color: AppColors.primaryLightColor, width: 2),
    ),
  );

  static const DividerThemeData _lightDividerTheme = DividerThemeData(
    color: AppColors.lightDivider,
    thickness: 1,
  );

  static const DividerThemeData _darkDividerTheme = DividerThemeData(
    color: AppColors.darkDivider,
    thickness: 1,
  );

  static final ChipThemeData _lightChipTheme = ChipThemeData(
    backgroundColor: AppColors.lightInputFill,
    selectedColor: AppColors.primaryColor,
    labelStyle: const TextStyle(color: AppColors.lightTextPrimary),
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(16),
    ),
  );

  static final ChipThemeData _darkChipTheme = ChipThemeData(
    backgroundColor: AppColors.darkInputFill,
    selectedColor: AppColors.primaryLightColor,
    labelStyle: const TextStyle(color: AppColors.darkTextPrimary),
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(16),
    ),
  );

  static const SnackBarThemeData _lightSnackBarTheme = SnackBarThemeData(
    backgroundColor: AppColors.lightTextPrimary,
    contentTextStyle: TextStyle(color: AppColors.lightSurface),
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.all(Radius.circular(8)),
    ),
  );

  static const SnackBarThemeData _darkSnackBarTheme = SnackBarThemeData(
    backgroundColor: AppColors.darkTextPrimary,
    contentTextStyle: TextStyle(color: AppColors.darkSurface),
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.all(Radius.circular(8)),
    ),
  );

  static const DialogThemeData _lightDialogTheme = DialogThemeData(
    backgroundColor: AppColors.lightSurface,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.all(Radius.circular(16)),
    ),
  );

  static const DialogThemeData _darkDialogTheme = DialogThemeData(
    backgroundColor: AppColors.darkSurface,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.all(Radius.circular(16)),
    ),
  );

  static const FloatingActionButtonThemeData _lightFABTheme =
      FloatingActionButtonThemeData(
    backgroundColor: AppColors.primaryColor,
    foregroundColor: AppColors.lightOnPrimary,
  );

  static const FloatingActionButtonThemeData _darkFABTheme =
      FloatingActionButtonThemeData(
    backgroundColor: AppColors.primaryLightColor,
    foregroundColor: AppColors.darkOnPrimary,
  );

  static const IconThemeData _lightIconTheme = IconThemeData(
    color: AppColors.lightTextPrimary,
    size: 24,
  );

  static const IconThemeData _darkIconTheme = IconThemeData(
    color: AppColors.darkTextPrimary,
    size: 24,
  );

  static const ListTileThemeData _lightListTileTheme = ListTileThemeData(
    iconColor: AppColors.lightTextSecondary,
    textColor: AppColors.lightTextPrimary,
  );

  static const ListTileThemeData _darkListTileTheme = ListTileThemeData(
    iconColor: AppColors.darkTextSecondary,
    textColor: AppColors.darkTextPrimary,
  );

  /// Light theme tinted by service accent (Courier / Taxi / Handyman / Food).
  static ThemeData lightThemeWithSeed(Color seed) {
    final cs = ColorScheme.fromSeed(
      seedColor: seed,
      brightness: Brightness.light,
    );
    return lightTheme.copyWith(
      colorScheme: cs,
      primaryColor: cs.primary,
      appBarTheme: _lightAppBarTheme.copyWith(
        backgroundColor: cs.primary,
        foregroundColor: cs.onPrimary,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: cs.primary,
          foregroundColor: cs.onPrimary,
          elevation: 2,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: cs.primary,
          side: BorderSide(color: cs.primary),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: cs.primary,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        ),
      ),
      inputDecorationTheme: _lightInputDecorationTheme.copyWith(
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: cs.primary, width: 2),
        ),
      ),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: cs.primary,
        foregroundColor: cs.onPrimary,
      ),
      bottomNavigationBarTheme: _lightBottomNavigationBarTheme.copyWith(
        selectedItemColor: cs.primary,
      ),
      tabBarTheme: _lightTabBarTheme.copyWith(
        labelColor: cs.primary,
        indicator: UnderlineTabIndicator(
          borderSide: BorderSide(color: cs.primary, width: 2),
        ),
      ),
      chipTheme: _lightChipTheme.copyWith(
        selectedColor: cs.primary,
      ),
    );
  }

  /// Dark theme tinted by service accent.
  static ThemeData darkThemeWithSeed(Color seed) {
    final cs = ColorScheme.fromSeed(
      seedColor: seed,
      brightness: Brightness.dark,
    );
    return darkTheme.copyWith(
      colorScheme: cs,
      primaryColor: cs.primary,
      appBarTheme: _darkAppBarTheme.copyWith(
        backgroundColor: cs.primary,
        foregroundColor: cs.onPrimary,
        systemOverlayStyle: SystemUiOverlayStyle.light,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: cs.primary,
          foregroundColor: cs.onPrimary,
          elevation: 2,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: cs.primary,
          side: BorderSide(color: cs.primary),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: cs.primary,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        ),
      ),
      inputDecorationTheme: _darkInputDecorationTheme.copyWith(
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: cs.primary, width: 2),
        ),
      ),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: cs.primary,
        foregroundColor: cs.onPrimary,
      ),
      bottomNavigationBarTheme: _darkBottomNavigationBarTheme.copyWith(
        selectedItemColor: cs.primary,
      ),
      tabBarTheme: _darkTabBarTheme.copyWith(
        labelColor: cs.primary,
        indicator: UnderlineTabIndicator(
          borderSide: BorderSide(color: cs.primary, width: 2),
        ),
      ),
      chipTheme: _darkChipTheme.copyWith(
        selectedColor: cs.primary,
      ),
    );
  }
}
