import 'package:flutter/material.dart';
import 'package:hudhud_delivery/controllers/theme_controller.dart';
import 'package:hudhud_delivery/core/l10n/context_l10n.dart';
import 'package:provider/provider.dart';

/// Icon button that toggles between light and dark theme.
class ThemeToggleIconButton extends StatelessWidget {
  const ThemeToggleIconButton({
    super.key,
    this.iconColor,
    this.iconSize = 22,
    this.padding = EdgeInsets.zero,
    this.constraints = const BoxConstraints(minWidth: 40, minHeight: 40),
  });

  final Color? iconColor;
  final double iconSize;
  final EdgeInsetsGeometry padding;
  final BoxConstraints constraints;

  @override
  Widget build(BuildContext context) {
    final themeController = context.watch<ThemeController>();
    final color = iconColor ?? Theme.of(context).colorScheme.onSurface;
    final icon = themeController.isDarkMode
        ? Icons.light_mode_outlined
        : Icons.dark_mode_outlined;

    return IconButton(
      onPressed: () => themeController.toggleTheme(),
      icon: Icon(icon, color: color, size: iconSize),
      tooltip: context.l10n.toggleThemeTooltip,
      padding: padding,
      constraints: constraints,
    );
  }
}
