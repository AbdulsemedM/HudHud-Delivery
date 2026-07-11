import 'package:flutter/material.dart';
import 'package:hudhud_delivery/core/theme/app_colors.dart';
import 'package:hudhud_delivery/l10n/app_localizations.dart';

enum LoginMethod { email, phone }

class LoginMethodTabs extends StatelessWidget {
  final LoginMethod selected;
  final ValueChanged<LoginMethod> onChanged;

  const LoginMethodTabs({
    super.key,
    required this.selected,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final trackColor = theme.brightness == Brightness.dark
        ? theme.colorScheme.surfaceContainerHighest
        : AppColors.borderLight;

    return Semantics(
      container: true,
      label: 'Sign in method',
      child: Container(
        padding: const EdgeInsets.all(4),
        decoration: BoxDecoration(
          color: trackColor,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Expanded(
              child: _TabSegment(
                label: l10n.loginTabPhone,
                isSelected: selected == LoginMethod.phone,
                semanticsLabel: l10n.loginTabPhoneSemantics,
                onTap: () => onChanged(LoginMethod.phone),
              ),
            ),
            Expanded(
              child: _TabSegment(
                label: l10n.loginTabEmail,
                isSelected: selected == LoginMethod.email,
                semanticsLabel: l10n.loginTabEmailSemantics,
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
  final String semanticsLabel;
  final bool isSelected;
  final VoidCallback onTap;

  const _TabSegment({
    required this.label,
    required this.semanticsLabel,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final activeColor = AppColors.primaryColor;

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
              boxShadow: isSelected
                  ? [
                      BoxShadow(
                        color: activeColor.withValues(alpha: 0.28),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ]
                  : null,
            ),
            child: Text(
              label,
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: isSelected
                    ? Colors.white
                    : theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
