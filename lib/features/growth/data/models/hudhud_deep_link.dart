import 'package:flutter/foundation.dart';

/// Parsed HudHud app link.
@immutable
class HudhudDeepLink {
  const HudhudDeepLink._({this.referralCode, this.orderId});

  /// `https://hudhuddelivery.com/r/{code}`
  final String? referralCode;

  /// `https://hudhuddelivery.com/o/{orderId}`
  final int? orderId;

  static const Set<String> hosts = {
    'hudhuddelivery.com',
    'www.hudhuddelivery.com',
  };

  /// Returns null for anything that is not a recognised HudHud link.
  static HudhudDeepLink? parse(Uri uri) {
    if (uri.scheme != 'https' && uri.scheme != 'http') return null;
    if (!hosts.contains(uri.host.toLowerCase())) return null;
    final segments = uri.pathSegments.where((s) => s.isNotEmpty).toList();
    if (segments.length < 2) return null;
    final kind = segments[0].toLowerCase();
    final value = segments[1].trim();
    if (kind == 'r') {
      final code = value.toUpperCase();
      if (!RegExp(r'^[A-Z0-9_-]{2,40}$').hasMatch(code)) return null;
      return HudhudDeepLink._(referralCode: code);
    }
    if (kind == 'o') {
      final id = int.tryParse(value);
      if (id == null || id <= 0) return null;
      return HudhudDeepLink._(orderId: id);
    }
    return null;
  }
}
