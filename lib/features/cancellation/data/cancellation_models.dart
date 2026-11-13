/// Cancellation penalty points.
///
/// Contract: docs/backend-multi-stop-and-cancellation-penalty.md (§2).
/// A customer cancel after a courier/driver is assigned (and before pickup)
/// adds penalty points. At `fine_threshold` a fine is issued and new bookings
/// are blocked until it is paid; at `ban_threshold` the account is suspended
/// for a while. Points decay over time. The server decides everything; the
/// app only shows what it is told.

enum CancellationStandingStatus { good, warning, fineDue, suspended }

CancellationStandingStatus _statusFrom(String? raw) {
  switch (raw?.trim().toLowerCase()) {
    case 'warning':
      return CancellationStandingStatus.warning;
    case 'fine_due':
      return CancellationStandingStatus.fineDue;
    case 'suspended':
      return CancellationStandingStatus.suspended;
    default:
      return CancellationStandingStatus.good;
  }
}

enum CancellationConsequence { none, fine, suspension }

CancellationConsequence _consequenceFrom(String? raw) {
  switch (raw?.trim().toLowerCase()) {
    case 'fine':
      return CancellationConsequence.fine;
    case 'suspension':
    case 'ban':
      return CancellationConsequence.suspension;
    default:
      return CancellationConsequence.none;
  }
}

/// An unpaid cancellation fine.
class CancellationFine {
  final int id;
  final double amount;
  final String currency;
  final DateTime? issuedAt;

  const CancellationFine({
    required this.id,
    required this.amount,
    this.currency = 'ETB',
    this.issuedAt,
  });

  static CancellationFine? fromJson(dynamic raw) {
    if (raw is! Map) return null;
    final id = _int(raw['id']);
    final amount = _double(raw['amount']);
    if (id == null || amount == null || amount <= 0) return null;
    return CancellationFine(
      id: id,
      amount: amount,
      currency: (_string(raw['currency']) ?? 'ETB').toUpperCase(),
      issuedAt: _date(raw['issued_at']),
    );
  }
}

/// `GET /api/customer/cancellation-standing` → `data`.
class CancellationStanding {
  final bool enabled;
  final int points;
  final int fineThreshold;
  final int banThreshold;
  final int pointsPerLateCancel;
  final int decayDays;
  final DateTime? nextDecayAt;
  final int nextDecayPoints;
  final CancellationStandingStatus status;
  final CancellationFine? fine;
  final DateTime? suspendedUntil;

  const CancellationStanding({
    this.enabled = false,
    this.points = 0,
    this.fineThreshold = 50,
    this.banThreshold = 100,
    this.pointsPerLateCancel = 10,
    this.decayDays = 30,
    this.nextDecayAt,
    this.nextDecayPoints = 0,
    this.status = CancellationStandingStatus.good,
    this.fine,
    this.suspendedUntil,
  });

  static const disabled = CancellationStanding();

  bool get hasFine => fine != null;
  bool get isSuspended =>
      status == CancellationStandingStatus.suspended &&
      (suspendedUntil == null || suspendedUntil!.isAfter(DateTime.now()));

  /// The customer cannot book or order right now.
  bool get isBlocked => hasFine || isSuspended;

  /// Worth a banner (warning, fine, or ban).
  bool get needsAttention =>
      enabled && status != CancellationStandingStatus.good;

  /// The threshold the customer is heading towards next.
  int get nextThreshold => points < fineThreshold ? fineThreshold : banThreshold;

  static CancellationStanding fromResponseBody(dynamic body) {
    final root = body is Map ? body : const {};
    final data = root['data'] is Map ? root['data'] as Map : root;
    if (data['enabled'] != true) return disabled;
    return CancellationStanding(
      enabled: true,
      points: _int(data['points']) ?? 0,
      fineThreshold: _int(data['fine_threshold']) ?? 50,
      banThreshold: _int(data['ban_threshold']) ?? 100,
      pointsPerLateCancel: _int(data['points_per_late_cancel']) ?? 10,
      decayDays: _int(data['decay_days']) ?? 30,
      nextDecayAt: _date(data['next_decay_at']),
      nextDecayPoints: _int(data['next_decay_points']) ?? 0,
      status: _statusFrom(_string(data['status'])),
      fine: CancellationFine.fromJson(data['fine']),
      suspendedUntil: _date(data['suspended_until']),
    );
  }
}

/// `GET .../cancellation-preview` → `data`.
class CancellationPreview {
  final bool canCancel;

  /// Why not (e.g. `ALREADY_PICKED_UP`), when [canCancel] is false.
  final String? reasonCode;
  final String? message;
  final int penaltyPoints;
  final int pointsBefore;
  final int pointsAfter;
  final int fineThreshold;
  final int banThreshold;
  final CancellationConsequence consequence;
  final double? fineAmount;
  final String currency;
  final int? suspensionDays;
  final double? refundAmount;

  const CancellationPreview({
    required this.canCancel,
    this.reasonCode,
    this.message,
    this.penaltyPoints = 0,
    this.pointsBefore = 0,
    this.pointsAfter = 0,
    this.fineThreshold = 50,
    this.banThreshold = 100,
    this.consequence = CancellationConsequence.none,
    this.fineAmount,
    this.currency = 'ETB',
    this.suspensionDays,
    this.refundAmount,
  });

  /// Free cancel (before a courier is assigned).
  bool get isFree => penaltyPoints <= 0;

  static CancellationPreview? fromResponseBody(dynamic body) {
    final root = body is Map ? body : null;
    if (root == null) return null;
    final data = root['data'] is Map ? root['data'] as Map : root;
    if (!data.containsKey('can_cancel')) return null;
    final before = _int(data['points_before']) ?? 0;
    final penalty = _int(data['penalty_points']) ?? 0;
    return CancellationPreview(
      canCancel: data['can_cancel'] == true,
      reasonCode: _string(data['reason_code']),
      message: _string(data['message']),
      penaltyPoints: penalty,
      pointsBefore: before,
      pointsAfter: _int(data['points_after']) ?? before + penalty,
      fineThreshold: _int(data['fine_threshold']) ?? 50,
      banThreshold: _int(data['ban_threshold']) ?? 100,
      consequence: _consequenceFrom(_string(data['consequence'])),
      fineAmount: _double(data['fine_amount']),
      currency: (_string(data['currency']) ?? 'ETB').toUpperCase(),
      suspensionDays: _int(data['suspension_days']),
      refundAmount: _double(data['refund_amount']),
    );
  }
}

/// `penalty` block in a successful cancel response.
class CancellationPenaltyOutcome {
  final int pointsAdded;
  final int pointsTotal;
  final CancellationConsequence consequence;
  final CancellationFine? fine;
  final DateTime? suspendedUntil;

  const CancellationPenaltyOutcome({
    this.pointsAdded = 0,
    this.pointsTotal = 0,
    this.consequence = CancellationConsequence.none,
    this.fine,
    this.suspendedUntil,
  });

  /// Reads `penalty` from `{penalty}` or `{data: {penalty}}`.
  static CancellationPenaltyOutcome? fromResponseBody(dynamic body) {
    if (body is! Map) return null;
    var raw = body['penalty'];
    if (raw is! Map && body['data'] is Map) raw = (body['data'] as Map)['penalty'];
    if (raw is! Map) return null;
    final added = _int(raw['points_added']) ?? 0;
    if (added <= 0) return null;
    return CancellationPenaltyOutcome(
      pointsAdded: added,
      pointsTotal: _int(raw['points_total']) ?? added,
      consequence: _consequenceFrom(_string(raw['consequence'])),
      fine: CancellationFine.fromJson(raw['fine']),
      suspendedUntil: _date(raw['suspended_until']),
    );
  }
}

int? _int(dynamic v) {
  if (v is int) return v;
  if (v is num) return v.toInt();
  return int.tryParse(v?.toString() ?? '');
}

double? _double(dynamic v) {
  if (v is num) return v.toDouble();
  return double.tryParse(v?.toString() ?? '');
}

String? _string(dynamic v) {
  final s = v?.toString().trim();
  return s == null || s.isEmpty ? null : s;
}

DateTime? _date(dynamic v) {
  final s = _string(v);
  return s == null ? null : DateTime.tryParse(s)?.toLocal();
}
