import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:hudhud_delivery/features/login/presentation/theme/auth_screen_colors.dart';

class AuthBrandHeader extends StatelessWidget {
  const AuthBrandHeader({super.key});

  @override
  Widget build(BuildContext context) {
    return Image.asset(
      'assets/images/logo.png',
      width: 96,
      height: 96,
      fit: BoxFit.contain,
      errorBuilder: (_, __, ___) => const Icon(
        Icons.local_shipping_rounded,
        size: 80,
        color: AuthScreenColors.orange,
      ),
    );
  }
}

/// Compact decorative curve used above welcome titles when brand is omitted.
class AuthDashedCurve extends StatelessWidget {
  const AuthDashedCurve({super.key});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 28,
      child: CustomPaint(
        painter: _AuthDashedCurvePainter(
          dashColor: AuthScreenColors.textSecondaryOf(context),
        ),
      ),
    );
  }
}

class _AuthDashedCurvePainter extends CustomPainter {
  const _AuthDashedCurvePainter({required this.dashColor});

  final Color dashColor;

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
      ..color = dashColor.withValues(alpha: 0.45)
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
  bool shouldRepaint(covariant _AuthDashedCurvePainter oldDelegate) =>
      oldDelegate.dashColor != dashColor;
}
