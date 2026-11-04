import 'package:flutter/material.dart';

import 'package:hudhud_delivery/core/l10n/context_l10n.dart';
import 'package:hudhud_delivery/core/theme/app_colors.dart';

/// "Get free delivery with HudHud Plus" — shown on checkout under the
/// free-delivery bar when Plus is on and the customer is not a member.
class PlusUpsellBanner extends StatelessWidget {
  const PlusUpsellBanner({super.key, required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Material(
        color: AppColors.brandIndigo.withValues(alpha: dark ? 0.28 : 0.08),
        borderRadius: BorderRadius.circular(16),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: ConstrainedBox(
            constraints: const BoxConstraints(minHeight: 52),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              child: Row(
                children: [
                  const PlusBadge(),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      context.l10n.p3PlusUpsell,
                      style: TextStyle(
                        fontSize: 14.5,
                        fontWeight: FontWeight.w700,
                        color: dark ? Colors.white : AppColors.brandIndigo,
                      ),
                    ),
                  ),
                  Icon(
                    Icons.chevron_right_rounded,
                    color: dark ? Colors.white : AppColors.brandIndigo,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Small "Plus" pill used on the profile header, checkout and Plus screen.
class PlusBadge extends StatelessWidget {
  const PlusBadge({super.key, this.onTap, this.onDark = false});

  final VoidCallback? onTap;

  /// Use white-on-indigo contrast tuned for a dark/gradient background.
  final bool onDark;

  @override
  Widget build(BuildContext context) {
    final chip = Padding(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(
            Icons.workspace_premium_rounded,
            size: 16,
            color: Colors.white,
          ),
          const SizedBox(width: 5),
          Text(
            context.l10n.p3PlusBadge,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w800,
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
    return Material(
      color: onDark
          ? Colors.white.withValues(alpha: 0.22)
          : AppColors.brandIndigo,
      shape: const StadiumBorder(),
      clipBehavior: Clip.antiAlias,
      child: onTap == null ? chip : InkWell(onTap: onTap, child: chip),
    );
  }
}
