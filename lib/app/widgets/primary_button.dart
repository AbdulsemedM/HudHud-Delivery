import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';

class PrimaryButton extends StatelessWidget {
  final String text;
  final VoidCallback? onPressed;
  final bool isLoading;
  final bool isFullWidth;
  final EdgeInsetsGeometry? padding;
  final double? fontSize;
  final FontWeight? fontWeight;
  final IconData? icon;
  final Color? backgroundColor;
  final Color? textColor;
  final double? borderRadius;
  final double? elevation;
  final Size? minimumSize;
  final bool enabled;

  const PrimaryButton({
    Key? key,
    required this.text,
    this.onPressed,
    this.isLoading = false,
    this.isFullWidth = true,
    this.padding,
    this.fontSize,
    this.fontWeight,
    this.icon,
    this.backgroundColor,
    this.textColor,
    this.borderRadius,
    this.elevation,
    this.minimumSize,
    this.enabled = true,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return SizedBox(
      width: isFullWidth ? double.infinity : null,
      child: ElevatedButton(
        onPressed: (enabled && !isLoading) ? onPressed : null,
        style: ElevatedButton.styleFrom(
          backgroundColor: backgroundColor ?? theme.colorScheme.primary,
          foregroundColor: textColor ?? theme.colorScheme.onPrimary,
          padding: padding ?? const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          elevation: elevation ?? 2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(borderRadius ?? 8),
          ),
          minimumSize: minimumSize ?? const Size(0, 48),
          disabledBackgroundColor: AppColors.disabledButton,
          disabledForegroundColor: AppColors.disabledButtonText,
        ),
        child: AnimatedSwitcher(
          duration: const Duration(milliseconds: 200),
          child: isLoading
              ? SizedBox(
                  key: const ValueKey('loading'),
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(
                      textColor ?? theme.colorScheme.onPrimary,
                    ),
                  ),
                )
              : Row(
                  key: const ValueKey('content'),
                  mainAxisSize: MainAxisSize.min,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    if (icon != null) ...[
                      Icon(icon, size: 18),
                      const SizedBox(width: 8),
                    ],
                    Text(
                      text,
                      style: TextStyle(
                        fontSize: fontSize ?? 16,
                        fontWeight: fontWeight ?? FontWeight.w600,
                      ),
                    ),
                  ],
                ),
        ),
      ),
    );
  }
}

// Specialized primary button variants
class PrimaryButtonLarge extends PrimaryButton {
  const PrimaryButtonLarge({
    Key? key,
    required String text,
    VoidCallback? onPressed,
    bool isLoading = false,
    bool isFullWidth = true,
    IconData? icon,
    Color? backgroundColor,
    Color? textColor,
    bool enabled = true,
  }) : super(
          key: key,
          text: text,
          onPressed: onPressed,
          isLoading: isLoading,
          isFullWidth: isFullWidth,
          icon: icon,
          backgroundColor: backgroundColor,
          textColor: textColor,
          enabled: enabled,
          fontSize: 18,
          padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 20),
          minimumSize: const Size(0, 56),
        );
}

class PrimaryButtonSmall extends PrimaryButton {
  const PrimaryButtonSmall({
    Key? key,
    required String text,
    VoidCallback? onPressed,
    bool isLoading = false,
    bool isFullWidth = false,
    IconData? icon,
    Color? backgroundColor,
    Color? textColor,
    bool enabled = true,
  }) : super(
          key: key,
          text: text,
          onPressed: onPressed,
          isLoading: isLoading,
          isFullWidth: isFullWidth,
          icon: icon,
          backgroundColor: backgroundColor,
          textColor: textColor,
          enabled: enabled,
          fontSize: 14,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          minimumSize: const Size(0, 36),
        );
}

class PrimaryButtonIcon extends StatelessWidget {
  final IconData icon;
  final VoidCallback? onPressed;
  final bool isLoading;
  final Color? backgroundColor;
  final Color? iconColor;
  final double? size;
  final double? iconSize;
  final String? tooltip;
  final bool enabled;

  const PrimaryButtonIcon({
    Key? key,
    required this.icon,
    this.onPressed,
    this.isLoading = false,
    this.backgroundColor,
    this.iconColor,
    this.size,
    this.iconSize,
    this.tooltip,
    this.enabled = true,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Container(
      width: size ?? 48,
      height: size ?? 48,
      decoration: BoxDecoration(
        color: backgroundColor ?? theme.colorScheme.primary,
        borderRadius: BorderRadius.circular(8),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: (enabled && !isLoading) ? onPressed : null,
          borderRadius: BorderRadius.circular(8),
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 200),
            child: isLoading
                ? Center(
                    key: const ValueKey('loading'),
                    child: SizedBox(
                      width: (iconSize ?? 24) * 0.8,
                      height: (iconSize ?? 24) * 0.8,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(
                          iconColor ?? theme.colorScheme.onPrimary,
                        ),
                      ),
                    ),
                  )
                : Icon(
                    key: const ValueKey('icon'),
                    icon,
                    color: iconColor ?? theme.colorScheme.onPrimary,
                    size: iconSize ?? 24,
                  ),
          ),
        ),
      ),
    );
  }
}