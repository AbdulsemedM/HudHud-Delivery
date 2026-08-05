import 'package:flutter/material.dart';
import 'package:hudhud_delivery/features/onboarding_tour/data/onboarding_tour_prefs.dart';
import 'package:hudhud_delivery/features/onboarding_tour/presentation/onboarding_tour_keys.dart';
import 'package:hudhud_delivery/features/onboarding_tour/presentation/widgets/home_spotlight_tour.dart';
import 'package:hudhud_delivery/features/onboarding_tour/presentation/widgets/welcome_carousel.dart';

/// Orchestrates the first-run welcome carousel and home spotlight tour.
class OnboardingTourController {
  OnboardingTourController._();

  static bool _running = false;

  /// Increment to request replay after [resetForTesting].
  static final ValueNotifier<int> replaySignal = ValueNotifier<int>(0);

  static Future<void> maybeStart({
    required BuildContext context,
    required OnboardingTourKeys keys,
  }) async {
    if (_running) return;
    if (await OnboardingTourPrefs.hasSeenTour()) return;
    if (!context.mounted) return;

    _running = true;
    try {
      await Navigator.of(context).push<void>(
        PageRouteBuilder<void>(
          opaque: true,
          barrierDismissible: false,
          transitionDuration: const Duration(milliseconds: 350),
          reverseTransitionDuration: const Duration(milliseconds: 300),
          pageBuilder: (context, animation, secondaryAnimation) {
            return FadeTransition(
              opacity: CurvedAnimation(
                parent: animation,
                curve: Curves.easeOutCubic,
              ),
              child: const WelcomeCarousel(),
            );
          },
        ),
      );

      if (!context.mounted) return;

      await Future<void>.delayed(const Duration(milliseconds: 200));
      if (!context.mounted) return;

      await HomeSpotlightTour.show(
        context: context,
        keys: keys,
        onComplete: OnboardingTourPrefs.markTourSeen,
        onSkip: OnboardingTourPrefs.markTourSeen,
      );
    } finally {
      _running = false;
    }
  }

  static Future<void> resetForTesting() async {
    await OnboardingTourPrefs.resetForTesting();
    replaySignal.value++;
  }
}
