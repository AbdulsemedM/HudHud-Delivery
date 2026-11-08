import 'package:flutter/material.dart';

import 'package:hudhud_delivery/core/l10n/context_l10n.dart';
import 'package:hudhud_delivery/core/theme/app_colors.dart';

/// Promo-code entry used on checkout when `promo_codes.enabled`.
///
/// Stateless about validity: the parent owns the applied code and the
/// server message, so the code survives rebuilds and quote refreshes.
class GrowthPromoCodeSection extends StatefulWidget {
  const GrowthPromoCodeSection({
    super.key,
    required this.appliedCode,
    required this.applying,
    required this.message,
    required this.messageIsError,
    required this.onApply,
    required this.onRemove,
  });

  final String? appliedCode;
  final bool applying;
  final String? message;
  final bool messageIsError;
  final ValueChanged<String> onApply;
  final VoidCallback onRemove;

  @override
  State<GrowthPromoCodeSection> createState() => _GrowthPromoCodeSectionState();
}

class _GrowthPromoCodeSectionState extends State<GrowthPromoCodeSection> {
  final TextEditingController _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _submit() {
    final code = _controller.text.trim();
    if (code.isEmpty || widget.applying) return;
    FocusScope.of(context).unfocus();
    widget.onApply(code);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final scheme = Theme.of(context).colorScheme;
    final applied = widget.appliedCode;

    final Widget field;
    if (applied != null) {
      field = Container(
        padding: const EdgeInsets.fromLTRB(14, 6, 6, 6),
        decoration: BoxDecoration(
          color: AppColors.successColor.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: AppColors.successColor.withValues(alpha: 0.45),
            width: 1.5,
          ),
        ),
        child: Row(
          children: [
            const Icon(
              Icons.check_circle_rounded,
              color: AppColors.successColor,
              size: 22,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                applied,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.6,
                ),
              ),
            ),
            TextButton(
              onPressed: widget.applying ? null : widget.onRemove,
              child: Text(l10n.growthPromoRemove),
            ),
          ],
        ),
      );
    } else {
      field = Container(
        padding: const EdgeInsets.all(4),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: AppColors.primaryColor.withValues(alpha: 0.35),
            width: 1.5,
          ),
        ),
        child: Row(
          children: [
            Padding(
              padding: const EdgeInsets.only(left: 12),
              child: Icon(
                Icons.local_offer_outlined,
                color: AppColors.primaryColor.withValues(alpha: 0.85),
                size: 22,
              ),
            ),
            Expanded(
              child: TextField(
                controller: _controller,
                textCapitalization: TextCapitalization.characters,
                textInputAction: TextInputAction.done,
                onSubmitted: (_) => _submit(),
                decoration: InputDecoration(
                  hintText: l10n.growthPromoHint,
                  hintStyle: TextStyle(color: scheme.onSurfaceVariant),
                  border: InputBorder.none,
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(right: 4),
              child: FilledButton(
                onPressed: widget.applying ? null : _submit,
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.primaryColor,
                  foregroundColor: AppColors.lightOnPrimary,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: widget.applying
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: AppColors.lightOnPrimary,
                        ),
                      )
                    : Text(
                        l10n.growthPromoApply,
                        style: const TextStyle(fontWeight: FontWeight.w700),
                      ),
              ),
            ),
          ],
        ),
      );
    }

    final message = widget.message;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        field,
        if (message != null && message.isNotEmpty) ...[
          const SizedBox(height: 8),
          Text(
            message,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: widget.messageIsError
                  ? scheme.error
                  : AppColors.successColor,
            ),
          ),
        ],
      ],
    );
  }
}

/// "Use N points (−X ETB on delivery)" switch.
class GrowthPointsToggle extends StatelessWidget {
  const GrowthPointsToggle({
    super.key,
    required this.points,
    required this.amountLabel,
    required this.value,
    required this.onChanged,
  });

  final int points;
  final String amountLabel;
  final bool value;
  final ValueChanged<bool>? onChanged;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final scheme = Theme.of(context).colorScheme;
    return Material(
      color: AppColors.secondaryColor.withValues(alpha: 0.06),
      borderRadius: BorderRadius.circular(16),
      child: SwitchListTile.adaptive(
        value: value,
        onChanged: onChanged,
        activeThumbColor: AppColors.primaryColor,
        contentPadding: const EdgeInsets.symmetric(horizontal: 14),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        secondary: const Icon(
          Icons.stars_rounded,
          color: AppColors.warningColor,
          size: 28,
        ),
        title: Text(
          l10n.growthPointsToggle(points, amountLabel),
          style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
        ),
        subtitle: Text(
          l10n.growthPointsSubtitle,
          style: TextStyle(fontSize: 12.5, color: scheme.onSurfaceVariant),
        ),
      ),
    );
  }
}

/// "Add X ETB more for free delivery" with a progress bar.
class FreeDeliveryHint extends StatelessWidget {
  const FreeDeliveryHint({
    super.key,
    required this.remainingLabel,
    required this.progress,
  });

  final String remainingLabel;

  /// 0..1
  final double progress;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final dark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 14),
      decoration: BoxDecoration(
        color: dark ? AppColors.orangeTintDark : AppColors.orangeTint,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              const Icon(
                Icons.local_shipping_rounded,
                color: AppColors.primaryColor,
                size: 22,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  l10n.growthFreeDeliveryHint(remainingLabel),
                  style: const TextStyle(
                    fontSize: 14.5,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(
              value: progress.clamp(0.0, 1.0).toDouble(),
              minHeight: 8,
              color: AppColors.primaryColor,
              backgroundColor: AppColors.primaryColor.withValues(alpha: 0.18),
            ),
          ),
        ],
      ),
    );
  }
}

/// Shown once the free-delivery threshold is reached.
class FreeDeliveryUnlockedBanner extends StatelessWidget {
  const FreeDeliveryUnlockedBanner({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.successColor.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.celebration_rounded,
            color: AppColors.successColor,
            size: 22,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              context.l10n.growthFreeDeliveryUnlocked,
              style: const TextStyle(
                fontSize: 14.5,
                fontWeight: FontWeight.w700,
                color: AppColors.successColor,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
