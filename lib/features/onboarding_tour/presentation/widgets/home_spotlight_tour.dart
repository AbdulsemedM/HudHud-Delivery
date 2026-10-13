import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:hudhud_delivery/core/l10n/context_l10n.dart';
import 'package:hudhud_delivery/core/theme/app_colors.dart';
import 'package:hudhud_delivery/core/theme/service_tab_palette.dart';
import 'package:hudhud_delivery/features/home/presentation/theme/home_colors.dart';
import 'package:hudhud_delivery/features/onboarding_tour/presentation/onboarding_tour_keys.dart';
import 'package:tutorial_coach_mark/tutorial_coach_mark.dart';

class HomeSpotlightTour {
  HomeSpotlightTour._();

  static Future<void> show({
    required BuildContext context,
    required OnboardingTourKeys keys,
    required VoidCallback onComplete,
    required VoidCallback onSkip,
  }) async {
    final l10n = context.l10n;

    // tutorial_coach_mark ends the whole tour if the first target has no
    // RenderObject — only include keys that are currently mounted.
    final specs = <_TargetSpec>[
      if (_isKeyMounted(keys.locationKey))
        _TargetSpec(
          identify: 'location',
          key: keys.locationKey,
          color: HomeColors.orange,
          title: l10n.onboardingSpotlightLocationTitle,
          description: l10n.onboardingSpotlightLocationDescription,
          actionLabel: l10n.actionNext,
        ),
      if (_isKeyMounted(keys.notificationsKey))
        _TargetSpec(
          identify: 'notifications',
          key: keys.notificationsKey,
          color: HomeColors.violetOf(context),
          title: l10n.onboardingSpotlightNotificationsTitle,
          description: l10n.onboardingSpotlightNotificationsDescription,
          actionLabel: l10n.actionNext,
          shape: ShapeLightFocus.Circle,
        ),
      if (_isKeyMounted(keys.courierTabKey))
        _TargetSpec(
          identify: 'courier',
          key: keys.courierTabKey,
          color: ServiceTabPalette.courier,
          title: l10n.onboardingSpotlightCourierTitle,
          description: l10n.onboardingSpotlightCourierDescription,
          actionLabel: l10n.actionNext,
        ),
      if (_isKeyMounted(keys.foodTabKey))
        _TargetSpec(
          identify: 'food',
          key: keys.foodTabKey,
          color: ServiceTabPalette.foodGroceries,
          title: l10n.onboardingSpotlightFoodTitle,
          description: l10n.onboardingSpotlightFoodDescription,
          actionLabel: l10n.actionNext,
        ),
      if (_isKeyMounted(keys.taxiTabKey))
        _TargetSpec(
          identify: 'taxi',
          key: keys.taxiTabKey,
          color: ServiceTabPalette.taxi,
          title: l10n.onboardingSpotlightTaxiTitle,
          description: l10n.onboardingSpotlightTaxiDescription,
          actionLabel: l10n.actionNext,
        ),
      if (_isKeyMounted(keys.handymanTabKey))
        _TargetSpec(
          identify: 'handyman',
          key: keys.handymanTabKey,
          color: ServiceTabPalette.handyman,
          title: l10n.onboardingSpotlightHandymanTitle,
          description: l10n.onboardingSpotlightHandymanDescription,
          actionLabel: l10n.actionNext,
        ),
      if (_isKeyMounted(keys.serviceTabsKey))
        _TargetSpec(
          identify: 'done',
          key: keys.serviceTabsKey,
          color: HomeColors.orange,
          title: l10n.onboardingSpotlightDoneTitle,
          description: l10n.onboardingSpotlightDoneDescription,
          actionLabel: l10n.actionDone,
        ),
    ];

    final candidates = <TargetFocus>[
      for (var i = 0; i < specs.length; i++)
        _buildTarget(
          spec: specs[i],
          step: i + 1,
          total: specs.length,
          stepLabel: l10n.easyStepOf(i + 1, specs.length),
          skipLabel: l10n.actionSkip,
        ),
    ];

    if (candidates.isEmpty) {
      if (kDebugMode) {
        debugPrint(
          'HomeSpotlightTour: no mounted targets — skipping spotlight.',
        );
      }
      onComplete();
      return;
    }

    final completer = Completer<void>();

    TutorialCoachMark(
      targets: candidates,
      colorShadow: AppColors.brandInk,
      opacityShadow: 0.8,
      paddingFocus: 8,
      alignSkip: Alignment.topRight,
      textSkip: l10n.actionSkip,
      // Skip lives inside the tooltip card instead of floating on the scrim.
      hideSkip: true,
      focusAnimationDuration: const Duration(milliseconds: 350),
      unFocusAnimationDuration: const Duration(milliseconds: 300),
      pulseEnable: true,
      onFinish: () {
        onComplete();
        if (!completer.isCompleted) completer.complete();
      },
      onSkip: () {
        onSkip();
        if (!completer.isCompleted) completer.complete();
        return true;
      },
    ).show(context: context, rootOverlay: true);

    return completer.future;
  }

  static bool _isKeyMounted(GlobalKey key) {
    final ctx = key.currentContext;
    if (ctx == null) return false;
    final renderObject = ctx.findRenderObject();
    return renderObject is RenderBox && renderObject.hasSize;
  }

  static TargetFocus _buildTarget({
    required _TargetSpec spec,
    required int step,
    required int total,
    required String stepLabel,
    required String skipLabel,
  }) {
    final shape = spec.shape;
    return TargetFocus(
      identify: spec.identify,
      keyTarget: spec.key,
      shape: shape,
      radius: shape == ShapeLightFocus.RRect ? 18 : 0,
      // Same calm ink scrim for every step (no per-step colour wash).
      color: AppColors.brandInk,
      enableTargetTab: true,
      enableOverlayTab: false,
      contents: [
        TargetContent(
          align: ContentAlign.bottom,
          padding: const EdgeInsets.symmetric(vertical: 16),
          builder: (context, controller) {
            return _SpotlightBubble(
              accent: spec.color,
              title: spec.title,
              description: spec.description,
              actionLabel: spec.actionLabel,
              stepLabel: stepLabel,
              step: step,
              total: total,
              skipLabel: step < total ? skipLabel : null,
              onAction: controller.next,
              onSkip: controller.skip,
            );
          },
        ),
      ],
    );
  }
}

class _TargetSpec {
  const _TargetSpec({
    required this.identify,
    required this.key,
    required this.color,
    required this.title,
    required this.description,
    required this.actionLabel,
    this.shape = ShapeLightFocus.RRect,
  });

  final String identify;
  final GlobalKey key;
  final Color color;
  final String title;
  final String description;
  final String actionLabel;
  final ShapeLightFocus shape;
}

class _SpotlightBubble extends StatefulWidget {
  const _SpotlightBubble({
    required this.accent,
    required this.title,
    required this.description,
    required this.actionLabel,
    required this.stepLabel,
    required this.step,
    required this.total,
    required this.onAction,
    required this.onSkip,
    this.skipLabel,
  });

  final Color accent;
  final String title;
  final String description;
  final String actionLabel;
  final String stepLabel;
  final int step;
  final int total;
  final String? skipLabel;
  final VoidCallback onAction;
  final VoidCallback onSkip;

  @override
  State<_SpotlightBubble> createState() => _SpotlightBubbleState();
}

class _SpotlightBubbleState extends State<_SpotlightBubble>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _scale;
  late final Animation<double> _fade;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 350),
    );
    _scale = Tween<double>(begin: 0.95, end: 1).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic),
    );
    _fade = CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic);
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final dark = HomeColors.isDark(context);
    final isLast = widget.step >= widget.total;
    final indigo = HomeColors.violetOf(context);

    return FadeTransition(
      opacity: _fade,
      child: ScaleTransition(
        scale: _scale,
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 20),
          padding: const EdgeInsets.fromLTRB(20, 18, 20, 16),
          decoration: BoxDecoration(
            color: HomeColors.surfaceOf(context),
            borderRadius: BorderRadius.circular(24),
            border:
                dark ? Border.all(color: HomeColors.borderOf(context)) : null,
            boxShadow: const [
              BoxShadow(
                color: Color(0x40000000),
                blurRadius: 32,
                offset: Offset(0, 14),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 5,
                    ),
                    decoration: BoxDecoration(
                      color: HomeColors.violetTintOf(context),
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: Text(
                      widget.stepLabel,
                      style: TextStyle(
                        color: indigo,
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.2,
                      ),
                    ),
                  ),
                  const Spacer(),
                  _StepDots(
                    total: widget.total,
                    current: widget.step,
                  ),
                ],
              ),
              const SizedBox(height: 14),
              Text(
                widget.title,
                style: TextStyle(
                  color: HomeColors.textPrimaryOf(context),
                  fontWeight: FontWeight.w800,
                  fontSize: 19,
                  letterSpacing: -0.4,
                  height: 1.2,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                widget.description,
                style: TextStyle(
                  color: HomeColors.textSecondaryOf(context),
                  fontSize: 15,
                  fontWeight: FontWeight.w500,
                  height: 1.45,
                ),
              ),
              const SizedBox(height: 18),
              Row(
                children: [
                  if (widget.skipLabel != null)
                    TextButton(
                      onPressed: widget.onSkip,
                      style: TextButton.styleFrom(
                        foregroundColor: HomeColors.textMutedOf(context),
                        minimumSize: const Size(48, 48),
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        textStyle: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      child: Text(widget.skipLabel!),
                    ),
                  const Spacer(),
                  FilledButton(
                    onPressed: widget.onAction,
                    style: FilledButton.styleFrom(
                      backgroundColor: AppColors.brandOrange,
                      foregroundColor: Colors.white,
                      minimumSize: const Size(120, 50),
                      padding: const EdgeInsets.symmetric(horizontal: 22),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          widget.actionLabel,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Icon(
                          isLast
                              ? Icons.check_rounded
                              : Icons.arrow_forward_rounded,
                          size: 20,
                          color: Colors.white,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _StepDots extends StatelessWidget {
  const _StepDots({required this.total, required this.current});

  final int total;
  final int current;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(total, (i) {
        final active = i + 1 == current;
        final done = i + 1 < current;
        return Container(
          margin: const EdgeInsetsDirectional.only(start: 4),
          width: active ? 18 : 6,
          height: 6,
          decoration: BoxDecoration(
            color: active
                ? AppColors.brandOrange
                : (done
                    ? AppColors.brandOrange.withValues(alpha: 0.4)
                    : HomeColors.borderOf(context)),
            borderRadius: BorderRadius.circular(6),
          ),
        );
      }),
    );
  }
}
