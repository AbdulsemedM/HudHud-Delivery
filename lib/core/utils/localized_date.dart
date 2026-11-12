import 'package:flutter/widgets.dart';
import 'package:hudhud_delivery/core/l10n/context_l10n.dart';
import 'package:intl/intl.dart';

/// Gregorian month names for app languages that `intl` has no date data for.
/// (`intl` covers en, am and ar; Somali and Afaan Oromo are not in it.)
const Map<String, List<String>> _fallbackMonths = {
  'so': [
    'Janaayo', 'Febraayo', 'Maarso', 'Abriil', 'Maajo', 'Juun', //
    'Luuliyo', 'Ogost', 'Sebtembar', 'Oktoobar', 'Nofembar', 'Desembar',
  ],
  'om': [
    'Amajjii', 'Guraandhala', 'Bitootessa', 'Elba', 'Caamsa', 'Waxabajjii', //
    'Adooleessa', 'Hagayya', 'Fuulbaana', 'Onkololeessa', 'Sadaasa', 'Muddee',
  ],
};

DateTime? _parse(dynamic value) {
  if (value == null) return null;
  if (value is DateTime) return value.toLocal();
  final parsed = DateTime.tryParse(value.toString());
  return parsed?.toLocal();
}

String _hm(DateTime dt) =>
    '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';

/// "10 November 2026, 08:23" in the app's current language.
///
/// Returns [placeholder] for null and the raw text when it is not a date.
String formatLocalizedDateTime(
  dynamic value,
  String localeName, {
  String placeholder = '—',
}) {
  if (value == null || value.toString().trim().isEmpty) return placeholder;
  final dt = _parse(value);
  if (dt == null) return value.toString();

  final lang = localeName.split(RegExp('[_-]')).first;
  final months = _fallbackMonths[lang];
  if (months != null) {
    return '${dt.day} ${months[dt.month - 1]} ${dt.year}, ${_hm(dt)}';
  }
  try {
    return '${DateFormat.yMMMMd(localeName).format(dt)}, '
        '${DateFormat.Hm(localeName).format(dt)}';
  } catch (_) {
    // Locale data not loaded: fall back to English rather than throwing.
    return '${DateFormat.yMMMMd('en').format(dt)}, ${_hm(dt)}';
  }
}

extension LocalizedDateContext on BuildContext {
  String formatDateTime(dynamic value, {String placeholder = '—'}) =>
      formatLocalizedDateTime(value, l10n.localeName, placeholder: placeholder);
}
