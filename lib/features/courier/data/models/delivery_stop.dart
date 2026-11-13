import 'package:hudhud_delivery/core/api/api_constants.dart';
import 'package:hudhud_delivery/core/api/api_service.dart';
import 'package:latlong2/latlong.dart';

/// Multi-stop on the classic `/services/delivery/*` endpoints.
///
/// Contract: docs/backend-multi-stop-and-cancellation-penalty.md (§1).
/// Stop 1 is the screen's normal drop-off; extra stops are added after it.
/// One pickup, up to `max_stops` drop-offs, always paid by the sender.

/// `GET /api/services/delivery/config` → `data.multi_stop`.
class DeliveryMultiStopConfig {
  final bool enabled;

  /// Total drop-offs allowed, stop 1 included (>= 2 when enabled).
  final int maxStops;

  const DeliveryMultiStopConfig({this.enabled = false, this.maxStops = 1});

  static const disabled = DeliveryMultiStopConfig();

  /// Extra drop-offs (after stop 1) the customer may still add.
  int get maxExtraStops => enabled ? (maxStops - 1).clamp(0, 20) : 0;

  static DeliveryMultiStopConfig fromResponseBody(dynamic body) {
    final root = body is Map ? body : const {};
    final data = root['data'] is Map ? root['data'] as Map : root;
    final raw = data['multi_stop'];
    if (raw is! Map) return disabled;
    final enabled = raw['enabled'] == true;
    final max = _int(raw['max_stops']) ?? 1;
    if (!enabled || max < 2) return disabled;
    return DeliveryMultiStopConfig(enabled: true, maxStops: max);
  }
}

/// Loads [DeliveryMultiStopConfig] once per app session. Never throws: an
/// older backend (404) or a network error means "multi-stop off".
class DeliveryConfigRepository {
  DeliveryConfigRepository._();

  static final DeliveryConfigRepository instance = DeliveryConfigRepository._();

  DeliveryMultiStopConfig? _cached;
  DateTime? _fetchedAt;
  Future<DeliveryMultiStopConfig>? _inFlight;

  /// Test hook.
  Future<dynamic> Function()? fetchOverride;

  DeliveryMultiStopConfig get cached =>
      _cached ?? DeliveryMultiStopConfig.disabled;

  Future<DeliveryMultiStopConfig> multiStop({bool force = false}) {
    final fresh = _fetchedAt != null &&
        DateTime.now().difference(_fetchedAt!) < const Duration(minutes: 10);
    if (!force && _cached != null && fresh) return Future.value(_cached);
    return _inFlight ??= _load().whenComplete(() => _inFlight = null);
  }

  Future<DeliveryMultiStopConfig> _load() async {
    try {
      final body = fetchOverride != null
          ? await fetchOverride!()
          : (await ApiService.instance.get(
              '${ApiConstants.baseUrl}${ApiConstants.deliveryConfig}',
            ))
              .data;
      _cached = DeliveryMultiStopConfig.fromResponseBody(body);
    } catch (_) {
      _cached = DeliveryMultiStopConfig.disabled;
    }
    _fetchedAt = DateTime.now();
    return _cached!;
  }
}

/// A drop-off the customer is adding while booking.
class DeliveryStopDraft {
  final String location;
  final LatLng position;
  final String receiverName;
  final String receiverPhone;
  final String note;

  const DeliveryStopDraft({
    required this.location,
    required this.position,
    this.receiverName = '',
    this.receiverPhone = '',
    this.note = '',
  });

  DeliveryStopDraft copyWith({
    String? location,
    LatLng? position,
    String? receiverName,
    String? receiverPhone,
    String? note,
  }) {
    return DeliveryStopDraft(
      location: location ?? this.location,
      position: position ?? this.position,
      receiverName: receiverName ?? this.receiverName,
      receiverPhone: receiverPhone ?? this.receiverPhone,
      note: note ?? this.note,
    );
  }

  bool get hasReceiver =>
      receiverName.trim().isNotEmpty && receiverPhone.trim().isNotEmpty;

  /// `stops[]` item for `POST /services/delivery/estimate`.
  Map<String, dynamic> toEstimateJson(int sequence) => {
        'sequence': sequence,
        'latitude': position.latitude,
        'longitude': position.longitude,
      };

  /// `stops[]` item for `POST /services/delivery/request`.
  /// [normalizePhone] turns the typed phone into the backend format.
  Map<String, dynamic> toRequestJson(
    int sequence, {
    String Function(String)? normalizePhone,
  }) {
    final n = note.trim();
    final phone = receiverPhone.trim();
    return {
      'sequence': sequence,
      'location': location,
      'latitude': position.latitude,
      'longitude': position.longitude,
      'receiver_name': receiverName.trim(),
      'receiver_phone': normalizePhone == null ? phone : normalizePhone(phone),
      if (n.isNotEmpty) 'note': n,
    };
  }
}

/// Stop states (server `delivery_stops.status`).
class DeliveryStopStatus {
  DeliveryStopStatus._();

  static const pending = 'pending';
  static const enRoute = 'en_route';
  static const arrived = 'arrived';
  static const delivered = 'delivered';
  static const failed = 'failed';
  static const skipped = 'skipped';

  static const done = {delivered, failed, skipped};
}

/// One drop-off of a delivery as returned by details / track / active /
/// list / live-tracking (`stops[]`).
class DeliveryStop {
  final int sequence;
  final String status;
  final String? location;
  final double? latitude;
  final double? longitude;
  final String? receiverName;
  final String? receiverPhone;

  /// Code this stop's receiver gives the courier (sender sees all of them).
  final String? deliveryCode;
  final DateTime? arrivedAt;
  final DateTime? deliveredAt;
  final String? failureReason;

  const DeliveryStop({
    required this.sequence,
    this.status = DeliveryStopStatus.pending,
    this.location,
    this.latitude,
    this.longitude,
    this.receiverName,
    this.receiverPhone,
    this.deliveryCode,
    this.arrivedAt,
    this.deliveredAt,
    this.failureReason,
  });

  bool get isDone => DeliveryStopStatus.done.contains(status);
  bool get isDelivered => status == DeliveryStopStatus.delivered;
  bool get isFailed =>
      status == DeliveryStopStatus.failed ||
      status == DeliveryStopStatus.skipped;

  LatLng? get position => latitude == null || longitude == null
      ? null
      : LatLng(latitude!, longitude!);

  static DeliveryStop? fromJson(dynamic raw) {
    if (raw is! Map) return null;
    final sequence = _int(raw['sequence']);
    if (sequence == null) return null;
    return DeliveryStop(
      sequence: sequence,
      status: (_string(raw['status']) ?? DeliveryStopStatus.pending)
          .toLowerCase(),
      location: _string(raw['location']) ?? _string(raw['address']),
      latitude: _double(raw['latitude']),
      longitude: _double(raw['longitude']),
      receiverName: _string(raw['receiver_name']) ??
          _string(raw['recipient_name']),
      receiverPhone: _string(raw['receiver_phone']) ??
          _string(raw['recipient_phone']),
      deliveryCode: _string(raw['delivery_code']) ??
          _string(raw['otp']) ??
          _string(raw['handover_code']),
      arrivedAt: _date(raw['arrived_at']),
      deliveredAt: _date(raw['delivered_at']),
      failureReason: _string(raw['failure_reason']),
    );
  }
}

/// Stops of a delivery map, sorted by sequence. Empty for single-drop
/// deliveries (or backends without multi-stop). Reads `stops`, or
/// `data.stops` / `delivery.stops` when the caller passes a whole response.
List<DeliveryStop> parseDeliveryStops(Map<String, dynamic>? delivery) {
  if (delivery == null) return const [];
  dynamic raw = delivery['stops'];
  if (raw is! List) {
    for (final key in const ['data', 'delivery']) {
      final nested = delivery[key];
      if (nested is Map && nested['stops'] is List) {
        raw = nested['stops'];
        break;
      }
    }
  }
  if (raw is! List) return const [];
  final stops = raw.map(DeliveryStop.fromJson).whereType<DeliveryStop>().toList()
    ..sort((a, b) => a.sequence.compareTo(b.sequence));
  return stops;
}

/// True when the delivery has more than one drop-off.
bool isMultiStopDelivery(Map<String, dynamic>? delivery) =>
    parseDeliveryStops(delivery).length > 1;

/// The stop the courier is heading to: server `current_stop_sequence`, else
/// the first stop that is not done. Null when all are done / no stops.
DeliveryStop? currentDeliveryStop(
  Map<String, dynamic>? delivery, [
  List<DeliveryStop>? stops,
]) {
  final list = stops ?? parseDeliveryStops(delivery);
  if (list.isEmpty) return null;
  final seq = _int(delivery?['current_stop_sequence']);
  if (seq != null) {
    for (final s in list) {
      if (s.sequence == seq) return s;
    }
  }
  for (final s in list) {
    if (!s.isDone) return s;
  }
  return null;
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
