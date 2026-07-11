import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:hudhud_delivery/controllers/theme_controller.dart';
import 'package:hudhud_delivery/core/theme/app_colors.dart';
import 'package:hudhud_delivery/l10n/app_localizations.dart';

class AppearanceScreen extends StatelessWidget {
  const AppearanceScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final themeController = Provider.of<ThemeController>(context);
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text(l10n.settingsAppearance),
        backgroundColor: theme.colorScheme.surface,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
      ),
      body: ListView(
        padding: const EdgeInsets.all(AppColors.spaceMD),
        children: [
          Text(
            l10n.appearanceChooseTheme,
            style: theme.textTheme.bodyLarge?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: AppColors.spaceMD),
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
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final borderColor =
        isDark ? const Color(0xFF2A2A2A) : const Color(0xFFEEEEEE);

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Material(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(AppColors.radiusLG),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(AppColors.radiusLG),
          child: Container(
            padding: const EdgeInsets.all(AppColors.spaceMD),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(AppColors.radiusLG),
              border: Border.all(
                color: isSelected ? AppColors.primaryColor : borderColor,
                width: isSelected ? 2 : 1,
              ),
              color: isSelected
                  ? AppColors.primaryColor.withValues(alpha: 0.08)
                  : null,
            ),
            child: Row(
              children: [
                Icon(
                  icon,
                  color: isSelected
                      ? AppColors.primaryColor
                      : theme.colorScheme.onSurfaceVariant,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: theme.textTheme.titleSmall?.copyWith(
                          fontWeight:
                              isSelected ? FontWeight.w600 : FontWeight.normal,
                        ),
                      ),
                      Text(
                        subtitle,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
                if (isSelected)
                  const Icon(Icons.check_circle, color: AppColors.primaryColor),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
