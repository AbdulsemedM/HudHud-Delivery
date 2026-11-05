import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:hudhud_delivery/app/services/custom_location_service.dart';
import 'package:hudhud_delivery/app/services/startup_location_service.dart';

import '../gifting/gift_session.dart';
import 'data/growth_repository.dart';
import 'data/models/market.dart';
import 'growth_config_controller.dart';

/// Phase 3 markets (multi-city / multi-currency).
///
/// Loads `GET /api/markets` once at startup and picks the market from the
/// user's saved choice, else from the startup GPS fix
/// (`GET /api/markets/resolve`). When the markets call fails or returns
/// nothing (pre-Phase-3 backend), [selected] stays `null`: no `?market=` is
/// sent, [currency] is ETB and the picker is hidden — the app behaves
/// exactly as before.
class MarketController extends ChangeNotifier {
  MarketController({GrowthRepository? repository}) : _repository = repository;

  /// Global handle for code outside the widget tree (growth config,
  /// login/signup phone defaults, currency fallbacks).
  static MarketController? instance;

  /// Currency of the selected market; ETB when unknown.
  static String get currentCurrency => instance?.currency ?? 'ETB';

  /// Currency for catalog prices (store / product screens). While a gift is
  /// being prepared the customer browses the recipient's market, so its
  /// currency wins over the customer's own market.
  static String get catalogCurrency =>
      GiftSession.instance.market?.currency ?? currentCurrency;

  static const String _prefsCodeKey = 'p3_market_code';
  static const String _prefsManualKey = 'p3_market_manual';

  GrowthRepository? _repository;
  List<Market> _markets = const [];
  Market? _selected;
  bool _manual = false;
  bool _started = false;
  bool _loaded = false;
  bool _resolving = false;
  bool _resolvedFromLocation = false;
  bool _disposed = false;

  GrowthRepository get _repo => _repository ??= GrowthRepository.create();

  /// Active markets (empty on a pre-Phase-3 backend).
  List<Market> get markets => _markets;

  /// True once `GET /api/markets` has answered (successfully or not).
  bool get loaded => _loaded;

  Market? get selected => _selected;

  String? get selectedCode => _selected?.code;

  /// Show the Settings market picker only with more than one active market.
  bool get canPick => _markets.length > 1;

  String get currency => _selected?.currency ?? 'ETB';

  /// Dial prefix for phone inputs, e.g. `+252` (null when unknown).
  String? get phonePrefix => _selected?.phonePrefix;

  Market? marketFor(String? code) {
    if (code == null) return null;
    final c = code.trim().toLowerCase();
    for (final m in _markets) {
      if (m.code == c) return m;
    }
    return null;
  }

  /// Starts loading. Safe to call twice.
  void start() {
    instance = this;
    if (_started) return;
    _started = true;
    unawaited(_init());
  }

  Future<void> _init() async {
    String? storedCode;
    var storedManual = false;
    try {
      final prefs = await SharedPreferences.getInstance();
      storedCode = prefs.getString(_prefsCodeKey);
      storedManual = prefs.getBool(_prefsManualKey) ?? false;
    } catch (_) {}

    List<Market> markets;
    try {
      markets = await _repo.fetchMarkets();
    } catch (e) {
      if (kDebugMode) debugPrint('Markets fetch failed: $e');
      markets = const [];
    }
    if (_disposed) return;
    _loaded = true;
    _markets = markets;
    if (markets.isEmpty) {
      notifyListeners();
      return;
    }

    final stored = marketFor(storedCode);
    if (stored != null) {
      _selected = stored;
      _manual = storedManual;
    }
    notifyListeners();

    if (!_manual) {
      await _resolveFrom(StartupLocationService.cached);
    }
    if (_selected != null) _refreshGrowthConfig();
  }

  /// Called by the splash once the startup GPS fix is known.
  Future<void> onStartupLocation(LocationData? location) async {
    if (!_loaded || _markets.isEmpty || _manual) return;
    await _resolveFrom(location);
  }

  Future<void> _resolveFrom(LocationData? location) async {
    if (location == null || _resolving || _resolvedFromLocation) return;
    _resolving = true;
    try {
      final resolved = await _repo.resolveMarket(
        lat: location.latitude,
        lng: location.longitude,
      );
      if (_disposed) return;
      _resolvedFromLocation = true;
      final match = marketFor(resolved?.code);
      if (match == null || _manual) return;
      if (match.code == _selected?.code) return;
      _selected = match;
      notifyListeners();
      await _persist(match.code, manual: false);
      _refreshGrowthConfig();
    } catch (e) {
      if (kDebugMode) debugPrint('Market resolve failed: $e');
    } finally {
      _resolving = false;
    }
  }

  /// Applies a market the user picked (after the server accepted it).
  Future<void> select(Market market) async {
    final match = marketFor(market.code) ?? market;
    _selected = match;
    _manual = true;
    if (!_disposed) notifyListeners();
    await _persist(match.code, manual: true);
    _refreshGrowthConfig();
  }

  Future<void> _persist(String code, {required bool manual}) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_prefsCodeKey, code);
      await prefs.setBool(_prefsManualKey, manual);
    } catch (_) {}
  }

  void _refreshGrowthConfig() {
    final growth = GrowthConfigController.instance;
    if (growth != null) unawaited(growth.refresh(force: true));
  }

  @override
  void dispose() {
    _disposed = true;
    if (identical(instance, this)) instance = null;
    super.dispose();
  }
}
