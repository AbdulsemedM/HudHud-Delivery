import 'package:flutter/material.dart';
import 'package:hudhud_delivery/controllers/locale_controller.dart';
import 'package:hudhud_delivery/core/theme/app_colors.dart';
import 'package:hudhud_delivery/l10n/app_localizations.dart';
import 'package:provider/provider.dart';

class LanguageScreen extends StatelessWidget {
  const LanguageScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final controller = context.watch<LocaleController>();
    final theme = Theme.of(context);

    Widget tile({
      required String label,
      required String code,
      String? scriptLabel,
    }) {
      final isSelected = controller.locale.languageCode == code;
      return Container(
        margin: const EdgeInsets.only(bottom: 8),
        decoration: BoxDecoration(
          color: theme.colorScheme.surface,
          borderRadius: BorderRadius.circular(AppColors.radiusLG),
          border: Border.all(
            color: isSelected
                ? AppColors.primaryColor
                : (theme.brightness == Brightness.dark
                    ? const Color(0xFF2A2A2A)
                    : const Color(0xFFEEEEEE)),
            width: isSelected ? 2 : 1,
          ),
        ),
        child: ListTile(
          onTap: () async {
            await controller.setLocale(Locale(code));
          },
          title: Text(label, style: theme.textTheme.titleSmall),
          subtitle: scriptLabel != null
              ? Text(scriptLabel, style: theme.textTheme.bodySmall)
              : null,
          trailing: isSelected
              ? const Icon(Icons.check_circle, color: AppColors.primaryColor)
              : Icon(
                  Icons.circle_outlined,
                  color: theme.colorScheme.onSurfaceVariant,
                ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text(l10n.languageTitle),
        backgroundColor: theme.colorScheme.surface,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
      ),
      body: ListView(
        padding: const EdgeInsets.all(AppColors.spaceMD),
        children: [
          tile(label: l10n.languageEnglish, code: LocaleController.langEnglish),
          tile(label: l10n.languageAmharic, code: LocaleController.langAmharic),
          tile(label: l10n.languageOromo, code: LocaleController.langOromo),
          tile(label: l10n.languageSomali, code: LocaleController.langSomali),
          tile(label: l10n.languageArabic, code: LocaleController.langArabic),
        ],
      ),
    );
  }
}
