import 'package:flutter/material.dart';
import 'package:hudhud_delivery/core/l10n/context_l10n.dart';
import 'package:hudhud_delivery/core/utils/support_launcher.dart';
import 'package:hudhud_delivery/features/home/presentation/theme/home_colors.dart';
import 'package:hudhud_delivery/features/login/presentation/theme/auth_screen_colors.dart';
import 'package:hudhud_delivery/features/settings/presentation/widgets/auth_feedback.dart';

/// Large, always-visible help control that dials HudHud support.
class CallSupportFab extends StatelessWidget {
  const CallSupportFab({
    super.key,
    this.heroTag = 'call_support_fab',
    this.extended = true,
  });

  final Object heroTag;
  final bool extended;

  Future<void> _call(BuildContext context) async {
    final ok = await launchSupportPhone();
    if (!context.mounted) return;
    if (!ok) {
      AuthSnackBar.error(context, context.l10n.actionTryAgain);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (extended) {
      return FloatingActionButton.extended(
        heroTag: heroTag,
        backgroundColor: AuthScreenColors.orange,
        foregroundColor: Theme.of(context).colorScheme.onSecondary,
        icon: const Icon(Icons.phone_in_talk_rounded),
        label: Text(context.l10n.callSupport),
        onPressed: () => _call(context),
      );
    }
    return FloatingActionButton(
      heroTag: heroTag,
      backgroundColor: AuthScreenColors.orange,
      foregroundColor: Theme.of(context).colorScheme.onSecondary,
      tooltip: context.l10n.callSupport,
      onPressed: () => _call(context),
      child: const Icon(Icons.phone_in_talk_rounded),
    );
  }
}

/// Compact inline Call Support button for app bars / footers.
class CallSupportButton extends StatelessWidget {
  const CallSupportButton({
    super.key,
    this.compact = false,
  });

  final bool compact;

  Future<void> _call(BuildContext context) async {
    final ok = await launchSupportPhone();
    if (!context.mounted) return;
    if (!ok) {
      AuthSnackBar.error(context, context.l10n.actionTryAgain);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (compact) {
      return IconButton(
        tooltip: context.l10n.callSupport,
        onPressed: () => _call(context),
        icon: Icon(
          Icons.phone_in_talk_rounded,
          color: HomeColors.textPrimaryOf(context),
        ),
      );
    }
    return TextButton.icon(
      onPressed: () => _call(context),
      icon: const Icon(Icons.phone_in_talk_rounded),
      label: Text(context.l10n.callSupport),
      style: TextButton.styleFrom(
        foregroundColor: AuthScreenColors.orange,
      ),
    );
  }
}
