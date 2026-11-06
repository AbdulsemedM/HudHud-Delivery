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
    ]) {
      c.dispose();
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
    ]);
  }

  bool get _needsPaymentPhone =>
      !_recipientPays &&
      !_sellerCod &&
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
      recipientPays: _recipientPays,
      sellerCodAmount: _sellerCod ? _parseAmount(_codAmount.text) : null,
      scheduledPickup: _scheduledPickup,
      marketCode: MarketController.instance?.selectedCode,
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
    if (_sellerCod && _parseAmount(_codAmount.text) == null) return false;
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
    final method = draft.recipientPays || draft.sellerCod
        ? 'cash'
        : draft.paymentMethod;
    final delivery = parcel.toLegacyDeliveryMap(
      pickupLat: draft.pickupLat,
      pickupLng: draft.pickupLng,
      dropoffLat: draft.dropoffLat,
      dropoffLng: draft.dropoffLng,
      pickupLocation: draft.pickupLocation,
      dropoffLocation: draft.dropoffLocation,
      vehicleType: _quote?.vehicleType,
      packageType: draft.category,
      paymentMethod: method,
      recipientName: draft.recipientIsMe ? null : draft.recipientName,
      recipientPhone: draft.recipientIsMe ? null : draft.recipientPhone,
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
              title: l10n.p10ParcelRecipient,
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
                if (widget.config.recipientPaysEnabled && !_recipientIsMe)
                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    title: Text(l10n.p10ParcelRecipientPays),
                    value: _recipientPays || _sellerCod,
                    onChanged: _sellerCod
                        ? null
                        : (v) => setState(() => _recipientPays = v),
                  ),
                if (widget.config.sellerCodEnabled && !_recipientIsMe) ...[
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
                if (!_recipientPays && !_sellerCod)
                  ParcelPaymentMethodPicker(
                    methods: widget.config.paymentMethods.isEmpty
                        ? const ['wallet', 'cash']
                        : widget.config.paymentMethods,
                    selected: _paymentMethod,
                    onSelected: (m) => setState(() => _paymentMethod = m),
                  ),
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
          if (parcel.handoverCode != null)
            ParcelHandoverCodeView(
              code: parcel.handoverCode!,
              hint: toSelf
                  ? l10n.p10ParcelHandoverSelfHint
                  : l10n.p10ParcelHandoverHint,
            ),
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
