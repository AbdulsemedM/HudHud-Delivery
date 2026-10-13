import 'package:flutter/material.dart';
import 'package:hudhud_delivery/core/theme/app_colors.dart';
import 'package:hudhud_delivery/features/login/presentation/theme/auth_screen_colors.dart';

const double _kFieldRadius = 16;

OutlineInputBorder _authBorder(Color color, {double width = 1.2}) {
  return OutlineInputBorder(
    borderRadius: BorderRadius.circular(_kFieldRadius),
    borderSide: BorderSide(color: color, width: width),
  );
}

InputDecoration authFieldDecoration(
  BuildContext context, {
  String? hint,
  Widget? prefixIcon,
  Widget? suffixIcon,
  String? labelText,
}) {
  final border = AuthScreenColors.surfaceBorderOf(context);
  return InputDecoration(
    hintText: hint,
    labelText: labelText,
    prefixIcon: prefixIcon,
    suffixIcon: suffixIcon,
    prefixIconColor: AuthScreenColors.textMutedOf(context),
    suffixIconColor: AuthScreenColors.textMutedOf(context),
    hintStyle: TextStyle(
      color: AuthScreenColors.textMutedOf(context),
      fontSize: 15,
      fontWeight: FontWeight.w500,
    ),
    errorStyle: const TextStyle(
      color: AppColors.errorColor,
      fontSize: 13,
      fontWeight: FontWeight.w600,
    ),
    filled: true,
    fillColor: AuthScreenColors.surfaceOf(context),
    border: _authBorder(border),
    enabledBorder: _authBorder(border),
    disabledBorder: _authBorder(border.withValues(alpha: 0.6)),
    focusedBorder: _authBorder(AuthScreenColors.orange, width: 1.8),
    errorBorder: _authBorder(AppColors.errorColor, width: 1.4),
    focusedErrorBorder: _authBorder(AppColors.errorColor, width: 1.8),
    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
  );
}

BoxDecoration authSurfaceBoxDecoration(
  BuildContext context, {
  bool withBorder = false,
}) {
  return BoxDecoration(
    color: AuthScreenColors.surfaceOf(context),
    borderRadius: BorderRadius.circular(_kFieldRadius),
    border: withBorder
        ? Border.all(color: AuthScreenColors.surfaceBorderOf(context))
        : null,
  );
}
