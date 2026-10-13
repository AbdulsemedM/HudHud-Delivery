import 'package:flutter/material.dart';
import 'package:hudhud_delivery/core/theme/app_colors.dart';
import 'package:hudhud_delivery/features/home/presentation/theme/home_colors.dart';
import 'package:hudhud_delivery/l10n/app_localizations.dart';

enum LoginMethod { email, phone }

/// Soft pill segmented control: tinted track with a sliding white thumb.
class LoginMethodTabs extends StatelessWidget {
  final LoginMethod selected;
  final ValueChanged<LoginMethod> onChanged;

  /// Kept for API compatibility; both styles now share the pill look.
  final bool authStyle;

  const LoginMethodTabs({
    super.key,
    required this.selected,
    required this.onChanged,
    this.authStyle = false,
  });

  static const double _height = 56;
  static const double _inset = 5;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final dark = HomeColors.isDark(context);
    final thumbColor = dark ? AppColors.darkBorder : AppColors.lightSurface;
    final thumbRadius = BorderRadius.circular(_height / 2 - _inset);

    return Semantics(
      container: true,
      label: 'Sign in method',
      child: Container(
        height: _height,
        padding: const EdgeInsets.all(_inset),
        decoration: BoxDecoration(
          color: HomeColors.surfaceElevatedOf(context),
          borderRadius: BorderRadius.circular(_height / 2),
          border: Border.all(color: HomeColors.borderOf(context)),
        ),
        child: Stack(
          children: [
            AnimatedAlign(
              duration: const Duration(milliseconds: 260),
              curve: Curves.easeOutCubic,
              alignment: selected == LoginMethod.phone
                  ? AlignmentDirectional.centerStart
                  : AlignmentDirectional.centerEnd,
              child: FractionallySizedBox(
                widthFactor: 0.5,
                heightFactor: 1,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    color: thumbColor,
                    borderRadius: thumbRadius,
                    boxShadow: dark
                        ? null
                        : const [
                            BoxShadow(
                              color: Color(0x1A1B1530),
                              blurRadius: 12,
                              offset: Offset(0, 3),
                            ),
                          ],
                  ),
                ),
              ),
            ),
            Row(
              children: [
                Expanded(
                  child: _TabSegment(
                    label: l10n.loginTabPhone,
                    icon: Icons.phone_iphone_rounded,
                    isSelected: selected == LoginMethod.phone,
                    semanticsLabel: l10n.loginTabPhoneSemantics,
                    radius: thumbRadius,
                    onTap: () => onChanged(LoginMethod.phone),
                  ),
                ),
                Expanded(
                  child: _TabSegment(
                    label: l10n.loginTabEmail,
                    icon: Icons.alternate_email_rounded,
                    isSelected: selected == LoginMethod.email,
                    semanticsLabel: l10n.loginTabEmailSemantics,
                    radius: thumbRadius,
                    onTap: () => onChanged(LoginMethod.email),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _TabSegment extends StatelessWidget {
  final String label;
  final IconData icon;
  final String semanticsLabel;
  final bool isSelected;
  final BorderRadius radius;
  final VoidCallback onTap;

  const _TabSegment({
    required this.label,
    required this.icon,
    required this.semanticsLabel,
    required this.isSelected,
    required this.radius,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final activeIcon = HomeColors.violetOf(context);
    final activeText = HomeColors.textPrimaryOf(context);
    final inactive = HomeColors.textMutedOf(context);

    return Semantics(
      button: true,
      selected: isSelected,
      label: semanticsLabel,
      child: Material(
        type: MaterialType.transparency,
        child: InkWell(
          onTap: onTap,
          borderRadius: radius,
          child: Center(
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                AnimatedSwitcher(
                  duration: const Duration(milliseconds: 200),
                  child: Icon(
                    icon,
                    key: ValueKey(isSelected),
                    size: 20,
                    color: isSelected ? activeIcon : inactive,
                  ),
                ),
                const SizedBox(width: 8),
                Flexible(
                  child: AnimatedDefaultTextStyle(
                    duration: const Duration(milliseconds: 200),
                    style: DefaultTextStyle.of(context).style.copyWith(
                          fontSize: 15,
                          fontWeight:
                              isSelected ? FontWeight.w800 : FontWeight.w600,
                          letterSpacing: -0.1,
                          color: isSelected ? activeText : inactive,
                        ),
                    child: Text(
                      label,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
