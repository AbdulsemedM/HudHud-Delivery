import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';

class SecondaryButton extends StatelessWidget {
  final String text;
  final VoidCallback? onPressed;
  final bool isLoading;
  final bool isFullWidth;
  final EdgeInsetsGeometry? padding;
  final double? fontSize;
  final FontWeight? fontWeight;
  final IconData? icon;
  final Color? borderColor;
  final Color? textColor;
  final Color? backgroundColor;
  final double? borderRadius;
  final Size? minimumSize;
  final double? borderWidth;
  final bool enabled;

  const SecondaryButton({
    Key? key,
    required this.text,
    this.onPressed,
    this.isLoading = false,
    this.isFullWidth = true,
    this.padding,
    this.fontSize,
    this.fontWeight,
    this.icon,
    this.borderColor,
    this.textColor,
    this.backgroundColor,
    this.borderRadius,
    this.minimumSize,
    this.borderWidth,
    this.enabled = true,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return SizedBox(
      width: isFullWidth ? double.infinity : null,
      child: OutlinedButton(
        onPressed: (enabled && !isLoading) ? onPressed : null,
        style: OutlinedButton.styleFrom(
          foregroundColor: textColor ?? theme.colorScheme.primary,
          backgroundColor: backgroundColor,
          padding: padding ?? const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          side: BorderSide(
            color: borderColor ?? theme.colorScheme.primary,
            width: borderWidth ?? 1.5,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(borderRadius ?? 8),
          ),
          minimumSize: minimumSize ?? const Size(0, 48),
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
                      textColor ?? theme.colorScheme.primary,
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

// Specialized secondary button variants
class SecondaryButtonLarge extends SecondaryButton {
  const SecondaryButtonLarge({
    Key? key,
    required String text,
    VoidCallback? onPressed,
    bool isLoading = false,
    bool isFullWidth = true,
    IconData? icon,
    Color? borderColor,
    Color? textColor,
    Color? backgroundColor,
    bool enabled = true,
  }) : super(
          key: key,
          text: text,
          onPressed: onPressed,
          isLoading: isLoading,
          isFullWidth: isFullWidth,
          icon: icon,
          borderColor: borderColor,
          textColor: textColor,
          backgroundColor: backgroundColor,
          enabled: enabled,
          fontSize: 18,
          padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 20),
          minimumSize: const Size(0, 56),
        );
}

class SecondaryButtonSmall extends SecondaryButton {
  const SecondaryButtonSmall({
    Key? key,
    required String text,
    VoidCallback? onPressed,
    bool isLoading = false,
    bool isFullWidth = false,
    IconData? icon,
    Color? borderColor,
    Color? textColor,
    Color? backgroundColor,
    bool enabled = true,
  }) : super(
          key: key,
          text: text,
          onPressed: onPressed,
          isLoading: isLoading,
          isFullWidth: isFullWidth,
          icon: icon,
          borderColor: borderColor,
          textColor: textColor,
          backgroundColor: backgroundColor,
          enabled: enabled,
          fontSize: 14,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          minimumSize: const Size(0, 36),
          borderWidth: 1,
        );
}

class SecondaryButtonIcon extends StatelessWidget {
  final IconData icon;
  final VoidCallback? onPressed;
  final bool isLoading;
  final Color? borderColor;
  final Color? iconColor;
  final Color? backgroundColor;
  final double? size;
  final double? iconSize;
  final double? borderWidth;
  final String? tooltip;
  final bool enabled;

  const SecondaryButtonIcon({
    Key? key,
    required this.icon,
    this.onPressed,
    this.isLoading = false,
    this.borderColor,
    this.iconColor,
    this.backgroundColor,
    this.size,
    this.iconSize,
    this.borderWidth,
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
        color: backgroundColor ?? Colors.transparent,
        border: Border.all(
          color: borderColor ?? theme.colorScheme.primary,
          width: borderWidth ?? 1.5,
        ),
        borderRadius: BorderRadius.circular(8),
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
                          iconColor ?? theme.colorScheme.primary,
                        ),
                      ),
                    ),
                  )
                : Icon(
                    key: const ValueKey('icon'),
                    icon,
                    color: iconColor ?? theme.colorScheme.primary,
                    size: iconSize ?? 24,
                  ),
          ),
        ),
      ),
    );
  }
}

// Ghost button variant (no border, just text)
class GhostButton extends StatelessWidget {
  final String text;
  final VoidCallback? onPressed;
  final bool isLoading;
  final bool isFullWidth;
  final EdgeInsetsGeometry? padding;
  final double? fontSize;
  final FontWeight? fontWeight;
  final IconData? icon;
  final Color? textColor;
  final Color? backgroundColor;
  final double? borderRadius;
  final Size? minimumSize;
  final bool enabled;

  const GhostButton({
    Key? key,
    required this.text,
    this.onPressed,
    this.isLoading = false,
    this.isFullWidth = false,
    this.padding,
    this.fontSize,
    this.fontWeight,
    this.icon,
    this.textColor,
    this.backgroundColor,
    this.borderRadius,
    this.minimumSize,
    this.enabled = true,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return SizedBox(
      width: isFullWidth ? double.infinity : null,
      child: TextButton(
        onPressed: (enabled && !isLoading) ? onPressed : null,
        style: TextButton.styleFrom(
          foregroundColor: textColor ?? theme.colorScheme.primary,
          backgroundColor: backgroundColor,
          padding: padding ?? const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          minimumSize: minimumSize ?? const Size(0, 40),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(borderRadius ?? 8),
          ),
          disabledForegroundColor: AppColors.disabledButtonText,
        ),
        child: AnimatedSwitcher(
          duration: const Duration(milliseconds: 200),
          child: isLoading
              ? SizedBox(
                  key: const ValueKey('loading'),
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(
                      textColor ?? theme.colorScheme.primary,
                    ),
                  ),
                )
              : Row(
                  key: const ValueKey('content'),
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (icon != null) ...[
                      Icon(icon, size: 16),
                      const SizedBox(width: 6),
                    ],
                    Text(
                      text,
                      style: TextStyle(
                        fontSize: fontSize ?? 14,
                        fontWeight: fontWeight ?? FontWeight.w500,
                      ),
                    ),
                  ],
                ),
        ),
      ),
    );
  }
}