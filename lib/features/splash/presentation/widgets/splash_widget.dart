import 'package:flutter/material.dart';
import 'package:hudhud_delivery/core/l10n/context_l10n.dart';
import 'package:hudhud_delivery/features/splash/presentation/theme/splash_colors.dart';

/// Full splash content: soft brand glow, logo, status.
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

  /// Kept for API compatibility; the decorative route lines were removed.
  final Animation<double> routesTwinkle;
  final Animation<double> dotsBounce;

  @override
  Widget build(BuildContext context) {
    final markOpacity = CurvedAnimation(
      parent: intro,
      curve: const Interval(0.0, 0.45, curve: Curves.easeOutCubic),
    );
    final markScale = Tween<double>(begin: 0.85, end: 1.0).animate(
      CurvedAnimation(
        parent: intro,
        curve: const Interval(0.0, 0.45, curve: Curves.easeOutCubic),
      ),
    );
    final status = CurvedAnimation(
      parent: intro,
      curve: const Interval(0.55, 0.9, curve: Curves.easeOut),
    );

    return Stack(
      fit: StackFit.expand,
      children: [
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
                      final scale = 0.96 + (t * 0.08);
                      final opacity = 0.7 + (t * 0.3);
                      return SizedBox(
                        width: 240,
                        height: 140,
                        child: OverflowBox(
                          maxWidth: 340,
                          maxHeight: 340,
                          child: Transform.scale(
                            scale: scale,
                            child: Opacity(
                              opacity: opacity,
                              child: Container(
                                width: 340,
                                height: 340,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  gradient: RadialGradient(
                                    colors: [
                                      SplashColors.orange
                                          .withValues(alpha: 0.16),
                                      SplashColors.orange
                                          .withValues(alpha: 0.05),
                                      SplashColors.orange.withValues(alpha: 0),
                                    ],
                                    stops: const [0.0, 0.5, 1.0],
                                  ),
                                ),
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

  static const assetPath = 'assets/images/logo.png';
  static const darkAssetPath = 'assets/images/logo_dark.png';

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return SizedBox(
      width: 232,
      height: 96,
      child: Image.asset(
        isDark ? darkAssetPath : assetPath,
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
          style: TextStyle(
            fontSize: 13,
            color: SplashColors.textMutedOf(context),
            fontWeight: FontWeight.w600,
            letterSpacing: 0.2,
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
                    width: 8,
                    height: 8,
                    decoration: const BoxDecoration(
                      shape: BoxShape.circle,
                      color: SplashColors.orangeDeep,
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

/// Calm brand backdrop: the page colour with two large, very soft blurred
/// blobs (orange top-left, indigo bottom-right).
class SplashGlowBackground extends StatelessWidget {
  const SplashGlowBackground({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      width: double.infinity,
      height: double.infinity,
      color: SplashColors.bgDeepOf(context),
      child: Stack(
        fit: StackFit.expand,
        children: [
          DecoratedBox(
            decoration: BoxDecoration(
              gradient: RadialGradient(
                center: const Alignment(-1.1, -1.0),
                radius: 1.0,
                colors: [
                  SplashColors.orange.withValues(alpha: dark ? 0.14 : 0.12),
                  SplashColors.orange.withValues(alpha: 0),
                ],
              ),
            ),
          ),
          DecoratedBox(
            decoration: BoxDecoration(
              gradient: RadialGradient(
                center: const Alignment(1.1, 1.0),
                radius: 1.1,
                colors: [
                  (dark ? SplashColors.violet : SplashColors.violetDeep)
                      .withValues(alpha: dark ? 0.16 : 0.08),
                  SplashColors.violetDeep.withValues(alpha: 0),
                ],
              ),
            ),
          ),
          child,
        ],
      ),
    );
  }
}
