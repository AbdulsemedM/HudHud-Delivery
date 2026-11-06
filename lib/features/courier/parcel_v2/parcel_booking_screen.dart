import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:latlong2/latlong.dart';
import 'package:share_plus/share_plus.dart';

import 'package:hudhud_delivery/app/services/city_scope.dart';
import 'package:hudhud_delivery/core/api/api_service.dart';
import 'package:hudhud_delivery/core/l10n/context_l10n.dart';
import 'package:hudhud_delivery/core/theme/app_colors.dart';
import 'package:hudhud_delivery/core/utils/payment_idempotency.dart';
import 'package:hudhud_delivery/core/widgets/city_outside_area_banner.dart';
import 'package:hudhud_delivery/features/courier/utils/courier_home_refresh.dart';
import 'package:hudhud_delivery/features/courier/utils/courier_live_job_screen.dart';
import 'package:hudhud_delivery/features/courier/utils/delivery_payment_helper.dart';
import 'package:hudhud_delivery/features/growth/market_controller.dart';
import 'package:hudhud_delivery/features/home/presentation/screen/location_search_screen.dart';
import 'package:hudhud_delivery/features/payment/data/data_provider/payment_data_provider.dart';
import 'package:hudhud_delivery/features/payment/data/repository/payment_repository.dart';
import 'package:hudhud_delivery/features/payment/presentation/screen/payment_initiate_result_screen.dart';
import 'package:hudhud_delivery/l10n/app_localizations.dart';

import 'parcel_v2_models.dart';
import 'parcel_v2_repository.dart';
import 'parcel_v2_widgets.dart';

/// Phase 10 parcel booking (Yango-style): pickup and drop-off with address
/// details, recipient (defaults to you), item category and size, optional
/// value and note, payment incl. "recipient pays" / seller COD, and an
/// upfront server price that stays locked for a few minutes.
///
/// Shown instead of the legacy courier flow only when the server reports
/// `parcel.v2_enabled` (GET /api/parcels/config).
class ParcelBookingScreen extends StatefulWidget {
  final ParcelV2Config config;

  /// Ask for a pickup time (schedule card on the courier tab).
  final bool scheduled;

  final ParcelV2Repository? repository;

  const ParcelBookingScreen({
    super.key,
    required this.config,
    this.scheduled = false,
    this.repository,
  });

  @override
  State<ParcelBookingScreen> createState() => _ParcelBookingScreenState();
}

class _PickedPlace {
  final String address;
  final LatLng position;

  const _PickedPlace(this.address, this.position);
}

/// Phase 11: form state of a drop-off after the first one.
class _ExtraStopForm {
  _PickedPlace? place;
  bool recipientIsMe = false;
  final building = TextEditingController();
  final floor = TextEditingController();
  final apartment = TextEditingController();
  final landmark = TextEditingController();
  final name = TextEditingController();
  final phone = TextEditingController();
  final note = TextEditingController();

  bool get complete =>
      place != null && (recipientIsMe || phone.text.trim().length >= 7);

  ParcelStopDraft? toDraft() {
    final p = place;
    if (p == null) return null;
    return ParcelStopDraft(
      location: p.address,
      lat: p.position.latitude,
      lng: p.position.longitude,
      details: ParcelAddressDetails(
        building: building.text,
        floor: floor.text,
        apartment: apartment.text,
        landmark: landmark.text,
      ),
      recipientIsMe: recipientIsMe,
      recipientName: name.text,
      recipientPhone: phone.text,
      note: note.text,
    );
  }

  void dispose() {
    for (final c in [building, floor, apartment, landmark, name, phone, note]) {
      c.dispose();
    }
  }
}

class _ParcelBookingScreenState extends State<ParcelBookingScreen> {
  late final ParcelV2Repository _repo;

  _PickedPlace? _pickup;
  _PickedPlace? _dropoff;
  final _pickupBuilding = TextEditingController();
  final _pickupFloor = TextEditingController();
  final _pickupApartment = TextEditingController();
  final _pickupLandmark = TextEditingController();
  final _dropoffBuilding = TextEditingController();
  final _dropoffFloor = TextEditingController();
  final _dropoffApartment = TextEditingController();
  final _dropoffLandmark = TextEditingController();
  final _recipientName = TextEditingController();
  final _recipientPhone = TextEditingController();
  final _description = TextEditingController();
  final _itemValue = TextEditingController();
  final _note = TextEditingController();
  final _paymentPhone = TextEditingController();
  final _codAmount = TextEditingController();
  final _dropoffNote = TextEditingController();

  /// Phase 11: drop-offs 2..N (stop 1 is _dropoff + the recipient section).
  final List<_ExtraStopForm> _extraStops = [];
  bool _payAtPickup = false;

  bool _recipientIsMe = false;
  String _category = 'parcel';
  String _size = 'small';
  String _paymentMethod = 'wallet';
  bool _recipientPays = false;
  bool _sellerCod = false;
  DateTime? _scheduledPickup;

  ParcelQuote? _quote;
  bool _quoting = false;
  String? _quoteError;
  bool _booking = false;
  Timer? _ticker;
  Timer? _requoteDebounce;
  int _quoteRequestId = 0;

  @override
  void initState() {
    super.initState();
    _repo = widget.repository ?? ParcelV2Repository();
    final methods = widget.config.paymentMethods;
    if (methods.isNotEmpty && !methods.contains(_paymentMethod)) {
      _paymentMethod = methods.first;
    }
    final firstAvailable = widget.config.sizes.where((s) => s.available);
    if (firstAvailable.isNotEmpty &&
        widget.config.sizeOption(_size)?.available == false) {
      _size = firstAvailable.first.size;
    }
    _ticker = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted && _quote != null) setState(() {});
    });
  }

  @override
  void dispose() {
    _ticker?.cancel();
    _requoteDebounce?.cancel();
    for (final c in [
      _pickupBuilding,
      _pickupFloor,
      _pickupApartment,
      _pickupLandmark,
      _dropoffBuilding,
      _dropoffFloor,
      _dropoffApartment,
      _dropoffLandmark,
      _recipientName,
      _recipientPhone,
      _description,
      _itemValue,
      _note,
      _paymentPhone,
      _codAmount,
      _dropoffNote,
    ]) {
      c.dispose();
    }
    for (final stop in _extraStops) {
      stop.dispose();
    }
    super.dispose();
  }

  // ── Derived state ────────────────────────────────────────────────────

  CityCheck get _cityCheck {
    final p = _pickup;
    final d = _dropoff;
    if (p == null || d == null) return CityCheck.ok;
    return CityScope.check([
      [p.position.latitude, p.position.longitude],
      [d.position.latitude, d.position.longitude],
      for (final stop in _extraStops)
        if (stop.place != null)
          [stop.place!.position.latitude, stop.place!.position.longitude],
    ]);
  }

  bool get _multiStop => _extraStops.isNotEmpty;

  bool get _canAddStop =>
      _dropoff != null && 1 + _extraStops.length < widget.config.maxDropoffs;

  /// With several drop-offs the sender always pays (no recipient pays / COD).
  bool get _recipientPaysActive => !_multiStop && _recipientPays;
  bool get _sellerCodActive => !_multiStop && _sellerCod;

  bool get _cashAtPickup =>
      _paymentMethod == 'cash' &&
      !_recipientPaysActive &&
      !_sellerCodActive &&
      (_multiStop || (_payAtPickup && widget.config.payAtPickupEnabled));

  bool get _needsPaymentPhone =>
      !_recipientPaysActive &&
      !_sellerCodActive &&
      _paymentMethod != 'wallet' &&
      _paymentMethod != 'cash';

  double? _parseAmount(String text) {
    final value = double.tryParse(text.trim().replaceAll(',', '.'));
    return value != null && value > 0 ? value : null;
  }

  ParcelBookingDraft? _draft() {
    final p = _pickup;
    final d = _dropoff;
    if (p == null || d == null) return null;
    return ParcelBookingDraft(
      pickupLocation: p.address,
      pickupLat: p.position.latitude,
      pickupLng: p.position.longitude,
      pickupDetails: ParcelAddressDetails(
        building: _pickupBuilding.text,
        floor: _pickupFloor.text,
        apartment: _pickupApartment.text,
        landmark: _pickupLandmark.text,
      ),
      dropoffLocation: d.address,
      dropoffLat: d.position.latitude,
      dropoffLng: d.position.longitude,
      dropoffDetails: ParcelAddressDetails(
        building: _dropoffBuilding.text,
        floor: _dropoffFloor.text,
        apartment: _dropoffApartment.text,
        landmark: _dropoffLandmark.text,
      ),
      recipientIsMe: _recipientIsMe,
      recipientName: _recipientName.text,
      recipientPhone: _recipientPhone.text,
      category: _category,
      size: _size,
      description: _description.text,
      itemValue: _parseAmount(_itemValue.text),
      courierNote: _note.text,
      paymentMethod: _paymentMethod,
      paymentPhone: _needsPaymentPhone ? _paymentPhone.text : null,
      recipientPays: _recipientPaysActive,
      sellerCodAmount:
          _sellerCodActive ? _parseAmount(_codAmount.text) : null,
      scheduledPickup: _scheduledPickup,
      marketCode: MarketController.instance?.selectedCode,
      dropoffNote: _multiStop ? _dropoffNote.text : '',
      extraStops: _extraStops
          .map((stop) => stop.toDraft())
          .whereType<ParcelStopDraft>()
          .toList(),
      payAtPickup: _cashAtPickup,
    );
  }

  // ── Actions ──────────────────────────────────────────────────────────

  Future<void> _pickLocation({required bool pickup}) async {
    final current = pickup ? _pickup : _dropoff;
    final result = await Navigator.push<Map<String, dynamic>>(
      context,
      MaterialPageRoute(
        builder: (_) => LocationSearchScreen(currentLocation: current?.address),
      ),
    );
    if (!mounted || result == null) return;
    final coords = result['coordinates'];
    final address = result['address']?.toString() ?? '';
    if (coords is! LatLng || address.isEmpty) return;
    setState(() {
      final picked = _PickedPlace(address, coords);
      if (pickup) {
        _pickup = picked;
      } else {
        _dropoff = picked;
      }
    });
    _scheduleQuote(immediate: true);
  }

  Future<_PickedPlace?> _searchPlace(String? current) async {
    final result = await Navigator.push<Map<String, dynamic>>(
      context,
      MaterialPageRoute(
        builder: (_) => LocationSearchScreen(currentLocation: current),
      ),
    );
    if (!mounted || result == null) return null;
    final coords = result['coordinates'];
    final address = result['address']?.toString() ?? '';
    if (coords is! LatLng || address.isEmpty) return null;
    return _PickedPlace(address, coords);
  }

  Future<void> _pickStopLocation(_ExtraStopForm stop) async {
    final picked = await _searchPlace(stop.place?.address);
    if (!mounted || picked == null) return;
    setState(() => stop.place = picked);
    _scheduleQuote(immediate: true);
  }

  Future<void> _addStop() async {
    if (!_canAddStop) return;
    final stop = _ExtraStopForm();
    setState(() {
      _extraStops.add(stop);
      // Several drop-offs: the sender pays (cash only at pickup).
      _recipientPays = false;
      _sellerCod = false;
      final shown = _paymentMethodsShown;
      if (!shown.contains(_paymentMethod) && shown.isNotEmpty) {
        _paymentMethod = shown.first;
      }
    });
    await _pickStopLocation(stop);
  }

  void _removeStop(_ExtraStopForm stop) {
    setState(() {
      _extraStops.remove(stop);
      stop.dispose();
    });
    _scheduleQuote(immediate: true);
  }

  /// Move drop-off [index] (0 = stop 1) one place up or down.
  void _moveStop(int index, int delta) {
    final target = index + delta;
    final total = 1 + _extraStops.length;
    if (target < 0 || target >= total) return;
    setState(() {
      if (index == 0 || target == 0) {
        _swapWithFirst(_extraStops[(index == 0 ? target : index) - 1]);
      } else {
        final a = _extraStops[index - 1];
        _extraStops[index - 1] = _extraStops[target - 1];
        _extraStops[target - 1] = a;
      }
    });
    _scheduleQuote(immediate: true);
  }

  /// Stop 1 lives in the dropoff / recipient fields: swap values with [other].
  void _swapWithFirst(_ExtraStopForm other) {
    final place = _dropoff;
    _dropoff = other.place;
    other.place = place;
    final isMe = _recipientIsMe;
    _recipientIsMe = other.recipientIsMe;
    other.recipientIsMe = isMe;
    void swap(TextEditingController a, TextEditingController b) {
      final text = a.text;
      a.text = b.text;
      b.text = text;
    }

    swap(_dropoffBuilding, other.building);
    swap(_dropoffFloor, other.floor);
    swap(_dropoffApartment, other.apartment);
    swap(_dropoffLandmark, other.landmark);
    swap(_recipientName, other.name);
    swap(_recipientPhone, other.phone);
    swap(_dropoffNote, other.note);
  }

  Future<void> _pickTime() async {
    final now = DateTime.now();
    final date = await showDatePicker(
      context: context,
      initialDate: _scheduledPickup ?? now,
      firstDate: now,
      lastDate: now.add(const Duration(days: 7)),
    );
    if (!mounted || date == null) return;
    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(
        _scheduledPickup ?? now.add(const Duration(hours: 1)),
      ),
    );
    if (!mounted || time == null) return;
    final picked =
        DateTime(date.year, date.month, date.day, time.hour, time.minute);
    setState(() {
      _scheduledPickup = picked.isBefore(now) ? null : picked;
    });
    _scheduleQuote(immediate: true);
  }

  void _scheduleQuote({bool immediate = false}) {
    _requoteDebounce?.cancel();
    _requoteDebounce = Timer(
      immediate ? Duration.zero : const Duration(milliseconds: 500),
      _fetchQuote,
    );
  }

  Future<void> _fetchQuote() async {
    final draft = _draft();
    if (draft == null) return;
    if (_cityCheck != CityCheck.ok) {
      setState(() {
        _quote = null;
        _quoteError = null;
      });
      return;
    }
    final requestId = ++_quoteRequestId;
    setState(() {
      _quoting = true;
      _quoteError = null;
    });
    final result = await _repo.quote(draft);
    if (!mounted || requestId != _quoteRequestId) return;
    setState(() {
      _quoting = false;
      _quote = result.value;
      _quoteError = result.ok ? null : _errorText(result);
    });
  }

  String _errorText(ParcelResult<dynamic> result) {
    final l10n = context.l10n;
    switch (result.errorKind) {
      case ParcelErrorKind.outsideArea:
        return l10n.p10CityNotServed;
      case ParcelErrorKind.crossCity:
        return l10n.p10CityCrossCity;
      case ParcelErrorKind.otherCity:
        return l10n.p10CityOtherCity;
      case ParcelErrorKind.quoteExpired:
      case ParcelErrorKind.quoteChanged:
        return l10n.p10ParcelPriceUpdated;
      case ParcelErrorKind.sizeNotSupported:
        return l10n.p10ParcelSizeNotSupported;
      case ParcelErrorKind.paymentNotAvailable:
        return l10n.p10ParcelPaymentNotAvailable;
      case ParcelErrorKind.insufficientWallet:
        return l10n.p10ParcelInsufficientWallet;
      case ParcelErrorKind.multiStopDisabled:
        return l10n.p11ParcelMultiStopDisabled;
      case ParcelErrorKind.tooManyStops:
        return l10n.p11ParcelTooManyStops;
      case ParcelErrorKind.multiStopSenderPays:
        return l10n.p11ParcelMultiStopSenderPays;
      case ParcelErrorKind.multiStopCashAtPickup:
        return l10n.p11ParcelMultiStopCashAtPickup;
      case ParcelErrorKind.payAtPickupUnavailable:
        return l10n.p11ParcelPayAtPickupUnavailable;
      case ParcelErrorKind.feeConfirmation:
      case ParcelErrorKind.pickedUp:
      case ParcelErrorKind.other:
        return result.message?.isNotEmpty == true
            ? result.message!
            : l10n.p10ParcelSomethingWrong;
    }
  }

  bool _formComplete() {
    if (_pickup == null || _dropoff == null) return false;
    if (!_recipientIsMe && _recipientPhone.text.trim().length < 7) {
      return false;
    }
    if (_extraStops.any((stop) => !stop.complete)) return false;
    if (_sellerCodActive && _parseAmount(_codAmount.text) == null) {
      return false;
    }
    if (_needsPaymentPhone && _paymentPhone.text.trim().length < 7) {
      return false;
    }
    return true;
  }

  Future<void> _book() async {
    final l10n = context.l10n;
    final messenger = ScaffoldMessenger.of(context);
    if (!_formComplete()) {
      messenger.showSnackBar(SnackBar(content: Text(l10n.p10ParcelFillRequired)));
      return;
    }
    var quote = _quote;
    if (quote == null || quote.isExpired()) {
      await _fetchQuote();
      if (!mounted) return;
      quote = _quote;
      if (quote == null) return;
    }
    final draft = _draft();
    if (draft == null) return;

    setState(() => _booking = true);
    final result = await _repo.book(draft, quote.quoteId);
    if (!mounted) return;

    if (!result.ok) {
      setState(() => _booking = false);
      final kind = result.errorKind;
      if (kind == ParcelErrorKind.quoteExpired ||
          kind == ParcelErrorKind.quoteChanged) {
        await _fetchQuote();
      }
      if (!mounted) return;
      messenger.showSnackBar(
        SnackBar(
          content: Text(_errorText(result)),
          backgroundColor: AppColors.errorColor,
        ),
      );
      return;
    }

    final parcel = result.value!;
    CourierHomeRefresh.instance.notifyRefresh();
    await _handlePayment(parcel, draft, result.body);
  }

  Future<void> _handlePayment(
    ParcelV2Parcel parcel,
    ParcelBookingDraft draft,
    Map<String, dynamic>? body,
  ) async {
    final method = draft.effectivePaymentMethod;
    // The live screens follow the route's last drop-off.
    final last = draft.lastStop;
    final delivery = parcel.toLegacyDeliveryMap(
      pickupLat: draft.pickupLat,
      pickupLng: draft.pickupLng,
      dropoffLat: last.lat,
      dropoffLng: last.lng,
      pickupLocation: draft.pickupLocation,
      dropoffLocation: last.location,
      vehicleType: _quote?.vehicleType,
      packageType: draft.category,
      paymentMethod: method,
      recipientName: last.recipientIsMe ? null : last.recipientName,
      recipientPhone: last.recipientIsMe ? null : last.recipientPhone,
    );

    await showParcelBookedSheet(context, parcel: parcel, toSelf: _recipientIsMe);
    if (!mounted) return;

    final ussdSent = body?['payment'] is Map &&
        (body!['payment'] as Map)['ussd_sent'] == true;
    final online = method != 'wallet' && !isOfflineDeliveryPayment(method);
    if (!online || ussdSent || method.startsWith('ebirr')) {
      if (ussdSent) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(context.l10n.p10ParcelApprovePayment)),
        );
      }
      _openLiveJob(delivery);
      return;
    }

    final paymentRepository = PaymentRepository(
      paymentDataProvider: PaymentDataProvider(apiService: ApiService.instance),
    );
    final paymentResult = await initiateDeliveryPayment(
      repo: paymentRepository,
      packageDeliveryId: parcel.id,
      paymentMethodCode: method,
      amount: parcel.amount,
      currency: parcel.currency ?? widget.config.currency,
      paymentDetails: {'phone': draft.paymentPhone ?? ''},
      idempotencyKey: createPaymentIdempotencyKey(
        type: 'delivery',
        entityId: parcel.id,
      ),
    );
    if (!mounted) return;
    setState(() => _booking = false);
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (_) => PaymentInitiateResultScreen(
          result: paymentResult,
          orderId: parcel.id.toString(),
          trackingNumber: parcel.trackingNumber ?? '',
          onTerminalSuccess: (resultContext) {
            Navigator.of(resultContext).pushAndRemoveUntil(
              MaterialPageRoute(
                builder: (_) => courierLiveJobScreenFromDelivery(delivery),
              ),
              (route) => route.isFirst,
            );
          },
        ),
      ),
    );
  }

  void _openLiveJob(Map<String, dynamic> delivery) {
    setState(() => _booking = false);
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (_) => courierLiveJobScreenFromDelivery(delivery),
      ),
    );
  }

  // ── UI ───────────────────────────────────────────────────────────────

  /// Cash on a multi-stop parcel is only possible as cash at pickup.
  List<String> get _paymentMethodsShown {
    final methods = widget.config.paymentMethods.isEmpty
        ? const ['wallet', 'cash']
        : widget.config.paymentMethods;
    if (_multiStop && !widget.config.payAtPickupEnabled) {
      return methods.where((m) => m != 'cash').toList();
    }
    return methods;
  }

  Widget _buildExtraStop(BuildContext context, int i) {
    final l10n = context.l10n;
    final stop = _extraStops[i];
    final index = i + 1; // 0 = stop 1
    return Column(
      key: ObjectKey(stop),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Divider(height: 24),
        ParcelStopHeader(
          number: index + 1,
          onMoveUp: () => _moveStop(index, -1),
          onMoveDown:
              i < _extraStops.length - 1 ? () => _moveStop(index, 1) : null,
          onRemove: () => _removeStop(stop),
        ),
        ParcelAddressTile(
          key: ValueKey('parcel_stop_${index + 1}_address'),
          icon: Icons.location_on_outlined,
          label: l10n.p11ParcelStopN((index + 1).toString()),
          address: stop.place?.address,
          placeholder: l10n.p10ParcelChooseAddress,
          onTap: () => _pickStopLocation(stop),
        ),
        if (stop.place != null)
          ParcelAddressDetailsFields(
            building: stop.building,
            floor: stop.floor,
            apartment: stop.apartment,
            landmark: stop.landmark,
          ),
        SwitchListTile(
          contentPadding: EdgeInsets.zero,
          title: Text(l10n.p10ParcelSendToMyself),
          value: stop.recipientIsMe,
          onChanged: (v) => setState(() => stop.recipientIsMe = v),
        ),
        if (!stop.recipientIsMe) ...[
          TextField(
            key: ValueKey('parcel_stop_${index + 1}_name'),
            controller: stop.name,
            textCapitalization: TextCapitalization.words,
            decoration: InputDecoration(
              labelText: l10n.p10ParcelRecipientName,
            ),
          ),
          TextField(
            key: ValueKey('parcel_stop_${index + 1}_phone'),
            controller: stop.phone,
            keyboardType: TextInputType.phone,
            inputFormatters: [
              FilteringTextInputFormatter.allow(RegExp(r'[0-9+ ]')),
            ],
            decoration: InputDecoration(
              labelText: l10n.p10ParcelRecipientPhone,
              hintText: MarketController.instance?.phonePrefix,
            ),
            onChanged: (_) => setState(() {}),
          ),
        ],
        TextField(
          controller: stop.note,
          maxLength: 300,
          decoration: InputDecoration(labelText: l10n.p10ParcelCourierNote),
        ),
      ],
    );
  }

  static String _formatPickupTime(BuildContext context, DateTime at) {
    final material = MaterialLocalizations.of(context);
    final date = material.formatMediumDate(at);
    final time = material.formatTimeOfDay(TimeOfDay.fromDateTime(at));
    return '$date · $time';
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final cityCheck = _cityCheck;
    final cityError = switch (cityCheck) {
      CityCheck.ok => null,
      CityCheck.outside => l10n.p10CityNotServed,
      CityCheck.crossCity => l10n.p10CityCrossCity,
      CityCheck.otherCity => l10n.p10CityOtherCity,
    };

    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.scheduled ? l10n.p10ParcelScheduledTitle : l10n.p10ParcelTitle,
        ),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
          children: [
            if (widget.config.outstandingDues?.hasDues ?? false)
              ParcelDuesBanner(dues: widget.config.outstandingDues!),
            ParcelSection(
              title: l10n.p10ParcelRoute,
              children: [
                ParcelAddressTile(
                  key: const ValueKey('parcel_pickup'),
                  icon: Icons.radio_button_checked,
                  label: l10n.p10ParcelPickup,
                  address: _pickup?.address,
                  placeholder: l10n.p10ParcelChooseAddress,
                  onTap: () => _pickLocation(pickup: true),
                ),
                if (_pickup != null)
                  ParcelAddressDetailsFields(
                    building: _pickupBuilding,
                    floor: _pickupFloor,
                    apartment: _pickupApartment,
                    landmark: _pickupLandmark,
                  ),
                const Divider(height: 24),
                if (_multiStop)
                  ParcelStopHeader(
                    number: 1,
                    onMoveDown: () => _moveStop(0, 1),
                  ),
                ParcelAddressTile(
                  key: const ValueKey('parcel_dropoff'),
                  icon: Icons.location_on,
                  label: l10n.p10ParcelDropoff,
                  address: _dropoff?.address,
                  placeholder: l10n.p10ParcelChooseAddress,
                  onTap: () => _pickLocation(pickup: false),
                ),
                if (_dropoff != null)
                  ParcelAddressDetailsFields(
                    building: _dropoffBuilding,
                    floor: _dropoffFloor,
                    apartment: _dropoffApartment,
                    landmark: _dropoffLandmark,
                  ),
                for (var i = 0; i < _extraStops.length; i++)
                  _buildExtraStop(context, i),
                if (_canAddStop)
                  Align(
                    alignment: AlignmentDirectional.centerStart,
                    child: TextButton.icon(
                      key: const ValueKey('parcel_add_stop'),
                      icon: const Icon(Icons.add_location_alt_outlined),
                      label: Text(l10n.p11ParcelAddStop),
                      onPressed: _addStop,
                    ),
                  ),
                if (widget.config.multiStopEnabled && _multiStop)
                  Text(
                    l10n.p11ParcelStopsLimit(
                      widget.config.maxDropoffs.toString(),
                    ),
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                if (cityError != null) ...[
                  const SizedBox(height: 12),
                  CityOutsideAreaBanner(message: cityError),
                ],
                if (widget.scheduled) ...[
                  const Divider(height: 24),
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: const Icon(Icons.schedule),
                    title: Text(l10n.p10ParcelPickupTime),
                    subtitle: Text(
                      _scheduledPickup == null
                          ? l10n.p10ParcelPickupNow
                          : _formatPickupTime(context, _scheduledPickup!),
                    ),
                    onTap: _pickTime,
                  ),
                ],
              ],
            ),
            ParcelSection(
              title: _multiStop
                  ? '${l10n.p10ParcelRecipient} · ${l10n.p11ParcelStopN('1')}'
                  : l10n.p10ParcelRecipient,
              children: [
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text(l10n.p10ParcelSendToMyself),
                  value: _recipientIsMe,
                  onChanged: (v) => setState(() {
                    _recipientIsMe = v;
                    if (v) _sellerCod = false;
                  }),
                ),
                if (!_recipientIsMe) ...[
                  TextField(
                    controller: _recipientName,
                    textCapitalization: TextCapitalization.words,
                    decoration: InputDecoration(
                      labelText: l10n.p10ParcelRecipientName,
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _recipientPhone,
                    keyboardType: TextInputType.phone,
                    inputFormatters: [
                      FilteringTextInputFormatter.allow(RegExp(r'[0-9+ ]')),
                    ],
                    decoration: InputDecoration(
                      labelText: l10n.p10ParcelRecipientPhone,
                      hintText: MarketController.instance?.phonePrefix,
                    ),
                    onChanged: (_) => setState(() {}),
                  ),
                ],
                if (_multiStop)
                  TextField(
                    controller: _dropoffNote,
                    maxLength: 300,
                    decoration: InputDecoration(
                      labelText: l10n.p10ParcelCourierNote,
                    ),
                  ),
              ],
            ),
            ParcelSection(
              title: l10n.p10ParcelWhatSending,
              children: [
                ParcelCategoryChips(
                  categories: widget.config.categories.isEmpty
                      ? kParcelDefaultCategories
                      : widget.config.categories,
                  selected: _category,
                  onSelected: (c) => setState(() => _category = c),
                ),
                const SizedBox(height: 12),
                ParcelSizeSelector(
                  config: widget.config,
                  selected: _size,
                  onSelected: (s) {
                    setState(() => _size = s);
                    _scheduleQuote(immediate: true);
                  },
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _description,
                  maxLength: 200,
                  decoration: InputDecoration(
                    labelText: l10n.p10ParcelDescription,
                  ),
                ),
                TextField(
                  controller: _itemValue,
                  keyboardType:
                      const TextInputType.numberWithOptions(decimal: true),
                  decoration: InputDecoration(
                    labelText: l10n.p10ParcelItemValue,
                    suffixText: widget.config.currency,
                  ),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: _note,
                  maxLength: 300,
                  decoration: InputDecoration(
                    labelText: l10n.p10ParcelCourierNote,
                  ),
                ),
              ],
            ),
            ParcelSection(
              title: l10n.p10ParcelPayment,
              children: [
                if (_multiStop)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Text(
                      l10n.p11ParcelMultiStopSenderPays,
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ),
                if (widget.config.recipientPaysEnabled &&
                    !_recipientIsMe &&
                    !_multiStop)
                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    title: Text(l10n.p10ParcelRecipientPays),
                    value: _recipientPays || _sellerCod,
                    onChanged: _sellerCod
                        ? null
                        : (v) => setState(() => _recipientPays = v),
                  ),
                if (widget.config.sellerCodEnabled &&
                    !_recipientIsMe &&
                    !_multiStop) ...[
                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    title: Text(l10n.p10ParcelSellerCod),
                    subtitle: Text(l10n.p10ParcelSellerCodHint),
                    value: _sellerCod,
                    onChanged: (v) => setState(() => _sellerCod = v),
                  ),
                  if (_sellerCod)
                    TextField(
                      controller: _codAmount,
                      keyboardType:
                          const TextInputType.numberWithOptions(decimal: true),
                      decoration: InputDecoration(
                        labelText: l10n.p10ParcelSellerCodAmount,
                        suffixText: widget.config.currency,
                      ),
                      onChanged: (_) => setState(() {}),
                    ),
                ],
                if (!_recipientPaysActive && !_sellerCodActive)
                  ParcelPaymentMethodPicker(
                    methods: _paymentMethodsShown,
                    selected: _paymentMethod,
                    onSelected: (m) => setState(() => _paymentMethod = m),
                  ),
                if (_paymentMethod == 'cash' &&
                    !_recipientPaysActive &&
                    !_sellerCodActive &&
                    widget.config.payAtPickupEnabled) ...[
                  if (_multiStop)
                    Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: Text(l10n.p11ParcelMultiStopCashAtPickup),
                    )
                  else
                    SwitchListTile(
                      key: const ValueKey('parcel_pay_at_pickup'),
                      contentPadding: EdgeInsets.zero,
                      title: Text(l10n.p11ParcelPayAtPickup),
                      subtitle: Text(l10n.p11ParcelPayAtPickupHint),
                      value: _payAtPickup,
                      onChanged: (v) => setState(() => _payAtPickup = v),
                    ),
                ],
                if (_needsPaymentPhone)
                  TextField(
                    controller: _paymentPhone,
                    keyboardType: TextInputType.phone,
                    decoration: InputDecoration(
                      labelText: l10n.p10ParcelPaymentPhone,
                      hintText: MarketController.instance?.phonePrefix,
                    ),
                    onChanged: (_) => setState(() {}),
                  ),
              ],
            ),
            const SizedBox(height: 8),
            ParcelQuoteCard(
              quote: _quote,
              loading: _quoting,
              error: cityError == null ? _quoteError : null,
              waitingForRoute: _pickup == null || _dropoff == null,
              onRefresh: () => _scheduleQuote(immediate: true),
            ),
            const SizedBox(height: 16),
            SizedBox(
              height: 52,
              child: FilledButton(
                key: const ValueKey('parcel_book_button'),
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.primaryColor,
                ),
                onPressed: _booking ||
                        _quoting ||
                        cityError != null ||
                        _quote == null ||
                        !_formComplete()
                    ? null
                    : _book,
                child: _booking
                    ? const SizedBox(
                        width: 22,
                        height: 22,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : Text(
                        _quote == null
                            ? l10n.p10ParcelContinue
                            : l10n.p10ParcelBook(
                                formatParcelMoney(
                                  _quote!.amount,
                                  _quote!.currency,
                                ),
                              ),
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Bottom sheet after booking: handover code and the tracking link to share.
Future<void> showParcelBookedSheet(
  BuildContext context, {
  required ParcelV2Parcel parcel,
  required bool toSelf,
}) {
  final AppLocalizations l10n = context.l10n;
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    builder: (sheetContext) => Padding(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            l10n.p10ParcelBooked,
            style: Theme.of(sheetContext).textTheme.titleLarge,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          if (parcel.isMultiStop)
            ParcelStopsList(stops: parcel.stops)
          else if (parcel.handoverCode != null)
            ParcelHandoverCodeView(
              code: parcel.handoverCode!,
              hint: toSelf
                  ? l10n.p10ParcelHandoverSelfHint
                  : l10n.p10ParcelHandoverHint,
            ),
          if (parcel.paysAtPickup) ...[
            const SizedBox(height: 12),
            ParcelPayAtPickupNote(
              amount: parcel.amount,
              currency: parcel.currency,
            ),
          ],
          if (parcel.trackingUrl != null) ...[
            const SizedBox(height: 12),
            OutlinedButton.icon(
              icon: const Icon(Icons.share),
              label: Text(l10n.p10ParcelShareTracking),
              onPressed: () => Share.share(
                l10n.p10ParcelTrackingShareText(parcel.trackingUrl!),
              ),
            ),
          ],
          const SizedBox(height: 12),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.primaryColor,
            ),
            onPressed: () => Navigator.pop(sheetContext),
            child: Text(l10n.p10ParcelContinue),
          ),
        ],
      ),
    ),
  );
}
