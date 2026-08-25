import 'package:flutter/material.dart';
import 'package:hudhud_delivery/core/theme/app_colors.dart';
import 'package:hudhud_delivery/features/login/presentation/theme/auth_screen_colors.dart';
import 'package:hudhud_delivery/l10n/app_localizations.dart';

enum LoginMethod { email, phone }

class LoginMethodTabs extends StatelessWidget {
  final LoginMethod selected;
  final ValueChanged<LoginMethod> onChanged;

  /// When true, uses auth screen styling (orange selected pill).
  final bool authStyle;

  const LoginMethodTabs({
    super.key,
    required this.selected,
    required this.onChanged,
    this.authStyle = false,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final trackColor = authStyle
        ? AuthScreenColors.surfaceOf(context)
        : (theme.brightness == Brightness.dark
            ? theme.colorScheme.surfaceContainerHighest
            : const Color(0xFFE8EEF4));

    return Semantics(
      container: true,
      label: 'Sign in method',
      child: Container(
        padding: const EdgeInsets.all(4),
        decoration: BoxDecoration(
          color: trackColor,
          borderRadius: BorderRadius.circular(14),
          border: authStyle
              ? Border.all(color: AuthScreenColors.surfaceBorderOf(context))
              : null,
        ),
        child: Row(
          children: [
            Expanded(
              child: _TabSegment(
                label: l10n.loginTabPhone,
                icon: Icons.phone_outlined,
                isSelected: selected == LoginMethod.phone,
                semanticsLabel: l10n.loginTabPhoneSemantics,
                authStyle: authStyle,
                onTap: () => onChanged(LoginMethod.phone),
              ),
            ),
            Expanded(
              child: _TabSegment(
                label: l10n.loginTabEmail,
                icon: Icons.mail_outline_rounded,
                isSelected: selected == LoginMethod.email,
                semanticsLabel: l10n.loginTabEmailSemantics,
                authStyle: authStyle,
                onTap: () => onChanged(LoginMethod.email),
              ),
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
  final bool authStyle;
  final VoidCallback onTap;

  const _TabSegment({
    required this.label,
    required this.icon,
    required this.semanticsLabel,
    required this.isSelected,
    required this.authStyle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final Color activeColor;
    final Color activeFg;
    final Color inactiveFg;

    if (authStyle) {
      activeColor = AuthScreenColors.orange;
      activeFg = Colors.black;
      inactiveFg = AuthScreenColors.textMutedOf(context);
    } else {
      activeColor = theme.brightness == Brightness.dark
          ? AppColors.primaryLightColor
          : AppColors.primaryColor;
      activeFg = Colors.white;
      inactiveFg = theme.colorScheme.onSurfaceVariant;
    }

    return Semantics(
      button: true,
      selected: isSelected,
      label: semanticsLabel,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(10),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            curve: Curves.easeOutCubic,
            height: 44,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: isSelected ? activeColor : Colors.transparent,
              borderRadius: BorderRadius.circular(10),
              boxShadow: isSelected && !authStyle
                  ? [
                      BoxShadow(
                        color: activeColor.withValues(alpha: 0.28),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ]
                  : null,
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  icon,
                  size: 18,
                  color: isSelected ? activeFg : inactiveFg,
                ),
                const SizedBox(width: 6),
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: isSelected ? activeFg : inactiveFg,
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
