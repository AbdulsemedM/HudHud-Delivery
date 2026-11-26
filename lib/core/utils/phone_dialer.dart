import 'package:url_launcher/url_launcher.dart';

/// Dialing a phone number from the app.
///
/// The API stores numbers as `2519xxxxxxxx` - country code, no `+`. Passed
/// straight to `tel:`, the dialer treats `251…` as a local number and the call
/// fails, which is what happened on "Call" for the courier. Everything that
/// opens the dialer goes through [telPath].
///
/// Same rules as the driver app's PhoneLauncher.telPath, so both sides dial
/// the same number for the same stored value.
class PhoneDialer {
  PhoneDialer._();

  static final RegExp _nonDigits = RegExp(r'\D');
  static final RegExp _ethiopianMobile = RegExp(r'^9\d{8}$');

  /// The path for a `tel:` URI, or null when there is nothing to dial.
  ///
  /// - Ethiopian mobiles in any form (`2519…`, `+2519…`, `09…`, `9…`,
  ///   `25109…`) -> `+2519xxxxxxxx`
  /// - already international (`+…`) keeps its `+`; `00…` becomes `+…`
  /// - 11+ digits otherwise carry a country code (e.g. `252…` Somaliland)
  ///   and get a `+`
  /// - anything shorter is a local number or short code and stays as is
  static String? telPath(String? phone) {
    final raw = (phone ?? '').trim();
    final digits = raw.replaceAll(_nonDigits, '');
    if (digits.isEmpty) return null;

    final ethiopian = _ethiopianLocal(digits);
    if (ethiopian != null) return '+251$ethiopian';

    if (raw.startsWith('+')) return '+$digits';
    if (digits.startsWith('00') && digits.length > 2) {
      return '+${digits.substring(2)}';
    }
    if (digits.length >= 11) return '+$digits';
    return digits;
  }

  /// The `tel:` URI for [phone], or null when there is nothing to dial.
  static Uri? telUri(String? phone) {
    final path = telPath(phone);
    return path == null ? null : Uri(scheme: 'tel', path: path);
  }

  /// Opens the dialer. False when there is no number or it could not open.
  static Future<bool> call(
    String? phone, {
    LaunchMode mode = LaunchMode.externalApplication,
  }) async {
    final uri = telUri(phone);
    if (uri == null) return false;
    try {
      return await launchUrl(uri, mode: mode);
    } catch (_) {
      return false;
    }
  }

  static String? _ethiopianLocal(String digits) {
    String? local;
    if (digits.startsWith('2510') && digits.length == 13) {
      local = digits.substring(4);
    } else if (digits.startsWith('251') && digits.length == 12) {
      local = digits.substring(3);
    } else if (digits.startsWith('0') && digits.length == 10) {
      local = digits.substring(1);
    } else if (digits.length == 9) {
      local = digits;
    }
    return local != null && _ethiopianMobile.hasMatch(local) ? local : null;
  }
}
