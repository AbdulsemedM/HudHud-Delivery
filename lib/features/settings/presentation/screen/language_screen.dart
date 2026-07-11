import 'package:flutter/material.dart';
import 'package:hudhud_delivery/controllers/locale_controller.dart';
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
      return RadioListTile<String>(
        value: code,
        groupValue: controller.locale.languageCode,
        title: Text(label, style: theme.textTheme.titleSmall),
        subtitle: scriptLabel != null
            ? Text(scriptLabel, style: theme.textTheme.bodySmall)
            : null,
        onChanged: (_) async {
          await controller.setLocale(Locale(code));
        },
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.languageTitle),
      ),
      body: ListView(
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
