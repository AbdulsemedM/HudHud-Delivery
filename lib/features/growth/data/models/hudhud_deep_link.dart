import 'package:flutter/foundation.dart';

/// Parsed HudHud app link.
@immutable
class HudhudDeepLink {
  const HudhudDeepLink._({this.referralCode, this.orderId, this.vendorId});

  /// `https://hudhuddelivery.com/r/{code}`
  final String? referralCode;

  /// `https://hudhuddelivery.com/o/{orderId}`
  final int? orderId;

  /// Vendor OWNER user id (orders/products.vendor_id — the id
  /// `/api/public/vendors/{id}` and the store screen expect, never
  /// vendors.id). Same id the founding-vendor QR stickers carry as the
  /// Telegram start parameter `v<id>`:
  /// - `https://hudhuddelivery.com/v/{id}` or `/v/v{id}`
  /// - `hudhud://vendor/{id}` or `hudhud://vendor/v{id}`
  /// - `https://t.me/<bot>?startapp=v{id}` (or `?start=v{id}`)
  final int? vendorId;

  static const Set<String> hosts = {
    'hudhuddelivery.com',
    'www.hudhuddelivery.com',
  };

  /// Custom app scheme (parsing only; see DeepLinkService for native setup).
  static const String appScheme = 'hudhud';

  static const Set<String> telegramHosts = {'t.me', 'telegram.me'};

  /// "v123" (Telegram start param) or "123" → 123; null for anything else.
  /// Mirrors the backend's VendorDeepLinks::parseStartParam (1–19 digits,
  /// no leading zero).
  static int? parseVendorId(String? raw) {
    final value = raw?.trim();
    if (value == null || value.isEmpty) return null;
    final match = RegExp(r'^v?([1-9]\d{0,18})$').firstMatch(value);
    if (match == null) return null;
    return int.tryParse(match.group(1)!);
  }

  /// Returns null for anything that is not a recognised HudHud link.
  static HudhudDeepLink? parse(Uri uri) {
    final scheme = uri.scheme.toLowerCase();
    if (scheme == appScheme) return _parseAppScheme(uri);
    if (scheme != 'https' && scheme != 'http') return null;
    final host = uri.host.toLowerCase();
    if (telegramHosts.contains(host)) return _parseTelegram(uri);
    if (!hosts.contains(host)) return null;
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
    if (kind == 'v') {
      final id = parseVendorId(value);
      if (id == null) return null;
      return HudhudDeepLink._(vendorId: id);
    }
    return null;
  }

  /// `hudhud://vendor/{id}` (host = "vendor") or `hudhud:///vendor/{id}`.
  static HudhudDeepLink? _parseAppScheme(Uri uri) {
    final parts = <String>[
      if (uri.host.isNotEmpty) uri.host,
      ...uri.pathSegments.where((s) => s.isNotEmpty),
    ];
    if (parts.length < 2 || parts[0].toLowerCase() != 'vendor') return null;
    final id = parseVendorId(parts[1]);
    if (id == null) return null;
    return HudhudDeepLink._(vendorId: id);
  }

  /// `https://t.me/<bot>?startapp=v{id}` / `?start=v{id}`.
  static HudhudDeepLink? _parseTelegram(Uri uri) {
    final param =
        uri.queryParameters['startapp'] ?? uri.queryParameters['start'];
    final raw = param?.trim() ?? '';
    // Only the explicit "v" form here: other bots' numeric params are not ours.
    if (!raw.startsWith('v')) return null;
    final id = parseVendorId(raw);
    if (id == null) return null;
    return HudhudDeepLink._(vendorId: id);
  }
}
