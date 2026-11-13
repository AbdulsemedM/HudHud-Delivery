/// Phase 10 parcel booking v2 (Yango-style) client models.
///
/// All parsing is defensive: a missing or malformed field never throws, so an
/// older backend simply reports `enabled: false` and the app keeps the
/// existing courier flow.
library;

double? _double(dynamic value) {
  if (value is num) return value.toDouble();
  if (value is String) return double.tryParse(value.trim());
  return null;
}

int? _int(dynamic value) {
  if (value is int) return value;
  if (value is num) return value.toInt();
  if (value is String) return int.tryParse(value.trim());
  return null;
}

String? _string(dynamic value) {
  if (value == null) return null;
  final text = value.toString().trim();
  return text.isEmpty ? null : text;
}

Map<String, dynamic>? _map(dynamic value) =>
    value is Map ? Map<String, dynamic>.from(value) : null;

Map<String, dynamic>? _data(dynamic body) {
  final root = _map(body);
  if (root == null) return null;
  return _map(root['data']) ?? root;
}

/// Item sizes and the vehicle the city uses for each.
class ParcelSizeOption {
  final String size;
  final String? vehicleType;
  final bool available;

  const ParcelSizeOption({
    required this.size,
    this.vehicleType,
    this.available = true,
  });
}

/// `GET /api/parcels/config`.
class ParcelV2Config {
  final bool enabled;
  final String? market;
  final String currency;
  final int quoteTtlMinutes;
  final int handoverCodeDigits;
  final List<ParcelSizeOption> sizes;
  final List<String> categories;
  final List<String> paymentMethods;
  final bool recipientPaysEnabled;
  final bool sellerCodEnabled;
  final bool requireDeliveryPhoto;
  final double cancellationFeeAfterAssign;
  final bool cityScopeEnforced;

  /// Phase 11: drop-offs per parcel (1 while multi-stop is off).
  final int maxDropoffs;
  final bool payAtPickupEnabled;
  final bool cashCancellationFeeEnabled;
  final ParcelDuesSummary? outstandingDues;

  const ParcelV2Config({
    this.enabled = false,
    this.market,
    this.currency = 'ETB',
    this.quoteTtlMinutes = 10,
    this.handoverCodeDigits = 4,
    this.sizes = const [],
    this.categories = const [],
    this.paymentMethods = const [],
    this.recipientPaysEnabled = false,
    this.sellerCodEnabled = false,
    this.requireDeliveryPhoto = false,
    this.cancellationFeeAfterAssign = 0,
    this.cityScopeEnforced = false,
    this.maxDropoffs = 1,
    this.payAtPickupEnabled = false,
    this.cashCancellationFeeEnabled = false,
    this.outstandingDues,
  });

  static const ParcelV2Config disabled = ParcelV2Config();

  bool get multiStopEnabled => maxDropoffs > 1;

  factory ParcelV2Config.fromResponseBody(dynamic body) {
    final data = _data(body);
    if (data == null) return disabled;
    final sizes = <ParcelSizeOption>[];
    final rawSizes = data['sizes'];
    if (rawSizes is List) {
      for (final raw in rawSizes) {
        final m = _map(raw);
        final size = _string(m?['size']);
        if (m == null || size == null) continue;
        sizes.add(ParcelSizeOption(
          size: size,
          vehicleType: _string(m['vehicle_type']),
          available: m['available'] != false,
        ));
      }
    }
    List<String> strings(dynamic raw) => raw is List
        ? raw.map(_string).whereType<String>().toList()
        : const <String>[];
    return ParcelV2Config(
      enabled: data['enabled'] == true,
      market: _string(data['market']),
      currency: (_string(data['currency']) ?? 'ETB').toUpperCase(),
      quoteTtlMinutes: _int(data['quote_ttl_minutes']) ?? 10,
      handoverCodeDigits: _int(data['handover_code_digits']) ?? 4,
      sizes: sizes,
      categories: strings(data['categories']),
      paymentMethods: strings(data['payment_methods']),
      recipientPaysEnabled: data['recipient_pays_enabled'] == true,
      sellerCodEnabled: data['seller_cod_enabled'] == true,
      requireDeliveryPhoto: data['require_delivery_photo'] == true,
      cancellationFeeAfterAssign:
          _double(data['cancellation_fee_after_assign']) ?? 0,
      cityScopeEnforced: data['city_scope_enforced'] == true,
      maxDropoffs: (_int(data['max_dropoffs']) ?? 1).clamp(1, 3),
      payAtPickupEnabled: data['pay_at_pickup_enabled'] == true,
      cashCancellationFeeEnabled:
          data['cash_cancellation_fee_enabled'] == true,
      outstandingDues: ParcelDuesSummary.fromJson(data['outstanding_dues']),
    );
  }

  ParcelSizeOption? sizeOption(String size) {
    for (final option in sizes) {
      if (option.size == size) return option;
    }
    return null;
  }
}

/// Phase 11: money the customer still owes (e.g. a cash cancellation fee).
class ParcelDuesSummary {
  final int count;

  /// currency => amount
  final Map<String, double> amounts;

  const ParcelDuesSummary({this.count = 0, this.amounts = const {}});

  bool get hasDues => count > 0 && amounts.values.any((a) => a > 0);

  static ParcelDuesSummary? fromJson(dynamic raw) {
    final m = _map(raw);
    if (m == null) return null;
    final amounts = <String, double>{};
    final list = m['amounts'];
    if (list is List) {
      for (final item in list) {
        final row = _map(item);
        final currency = _string(row?['currency']);
        final amount = _double(row?['amount']);
        if (currency != null && amount != null) {
          amounts[currency.toUpperCase()] = amount;
        }
      }
    }
    return ParcelDuesSummary(count: _int(m['count']) ?? 0, amounts: amounts);
  }
}

/// `POST /api/parcels/quote` — a server price locked until [expiresAt].
class ParcelQuote {
  final String quoteId;
  final double amount;
  final String currency;
  final String? vehicleType;
  final String? itemSize;
  final double? distanceKm;
  final int? durationMinutes;
  final DateTime expiresAt;

  /// Phase 11: drop-offs priced in this quote (whole route, in order).
  final int stopCount;

  const ParcelQuote({
    required this.quoteId,
    required this.amount,
    required this.currency,
    required this.expiresAt,
    this.vehicleType,
    this.itemSize,
    this.distanceKm,
    this.durationMinutes,
    this.stopCount = 1,
  });

  /// [receivedAt] anchors the countdown to the device clock (server
  /// `expires_in_seconds`), so a skewed phone clock cannot extend the lock.
  static ParcelQuote? fromResponseBody(dynamic body, {DateTime? receivedAt}) {
    final data = _data(body);
    final id = _string(data?['quote_id']);
    final amount = _double(data?['amount']);
    if (data == null || id == null || amount == null) return null;
    final now = receivedAt ?? DateTime.now();
    final seconds = _int(data['expires_in_seconds']);
    final expires = seconds != null
        ? now.add(Duration(seconds: seconds))
        : (DateTime.tryParse(data['expires_at']?.toString() ?? '')
                ?.toLocal() ??
            now.add(const Duration(minutes: 10)));
    return ParcelQuote(
      quoteId: id,
      amount: amount,
      currency: (_string(data['currency']) ?? 'ETB').toUpperCase(),
      vehicleType: _string(data['vehicle_type']),
      itemSize: _string(data['item_size']),
      distanceKm: _double(data['distance_km']),
      durationMinutes: _int(data['duration_minutes']),
      expiresAt: expires,
      stopCount: _int(data['stop_count']) ?? 1,
    );
  }

  Duration remaining([DateTime? now]) {
    final left = expiresAt.difference(now ?? DateTime.now());
    return left.isNegative ? Duration.zero : left;
  }

  bool isExpired([DateTime? now]) => remaining(now) == Duration.zero;
}

/// "mm:ss" for the price-lock countdown.
String formatQuoteCountdown(Duration left) {
  final minutes = left.inMinutes;
  final seconds = left.inSeconds % 60;
  return '$minutes:${seconds.toString().padLeft(2, '0')}';
}

/// Fee preview (`GET /api/parcels/{id}/cancellation`, also in the detail).
class ParcelCancellationPreview {
  final bool canCancel;
  final String? code;
  final double fee;
  final String? currency;
  final double refund;

  /// Phase 11: `payment` | `wallet_or_outstanding_balance` | `not_collected`.
  final String? feeChargedTo;

  const ParcelCancellationPreview({
    required this.canCancel,
    this.code,
    this.fee = 0,
    this.currency,
    this.refund = 0,
    this.feeChargedTo,
  });

  bool get hasFee => fee > 0;

  /// A cash parcel's fee comes from the wallet or becomes a balance owed.
  bool get chargedToWalletOrBalance =>
      feeChargedTo == 'wallet_or_outstanding_balance';

  static ParcelCancellationPreview? fromJson(dynamic raw) {
    final m = _map(raw);
    if (m == null) return null;
    return ParcelCancellationPreview(
      canCancel: m['can_cancel'] == true,
      code: _string(m['code']),
      fee: _double(m['fee']) ?? 0,
      currency: _string(m['currency']),
      refund: _double(m['refund']) ?? 0,
      feeChargedTo: _string(m['fee_charged_to']),
    );
  }
}

/// Customer-facing statuses (server ParcelStatus).
class ParcelV2Status {
  ParcelV2Status._();

  static const awaitingPayment = 'awaiting_payment';
  static const scheduled = 'scheduled';
  static const searching = 'searching';
  static const courierAssigned = 'courier_assigned';
  static const atPickup = 'at_pickup';
  static const pickedUp = 'picked_up';
  static const atDropoff = 'at_dropoff';
  static const delivered = 'delivered';
  static const cancelled = 'cancelled';
  static const failed = 'failed';
  static const returned = 'returned';

  static const terminal = {delivered, cancelled, failed, returned};
}

/// Phase 11 per-drop-off states (server package_delivery_stops.status).
class ParcelStopStatus {
  ParcelStopStatus._();

  static const pending = 'pending';
  static const arrived = 'arrived';
  static const delivered = 'delivered';
  static const failed = 'failed';
  static const returned = 'returned';
}

/// One drop-off of a multi-stop parcel as the sender sees it.
class ParcelV2Stop {
  final int sequence;
  final String status;
  final String? address;
  final String? recipientName;
  final String? recipientPhone;
  final bool recipientIsMe;
  final String? handoverCode;
  final bool handoverVerified;
  final String? trackingUrl;

  const ParcelV2Stop({
    required this.sequence,
    this.status = ParcelStopStatus.pending,
    this.address,
    this.recipientName,
    this.recipientPhone,
    this.recipientIsMe = false,
    this.handoverCode,
    this.handoverVerified = false,
    this.trackingUrl,
  });

  bool get isDone =>
      status == ParcelStopStatus.delivered ||
      status == ParcelStopStatus.failed ||
      status == ParcelStopStatus.returned;

  /// `stops[]` item in the classic delivery-map shape (see
  /// `features/courier/data/models/delivery_stop.dart`), so the legacy
  /// finding / tracking screens can show v2 multi-drop parcels.
  Map<String, dynamic> toLegacyStopMap() {
    const statusMap = {
      ParcelStopStatus.pending: 'pending',
      ParcelStopStatus.arrived: 'arrived',
      ParcelStopStatus.delivered: 'delivered',
      ParcelStopStatus.failed: 'failed',
      ParcelStopStatus.returned: 'failed',
    };
    return {
      'sequence': sequence,
      'status': statusMap[status] ?? 'pending',
      if (address != null) 'location': address,
      if (recipientName != null) 'receiver_name': recipientName,
      if (recipientPhone != null) 'receiver_phone': recipientPhone,
      if (handoverCode != null && !handoverVerified)
        'delivery_code': handoverCode,
    };
  }

  static ParcelV2Stop? fromJson(dynamic raw) {
    final m = _map(raw);
    final sequence = _int(m?['sequence']);
    if (m == null || sequence == null) return null;
    final handover = _map(m['handover']);
    return ParcelV2Stop(
      sequence: sequence,
      status: _string(m['status']) ?? ParcelStopStatus.pending,
      address: _string(m['address']),
      recipientName: _string(m['recipient_name']),
      recipientPhone: _string(m['recipient_phone']),
      recipientIsMe: m['recipient_is_me'] == true,
      handoverCode: _string(handover?['code']),
      handoverVerified: handover?['verified'] == true,
      trackingUrl: _string(m['tracking_url']),
    );
  }
}

/// `GET /api/parcels/{id}` — the subset the app shows.
class ParcelV2Parcel {
  final int id;
  final int version;
  final String status;
  final int step;
  final String? trackingNumber;
  final double amount;
  final String? currency;
  final String? handoverCode;
  final int handoverDigits;
  final bool handoverVerified;
  final String? trackingUrl;
  final int? etaMinutes;
  final ParcelCancellationPreview? cancellation;

  /// Phase 11.
  final List<ParcelV2Stop> stops;
  final int? currentStop;
  final String? paymentTiming;
  final bool collectedAtPickup;

  const ParcelV2Parcel({
    required this.id,
    required this.status,
    this.version = 2,
    this.step = 0,
    this.trackingNumber,
    this.amount = 0,
    this.currency,
    this.handoverCode,
    this.handoverDigits = 4,
    this.handoverVerified = false,
    this.trackingUrl,
    this.etaMinutes,
    this.cancellation,
    this.stops = const [],
    this.currentStop,
    this.paymentTiming,
    this.collectedAtPickup = false,
  });

  bool get isV2 => version >= 2;
  bool get isMultiStop => stops.length > 1;
  bool get paysAtPickup => paymentTiming == 'pickup';
  bool get isTerminal => ParcelV2Status.terminal.contains(status);

  static ParcelV2Parcel? fromJson(dynamic raw) {
    final m = _map(raw);
    final id = _int(m?['id']);
    if (m == null || id == null) return null;
    final price = _map(m['price']);
    final handover = _map(m['handover']);
    final payment = _map(m['payment']);
    final stops = <ParcelV2Stop>[];
    final rawStops = m['stops'];
    if (rawStops is List) {
      for (final raw in rawStops) {
        final stop = ParcelV2Stop.fromJson(raw);
        if (stop != null) stops.add(stop);
      }
      stops.sort((a, b) => a.sequence.compareTo(b.sequence));
    }
    return ParcelV2Parcel(
      id: id,
      version: _int(m['version']) ?? 1,
      status: _string(m['status']) ?? ParcelV2Status.searching,
      step: _int(m['step']) ?? 0,
      trackingNumber: _string(m['tracking_number']),
      amount: _double(price?['amount']) ?? 0,
      currency: _string(price?['currency']),
      handoverCode: _string(handover?['code']),
      handoverDigits: _int(handover?['digits']) ?? 4,
      handoverVerified: handover?['verified'] == true,
      trackingUrl: _string(m['tracking_url']),
      etaMinutes: _int(m['eta_minutes']),
      cancellation: ParcelCancellationPreview.fromJson(m['cancellation']),
      stops: stops,
      currentStop: _int(m['current_stop']),
      paymentTiming: _string(payment?['timing']),
      collectedAtPickup: payment?['collected_at_pickup'] == true,
    );
  }

  static ParcelV2Parcel? fromResponseBody(dynamic body) {
    final root = _map(body);
    if (root == null) return null;
    return fromJson(root['parcel'] ?? root['data']);
  }

  /// The minimal delivery map the existing finding / tracking screens read.
  Map<String, dynamic> toLegacyDeliveryMap({
    required double pickupLat,
    required double pickupLng,
    required double dropoffLat,
    required double dropoffLng,
    required String pickupLocation,
    required String dropoffLocation,
    String? vehicleType,
    String? packageType,
    String? paymentMethod,
    String? recipientName,
    String? recipientPhone,
    List<List<double>>? stopCoordinates,
  }) {
    return {
      'id': id,
      'status': status == ParcelV2Status.searching ? 'pending' : status,
      'tracking_number': trackingNumber,
      'pickup_latitude': pickupLat,
      'pickup_longitude': pickupLng,
      'dropoff_latitude': dropoffLat,
      'dropoff_longitude': dropoffLng,
      'pickup_location': pickupLocation,
      'dropoff_location': dropoffLocation,
      'vehicle_type': vehicleType,
      'package_type': packageType,
      'payment_method': paymentMethod,
      'receiver_name': recipientName,
      'receiver_phone': recipientPhone,
      if (isMultiStop)
        'stops': [
          for (var i = 0; i < stops.length; i++)
            {
              ...stops[i].toLegacyStopMap(),
              // The parcel API has no stop coordinates; the booking draft
              // does (same order as `stops`).
              if (stopCoordinates != null && i < stopCoordinates.length) ...{
                'latitude': stopCoordinates[i][0],
                'longitude': stopCoordinates[i][1],
              },
            },
        ],
      if (isMultiStop && currentStop != null)
        'current_stop_sequence': currentStop,
    };
  }
}

/// Address extras a courier needs (building, floor, …).
class ParcelAddressDetails {
  final String building;
  final String floor;
  final String apartment;
  final String landmark;

  const ParcelAddressDetails({
    this.building = '',
    this.floor = '',
    this.apartment = '',
    this.landmark = '',
  });

  Map<String, dynamic> toJson(String formattedAddress) {
    final out = <String, dynamic>{'formatted_address': formattedAddress};
    void put(String key, String value) {
      final v = value.trim();
      if (v.isNotEmpty) out[key] = v;
    }

    put('building', building);
    put('floor', floor);
    put('apartment', apartment);
    put('landmark', landmark);
    return out;
  }
}

/// Phase 11: a drop-off after the first one (each with its own recipient).
class ParcelStopDraft {
  final String location;
  final double lat;
  final double lng;
  final ParcelAddressDetails details;
  final bool recipientIsMe;
  final String recipientName;
  final String recipientPhone;
  final String note;

  const ParcelStopDraft({
    required this.location,
    required this.lat,
    required this.lng,
    this.details = const ParcelAddressDetails(),
    this.recipientIsMe = false,
    this.recipientName = '',
    this.recipientPhone = '',
    this.note = '',
  });

  Map<String, dynamic> toJson() {
    final n = note.trim();
    return {
      'location': location,
      'latitude': lat,
      'longitude': lng,
      'address': details.toJson(location),
      'recipient_is_me': recipientIsMe,
      if (!recipientIsMe) 'recipient_name': recipientName.trim(),
      if (!recipientIsMe) 'recipient_phone': recipientPhone.trim(),
      if (n.isNotEmpty) 'note': n,
    };
  }
}

/// Everything the booking form collected; builds the API bodies.
class ParcelBookingDraft {
  final String pickupLocation;
  final double pickupLat;
  final double pickupLng;
  final ParcelAddressDetails pickupDetails;
  final String dropoffLocation;
  final double dropoffLat;
  final double dropoffLng;
  final ParcelAddressDetails dropoffDetails;
  final bool recipientIsMe;
  final String recipientName;
  final String recipientPhone;
  final String category;
  final String size;
  final String description;
  final double? itemValue;
  final String courierNote;
  final String paymentMethod;
  final String? paymentPhone;
  final bool recipientPays;
  final double? sellerCodAmount;
  final DateTime? scheduledPickup;
  final String? marketCode;

  /// Phase 11: drop-offs after the first (the dropoff* / recipient* fields).
  final List<ParcelStopDraft> extraStops;

  /// Phase 11: sender pays the courier in cash at pickup.
  final bool payAtPickup;

  /// Phase 11: courier note for stop 1 of a multi-stop parcel.
  final String dropoffNote;

  const ParcelBookingDraft({
    required this.pickupLocation,
    required this.pickupLat,
    required this.pickupLng,
    required this.dropoffLocation,
    required this.dropoffLat,
    required this.dropoffLng,
    this.pickupDetails = const ParcelAddressDetails(),
    this.dropoffDetails = const ParcelAddressDetails(),
    this.recipientIsMe = false,
    this.recipientName = '',
    this.recipientPhone = '',
    this.category = 'parcel',
    this.size = 'small',
    this.description = '',
    this.itemValue,
    this.courierNote = '',
    this.paymentMethod = 'wallet',
    this.paymentPhone,
    this.recipientPays = false,
    this.sellerCodAmount,
    this.scheduledPickup,
    this.marketCode,
    this.extraStops = const [],
    this.payAtPickup = false,
    this.dropoffNote = '',
  });

  bool get isMultiStop => extraStops.isNotEmpty;

  /// Multi-stop parcels are always paid by the sender.
  bool get sellerCod =>
      !isMultiStop && sellerCodAmount != null && sellerCodAmount! > 0;
  bool get _recipientPaysEffective => !isMultiStop && recipientPays;

  /// Cash at pickup: chosen, and always for a multi-stop cash parcel.
  bool get paysAtPickup =>
      !sellerCod &&
      !_recipientPaysEffective &&
      paymentMethod == 'cash' &&
      (payAtPickup || isMultiStop);

  /// The method the server receives.
  String get effectivePaymentMethod =>
      _recipientPaysEffective || sellerCod ? 'cash' : paymentMethod;

  ParcelStopDraft get firstStop => ParcelStopDraft(
        location: dropoffLocation,
        lat: dropoffLat,
        lng: dropoffLng,
        details: dropoffDetails,
        recipientIsMe: recipientIsMe,
        recipientName: recipientName,
        recipientPhone: recipientPhone,
        note: dropoffNote,
      );

  List<ParcelStopDraft> get allStops => [firstStop, ...extraStops];

  /// Where the route ends (the legacy screens' drop-off).
  ParcelStopDraft get lastStop => allStops.last;

  Map<String, dynamic> quoteBody() {
    return {
      'pickup_location': pickupLocation,
      'pickup_latitude': pickupLat,
      'pickup_longitude': pickupLng,
      if (!isMultiStop) 'dropoff_latitude': dropoffLat,
      if (!isMultiStop) 'dropoff_longitude': dropoffLng,
      if (isMultiStop)
        'stops': [
          for (final stop in allStops)
            {'latitude': stop.lat, 'longitude': stop.lng},
        ],
      'item_size': size,
      if (scheduledPickup != null)
        'scheduled_pickup': scheduledPickup!.toUtc().toIso8601String(),
      if (marketCode != null) 'market_code': marketCode,
    };
  }

  Map<String, dynamic> bookBody(String quoteId) {
    final note = courierNote.trim();
    final desc = description.trim();
    final phone = paymentPhone?.trim();
    final recipientSide = _recipientPaysEffective || sellerCod;
    return {
      'quote_id': quoteId,
      'pickup_location': pickupLocation,
      'pickup_latitude': pickupLat,
      'pickup_longitude': pickupLng,
      'pickup_address': pickupDetails.toJson(pickupLocation),
      if (!isMultiStop) ...{
        'dropoff_location': dropoffLocation,
        'dropoff_latitude': dropoffLat,
        'dropoff_longitude': dropoffLng,
        'dropoff_address': dropoffDetails.toJson(dropoffLocation),
        'recipient_is_me': recipientIsMe,
        if (!recipientIsMe) 'recipient_name': recipientName.trim(),
        if (!recipientIsMe) 'recipient_phone': recipientPhone.trim(),
      },
      if (isMultiStop)
        'stops': [for (final stop in allStops) stop.toJson()],
      'item_category': category,
      'item_size': size,
      if (desc.isNotEmpty) 'item_description': desc,
      if (itemValue != null) 'item_value': itemValue,
      if (note.isNotEmpty) 'courier_note': note,
      // "Recipient pays" and seller COD are always cash at drop-off.
      'payment_method': effectivePaymentMethod,
      if (paysAtPickup) 'payment_timing': 'pickup',
      if (phone != null && phone.isNotEmpty) 'payment_phone': phone,
      'payer': recipientSide ? 'recipient' : 'sender',
      if (sellerCod)
        'seller_cod': {'enabled': true, 'amount': sellerCodAmount},
      if (scheduledPickup != null)
        'scheduled_pickup': scheduledPickup!.toUtc().toIso8601String(),
      if (marketCode != null) 'market_code': marketCode,
    };
  }
}

/// Server error codes the booking screen explains in its own words.
enum ParcelErrorKind {
  outsideArea,
  crossCity,
  otherCity,
  quoteExpired,
  quoteChanged,
  sizeNotSupported,
  paymentNotAvailable,
  insufficientWallet,
  feeConfirmation,
  pickedUp,
  multiStopDisabled,
  tooManyStops,
  multiStopSenderPays,
  multiStopCashAtPickup,
  payAtPickupUnavailable,

  /// Cash refused while the customer owes a balance (OUTSTANDING_DUES).
  outstandingDues,
  other,
}

ParcelErrorKind parcelErrorKind(String? code, {String? message}) {
  switch (code) {
    case 'CITY_OUTSIDE_SERVICE_AREA':
    case 'PICKUP_SERVICE_AREA_UNAVAILABLE':
      return ParcelErrorKind.outsideArea;
    case 'CITY_CROSS_MARKET':
      return ParcelErrorKind.crossCity;
    case 'CITY_MARKET_MISMATCH':
      return ParcelErrorKind.otherCity;
    case 'PARCEL_QUOTE_EXPIRED':
    case 'PARCEL_QUOTE_USED':
    case 'PARCEL_QUOTE_NOT_FOUND':
      return ParcelErrorKind.quoteExpired;
    case 'PARCEL_QUOTE_MISMATCH':
      return ParcelErrorKind.quoteChanged;
    case 'PARCEL_SIZE_NOT_SUPPORTED':
    case 'CITY_VEHICLE_NOT_SUPPORTED':
      return ParcelErrorKind.sizeNotSupported;
    case 'PAYMENT_METHOD_NOT_AVAILABLE':
      return ParcelErrorKind.paymentNotAvailable;
    case 'PARCEL_CANCELLATION_FEE_CONFIRMATION_REQUIRED':
      return ParcelErrorKind.feeConfirmation;
    case 'PARCEL_ALREADY_PICKED_UP':
      return ParcelErrorKind.pickedUp;
    case 'PARCEL_MULTI_STOP_DISABLED':
      return ParcelErrorKind.multiStopDisabled;
    case 'PARCEL_TOO_MANY_STOPS':
      return ParcelErrorKind.tooManyStops;
    case 'PARCEL_MULTI_STOP_SENDER_PAYS':
      return ParcelErrorKind.multiStopSenderPays;
    case 'PARCEL_MULTI_STOP_CASH_AT_PICKUP':
      return ParcelErrorKind.multiStopCashAtPickup;
    case 'PARCEL_PAY_AT_PICKUP_DISABLED':
    case 'PARCEL_PAY_AT_PICKUP_SENDER_ONLY':
      return ParcelErrorKind.payAtPickupUnavailable;
    case 'OUTSTANDING_DUES':
      return ParcelErrorKind.outstandingDues;
  }
  if ((message ?? '').toLowerCase().contains('insufficient wallet')) {
    return ParcelErrorKind.insufficientWallet;
  }
  return ParcelErrorKind.other;
}
