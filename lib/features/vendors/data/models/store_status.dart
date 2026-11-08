import 'package:flutter/foundation.dart';

/// Whether a store takes orders right now (merchant store controls).
enum StoreState {
  open,

  /// Busy mode: the merchant paused new orders (server state `paused`).
  busy,

  /// Outside opening hours or a holiday closure.
  closed,
}

/// `store_status` block on public vendor JSON and on `STORE_CLOSED` /
/// `STORE_PAUSED` 422 errors (StoreAvailabilityService::status):
/// `{state: open|paused|closed, accepting_orders, opens_at, resumes_at,
/// closes_at, reason: holiday|outside_hours|busy, message}`.
///
/// Times are ISO-8601 with an offset; they are kept as UTC instants and
/// shown in device local time. A store with no block is treated as open
/// (pre-store-controls backend), exactly as before.
@immutable
class StoreStatus {
  const StoreStatus({
    required this.state,
    this.opensAt,
    this.resumesAt,
    this.closesAt,
    this.reason,
    this.message,
  });

  static const StoreStatus open = StoreStatus(state: StoreState.open);

  final StoreState state;

  /// Next opening (closed stores).
  final DateTime? opensAt;

  /// End of busy mode (null = paused until the merchant resumes).
  final DateTime? resumesAt;

  /// End of the current opening window (open stores with hours).
  final DateTime? closesAt;

  /// `holiday`, `outside_hours` or `busy`.
  final String? reason;

  /// Server text (English); the UI uses localized copy.
  final String? message;

  bool get acceptingOrders => state == StoreState.open;
  bool get isClosed => state == StoreState.closed;
  bool get isBusy => state == StoreState.busy;
  bool get isHoliday => reason == 'holiday';

  /// Parses a `store_status` map; null when [raw] is not one.
  static StoreStatus? tryParse(dynamic raw) {
    if (raw is! Map) return null;
    final rawState = raw['state']?.toString().trim().toLowerCase();
    final code = raw['code']?.toString().trim().toUpperCase();
    final accepting = raw['accepting_orders'];
    StoreState? state;
    switch (rawState) {
      case 'open':
        state = StoreState.open;
        break;
      case 'paused':
      case 'busy':
        state = StoreState.busy;
        break;
      case 'closed':
        state = StoreState.closed;
        break;
    }
    state ??= code == 'STORE_PAUSED'
        ? StoreState.busy
        : code == 'STORE_CLOSED'
            ? StoreState.closed
            : null;
    if (state == null && accepting is bool) {
      state = accepting ? StoreState.open : StoreState.closed;
    }
    if (state == null) return null;
    final reason = raw['reason']?.toString().trim();
    final message = raw['message']?.toString().trim();
    return StoreStatus(
      state: state,
      opensAt: _date(raw['opens_at']),
      resumesAt: _date(raw['resumes_at']),
      closesAt: _date(raw['closes_at']),
      reason: reason == null || reason.isEmpty ? null : reason,
      message: message == null || message.isEmpty ? null : message,
    );
  }

  /// Store status on a vendor payload: top level (`/restaurants/{id}`) or
  /// on the nested vendor profile (`/public/vendors` returns the owner user
  /// with `vendor_profile`).
  static StoreStatus? fromVendorJson(Map<dynamic, dynamic>? json) {
    if (json == null) return null;
    final direct = tryParse(json['store_status']);
    if (direct != null) return direct;
    for (final key in const ['vendor_profile', 'vendorProfile', 'vendor']) {
      final nested = json[key];
      if (nested is Map) {
        final status = tryParse(nested['store_status']);
        if (status != null) return status;
      }
    }
    return null;
  }

  static DateTime? _date(dynamic raw) {
    final text = raw?.toString().trim();
    if (text == null || text.isEmpty) return null;
    return DateTime.tryParse(text)?.toUtc();
  }

  @override
  bool operator ==(Object other) =>
      other is StoreStatus &&
      other.state == state &&
      other.opensAt == opensAt &&
      other.resumesAt == resumesAt &&
      other.closesAt == closesAt &&
      other.reason == reason;

  @override
  int get hashCode => Object.hash(state, opensAt, resumesAt, closesAt, reason);
}
