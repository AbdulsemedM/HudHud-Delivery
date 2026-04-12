import 'package:flutter/widgets.dart';
import 'package:hudhud_delivery/l10n/app_localizations.dart';

extension AppLocalizationContext on BuildContext {
  AppLocalizations get l10n => AppLocalizations.of(this)!;
}
