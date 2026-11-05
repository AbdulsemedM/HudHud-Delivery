import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../growth/data/models/growth_config.dart';
import '../growth/data/models/market.dart';

/// Phase 6 diaspora gifting: the "Send a gift" journey in progress.
///
/// Started from the home banner with the recipient's market (Hargeisa for
/// the launch). While active, the catalog shows that market's currency and
/// checkout opens with the gift section on. The recipient's name / phone /
/// message live in checkout only; nothing here is sent to the server.
class GiftSession extends ChangeNotifier {
  GiftSession._();

  static final GiftSession instance = GiftSession._();

  /// Error codes from `POST /api/customer/gift-orders` meaning the feature
  /// is switched off (`gifting.enabled`) or not migrated yet.
  static const Set<String> unavailableCodes = {
    'FEATURE_DISABLED',
    'GIFTING_NOT_READY',
  };

  /// How long the entry stays hidden after the server said "not available".
  static const Duration unavailableCooldown = Duration(hours: 6);

  static const String _prefsUnavailableKey = 'p9_gifting_unavailable_at';

  Market? _market;
  DateTime? _unavailableAt;
  bool _restored = false;

  /// Recipient's market while a gift is being prepared.
  Market? get market => _market;

  bool get active => _market != null;

  /// True while the server's last "not available" answer is fresh.
  bool get serverUnavailable {
    final at = _unavailableAt;
    if (at == null) return false;
    return DateTime.now().difference(at) < unavailableCooldown;
  }

  void start(Market market) {
    _market = market;
    notifyListeners();
  }

  void clear() {
    if (_market == null) return;
    _market = null;
    notifyListeners();
  }

  /// Records a FEATURE_DISABLED / GIFTING_NOT_READY answer and ends the
  /// session so the entry hides until [unavailableCooldown] passes.
  Future<void> markUnavailable({DateTime? now}) async {
    _unavailableAt = now ?? DateTime.now();
    _market = null;
    notifyListeners();
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(
        _prefsUnavailableKey,
        _unavailableAt!.toIso8601String(),
      );
    } catch (_) {}
  }

  /// Loads a persisted "not available" answer once per process.
  Future<void> restore() async {
    if (_restored) return;
    _restored = true;
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_prefsUnavailableKey);
      final at = raw == null ? null : DateTime.tryParse(raw);
      if (at != null && (_unavailableAt == null || at.isAfter(_unavailableAt!))) {
        _unavailableAt = at;
        notifyListeners();
      }
    } catch (_) {}
  }

  @visibleForTesting
  void resetForTest() {
    _market = null;
    _unavailableAt = null;
    _restored = false;
  }
}

/// Markets a gift can be sent to (the recipient's city).
///
/// Every active market except the default Addis Ababa one, Hargeisa first.
List<Market> giftMarkets(List<Market> markets) {
  final out = markets.where((m) => !m.isDefault).toList();
  out.sort((a, b) {
    if (a.code == Market.hargeisaCode) return -1;
    if (b.code == Market.hargeisaCode) return 1;
    return 0;
  });
  return out;
}

/// Whether to show the "Send a gift" entry.
///
/// `gifting.enabled` is not published to clients, so the entry is gated on
/// a gift market being available; a server `FEATURE_DISABLED` /
/// `GIFTING_NOT_READY` answer hides it again ([serverUnavailable]). If the
/// growth config ever sends `gifting.enabled`, that value wins.
bool giftingAvailable({
  required GrowthConfig config,
  required List<Market> markets,
  required bool serverUnavailable,
}) {
  if (serverUnavailable) return false;
  if (config.giftingEnabled == false) return false;
  return giftMarkets(markets).isNotEmpty;
}

/// Starts [GiftSession.restore] without awaiting it.
void restoreGiftSession() => unawaited(GiftSession.instance.restore());
