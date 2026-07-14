import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:hudhud_delivery/core/l10n/context_l10n.dart';
import 'package:hudhud_delivery/features/login/presentation/theme/auth_screen_colors.dart';

class AuthBrandHeader extends StatelessWidget {
  const AuthBrandHeader({super.key, this.showTagline = true});

  final bool showTagline;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Image.asset(
              'assets/images/logo.png',
              width: 40,
              height: 40,
              fit: BoxFit.contain,
              errorBuilder: (_, __, ___) => const Icon(
                Icons.local_shipping_rounded,
                size: 36,
                color: AuthScreenColors.orange,
              ),
            ),
            const SizedBox(width: 10),
            const Text.rich(
              TextSpan(
                children: [
                  TextSpan(
                    text: 'Hud',
                    style: TextStyle(
                      color: AuthScreenColors.orange,
                      fontSize: 28,
                      fontWeight: FontWeight.w800,
                      letterSpacing: -0.5,
                    ),
                  ),
                  TextSpan(
                    text: 'Hud',
                    style: TextStyle(
                      color: AuthScreenColors.lavender,
                      fontSize: 28,
                      fontWeight: FontWeight.w800,
                      letterSpacing: -0.5,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        if (showTagline) ...[
          const SizedBox(height: 8),
          Text(
            l10n.brandTagline,
            style: const TextStyle(
              color: AuthScreenColors.textSecondary,
              fontSize: 11,
              fontWeight: FontWeight.w500,
              letterSpacing: 1.4,
            ),
          ),
          const SizedBox(height: 16),
          const SizedBox(
            width: double.infinity,
            height: 28,
            child: CustomPaint(painter: _AuthDashedCurvePainter()),
          ),
        ],
      ],
    );
  }
}

/// Compact decorative curve used above welcome titles when brand is omitted.
class AuthDashedCurve extends StatelessWidget {
  const AuthDashedCurve({super.key});

  @override
  Widget build(BuildContext context) {
    return const SizedBox(
      width: double.infinity,
      height: 28,
      child: CustomPaint(painter: _AuthDashedCurvePainter()),
    );
  }
}

class _AuthDashedCurvePainter extends CustomPainter {
  const _AuthDashedCurvePainter();

  @override
  void paint(Canvas canvas, Size size) {
    final path = Path()
      ..moveTo(12, size.height * 0.35)
      ..quadraticBezierTo(
        size.width * 0.5,
        size.height * 1.15,
        size.width - 12,
        size.height * 0.35,
      );

    final dashPaint = Paint()
      ..color = AuthScreenColors.textSecondary.withValues(alpha: 0.45)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.4
      ..strokeCap = StrokeCap.round;

    _drawDashedPath(canvas, path, dashPaint, 5, 5);

    canvas.drawCircle(
      Offset(12, size.height * 0.35),
      4.5,
      Paint()..color = AuthScreenColors.lavender,
    );
    canvas.drawCircle(
      Offset(size.width - 12, size.height * 0.35),
      4.5,
      Paint()..color = AuthScreenColors.orange,
    );
  }

  void _drawDashedPath(
    Canvas canvas,
    Path path,
    Paint paint,
    double dashWidth,
    double dashSpace,
  ) {
    for (final metric in path.computeMetrics()) {
      var distance = 0.0;
      while (distance < metric.length) {
        final next = math.min(distance + dashWidth, metric.length);
        canvas.drawPath(metric.extractPath(distance, next), paint);
        distance = next + dashSpace;
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
