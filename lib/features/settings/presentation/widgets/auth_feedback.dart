import 'package:flutter/material.dart';
import 'package:hudhud_delivery/features/login/presentation/theme/auth_screen_colors.dart';

/// Floating snackbars matching Profile / auth chrome in light and dark modes.
class AuthSnackBar {
  AuthSnackBar._();

  static void show(
    BuildContext context,
    String message, {
    IconData icon = Icons.info_outline_rounded,
    Color accent = AuthScreenColors.orange,
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
        margin: EdgeInsets.fromLTRB(16, 0, 16, 16),
        padding: EdgeInsets.zero,
        duration: duration,
        content: _AuthSnackBarBody(
          message: message,
          icon: icon,
          accent: accent,
          action: action,
        ),
      ),
    );
  }

  static void success(BuildContext context, String message) {
    show(
      context,
      message,
      icon: Icons.check_circle_rounded,
      accent: const Color(0xFF4CAF50),
    );
  }

  static void error(BuildContext context, String message) {
    show(
      context,
      message,
      icon: Icons.error_outline_rounded,
      accent: const Color(0xFFEF5350),
      duration: const Duration(seconds: 4),
    );
  }

  static void info(BuildContext context, String message) {
    show(
      context,
      message,
      icon: Icons.info_outline_rounded,
      accent: AuthScreenColors.orange,
    );
  }

  static void comingSoon(BuildContext context, String message) {
    show(
      context,
      message,
      icon: Icons.schedule_rounded,
      accent: AuthScreenColors.purple,
    );
  }
}

class _AuthSnackBarBody extends StatelessWidget {
  const _AuthSnackBarBody({
    required this.message,
    required this.icon,
    required this.accent,
    this.action,
  });

  final String message;
  final IconData icon;
  final Color accent;
  final SnackBarAction? action;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: AuthScreenColors.surfaceOf(context),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AuthScreenColors.surfaceBorderOf(context)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.15),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(10),
              color: accent.withValues(alpha: 0.15),
            ),
            child: Icon(icon, color: accent, size: 20),
          ),
          SizedBox(width: 12),
          Expanded(
            child: Text(
              message,
              style: TextStyle(
                color: AuthScreenColors.textPrimaryOf(context),
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          if (action != null) ...[
            SizedBox(width: 8),
            TextButton(
              onPressed: () {
                ScaffoldMessenger.of(context).hideCurrentSnackBar();
                action!.onPressed();
              },
              style: TextButton.styleFrom(
                foregroundColor: AuthScreenColors.orange,
                padding: EdgeInsets.symmetric(horizontal: 8),
                minimumSize: Size.zero,
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
              child: Text(
                action!.label,
                style: TextStyle(fontWeight: FontWeight.w700),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// AlertDialog + bottom sheet helpers for Profile chrome.
class AuthModal {
  AuthModal._();

  static Future<T?> dialog<T>({
    required BuildContext context,
    required Widget Function(BuildContext dialogContext) builder,
    bool barrierDismissible = true,
  }) {
    return showDialog<T>(
      context: context,
      barrierDismissible: barrierDismissible,
      barrierColor: Colors.black.withValues(alpha: 0.45),
      builder: (dialogContext) {
        return Theme(
          data: AuthScreenColors.themeFor(context),
          child: builder(dialogContext),
        );
      },
    );
  }

  static Future<bool?> confirm({
    required BuildContext context,
    required String title,
    required String message,
    required String confirmLabel,
    String? cancelLabel,
    bool destructive = false,
    bool barrierDismissible = true,
  }) {
    return dialog<bool>(
      context: context,
      barrierDismissible: barrierDismissible,
      builder: (dialogContext) {
        return AuthAlertDialog(
          title: title,
          content: Text(message),
          actions: [
            AuthDialogAction(
              label: cancelLabel ??
                  MaterialLocalizations.of(dialogContext).cancelButtonLabel,
              onPressed: () => Navigator.of(dialogContext).pop(false),
            ),
            AuthDialogAction(
              label: confirmLabel,
              filled: true,
              destructive: destructive,
              onPressed: () => Navigator.of(dialogContext).pop(true),
            ),
          ],
        );
      },
    );
  }

  static Future<T?> sheet<T>({
    required BuildContext context,
    required Widget Function(BuildContext sheetContext) builder,
    bool isScrollControlled = false,
  }) {
    return showModalBottomSheet<T>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: isScrollControlled,
      barrierColor: Colors.black.withValues(alpha: 0.45),
      builder: (sheetContext) {
        return Theme(
          data: AuthScreenColors.themeFor(context),
          child: Container(
            decoration: BoxDecoration(
              color: AuthScreenColors.surfaceOf(context),
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(22)),
              border: Border(
                top: BorderSide(
                    color: AuthScreenColors.surfaceBorderOf(context)),
                left: BorderSide(
                    color: AuthScreenColors.surfaceBorderOf(context)),
                right: BorderSide(
                    color: AuthScreenColors.surfaceBorderOf(context)),
              ),
            ),
            child: builder(sheetContext),
          ),
        );
      },
    );
  }
}

class AuthAlertDialog extends StatelessWidget {
  const AuthAlertDialog({
    super.key,
    required this.title,
    this.content,
    this.actions = const [],
  });

  final String title;
  final Widget? content;
  final List<Widget> actions;

  @override
  Widget build(BuildContext context) {
    return Theme(
      data: AuthScreenColors.themeFor(context),
      child: Dialog(
        backgroundColor: AuthScreenColors.surfaceOf(context),
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        insetPadding: EdgeInsets.symmetric(horizontal: 28, vertical: 24),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(22),
          side: BorderSide(color: AuthScreenColors.surfaceBorderOf(context)),
        ),
        child: Padding(
          padding: EdgeInsets.fromLTRB(20, 22, 20, 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                title,
                style: TextStyle(
                  color: AuthScreenColors.textPrimaryOf(context),
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                ),
              ),
              if (content != null) ...[
                SizedBox(height: 12),
                DefaultTextStyle(
                  style: TextStyle(
                    color: AuthScreenColors.textSecondaryOf(context),
                    fontSize: 14,
                    height: 1.4,
                  ),
                  child: content!,
                ),
              ],
              if (actions.isNotEmpty) ...[
                SizedBox(height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    for (var i = 0; i < actions.length; i++) ...[
                      if (i > 0) SizedBox(width: 8),
                      actions[i],
                    ],
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class AuthDialogAction extends StatelessWidget {
  const AuthDialogAction({
    super.key,
    required this.label,
    required this.onPressed,
    this.filled = false,
    this.destructive = false,
    this.enabled = true,
  });

  final String label;
  final VoidCallback onPressed;
  final bool filled;
  final bool destructive;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    if (!filled) {
      return TextButton(
        onPressed: enabled ? onPressed : null,
        style: TextButton.styleFrom(
          foregroundColor: AuthScreenColors.textMutedOf(context),
        ),
        child: Text(label),
      );
    }

    final bg = destructive ? const Color(0xFFEF5350) : AuthScreenColors.orange;
    return FilledButton(
      onPressed: enabled ? onPressed : null,
      style: FilledButton.styleFrom(
        backgroundColor: bg,
        foregroundColor:
            destructive ? Colors.white : Theme.of(context).colorScheme.onPrimary,
        disabledBackgroundColor: bg.withValues(alpha: 0.35),
        shape: const StadiumBorder(),
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
      ),
      child: Text(
        label,
        style: const TextStyle(fontWeight: FontWeight.w700),
      ),
    );
  }
}
