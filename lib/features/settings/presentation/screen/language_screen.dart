import 'package:flutter/material.dart';
import 'package:hudhud_delivery/controllers/locale_controller.dart';
import 'package:hudhud_delivery/features/login/presentation/theme/auth_screen_colors.dart';
import 'package:hudhud_delivery/features/settings/presentation/widgets/profile_dark_page.dart';
import 'package:hudhud_delivery/l10n/app_localizations.dart';
import 'package:provider/provider.dart';

class LanguageScreen extends StatelessWidget {
  const LanguageScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final controller = context.watch<LocaleController>();

    Widget tile({
      required String label,
      required String code,
      String? scriptLabel,
    }) {
      final isSelected = controller.locale.languageCode == code;
      return Container(
        margin: EdgeInsets.only(bottom: 8),
        decoration: BoxDecoration(
          color: AuthScreenColors.surfaceOf(context),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected
                ? AuthScreenColors.orange
                : AuthScreenColors.surfaceBorderOf(context),
            width: isSelected ? 2 : 1,
          ),
        ),
        child: ListTile(
          onTap: () async {
            await controller.setLocale(Locale(code));
          },
          title: Text(
            label,
            style: TextStyle(color: AuthScreenColors.textPrimaryOf(context)),
          ),
          subtitle: scriptLabel != null
              ? Text(
                  scriptLabel,
                  style: TextStyle(color: AuthScreenColors.textSecondaryOf(context)),
                )
              : null,
          trailing: isSelected
              ? Icon(Icons.check_circle, color: AuthScreenColors.orange)
              : Icon(
                  Icons.circle_outlined,
                  color: AuthScreenColors.textMutedOf(context),
                ),
        ),
      );
    }

    return ProfileDarkPage(
      title: l10n.languageTitle,
      body: ListView(
        padding: const EdgeInsets.all(16),
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
