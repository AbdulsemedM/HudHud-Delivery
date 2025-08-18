import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';

enum SnackbarType {
  success,
  error,
  warning,
  info,
  custom,
}

class CustomSnackbar extends StatelessWidget {
  final String message;
  final SnackbarType type;
  final IconData? icon;
  final Color? backgroundColor;
  final Color? textColor;
  final Color? iconColor;
  final VoidCallback? onActionPressed;
  final String? actionLabel;
  final Duration? duration;
  final bool showCloseButton;

  const CustomSnackbar({
    Key? key,
    required this.message,
    this.type = SnackbarType.info,
    this.icon,
    this.backgroundColor,
    this.textColor,
    this.iconColor,
    this.onActionPressed,
    this.actionLabel,
    this.duration,
    this.showCloseButton = false,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final colors = _getColorsForType();
    
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: backgroundColor ?? colors['background'],
        borderRadius: BorderRadius.circular(8),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          if (icon != null || type != SnackbarType.custom) ...[
            Icon(
              icon ?? _getIconForType(),
              color: iconColor ?? colors['icon'],
              size: 20,
            ),
            const SizedBox(width: 12),
          ],
          Expanded(
            child: Text(
              message,
              style: TextStyle(
                color: textColor ?? colors['text'],
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          if (onActionPressed != null && actionLabel != null) ...[
            const SizedBox(width: 8),
            TextButton(
              onPressed: onActionPressed,
              style: TextButton.styleFrom(
                foregroundColor: textColor ?? colors['text'],
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                minimumSize: Size.zero,
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
              child: Text(
                actionLabel!,
                style: const TextStyle(
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
          if (showCloseButton) ...[
            const SizedBox(width: 8),
            IconButton(
              onPressed: () {
                ScaffoldMessenger.of(context).hideCurrentSnackBar();
              },
              icon: Icon(
                Icons.close,
                color: iconColor ?? colors['icon'],
                size: 18,
              ),
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(
                minWidth: 24,
                minHeight: 24,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Map<String, Color> _getColorsForType() {
    switch (type) {
      case SnackbarType.success:
        return {
          'background': AppColors.successColor,
          'text': Colors.white,
          'icon': Colors.white,
        };
      case SnackbarType.error:
        return {
          'background': AppColors.errorColor,
          'text': Colors.white,
          'icon': Colors.white,
        };
      case SnackbarType.warning:
        return {
          'background': AppColors.warningColor,
          'text': Colors.white,
          'icon': Colors.white,
        };
      case SnackbarType.info:
        return {
          'background': AppColors.infoColor,
          'text': Colors.white,
          'icon': Colors.white,
        };
      case SnackbarType.custom:
      default:
        return {
          'background': AppColors.primaryColor,
          'text': Colors.white,
          'icon': Colors.white,
        };
    }
  }

  IconData _getIconForType() {
    switch (type) {
      case SnackbarType.success:
        return Icons.check_circle;
      case SnackbarType.error:
        return Icons.error;
      case SnackbarType.warning:
        return Icons.warning;
      case SnackbarType.info:
        return Icons.info;
      case SnackbarType.custom:
      default:
        return Icons.notifications;
    }
  }

  // Static methods for easy usage
  static void show(
    BuildContext context, {
    required String message,
    SnackbarType type = SnackbarType.info,
    IconData? icon,
    Color? backgroundColor,
    Color? textColor,
    Color? iconColor,
    VoidCallback? onActionPressed,
    String? actionLabel,
    Duration? duration,
    bool showCloseButton = false,
  }) {
    ScaffoldMessenger.of(context).removeCurrentSnackBar();
    
    final snackbar = SnackBar(
      content: CustomSnackbar(
        message: message,
        type: type,
        icon: icon,
        backgroundColor: backgroundColor,
        textColor: textColor,
        iconColor: iconColor,
        onActionPressed: onActionPressed,
        actionLabel: actionLabel,
        showCloseButton: showCloseButton,
      ),
      backgroundColor: Colors.transparent,
      elevation: 0,
      duration: duration ?? const Duration(seconds: 3),
      behavior: SnackBarBehavior.floating,
      margin: EdgeInsets.zero,
      padding: EdgeInsets.zero,
    );

    ScaffoldMessenger.of(context).showSnackBar(snackbar);
  }

  static void showSuccess(
    BuildContext context, {
    required String message,
    VoidCallback? onActionPressed,
    String? actionLabel,
    Duration? duration,
    bool showCloseButton = false,
  }) {
    show(
      context,
      message: message,
      type: SnackbarType.success,
      onActionPressed: onActionPressed,
      actionLabel: actionLabel,
      duration: duration,
      showCloseButton: showCloseButton,
    );
  }

  static void showError(
    BuildContext context, {
    required String message,
    VoidCallback? onActionPressed,
    String? actionLabel,
    Duration? duration,
    bool showCloseButton = true,
  }) {
    show(
      context,
      message: message,
      type: SnackbarType.error,
      onActionPressed: onActionPressed,
      actionLabel: actionLabel,
      duration: duration ?? const Duration(seconds: 4),
      showCloseButton: showCloseButton,
    );
  }

  static void showWarning(
    BuildContext context, {
    required String message,
    VoidCallback? onActionPressed,
    String? actionLabel,
    Duration? duration,
    bool showCloseButton = false,
  }) {
    show(
      context,
      message: message,
      type: SnackbarType.warning,
      onActionPressed: onActionPressed,
      actionLabel: actionLabel,
      duration: duration,
      showCloseButton: showCloseButton,
    );
  }

  static void showInfo(
    BuildContext context, {
    required String message,
    VoidCallback? onActionPressed,
    String? actionLabel,
    Duration? duration,
    bool showCloseButton = false,
  }) {
    show(
      context,
      message: message,
      type: SnackbarType.info,
      onActionPressed: onActionPressed,
      actionLabel: actionLabel,
      duration: duration,
      showCloseButton: showCloseButton,
    );
  }

  static void showLoading(
    BuildContext context, {
    String message = 'Loading...',
    Duration? duration,
  }) {
    ScaffoldMessenger.of(context).removeCurrentSnackBar();
    
    final snackbar = SnackBar(
      content: Container(
        margin: const EdgeInsets.all(16),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: AppColors.primaryColor,
          borderRadius: BorderRadius.circular(8),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            const SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                message,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
      ),
      backgroundColor: Colors.transparent,
      elevation: 0,
      duration: duration ?? const Duration(days: 1), // Long duration for loading
      behavior: SnackBarBehavior.floating,
      margin: EdgeInsets.zero,
      padding: EdgeInsets.zero,
    );

    ScaffoldMessenger.of(context).showSnackBar(snackbar);
  }

  static void hide(BuildContext context) {
    ScaffoldMessenger.of(context).removeCurrentSnackBar();
  }
}