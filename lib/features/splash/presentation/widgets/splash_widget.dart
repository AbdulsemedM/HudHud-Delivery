import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:hudhud_delivery/core/l10n/context_l10n.dart';
import 'package:hudhud_delivery/features/splash/presentation/theme/splash_colors.dart';

/// Full splash content: routes, halo, logo, wordmark, tagline, status.
class SplashIntroContent extends StatelessWidget {
  const SplashIntroContent({
    super.key,
    required this.intro,
    required this.halo,
    required this.routesTwinkle,
    required this.dotsBounce,
  });

  /// 0 → 1 intro timeline (~2s).
  final Animation<double> intro;
  final Animation<double> halo;
  final Animation<double> routesTwinkle;
  final Animation<double> dotsBounce;

  @override
  Widget build(BuildContext context) {
    final markOpacity = CurvedAnimation(
      parent: intro,
      curve: const Interval(0.0, 0.35, curve: Curves.easeOutCubic),
    );
    final markScale = Tween<double>(begin: 0.85, end: 1.0).animate(
      CurvedAnimation(
        parent: intro,
        curve: const Interval(0.0, 0.35, curve: Curves.easeOutCubic),
      ),
    );
    final wordmark = CurvedAnimation(
      parent: intro,
      curve: const Interval(0.35, 0.55, curve: Curves.easeOut),
    );
    final tagline = CurvedAnimation(
      parent: intro,
      curve: const Interval(0.5, 0.7, curve: Curves.easeOut),
    );
    final status = CurvedAnimation(
      parent: intro,
      curve: const Interval(0.65, 0.9, curve: Curves.easeOut),
    );

    return Stack(
      fit: StackFit.expand,
      children: [
        AnimatedBuilder(
          animation: routesTwinkle,
          builder: (context, _) {
            return CustomPaint(
              painter: SplashRoutesPainter(twinkle: routesTwinkle.value),
            );
          },
        ),
        SafeArea(
          child: Column(
            children: [
              const Spacer(flex: 3),
              Stack(
                alignment: Alignment.center,
                clipBehavior: Clip.none,
                children: [
                  AnimatedBuilder(
                    animation: halo,
                    builder: (context, _) {
                      final t = halo.value;
                      final scale = 0.92 + (t * 0.16);
                      final opacity = 0.75 + (t * 0.25);
                      return Transform.scale(
                        scale: scale,
                        child: Opacity(
                          opacity: opacity,
                          child: Container(
                            width: 180,
                            height: 180,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              gradient: RadialGradient(
                                colors: [
                                  SplashColors.orange.withValues(alpha: 0.30),
                                  SplashColors.violet.withValues(alpha: 0.14),
                                  Colors.transparent,
                                ],
                                stops: const [0.0, 0.55, 0.75],
                              ),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                  FadeTransition(
                    opacity: markOpacity,
                    child: ScaleTransition(
                      scale: markScale,
                      child: const SplashLogoMark(),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 22),
              FadeTransition(
                opacity: wordmark,
                child: SlideTransition(
                  position: Tween<Offset>(
                    begin: const Offset(0, 0.18),
                    end: Offset.zero,
                  ).animate(wordmark),
                  child: const SplashWordmark(),
                ),
              ),
              const SizedBox(height: 8),
              FadeTransition(
                opacity: tagline,
                child: SlideTransition(
                  position: Tween<Offset>(
                    begin: const Offset(0, 0.15),
                    end: Offset.zero,
                  ).animate(tagline),
                  child: const SplashTagline(),
                ),
              ),
              const Spacer(flex: 4),
              FadeTransition(
                opacity: status,
                child: SlideTransition(
                  position: Tween<Offset>(
                    begin: const Offset(0, 0.2),
                    end: Offset.zero,
                  ).animate(status),
                  child: Padding(
                    padding: const EdgeInsets.only(bottom: 46),
                    child: SplashStatus(dotsBounce: dotsBounce),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class SplashLogoMark extends StatelessWidget {
  const SplashLogoMark({super.key});

  static const assetPath = 'assets/images/logo (2).jpg';

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 112,
      height: 112,
      child: Image.asset(
        assetPath,
        fit: BoxFit.contain,
        errorBuilder: (context, error, stackTrace) {
          return const Icon(
            Icons.local_shipping_rounded,
            size: 72,
            color: SplashColors.orange,
          );
        },
      ),
    );
  }
}

class SplashWordmark extends StatelessWidget {
  const SplashWordmark({super.key});

  @override
  Widget build(BuildContext context) {
    return const Text.rich(
      TextSpan(
        style: TextStyle(
          fontSize: 34,
          fontWeight: FontWeight.w700,
          letterSpacing: -0.5,
          height: 1.1,
        ),
        children: [
          TextSpan(
            text: 'Hud',
            style: TextStyle(color: SplashColors.orange),
          ),
          TextSpan(
            text: 'Hud',
            style: TextStyle(color: SplashColors.violet),
          ),
        ],
      ),
      textAlign: TextAlign.center,
    );
  }
}

class SplashTagline extends StatelessWidget {
  const SplashTagline({super.key});

  @override
  Widget build(BuildContext context) {
    return Text(
      context.l10n.splashTagline,
      textAlign: TextAlign.center,
      style: const TextStyle(
        fontSize: 11,
        fontWeight: FontWeight.w500,
        letterSpacing: 2.4,
        color: SplashColors.textMuted,
      ),
    );
  }
}

class SplashStatus extends StatelessWidget {
  const SplashStatus({super.key, required this.dotsBounce});

  final Animation<double> dotsBounce;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        SplashBouncingDots(animation: dotsBounce),
        const SizedBox(height: 12),
        Text(
          context.l10n.splashStatus,
          style: const TextStyle(
            fontSize: 12,
            color: SplashColors.textMuted,
            fontWeight: FontWeight.w400,
          ),
        ),
      ],
    );
  }
}

class SplashBouncingDots extends StatelessWidget {
  const SplashBouncingDots({super.key, required this.animation});

  final Animation<double> animation;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: animation,
      builder: (context, _) {
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: List.generate(3, (i) {
            // Stagger each dot: 0, 0.15, 0.30 of the bounce cycle.
            final phase = (animation.value + i * 0.15) % 1.0;
            final scale = _bounceScale(phase);
            final opacity = 0.5 + (scale - 0.6) / 0.4 * 0.5;
            return Padding(
              padding: EdgeInsets.only(left: i == 0 ? 0 : 7),
              child: Transform.scale(
                scale: scale,
                child: Opacity(
                  opacity: opacity.clamp(0.5, 1.0),
                  child: Container(
                    width: 7,
                    height: 7,
                    decoration: const BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [SplashColors.orange, SplashColors.violet],
                      ),
                    ),
                  ),
                ),
              ),
            );
          }),
        );
      },
    );
  }

  double _bounceScale(double t) {
    // Peak around 0.4 like CSS bounce keyframes.
    if (t < 0.4) {
      return 0.6 + (t / 0.4) * 0.4;
    }
    if (t < 0.8) {
      return 1.0 - ((t - 0.4) / 0.4) * 0.4;
    }
    return 0.6;
  }
}

class SplashRoutesPainter extends CustomPainter {
  SplashRoutesPainter({required this.twinkle});

  final double twinkle;

  @override
  void paint(Canvas canvas, Size size) {
    final opacity = 0.08 + (0.5 - (twinkle - 0.5).abs()) * 2 * 0.27;

    final orangePaint = Paint()
      ..color = SplashColors.orange.withValues(alpha: opacity)
      ..strokeWidth = 1.2
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final violetPaint = Paint()
      ..color = SplashColors.violet.withValues(alpha: opacity)
      ..strokeWidth = 1.2
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final orangeFill = Paint()
      ..color = SplashColors.orange.withValues(alpha: opacity);
    final violetFill = Paint()
      ..color = SplashColors.violet.withValues(alpha: opacity);

    // Design coords: 375 x 660 — scale to size.
    final sx = size.width / 375;
    final sy = size.height / 660;

    Offset p(double x, double y) => Offset(x * sx, y * sy);

    void line(List<Offset> pts, Paint paint) {
      final path = Path()..moveTo(pts.first.dx, pts.first.dy);
      for (var i = 1; i < pts.length; i++) {
        path.lineTo(pts[i].dx, pts[i].dy);
      }
      canvas.drawPath(path, paint);
    }

    line([p(40, 120), p(140, 180), p(110, 300)], orangePaint);
    line([p(330, 90), p(250, 200), p(300, 320)], violetPaint);
    line([p(60, 520), p(150, 470), p(90, 400)], violetPaint);
    line([p(320, 560), p(260, 480), p(310, 420)], orangePaint);

    void node(Offset c, double r, Paint fill) {
      canvas.drawCircle(c, r * math.min(sx, sy), fill);
    }

    node(p(40, 120), 3, orangeFill);
    node(p(140, 180), 2.5, orangeFill);
    node(p(110, 300), 2.5, orangeFill);
    node(p(330, 90), 3, violetFill);
    node(p(250, 200), 2.5, violetFill);
    node(p(300, 320), 2.5, violetFill);
    node(p(60, 520), 3, violetFill);
    node(p(150, 470), 2.5, violetFill);
    node(p(90, 400), 2.5, violetFill);
    node(p(320, 560), 3, orangeFill);
    node(p(260, 480), 2.5, orangeFill);
    node(p(310, 420), 2.5, orangeFill);
  }

  @override
  bool shouldRepaint(covariant SplashRoutesPainter oldDelegate) {
    return oldDelegate.twinkle != twinkle;
  }
}

/// Soft outer glow layers behind the main screen (fixed radials).
class SplashGlowBackground extends StatelessWidget {
  const SplashGlowBackground({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      height: double.infinity,
      decoration: const BoxDecoration(
        color: SplashColors.bgOuter,
      ),
      child: Stack(
        fit: StackFit.expand,
        children: [
          DecoratedBox(
            decoration: BoxDecoration(
              gradient: RadialGradient(
                center: const Alignment(-0.7, -0.75),
                radius: 1.1,
                colors: [
                  SplashColors.orange.withValues(alpha: 0.16),
                  Colors.transparent,
                ],
              ),
            ),
          ),
          DecoratedBox(
            decoration: BoxDecoration(
              gradient: RadialGradient(
                center: const Alignment(0.85, 0.8),
                radius: 1.15,
                colors: [
                  SplashColors.violet.withValues(alpha: 0.16),
                  Colors.transparent,
                ],
              ),
            ),
          ),
          DecoratedBox(
            decoration: BoxDecoration(
              gradient: RadialGradient(
                center: const Alignment(0, -0.35),
                radius: 0.85,
                colors: [
                  SplashColors.violet.withValues(alpha: 0.14),
                  Colors.transparent,
                ],
              ),
            ),
          ),
          DecoratedBox(
            decoration: BoxDecoration(
              gradient: RadialGradient(
                center: const Alignment(0, 0.55),
                radius: 0.75,
                colors: [
                  SplashColors.orange.withValues(alpha: 0.10),
                  Colors.transparent,
                ],
              ),
            ),
          ),
          const DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Color(0x001D1224),
                  SplashColors.bgDeep,
                ],
                stops: [0.0, 0.55],
              ),
            ),
          ),
          child,
        ],
      ),
    );
  }
}
