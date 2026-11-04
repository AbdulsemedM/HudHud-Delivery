import 'dart:async';

import 'package:flutter/foundation.dart';

import 'package:hudhud_delivery/app/services/auth_service.dart';

import 'data/growth_repository.dart';
import 'data/models/plus.dart';

/// Cached HudHud Plus status (`GET /api/customer/plus`, Phase 3 §5).
///
/// Customer-only: guests always get [PlusStatus.disabled] and no request is
/// made. Any failure keeps the last good status (or disabled), so every
/// Plus entry point stays hidden on an older backend.
class PlusController extends ChangeNotifier {
  PlusController._();

  static final PlusController instance = PlusController._();

  static const Duration _minRefreshInterval = Duration(minutes: 2);

  GrowthRepository? _repository;
  PlusStatus _status = PlusStatus.disabled;
  DateTime? _lastFetch;
  Future<void>? _inFlight;

  GrowthRepository get _repo => _repository ??= GrowthRepository.create();

  PlusStatus get status => _status;

  /// Fetches when stale (or always with [force]). Never throws.
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
      if (!await AuthService().isAuthenticated()) {
        _lastFetch = DateTime.now();
        _set(PlusStatus.disabled);
        return;
      }
      final next = await _repo.fetchPlus();
      _lastFetch = DateTime.now();
      // Keep the last good status when a refresh fails.
      if (!next.loaded && _status.loaded) return;
      _set(next);
    } catch (e) {
      if (kDebugMode) debugPrint('Plus status fetch failed: $e');
    }
  }

  void _set(PlusStatus next) {
    _status = next;
    notifyListeners();
  }

  /// Clears the cache (e.g. on logout).
  void reset() {
    _lastFetch = null;
    _set(PlusStatus.disabled);
  }
}
