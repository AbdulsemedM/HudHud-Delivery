import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:hudhud_delivery/controllers/theme_controller.dart';
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
            ),
          ),
          SizedBox(height: 16),
          _AppearanceOption(
            icon: Icons.dark_mode,
            title: l10n.themeDark,
            subtitle: l10n.themeSubtitleDark,
            isSelected: themeController.isThemeModeSelected(ThemeMode.dark),
            onTap: () => themeController.setThemeMode(ThemeMode.dark),
          ),
          _AppearanceOption(
            icon: Icons.light_mode,
            title: l10n.themeLight,
            subtitle: l10n.themeSubtitleLight,
            isSelected: themeController.isThemeModeSelected(ThemeMode.light),
            onTap: () => themeController.setThemeMode(ThemeMode.light),
          ),
          _AppearanceOption(
            icon: Icons.brightness_auto,
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
  final String title;
  final String subtitle;
  final bool isSelected;
  final VoidCallback onTap;

  const _AppearanceOption({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: 12),
      child: Material(
        color: AuthScreenColors.surfaceOf(context),
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: Container(
            padding: EdgeInsets.all(16),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: isSelected
                    ? AuthScreenColors.orange
                    : AuthScreenColors.surfaceBorderOf(context),
                width: isSelected ? 2 : 1,
              ),
              color: isSelected
                  ? AuthScreenColors.orange.withValues(alpha: 0.08)
                  : null,
            ),
            child: Row(
              children: [
                Icon(
                  icon,
                  color: isSelected
                      ? AuthScreenColors.orange
                      : AuthScreenColors.textMutedOf(context),
                ),
                SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: TextStyle(
                          fontWeight:
                              isSelected ? FontWeight.w600 : FontWeight.normal,
                          color: AuthScreenColors.textPrimaryOf(context),
                        ),
                      ),
                      Text(
                        subtitle,
                        style: TextStyle(
                          fontSize: 13,
                          color: AuthScreenColors.textSecondaryOf(context),
                        ),
                      ),
                    ],
                  ),
                ),
                if (isSelected)
                  const Icon(
                    Icons.check_circle,
                    color: AuthScreenColors.orange,
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
