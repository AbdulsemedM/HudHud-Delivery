import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:hudhud_delivery/controllers/theme_controller.dart';
import 'package:hudhud_delivery/l10n/app_localizations.dart';

class AppearanceScreen extends StatelessWidget {
  const AppearanceScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final themeController = Provider.of<ThemeController>(context);
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.settingsAppearance),
      ),
      body: ListView(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 24, 16, 8),
            child: Text(
              l10n.appearanceChooseTheme,
              style: theme.textTheme.bodyLarge?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ),
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

    return ListTile(
      leading: Icon(
        icon,
        color: isSelected
            ? theme.colorScheme.primary
            : theme.colorScheme.onSurfaceVariant,
      ),
      title: Text(
        title,
        style: TextStyle(
          fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
          color: theme.colorScheme.onSurface,
        ),
      ),
      subtitle: Text(
        subtitle,
        style: theme.textTheme.bodySmall?.copyWith(
          color: theme.colorScheme.onSurfaceVariant,
        ),
      ),
      trailing: isSelected
          ? Icon(
              Icons.check_circle,
              color: theme.colorScheme.primary,
            )
          : null,
      onTap: onTap,
    );
  }
}
