import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:hudhud_delivery/controllers/theme_controller.dart';
import 'package:hudhud_delivery/core/theme/app_colors.dart';
import 'package:hudhud_delivery/features/login/presentation/theme/auth_screen_colors.dart';
import 'package:hudhud_delivery/features/settings/presentation/widgets/profile_dark_page.dart';
import 'package:hudhud_delivery/l10n/app_localizations.dart';

class AppearanceScreen extends StatelessWidget {
  const AppearanceScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final themeController = Provider.of<ThemeController>(context);
    final l10n = AppLocalizations.of(context)!;

    return ProfileDarkPage(
      title: l10n.settingsAppearance,
      body: ListView(
        padding: EdgeInsets.all(16),
        children: [
          Text(
            l10n.appearanceChooseTheme,
            style: TextStyle(
              color: AuthScreenColors.textSecondaryOf(context),
              fontSize: 15,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 16),
          _AppearanceOption(
            icon: Icons.dark_mode_rounded,
            color: AuthScreenColors.isDark(context)
                ? AppColors.brandIndigoBright
                : AppColors.brandIndigo,
            title: l10n.themeDark,
            subtitle: l10n.themeSubtitleDark,
            isSelected: themeController.isThemeModeSelected(ThemeMode.dark),
            onTap: () => themeController.setThemeMode(ThemeMode.dark),
          ),
          _AppearanceOption(
            icon: Icons.light_mode_rounded,
            color: AppColors.warningColor,
            title: l10n.themeLight,
            subtitle: l10n.themeSubtitleLight,
            isSelected: themeController.isThemeModeSelected(ThemeMode.light),
            onTap: () => themeController.setThemeMode(ThemeMode.light),
          ),
          _AppearanceOption(
            icon: Icons.brightness_auto_rounded,
            color: AppColors.successColor,
            title: l10n.themeSystem,
            subtitle: l10n.themeSubtitleSystem,
            isSelected: themeController.isThemeModeSelected(ThemeMode.system),
            onTap: () => themeController.setThemeMode(ThemeMode.system),
          ),
        ],
      ),
    );
  }
}

class _AppearanceOption extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String title;
  final String subtitle;
  final bool isSelected;
  final VoidCallback onTap;

  const _AppearanceOption({
    required this.icon,
    required this.color,
    required this.title,
    required this.subtitle,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return _SelectableCard(
      leading: _LeadingTile(color: color, icon: icon, text: null),
      title: title,
      subtitle: subtitle,
      isSelected: isSelected,
      onTap: onTap,
    );
  }
}

/// Big selectable card: icon tile, title + hint, check when selected.
class _SelectableCard extends StatelessWidget {
  final Widget leading;
  final String title;
  final String? subtitle;
  final bool isSelected;
  final VoidCallback onTap;

  const _SelectableCard({
    required this.leading,
    required this.title,
    this.subtitle,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final dark = AuthScreenColors.isDark(context);
    final indigo = dark ? AppColors.brandIndigoBright : AppColors.brandIndigo;
    final radius = BorderRadius.circular(20);
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: DecoratedBox(
        decoration: BoxDecoration(
          borderRadius: radius,
          boxShadow: AppColors.softShadow(context),
        ),
        child: Material(
          color: isSelected
              ? (dark ? AppColors.indigoTintDark : AppColors.indigoTint)
              : AuthScreenColors.surfaceOf(context),
          shape: RoundedRectangleBorder(
            borderRadius: radius,
            side: BorderSide(
              color: isSelected
                  ? indigo
                  : (dark
                      ? AuthScreenColors.surfaceBorderOf(context)
                      : Colors.transparent),
              width: isSelected ? 2 : 1,
            ),
          ),
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            onTap: onTap,
            child: ConstrainedBox(
              constraints: const BoxConstraints(minHeight: 76),
              child: Padding(
                padding: const EdgeInsets.all(14),
                child: Row(
                  children: [
                    leading,
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            title,
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w800,
                              letterSpacing: -0.2,
                              color: AuthScreenColors.textPrimaryOf(context),
                            ),
                          ),
                          if (subtitle != null) ...[
                            const SizedBox(height: 2),
                            Text(
                              subtitle!,
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: AuthScreenColors.textMutedOf(context),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    Icon(
                      isSelected
                          ? Icons.check_circle_rounded
                          : Icons.circle_outlined,
                      size: 28,
                      color: isSelected
                          ? indigo
                          : AuthScreenColors.textMutedOf(context)
                              .withValues(alpha: 0.6),
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

/// 48px tinted tile used as the leading visual of a [_SelectableCard].
class _LeadingTile extends StatelessWidget {
  final Color color;
  final IconData? icon;
  final String? text;

  const _LeadingTile(
      {required this.color, required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    final dark = AuthScreenColors.isDark(context);
    return Container(
      width: 48,
      height: 48,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: color.withValues(alpha: dark ? 0.2 : 0.11),
        borderRadius: BorderRadius.circular(15),
      ),
      child: icon != null
          ? Icon(icon, color: color, size: 26)
          : Text(
              text ?? '',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w800,
                color: color,
              ),
            ),
    );
  }
}
