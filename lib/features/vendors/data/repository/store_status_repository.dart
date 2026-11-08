import 'package:hudhud_delivery/core/api/api_service.dart';
import 'package:hudhud_delivery/features/vendors/data/data_provider/vendors_data_provider.dart';
import 'package:hudhud_delivery/features/vendors/data/models/store_status.dart';

/// Looks up a store's live status (`GET /api/public/vendors/{id}`), with a
/// short in-memory cache so the store page, product page and cart do not
/// refetch it on every tap.
///
/// Never throws: on any failure it returns the last known status, or null
/// (unknown — callers then behave as before and the server still refuses
/// the order with STORE_CLOSED / STORE_PAUSED if needed).
class StoreStatusRepository {
  StoreStatusRepository({
    Future<Map<String, dynamic>> Function(int vendorId)? fetchVendor,
    DateTime Function()? clock,
    this.ttl = const Duration(seconds: 60),
  })  : _fetchVendor = fetchVendor ??
            VendorsDataProvider(apiService: ApiService.instance).getVendorById,
        _clock = clock ?? DateTime.now;

  static final StoreStatusRepository instance = StoreStatusRepository();

  final Future<Map<String, dynamic>> Function(int vendorId) _fetchVendor;
  final DateTime Function() _clock;
  final Duration ttl;

  final Map<int, _Entry> _cache = {};

  /// Cached status without a network call (null when never seen).
  StoreStatus? peek(int vendorId) => _cache[vendorId]?.status;

  /// Records a status seen elsewhere (vendor list, a STORE_* error).
  void remember(int vendorId, StoreStatus? status) {
    if (vendorId <= 0 || status == null) return;
    _cache[vendorId] = _Entry(status, _clock());
  }

  /// Drops the cached status, e.g. after a pull-to-refresh.
  void forget(int vendorId) => _cache.remove(vendorId);

  Future<StoreStatus?> statusFor(int vendorId, {bool force = false}) async {
    if (vendorId <= 0) return null;
    final cached = _cache[vendorId];
    if (!force && cached != null && _clock().difference(cached.at) < ttl) {
      return cached.status;
    }
    try {
      final response = await _fetchVendor(vendorId);
      if (response['statusCode'] != 200) return cached?.status;
      final body = response['data'];
      final data = body is Map && body['data'] is Map ? body['data'] : body;
      if (data is! Map) return cached?.status;
      final status = StoreStatus.fromVendorJson(data) ?? StoreStatus.open;
      _cache[vendorId] = _Entry(status, _clock());
      return status;
    } catch (_) {
      return cached?.status;
    }
  }
}

class _Entry {
  const _Entry(this.status, this.at);

  final StoreStatus status;
  final DateTime at;
}
