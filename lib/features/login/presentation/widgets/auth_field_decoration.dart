import 'package:flutter/material.dart';
import 'package:hudhud_delivery/features/login/presentation/theme/auth_screen_colors.dart';

InputDecoration authFieldDecoration(
  BuildContext context, {
  String? hint,
  Widget? prefixIcon,
  Widget? suffixIcon,
  String? labelText,
}) {
  return InputDecoration(
    hintText: hint,
    labelText: labelText,
    prefixIcon: prefixIcon,
    suffixIcon: suffixIcon,
    hintStyle: TextStyle(
      color: AuthScreenColors.textSecondaryOf(context),
      fontSize: 14,
    ),
    filled: true,
    fillColor: AuthScreenColors.surfaceOf(context),
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(14),
      borderSide: BorderSide.none,
    ),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(14),
      borderSide: BorderSide.none,
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(14),
      borderSide: const BorderSide(
        color: AuthScreenColors.orange,
        width: 1.5,
      ),
    ),
    errorBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(14),
      borderSide: const BorderSide(color: Color(0xFFEF5350), width: 1.5),
    ),
    focusedErrorBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(14),
      borderSide: const BorderSide(color: Color(0xFFEF5350), width: 1.5),
    ),
    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
  );
}

BoxDecoration authSurfaceBoxDecoration(
  BuildContext context, {
  bool withBorder = false,
}) {
  return BoxDecoration(
    color: AuthScreenColors.surfaceOf(context),
    borderRadius: BorderRadius.circular(14),
    border: withBorder
        ? Border.all(color: AuthScreenColors.surfaceBorderOf(context))
        : null,
  );
}
