import 'package:flutter/material.dart';
import 'package:hudhud_delivery/features/login/presentation/theme/auth_screen_colors.dart';
import 'package:hudhud_delivery/features/settings/presentation/widgets/auth_feedback.dart';

class SnackbarUtil {
  static void showSuccess(
    BuildContext context,
    String message, {
    Duration duration = const Duration(seconds: 3),
    SnackBarAction? action,
  }) {
    AuthSnackBar.show(
      context,
      message,
      icon: Icons.check_circle_rounded,
      accent: const Color(0xFF4CAF50),
      duration: duration,
      action: action,
    );
  }

  static void showError(
    BuildContext context,
    String message, {
    Duration duration = const Duration(seconds: 4),
    SnackBarAction? action,
  }) {
    AuthSnackBar.show(
      context,
      message,
      icon: Icons.error_outline_rounded,
      accent: const Color(0xFFEF5350),
      duration: duration,
      action: action,
    );
  }

  static void showWarning(
    BuildContext context,
    String message, {
    Duration duration = const Duration(seconds: 3),
    SnackBarAction? action,
  }) {
    AuthSnackBar.show(
      context,
      message,
      icon: Icons.warning_amber_rounded,
      accent: AuthScreenColors.orangeBright,
      duration: duration,
      action: action,
    );
  }

  static void showInfo(
    BuildContext context,
    String message, {
    Duration duration = const Duration(seconds: 3),
    SnackBarAction? action,
  }) {
    AuthSnackBar.show(
      context,
      message,
      icon: Icons.info_outline_rounded,
      accent: AuthScreenColors.orange,
      duration: duration,
      action: action,
    );
  }

  static void showCustom(
    BuildContext context,
    String message, {
    Color? backgroundColor,
    Color? textColor,
    IconData? icon,
    Duration duration = const Duration(seconds: 3),
    SnackBarAction? action,
  }) {
    AuthSnackBar.show(
      context,
      message,
      icon: icon ?? Icons.info_outline_rounded,
      accent: backgroundColor ?? AuthScreenColors.orange,
      duration: duration,
      action: action,
    );
  }

  static void showLoading(
    BuildContext context,
    String message, {
    Duration? duration,
  }) {
    AuthSnackBar.show(
      context,
      message,
      icon: Icons.hourglass_top_rounded,
      accent: AuthScreenColors.purple,
      duration: duration ?? const Duration(days: 1),
    );
  }

  static void hide(BuildContext context) {
    ScaffoldMessenger.of(context).removeCurrentSnackBar();
  }

  static void hideSnackbar(BuildContext context) {
    hide(context);
  }

  static void showCustomWidget(
    BuildContext context,
    Widget content, {
    Color? backgroundColor,
    Duration duration = const Duration(seconds: 3),
    SnackBarAction? action,
  }) {
    final messenger = ScaffoldMessenger.of(context);
    messenger.removeCurrentSnackBar();
    messenger.showSnackBar(
      SnackBar(
        behavior: SnackBarBehavior.floating,
        backgroundColor: Colors.transparent,
        elevation: 0,
        margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        padding: EdgeInsets.zero,
        duration: duration,
        content: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            color: backgroundColor ?? AuthScreenColors.surface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AuthScreenColors.surfaceBorder),
          ),
          child: content,
        ),
        action: action,
      ),
    );
  }
}
