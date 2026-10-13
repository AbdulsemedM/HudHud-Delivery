import 'package:flutter/material.dart';
import 'package:hudhud_delivery/core/theme/app_colors.dart';
import 'package:hudhud_delivery/features/home/presentation/theme/home_colors.dart';

/// Pickup / drop-off row for the booking sheets: a tappable card with a
/// tinted pin tile, the address in bold and a trailing chevron.
///
/// [accent] tints the icon tile (orange for pickup, indigo for drop-off).
/// When omitted, the indigo brand accent is used.
class SendPackageLocationRow extends StatelessWidget {
  const SendPackageLocationRow({
    super.key,
    required this.icon,
    required this.text,
    required this.onTap,
    this.isPlaceholder = false,
    this.label,
    this.accent,
  });

  final IconData icon;
  final String text;
  final VoidCallback onTap;
  final bool isPlaceholder;

  /// Optional small caption above the address (e.g. "Pickup").
  final String? label;

  /// Accent colour for the icon tile.
  final Color? accent;

  static const _radius = BorderRadius.all(Radius.circular(20));

  @override
  Widget build(BuildContext context) {
    final dark = HomeColors.isDark(context);
    final accentColor = accent ?? HomeColors.violetOf(context);
    final isOrange = accentColor == HomeColors.orange;
    final tint = isOrange
        ? (dark ? AppColors.orangeTintDark : AppColors.orangeTint)
        : HomeColors.violetTintOf(context);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: DecoratedBox(
        decoration: BoxDecoration(
          borderRadius: _radius,
          boxShadow: AppColors.softShadow(context),
        ),
        child: Material(
          color: HomeColors.surfaceOf(context),
          shape: RoundedRectangleBorder(
            borderRadius: _radius,
            side: BorderSide(color: HomeColors.borderOf(context)),
          ),
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            onTap: onTap,
            child: ConstrainedBox(
              constraints: const BoxConstraints(minHeight: 72),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(12, 10, 10, 10),
                child: Row(
                  children: [
                    Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        color: tint,
                        borderRadius: BorderRadius.circular(15),
                      ),
                      child: Icon(icon, size: 26, color: accentColor),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (label != null) ...[
                            Text(
                              label!,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontSize: 12.5,
                                fontWeight: FontWeight.w700,
                                color: HomeColors.textMutedOf(context),
                              ),
                            ),
                            const SizedBox(height: 2),
                          ],
                          Text(
                            text,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 15.5,
                              height: 1.25,
                              fontWeight: isPlaceholder
                                  ? FontWeight.w600
                                  : FontWeight.w700,
                              color: isPlaceholder
                                  ? HomeColors.textMutedOf(context)
                                  : HomeColors.textPrimaryOf(context),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 6),
                    Icon(
                      Icons.chevron_right_rounded,
                      size: 26,
                      color: HomeColors.textMutedOf(context),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
