import 'dart:async';

import 'package:flutter/material.dart';
import 'package:hudhud_delivery/core/l10n/context_l10n.dart';
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
    final media = MediaQuery.of(context);
    final center = Offset(
      media.size.width / 2,
      media.size.height * 0.45,
    );

    final targets = <TargetFocus>[
      _buildTarget(
        identify: 'location',
        key: keys.locationKey,
        color: HomeColors.orange,
        title: l10n.onboardingSpotlightLocationTitle,
        description: l10n.onboardingSpotlightLocationDescription,
        actionLabel: l10n.actionNext,
        isLast: false,
      ),
      _buildTarget(
        identify: 'notifications',
        key: keys.notificationsKey,
        color: HomeColors.violet,
        title: l10n.onboardingSpotlightNotificationsTitle,
        description: l10n.onboardingSpotlightNotificationsDescription,
        actionLabel: l10n.actionNext,
        isLast: false,
        shape: ShapeLightFocus.Circle,
      ),
      _buildTarget(
        identify: 'food',
        key: keys.foodTabKey,
        color: ServiceTabPalette.foodGroceries,
        title: l10n.onboardingSpotlightFoodTitle,
        description: l10n.onboardingSpotlightFoodDescription,
        actionLabel: l10n.actionNext,
        isLast: false,
      ),
      _buildTarget(
        identify: 'courier',
        key: keys.courierTabKey,
        color: ServiceTabPalette.courier,
        title: l10n.onboardingSpotlightCourierTitle,
        description: l10n.onboardingSpotlightCourierDescription,
        actionLabel: l10n.actionNext,
        isLast: false,
      ),
      _buildTarget(
        identify: 'taxi',
        key: keys.taxiTabKey,
        color: ServiceTabPalette.taxi,
        title: l10n.onboardingSpotlightTaxiTitle,
        description: l10n.onboardingSpotlightTaxiDescription,
        actionLabel: l10n.actionNext,
        isLast: false,
      ),
      _buildTarget(
        identify: 'handyman',
        key: keys.handymanTabKey,
        color: ServiceTabPalette.handyman,
        title: l10n.onboardingSpotlightHandymanTitle,
        description: l10n.onboardingSpotlightHandymanDescription,
        actionLabel: l10n.actionNext,
        isLast: false,
      ),
      TargetFocus(
        identify: 'done',
        targetPosition: TargetPosition(
          const Size(220, 120),
          Offset(center.dx - 110, center.dy - 60),
        ),
        shape: ShapeLightFocus.RRect,
        radius: 20,
        enableTargetTab: true,
        contents: [
          TargetContent(
            align: ContentAlign.bottom,
            builder: (context, controller) {
              return _SpotlightBubble(
                accent: HomeColors.orange,
                title: l10n.onboardingSpotlightDoneTitle,
                description: l10n.onboardingSpotlightDoneDescription,
                actionLabel: l10n.actionDone,
                isLast: true,
                onAction: controller.next,
              );
            },
          ),
        ],
      ),
    ];

    final completer = Completer<void>();

    TutorialCoachMark(
      targets: targets,
      colorShadow: Colors.black,
      opacityShadow: 0.82,
      paddingFocus: 8,
      alignSkip: Alignment.topRight,
      textSkip: l10n.actionSkip,
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
    ).show(context: context);

    return completer.future;
  }

  static TargetFocus _buildTarget({
    required String identify,
    required GlobalKey key,
    required Color color,
    required String title,
    required String description,
    required String actionLabel,
    required bool isLast,
    ShapeLightFocus shape = ShapeLightFocus.RRect,
  }) {
    return TargetFocus(
      identify: identify,
      keyTarget: key,
      shape: shape,
      radius: shape == ShapeLightFocus.RRect ? 18 : 0,
      color: color.withValues(alpha: 0.15),
      enableTargetTab: true,
      enableOverlayTab: false,
      contents: [
        TargetContent(
          align: ContentAlign.bottom,
          builder: (context, controller) {
            return _SpotlightBubble(
              accent: color,
              title: title,
              description: description,
              actionLabel: actionLabel,
              isLast: isLast,
              onAction: controller.next,
            );
          },
        ),
      ],
    );
  }
}

class _SpotlightBubble extends StatefulWidget {
  const _SpotlightBubble({
    required this.accent,
    required this.title,
    required this.description,
    required this.actionLabel,
    required this.isLast,
    required this.onAction,
  });

  final Color accent;
  final String title;
  final String description;
  final String actionLabel;
  final bool isLast;
  final VoidCallback onAction;

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
    return FadeTransition(
      opacity: _fade,
      child: ScaleTransition(
        scale: _scale,
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 20),
          padding: const EdgeInsets.fromLTRB(18, 16, 18, 14),
          decoration: BoxDecoration(
            color: HomeColors.surfaceElevated,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: widget.accent.withValues(alpha: 0.35)),
            boxShadow: [
              BoxShadow(
                color: widget.accent.withValues(alpha: 0.2),
                blurRadius: 20,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                widget.title,
                style: const TextStyle(
                  color: HomeColors.textPrimary,
                  fontWeight: FontWeight.w800,
                  fontSize: 17,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                widget.description,
                style: const TextStyle(
                  color: HomeColors.textSecondary,
                  fontSize: 14,
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 14),
              Align(
                alignment: AlignmentDirectional.centerEnd,
                child: FilledButton(
                  onPressed: widget.onAction,
                  style: FilledButton.styleFrom(
                    backgroundColor: widget.accent,
                    foregroundColor: Colors.black87,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 18,
                      vertical: 10,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: Text(
                    widget.actionLabel,
                    style: const TextStyle(fontWeight: FontWeight.w700),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
