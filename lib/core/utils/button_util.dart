import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

class ButtonUtil {
  // Primary Button
  static Widget primaryButton({
    required String text,
    required VoidCallback? onPressed,
    bool isLoading = false,
    bool isFullWidth = true,
    EdgeInsetsGeometry? padding,
    double? fontSize,
    FontWeight? fontWeight,
    IconData? icon,
    Color? backgroundColor,
    Color? textColor,
    double? borderRadius,
    double? elevation,
    Size? minimumSize,
  }) {
    return SizedBox(
      width: isFullWidth ? double.infinity : null,
      child: ElevatedButton(
        onPressed: isLoading ? null : onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: backgroundColor ?? AppColors.primaryColor,
          foregroundColor: textColor ?? Colors.white,
          padding: padding ?? const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          elevation: elevation ?? 2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(borderRadius ?? 8),
          ),
          minimumSize: minimumSize ?? const Size(0, 48),
          disabledBackgroundColor: AppColors.disabledButton,
          disabledForegroundColor: AppColors.disabledButtonText,
        ),
        child: isLoading
            ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              )
            : Row(
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
    );
  }

  // Secondary Button
  static Widget secondaryButton({
    required String text,
    required VoidCallback? onPressed,
    bool isLoading = false,
    bool isFullWidth = true,
    EdgeInsetsGeometry? padding,
    double? fontSize,
    FontWeight? fontWeight,
    IconData? icon,
    Color? borderColor,
    Color? textColor,
    double? borderRadius,
    Size? minimumSize,
  }) {
    return SizedBox(
      width: isFullWidth ? double.infinity : null,
      child: OutlinedButton(
        onPressed: isLoading ? null : onPressed,
        style: OutlinedButton.styleFrom(
          foregroundColor: textColor ?? AppColors.primaryColor,
          padding: padding ?? const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          side: BorderSide(
            color: borderColor ?? AppColors.primaryColor,
            width: 1.5,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(borderRadius ?? 8),
          ),
          minimumSize: minimumSize ?? const Size(0, 48),
          disabledForegroundColor: AppColors.disabledButtonText,
        ),
        child: isLoading
            ? SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(
                    textColor ?? AppColors.primaryColor,
                  ),
                ),
              )
            : Row(
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
    );
  }

  // Text Button
  static Widget textButton({
    required String text,
    required VoidCallback? onPressed,
    bool isLoading = false,
    EdgeInsetsGeometry? padding,
    double? fontSize,
    FontWeight? fontWeight,
    IconData? icon,
    Color? textColor,
    Size? minimumSize,
  }) {
    return TextButton(
      onPressed: isLoading ? null : onPressed,
      style: TextButton.styleFrom(
        foregroundColor: textColor ?? AppColors.primaryColor,
        padding: padding ?? const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        minimumSize: minimumSize ?? const Size(0, 40),
        disabledForegroundColor: AppColors.disabledButtonText,
      ),
      child: isLoading
          ? SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation<Color>(
                  textColor ?? AppColors.primaryColor,
                ),
              ),
            )
          : Row(
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
    );
  }

  // Icon Button
  static Widget iconButton({
    required IconData icon,
    required VoidCallback? onPressed,
    bool isLoading = false,
    Color? backgroundColor,
    Color? iconColor,
    double? size,
    double? iconSize,
    EdgeInsetsGeometry? padding,
    double? borderRadius,
    String? tooltip,
  }) {
    return Container(
      width: size ?? 48,
      height: size ?? 48,
      decoration: BoxDecoration(
        color: backgroundColor ?? AppColors.primaryColor,
        borderRadius: BorderRadius.circular(borderRadius ?? 8),
      ),
      child: IconButton(
        onPressed: isLoading ? null : onPressed,
        icon: isLoading
            ? SizedBox(
                width: (iconSize ?? 24) * 0.8,
                height: (iconSize ?? 24) * 0.8,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(
                    iconColor ?? Colors.white,
                  ),
                ),
              )
            : Icon(
                icon,
                color: iconColor ?? Colors.white,
                size: iconSize ?? 24,
              ),
        padding: padding ?? EdgeInsets.zero,
        tooltip: tooltip,
      ),
    );
  }

  // Floating Action Button
  static Widget floatingActionButton({
    required VoidCallback? onPressed,
    required IconData icon,
    bool isLoading = false,
    Color? backgroundColor,
    Color? iconColor,
    double? iconSize,
    String? tooltip,
    String? heroTag,
  }) {
    return FloatingActionButton(
      onPressed: isLoading ? null : onPressed,
      backgroundColor: backgroundColor ?? AppColors.primaryColor,
      foregroundColor: iconColor ?? Colors.white,
      tooltip: tooltip,
      heroTag: heroTag,
      child: isLoading
          ? const SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
              ),
            )
          : Icon(
              icon,
              size: iconSize ?? 24,
            ),
    );
  }

  // Gradient Button
  static Widget gradientButton({
    required String text,
    required VoidCallback? onPressed,
    required List<Color> gradientColors,
    bool isLoading = false,
    bool isFullWidth = true,
    EdgeInsetsGeometry? padding,
    double? fontSize,
    FontWeight? fontWeight,
    IconData? icon,
    Color? textColor,
    double? borderRadius,
    Size? minimumSize,
  }) {
    return Container(
      width: isFullWidth ? double.infinity : null,
      height: minimumSize?.height ?? 48,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: gradientColors,
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
        ),
        borderRadius: BorderRadius.circular(borderRadius ?? 8),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: isLoading ? null : onPressed,
          borderRadius: BorderRadius.circular(borderRadius ?? 8),
          child: Container(
            padding: padding ?? const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            child: isLoading
                ? const Center(
                    child: SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    ),
                  )
                : Row(
                    mainAxisSize: MainAxisSize.min,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      if (icon != null) ...[
                        Icon(
                          icon,
                          size: 18,
                          color: textColor ?? Colors.white,
                        ),
                        const SizedBox(width: 8),
                      ],
                      Text(
                        text,
                        style: TextStyle(
                          fontSize: fontSize ?? 16,
                          fontWeight: fontWeight ?? FontWeight.w600,
                          color: textColor ?? Colors.white,
                        ),
                      ),
                    ],
                  ),
          ),
        ),
      ),
    );
  }
}