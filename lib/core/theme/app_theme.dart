import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'app_colors.dart';

/// App-wide [ThemeData].
///
/// Primary actions are always HudHud orange (one clear "go" colour for
/// low-literacy users); indigo is the brand/secondary colour. Type is set in
/// Plus Jakarta Sans with Noto Sans Ethiopic as the Amharic fallback.
class AppTheme {
  static const String fontFamily = 'PlusJakartaSans';
  static const List<String> fontFallback = ['NotoSansEthiopic'];

  static ThemeData get lightTheme => _build(Brightness.light);
  static ThemeData get darkTheme => _build(Brightness.dark);

  /// Kept for API compatibility. Service tabs no longer re-tint the app:
  /// orange stays the action colour everywhere so it is learnable.
  static ThemeData lightThemeWithSeed(Color seed) => lightTheme;
  static ThemeData darkThemeWithSeed(Color seed) => darkTheme;

  static ThemeData _build(Brightness brightness) {
    final dark = brightness == Brightness.dark;

    final primary = dark ? AppColors.primaryLightColor : AppColors.primaryColor;
    final secondary =
        dark ? AppColors.brandIndigoBright : AppColors.brandIndigo;
    final background =
        dark ? AppColors.darkBackground : AppColors.lightBackground;
    final surface = dark ? AppColors.darkSurface : AppColors.lightSurface;
    final surfaceHigh =
        dark ? AppColors.darkSurfaceVariant : AppColors.lightInputFill;
    final textPrimary =
        dark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary;
    final textSecondary =
        dark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary;
    final textHint = dark ? AppColors.darkTextHint : AppColors.lightTextHint;
    final border = dark ? AppColors.darkBorder : AppColors.lightBorder;
    final inputFill = dark ? AppColors.darkInputFill : AppColors.lightInputFill;
    final error = dark ? AppColors.errorLightColor : AppColors.errorColor;

    final scheme = ColorScheme(
      brightness: brightness,
      primary: primary,
      onPrimary: Colors.white,
      primaryContainer: dark ? AppColors.orangeTintDark : AppColors.orangeTint,
      onPrimaryContainer: dark ? const Color(0xFFFFB892) : AppColors.primaryDarkColor,
      secondary: secondary,
      onSecondary: Colors.white,
      secondaryContainer:
          dark ? AppColors.indigoTintDark : AppColors.indigoTint,
      onSecondaryContainer:
          dark ? const Color(0xFFD9CCFF) : AppColors.brandIndigo,
      tertiary: AppColors.successColor,
      onTertiary: Colors.white,
      error: error,
      onError: Colors.white,
      surface: surface,
      onSurface: textPrimary,
      onSurfaceVariant: textSecondary,
      surfaceContainerLowest: dark ? AppColors.darkBackground : Colors.white,
      surfaceContainerLow: dark ? AppColors.darkSurface : const Color(0xFFFAF9FC),
      surfaceContainer: dark ? AppColors.darkCard : AppColors.lightBackground,
      surfaceContainerHigh: surfaceHigh,
      surfaceContainerHighest:
          dark ? const Color(0xFF2A2240) : const Color(0xFFE9E6F0),
      outline: border,
      outlineVariant: dark ? AppColors.darkDivider : AppColors.lightDivider,
      shadow: Colors.black,
      scrim: Colors.black,
      inverseSurface: dark ? AppColors.lightSurface : AppColors.brandInk,
      onInverseSurface: dark ? AppColors.brandInk : Colors.white,
      inversePrimary: AppColors.primaryLightColor,
      surfaceTint: Colors.transparent,
    );

    final textTheme = _textTheme(textPrimary, textSecondary);

    final buttonShape = RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(16),
    );
    const buttonText = TextStyle(
      fontFamily: fontFamily,
      fontFamilyFallback: fontFallback,
      fontSize: 16,
      fontWeight: FontWeight.w700,
      letterSpacing: 0.1,
    );

    OutlineInputBorder inputBorder(Color c, [double w = 1]) =>
        OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: c, width: w),
        );

    return ThemeData(
      useMaterial3: true,
      brightness: brightness,
      fontFamily: fontFamily,
      fontFamilyFallback: fontFallback,
      colorScheme: scheme,
      primaryColor: primary,
      scaffoldBackgroundColor: background,
      canvasColor: background,
      splashFactory: InkSparkle.splashFactory,
      visualDensity: VisualDensity.standard,
      materialTapTargetSize: MaterialTapTargetSize.padded,
      textTheme: textTheme,
      primaryTextTheme: textTheme,
      appBarTheme: AppBarTheme(
        backgroundColor: background,
        foregroundColor: textPrimary,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0.5,
        centerTitle: true,
        titleTextStyle: textTheme.titleLarge?.copyWith(fontSize: 19),
        iconTheme: IconThemeData(color: textPrimary, size: 26),
        systemOverlayStyle:
            dark ? SystemUiOverlayStyle.light : SystemUiOverlayStyle.dark,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primary,
          foregroundColor: Colors.white,
          disabledBackgroundColor: dark
              ? const Color(0xFF2A2338)
              : AppColors.disabledButton,
          disabledForegroundColor: textHint,
          elevation: 0,
          shadowColor: Colors.transparent,
          minimumSize: const Size(64, 52),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          shape: buttonShape,
          textStyle: buttonText,
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: primary,
          foregroundColor: Colors.white,
          disabledBackgroundColor: dark
              ? const Color(0xFF2A2338)
              : AppColors.disabledButton,
          disabledForegroundColor: textHint,
          minimumSize: const Size(64, 52),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          shape: buttonShape,
          textStyle: buttonText,
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: textPrimary,
          side: BorderSide(color: border, width: 1.5),
          minimumSize: const Size(64, 52),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          shape: buttonShape,
          textStyle: buttonText,
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: primary,
          minimumSize: const Size(48, 44),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          textStyle: buttonText.copyWith(fontSize: 15),
        ),
      ),
      iconButtonTheme: IconButtonThemeData(
        style: IconButton.styleFrom(
          minimumSize: const Size(48, 48),
          foregroundColor: textPrimary,
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: inputFill,
        hintStyle: TextStyle(color: textHint, fontSize: 16),
        labelStyle: TextStyle(color: textSecondary, fontSize: 15),
        floatingLabelStyle:
            TextStyle(color: primary, fontWeight: FontWeight.w600),
        prefixIconColor: textSecondary,
        suffixIconColor: textSecondary,
        border: inputBorder(Colors.transparent),
        enabledBorder: inputBorder(Colors.transparent),
        focusedBorder: inputBorder(primary, 1.8),
        errorBorder: inputBorder(error, 1.4),
        focusedErrorBorder: inputBorder(error, 1.8),
        disabledBorder: inputBorder(Colors.transparent),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 18, vertical: 18),
      ),
      cardTheme: CardThemeData(
        color: dark ? AppColors.darkCard : AppColors.lightCard,
        elevation: 0,
        margin: EdgeInsets.zero,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: BorderSide(color: border),
        ),
      ),
      navigationBarTheme: NavigationBarThemeData(
        height: 72,
        elevation: 0,
        backgroundColor: surface,
        surfaceTintColor: Colors.transparent,
        indicatorColor: scheme.primaryContainer,
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          final selected = states.contains(WidgetState.selected);
          return TextStyle(
            fontFamily: fontFamily,
            fontSize: 12.5,
            fontWeight: selected ? FontWeight.w700 : FontWeight.w600,
            color: selected ? primary : textSecondary,
          );
        }),
      ),
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: surface,
        selectedItemColor: primary,
        unselectedItemColor: textSecondary,
        type: BottomNavigationBarType.fixed,
      ),
      tabBarTheme: TabBarThemeData(
        labelColor: primary,
        unselectedLabelColor: textSecondary,
        labelStyle: buttonText.copyWith(fontSize: 15),
        unselectedLabelStyle:
            buttonText.copyWith(fontSize: 15, fontWeight: FontWeight.w600),
        indicatorSize: TabBarIndicatorSize.label,
        dividerColor: Colors.transparent,
        indicator: UnderlineTabIndicator(
          borderSide: BorderSide(color: primary, width: 3),
          borderRadius: BorderRadius.circular(3),
        ),
      ),
      dividerTheme: DividerThemeData(
        color: dark ? AppColors.darkDivider : AppColors.lightDivider,
        thickness: 1,
        space: 1,
      ),
      chipTheme: ChipThemeData(
        backgroundColor: surface,
        selectedColor: scheme.secondary,
        secondarySelectedColor: scheme.secondary,
        checkmarkColor: Colors.white,
        side: BorderSide(color: border),
        labelStyle: TextStyle(
          fontFamily: fontFamily,
          color: textPrimary,
          fontWeight: FontWeight.w600,
          fontSize: 14,
        ),
        secondaryLabelStyle: const TextStyle(
          fontFamily: fontFamily,
          color: Colors.white,
          fontWeight: FontWeight.w700,
          fontSize: 14,
        ),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(999),
        ),
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: dark ? AppColors.darkSurfaceVariant : AppColors.brandInk,
        contentTextStyle: const TextStyle(
          fontFamily: fontFamily,
          color: Colors.white,
          fontSize: 15,
          fontWeight: FontWeight.w600,
        ),
        actionTextColor: AppColors.primaryLightColor,
        behavior: SnackBarBehavior.floating,
        elevation: 0,
        insetPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: surface,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(28),
        ),
        titleTextStyle: textTheme.titleLarge,
        contentTextStyle: textTheme.bodyLarge?.copyWith(color: textSecondary),
      ),
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: surface,
        modalBackgroundColor: surface,
        surfaceTintColor: Colors.transparent,
        showDragHandle: false,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
      ),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: primary,
        foregroundColor: Colors.white,
        elevation: 2,
        highlightElevation: 4,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        extendedTextStyle: buttonText,
      ),
      iconTheme: IconThemeData(color: textPrimary, size: 24),
      listTileTheme: ListTileThemeData(
        iconColor: textSecondary,
        textColor: textPrimary,
        minVerticalPadding: 12,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16),
        titleTextStyle: textTheme.titleMedium,
        subtitleTextStyle:
            textTheme.bodyMedium?.copyWith(color: textSecondary),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
      ),
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith(
          (s) => s.contains(WidgetState.selected) ? Colors.white : null,
        ),
        trackColor: WidgetStateProperty.resolveWith(
          (s) => s.contains(WidgetState.selected) ? AppColors.successColor : null,
        ),
        trackOutlineColor: WidgetStateProperty.resolveWith(
          (s) => s.contains(WidgetState.selected) ? Colors.transparent : null,
        ),
      ),
      checkboxTheme: CheckboxThemeData(
        fillColor: WidgetStateProperty.resolveWith(
          (s) => s.contains(WidgetState.selected) ? primary : null,
        ),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
        side: BorderSide(color: textHint, width: 1.6),
      ),
      radioTheme: RadioThemeData(
        fillColor: WidgetStateProperty.resolveWith(
          (s) => s.contains(WidgetState.selected) ? primary : textHint,
        ),
      ),
      progressIndicatorTheme: ProgressIndicatorThemeData(
        color: primary,
        linearTrackColor: scheme.primaryContainer,
        circularTrackColor: Colors.transparent,
      ),
      sliderTheme: SliderThemeData(
        activeTrackColor: primary,
        thumbColor: primary,
        inactiveTrackColor: scheme.primaryContainer,
      ),
      popupMenuTheme: PopupMenuThemeData(
        color: surface,
        surfaceTintColor: Colors.transparent,
        elevation: 6,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
      ),
      pageTransitionsTheme: const PageTransitionsTheme(
        builders: {
          TargetPlatform.android: FadeForwardsPageTransitionsBuilder(),
          TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
        },
      ),
    );
  }

  /// Slightly larger than Material defaults: easier to read at arm's length.
  static TextTheme _textTheme(Color primary, Color secondary) {
    TextStyle s(double size, FontWeight w, {double ls = 0, double? h, Color? c}) =>
        TextStyle(
          fontFamily: fontFamily,
          fontFamilyFallback: fontFallback,
          fontSize: size,
          fontWeight: w,
          letterSpacing: ls,
          height: h,
          color: c ?? primary,
        );
    return TextTheme(
      displayLarge: s(52, FontWeight.w800, ls: -1.2, h: 1.1),
      displayMedium: s(42, FontWeight.w800, ls: -1, h: 1.1),
      displaySmall: s(34, FontWeight.w800, ls: -0.8, h: 1.15),
      headlineLarge: s(30, FontWeight.w800, ls: -0.6, h: 1.2),
      headlineMedium: s(26, FontWeight.w800, ls: -0.5, h: 1.2),
      headlineSmall: s(22, FontWeight.w700, ls: -0.3, h: 1.25),
      titleLarge: s(20, FontWeight.w700, ls: -0.2, h: 1.3),
      titleMedium: s(16.5, FontWeight.w700, h: 1.35),
      titleSmall: s(14.5, FontWeight.w700, h: 1.35),
      bodyLarge: s(16.5, FontWeight.w500, h: 1.5),
      bodyMedium: s(15, FontWeight.w500, h: 1.45),
      bodySmall: s(13, FontWeight.w500, h: 1.4, c: secondary),
      labelLarge: s(15, FontWeight.w700, ls: 0.1),
      labelMedium: s(13, FontWeight.w600, ls: 0.1),
      labelSmall: s(11.5, FontWeight.w600, ls: 0.2),
    );
  }
}
