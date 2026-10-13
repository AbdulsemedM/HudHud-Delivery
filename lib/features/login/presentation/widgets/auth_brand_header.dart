import 'package:flutter/material.dart';
import 'package:hudhud_delivery/features/login/presentation/theme/auth_screen_colors.dart';

/// Compact, refined brand mark for the top of auth screens.
class AuthBrandHeader extends StatelessWidget {
  const AuthBrandHeader({super.key, this.height = 44});

  final double height;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Align(
      alignment: AlignmentDirectional.centerStart,
      child: Image.asset(
        isDark ? 'assets/images/logo_dark.png' : 'assets/images/logo.png',
        height: height,
        fit: BoxFit.contain,
        alignment: AlignmentDirectional.centerStart,
        errorBuilder: (_, __, ___) => Icon(
          Icons.local_shipping_rounded,
          size: height,
          color: AuthScreenColors.orange,
        ),
      ),
    );
  }
}

/// Formerly a dashed decorative curve; kept for API compatibility and now
/// renders nothing (the decoration read as template filler).
class AuthDashedCurve extends StatelessWidget {
  const AuthDashedCurve({super.key});

  @override
  Widget build(BuildContext context) => const SizedBox.shrink();
}
