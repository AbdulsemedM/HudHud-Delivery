import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';

import 'data/growth_repository.dart';
import 'data/models/growth_config.dart';

/// App-wide Phase 2 growth flags from `GET /api/growth/config`.
///
/// Loaded once at app start, refreshed when the app resumes (throttled), and
/// cached in memory. Any failure keeps the last good config, or
/// [GrowthConfig.disabled] when nothing has loaded yet — so every growth UI
/// stays hidden and the app looks exactly like it did before Phase 2.
class GrowthConfigController extends ChangeNotifier
    with WidgetsBindingObserver {
  GrowthConfigController({GrowthRepository? repository})
      : _repository = repository;

  /// Optional global handle for code outside the widget tree
  /// (e.g. FCM routing, CartService helpers).
  static GrowthConfigController? instance;

  static const Duration _minRefreshInterval = Duration(minutes: 2);

  GrowthRepository? _repository;
  GrowthConfig _config = GrowthConfig.disabled;
  DateTime? _lastFetch;
  Future<void>? _inFlight;
  bool _observing = false;
  bool _disposed = false;

  /// Promo code picked from a home banner (`promo` action); applied
  /// automatically the next time checkout opens.
  String? _pendingPromoCode;

  GrowthRepository get _repo => _repository ??= GrowthRepository.create();

  GrowthConfig get config => _config;

  bool get promoCodesEnabled => _config.promoCodesEnabled;
  bool get freeDeliveryEnabled => _config.freeDeliveryEnabled;
  bool get rewardsEnabled => _config.rewardsEnabled;
  bool get referralEnabled => _config.referralEnabled;
  bool get onTimeEnabled => _config.onTimeEnabled;
  bool get homeFeedEnabled => _config.homeFeedEnabled;
  bool get reorderEnabled => _config.loaded && _config.reorderEnabled;

  String? get pendingPromoCode => _pendingPromoCode;

  void setPendingPromoCode(String? code) {
    final next = code?.trim().toUpperCase();
    _pendingPromoCode = (next == null || next.isEmpty) ? null : next;
    if (!_disposed) notifyListeners();
  }

  /// Returns and clears the pending promo code.
  String? takePendingPromoCode() {
    final code = _pendingPromoCode;
    _pendingPromoCode = null;
    return code;
  }

  /// Starts the initial fetch and lifecycle observation. Safe to call twice.
  void start() {
    instance = this;
    if (!_observing) {
      WidgetsBinding.instance.addObserver(this);
      _observing = true;
    }
    unawaited(refresh(force: true));
  }

  Future<void> refresh({bool force = false}) {
    final last = _lastFetch;
    if (!force &&
        last != null &&
        DateTime.now().difference(last) < _minRefreshInterval) {
      return Future<void>.value();
    }
    return _inFlight ??= _fetch().whenComplete(() => _inFlight = null);
  }

  Future<void> _fetch() async {
    try {
      final next = await _repo.fetchConfig();
      if (_disposed) return;
      _lastFetch = DateTime.now();
      // Keep the last good config when a refresh fails.
      if (!next.loaded && _config.loaded) return;
      _config = next;
      notifyListeners();
    } catch (e) {
      if (kDebugMode) debugPrint('Growth config fetch failed: $e');
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      unawaited(refresh());
    }
  }

  @override
  void dispose() {
    _disposed = true;
    if (_observing) {
      WidgetsBinding.instance.removeObserver(this);
      _observing = false;
    }
    if (identical(instance, this)) instance = null;
    super.dispose();
  }
}
