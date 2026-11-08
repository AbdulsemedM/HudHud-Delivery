import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../app/services/cart_service.dart';
import '../../../../app/services/location_service.dart';
import '../../../../app/services/saved_location_service.dart';
import '../../../../core/l10n/api_error_l10n.dart';
import '../../../../core/utils/api_error_result.dart' show kCityMarketMismatchCode;
import '../../../../core/l10n/context_l10n.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/api/api_service.dart';
import '../../../courier/parcel_v2/parcel_v2_models.dart'
    show ParcelDuesSummary;
import '../../../courier/parcel_v2/parcel_v2_widgets.dart'
    show ParcelDuesBanner;
import '../../../gifting/gift_phone.dart';
import '../../../gifting/gift_session.dart';
import '../../../gifting/presentation/gift_widgets.dart';
import '../../../growth/data/growth_repository.dart';
import '../../../growth/data/models/checkout_quote.dart';
import '../../../growth/data/models/checkout_quote_request.dart';
import '../../../growth/data/models/growth_config.dart';
import '../../../growth/data/models/hudhud_set.dart';
import '../../../growth/data/models/market.dart';
import '../../../growth/growth_scope.dart';
import '../../../growth/market_controller.dart';
import '../../../growth/market_switch.dart';
import '../../../growth/plus_controller.dart';
import '../../../growth/presentation/screens/plus_screen.dart';
import '../../../growth/presentation/widgets/checkout_growth_widgets.dart';
import '../../../growth/presentation/widgets/plus_widgets.dart';
import '../../../../core/utils/money_format.dart';
import '../../../guest/data/branches_repository.dart';
import '../../../home/presentation/screen/map_location_screen.dart';
import '../../../payment/bloc/payment_bloc.dart';
import '../../../payment/data/data_provider/payment_data_provider.dart';
import '../../../payment/data/repository/payment_repository.dart';
import '../../../payment/model/payment_initiate_result.dart';
import '../../../payment/presentation/order_payment_issue_flow.dart';
import '../../../payment/presentation/screen/payment_initiate_result_screen.dart';
import '../../../payment/presentation/widgets/payment_details_form.dart';
import '../../../vendors/data/models/store_status.dart';
import '../../../vendors/data/repository/store_status_repository.dart';
import '../../../vendors/presentation/widgets/store_status_widgets.dart';
import '../../../wallet/data/customer_dues_repository.dart';
import '../../../wallet/presentation/screens/wallet_topup_page.dart';
import '../../data/data_provider/checkout_data_provider.dart';
import '../../data/models/delivery_fee_quote.dart';
import '../../data/repository/checkout_repository.dart';
import '../../utils/nearest_branch.dart';
import '../widgets/checkout_issue_card.dart';
import '../widgets/checkout_widgets.dart';

class CheckoutScreen extends StatefulWidget {
  final List<Map<String, dynamic>> cartItems;
  final double subtotal;

  const CheckoutScreen({
    super.key,
    required this.cartItems,
    required this.subtotal,
  });

  @override
  State<CheckoutScreen> createState() => _CheckoutScreenState();
}

class _CheckoutScreenState extends State<CheckoutScreen> {
  final TextEditingController _notesController = TextEditingController();
  final CartService _cart = CartService();
  final BranchesRepository _branchesRepository = BranchesRepository();
  late final CheckoutRepository _checkoutRepository;

  late List<Map<String, dynamic>> _cartItems;
  double _tipAmount = 0.0;
  String _deliveryAddress = 'Loading address...';
  double? _deliveryLatitude;
  double? _deliveryLongitude;
  String? _selectedPaymentMethod;
  List<Map<String, dynamic>> _paymentMethods = List.from(
    kDefaultAllowedPaymentMethods,
  );
  bool _loadingMethods = true;
  Map<String, dynamic> _paymentDetails = {};
  String _ebirrProvider = 'kaafi';
  bool _useHpp = false;

  int? _branchId;
  String? _branchName;
  DeliveryFeeQuote? _deliveryFeeQuote;
  String? _quoteCacheKey;
  bool _quoteLoading = false;
  String? _quoteError;
  bool _quoteRetryable = false;
  int _quoteRequestId = 0;

  // ── Phase 2 growth (server-priced checkout) ─────────────────────────────
  // Everything below is inert unless GET /growth/config enables a feature.
  final GrowthRepository _growthRepository = GrowthRepository.create();
  CheckoutQuote? _growthQuote;
  String? _growthQuoteKey;
  int _growthQuoteRequestId = 0;
  Timer? _growthQuoteDebounce;

  /// True while a re-quote is scheduled or in flight; the previous quote
  /// stays on screen meanwhile to avoid flicker.
  bool _growthQuotePending = false;
  String? _appliedPromoCode;
  bool _promoApplying = false;
  String? _promoMessage;
  bool _promoMessageIsError = false;
  bool _redeemPoints = false;

  /// Points requested when the toggle is on (the server's max_redeemable).
  int _redeemPointsAmount = 0;

  // ── Phase 6 diaspora gifting ────────────────────────────────────────────
  // POST /customer/gift-orders instead of /customer/orders; the recipient
  // gets the SMS tracking link + delivery code. No cash, no points.
  final TextEditingController _giftNameController = TextEditingController();
  final TextEditingController _giftPhoneController = TextEditingController();
  final TextEditingController _giftMessageController = TextEditingController();
  bool _giftMode = false;
  String? _giftNameError;
  String? _giftPhoneError;

  // ── Store controls, unpaid balance and one-city refusals ───────────────
  /// Set from a STORE_CLOSED / STORE_PAUSED refusal (the branch-aware
  /// delivery-fee quote, the checkout quote or the order call); cleared by
  /// the next successful quote.
  StoreStatus? _storeStatus;

  /// `GET /customer/dues`; cash is refused while any are open.
  ParcelDuesSummary? _dues;

  /// Refusal that blocks "Place order" until fixed (store closed / busy,
  /// sold-out item, address outside the city …).
  ApiErrorResult? _issue;

  @override
  void initState() {
    super.initState();
    _checkoutRepository = CheckoutRepository(
      checkoutDataProvider: CheckoutDataProvider(
        apiService: ApiService.instance,
      ),
    );
    _cartItems = widget.cartItems
        .map((item) => Map<String, dynamic>.from(item))
        .toList();
    _branchId = _cart.selectedBranchId;
    _giftMode = GiftSession.instance.active;
    restoreGiftSession();
    _loadDeliveryAddress();
    unawaited(_loadDues());
    WidgetsBinding.instance.addPostFrameCallback((_) => _applyPendingPromo());
    // Phase 3: Plus status for the upsell (hidden unless the server enables it).
    PlusController.instance.addListener(_onPlusChanged);
    unawaited(PlusController.instance.refresh());
  }

  /// Server quote is used when a Phase 2 feature is on, or (Phase 3) when
  /// the customer is a Plus member so the Plus free delivery is shown.
  bool get _quoteEnabled {
    final growth = _growth;
    if (growth.checkoutQuoteEnabled) return true;
    // Phase 4: a HudHud Set in the cart needs the server quote, which is
    // the only source of the set delivery subsidy.
    if (growth.loaded && _cartHasSet) return true;
    return growth.loaded && PlusController.instance.status.isMember;
  }

  /// True when a cart line is a HudHud Set seen in this session.
  bool get _cartHasSet => _cartItems
      .any((item) => KnownHudHudSets.contains(int.tryParse(_productId(item))));

  /// Explains why a set cart did not get delivery included (server reason).
  String? _setDeliveryNote(CheckoutQuote? quote) {
    final setBlock = quote?.hudhudSet;
    if (setBlock == null ||
        setBlock.applied ||
        !setBlock.enabled ||
        !_cartHasSet) {
      return null;
    }
    if (setBlock.isOverMaxQuantity) {
      return context.l10n.p5SetOverMaxQuantity(setBlock.maxPerOrder);
    }
    if (setBlock.isMixedCart) return context.l10n.p5SetMixedCart;
    return null;
  }

  void _onPlusChanged() {
    if (!mounted) return;
    final enabled = _quoteEnabled;
    if (enabled && !_growthQuoteWasEnabled) {
      _scheduleGrowthQuote(immediate: true);
    }
    _growthQuoteWasEnabled = enabled;
    setState(() {});
  }

  /// Phase 3: show "Get free delivery with HudHud Plus" to non-members.
  bool get _showPlusUpsell {
    final plus = PlusController.instance.status;
    if (!plus.available || plus.isMember) return false;
    final quote = _activeGrowthQuote;
    return quote == null || !quote.plusApplied;
  }

  Future<void> _openPlus() async {
    await Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const PlusScreen()),
    );
    if (!mounted) return;
    await PlusController.instance.refresh(force: true);
    if (!mounted) return;
    // Membership may have changed the delivery fee: force a fresh quote.
    _growthQuoteKey = null;
    _scheduleGrowthQuote(immediate: true);
  }

  /// Phase 3 display currency: server quote → delivery-fee quote → market.
  /// Null (= ETB, unchanged output) when nothing says otherwise.
  String? get _displayCurrency {
    final growthCurrency = _activeGrowthQuote?.currency.trim();
    if (growthCurrency != null && growthCurrency.isNotEmpty) {
      return growthCurrency;
    }
    final feeCurrency = _deliveryFeeQuote?.currency.trim();
    if (feeCurrency != null && feeCurrency.isNotEmpty) return feeCurrency;
    return MarketController.instance?.selected?.currency;
  }

  GrowthConfig get _growth => growthConfigOf(context, listen: false);

  bool _growthQuoteWasEnabled = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Listen to config so a late-loading config enables the quote.
    growthConfigOf(context);
    final enabled = _quoteEnabled;
    if (enabled && !_growthQuoteWasEnabled) {
      _scheduleGrowthQuote(immediate: true);
    }
    _growthQuoteWasEnabled = enabled;
  }

  /// Server quote is shown only when it matches the current inputs.
  CheckoutQuote? get _activeGrowthQuote {
    final quote = _growthQuote;
    if (quote == null || !_quoteEnabled) return null;
    if (_growthQuotePending) return quote;
    if (_growthQuoteKey != _currentGrowthRequest()?.cacheKey) return null;
    return quote;
  }

  /// Recipient's market: the gift session's, else the customer's own.
  Market? get _giftMarket =>
      GiftSession.instance.market ?? MarketController.instance?.selected;

  GiftPhonePlan get _giftPhonePlan => GiftPhonePlan.forMarket(_giftMarket);

  /// The gift section shows when gifting looks available, or when the
  /// customer already switched it on (e.g. started from "Send a gift").
  bool get _showGiftSection {
    if (_giftMode) return true;
    return giftingAvailable(
      config: _growth,
      markets: MarketController.instance?.markets ?? const <Market>[],
      serverUnavailable: GiftSession.instance.serverUnavailable,
    );
  }

  static bool _isCashMethod(Object? id) =>
      const {'cash_on_delivery', 'cod', 'cash'}.contains(id?.toString());

  /// Gifts are paid electronically only (the API refuses cash on delivery).
  List<Map<String, dynamic>> get _visiblePaymentMethods => _giftMode
      ? _paymentMethods.where((m) => !_isCashMethod(m['id'])).toList()
      : _paymentMethods;

  void _setGiftMode(bool value) {
    setState(() {
      _giftMode = value;
      _giftNameError = null;
      _giftPhoneError = null;
      if (value) {
        if (_isCashMethod(_selectedPaymentMethod)) {
          _selectedPaymentMethod = null;
          _paymentDetails = {};
        }
        // The API ignores points on gifts (they are valued in ETB).
        _redeemPoints = false;
        _redeemPointsAmount = 0;
      }
    });
    if (!value) GiftSession.instance.clear();
    _scheduleGrowthQuote(immediate: true);
  }

  void _stopGift() => _setGiftMode(false);

  Future<void> _loadDues() async {
    final dues = await CustomerDuesRepository().fetchSummary();
    if (!mounted || dues == null) return;
    setState(() => _dues = dues);
  }

  bool get _hasDues => _dues?.hasDues ?? false;

  bool get _storeBlocked => !(_storeStatus?.acceptingOrders ?? true);

  /// "Place order" stays disabled while a refusal needs fixing first.
  bool get _orderBlocked =>
      _storeBlocked || (_issue != null && !_issue!.isOutstandingDues);

  /// Records a refusal (call inside setState).
  void _setIssue(ApiErrorResult issue) {
    _issue = issue;
    if (issue.isStoreUnavailable) {
      final status = StoreStatus.tryParse(issue.storeStatus) ??
          StoreStatus(
            state: issue.isStorePaused ? StoreState.busy : StoreState.closed,
          );
      _storeStatus = status;
      final vendorId = _vendorId;
      if (vendorId != null) {
        StoreStatusRepository.instance.remember(vendorId, status);
      }
    }
  }

  /// A quote went through: store / city refusals no longer apply
  /// (call inside setState).
  void _clearResolvedIssue({bool soldOutToo = false}) {
    _storeStatus = null;
    final issue = _issue;
    if (issue == null) return;
    if (issue.isStoreUnavailable ||
        issue.isCityScopeError ||
        (soldOutToo && issue.isItemSoldOut)) {
      _issue = null;
    }
  }

  String? _cartItemName(int? productId) {
    if (productId == null) return null;
    for (final item in _cartItems) {
      if (_productId(item) == productId.toString()) {
        return item['name']?.toString();
      }
    }
    return null;
  }

  String _issueMessage(ApiErrorResult issue) =>
      localizedKnownApiError(
        context.l10n,
        issue,
        itemName: _cartItemName(issue.productId),
      ) ??
      issue.message;

  /// Wallet top-up; an open balance is collected from it automatically.
  Future<void> _openTopUpForDues({double? amount, String? currency}) async {
    MapEntry<String, double>? entry;
    for (final e in _dues?.amounts.entries ?? <MapEntry<String, double>>[]) {
      if (e.value > 0) {
        entry = e;
        break;
      }
    }
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => WalletTopUpPage(
          defaultCurrency: currency ?? entry?.key ?? _displayCurrency ?? 'ETB',
          initialAmount: amount ?? entry?.value,
        ),
      ),
    );
    if (!mounted) return;
    await _loadDues();
    if (!mounted) return;
    if (!_hasDues && (_issue?.isOutstandingDues ?? false)) {
      setState(() => _issue = null);
    }
  }

  Future<void> _showDuesDialog({double? amount, String? currency}) async {
    final l10n = context.l10n;
    final owed = amount ?? _firstDue?.value;
    final owedCurrency = currency ?? _firstDue?.key;
    final text = owed == null || owed <= 0
        ? l10n.p12CashBlockedByDues
        : l10n.p12ErrOutstandingDues(
            formatMoneyAmount(owed, currency: owedCurrency),
          );
    final payNow = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.p12DuesTitle),
        content: Text(text),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(l10n.p12ChooseOtherPayment),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(l10n.p12PayNow),
          ),
        ],
      ),
    );
    if (!mounted) return;
    if (payNow == true) {
      await _openTopUpForDues(amount: owed, currency: owedCurrency);
    } else if (_isCashMethod(_selectedPaymentMethod)) {
      setState(() {
        _selectedPaymentMethod = null;
        _paymentDetails = {};
      });
    }
  }

  MapEntry<String, double>? get _firstDue {
    for (final e in _dues?.amounts.entries ?? <MapEntry<String, double>>[]) {
      if (e.value > 0) return e;
    }
    return null;
  }

  /// Fix-it action for the current refusal.
  Widget _issueCard(ApiErrorResult issue) {
    final l10n = context.l10n;
    String? label;
    VoidCallback? action;
    IconData icon = Icons.error_outline_rounded;
    if (issue.isStoreUnavailable) {
      icon = issue.isStorePaused
          ? Icons.hourglass_top_rounded
          : Icons.storefront_outlined;
      label = l10n.actionRetry;
      action = () {
        setState(() => _issue = null);
        _refreshDeliveryFeeQuote(force: true);
        _growthQuoteKey = null;
        _scheduleGrowthQuote(immediate: true);
      };
    } else if (issue.isItemSoldOut) {
      icon = Icons.remove_shopping_cart_outlined;
      final productId = issue.productId?.toString();
      if (productId != null &&
          _cartItems.any((item) => _productId(item) == productId)) {
        label = l10n.p12RemoveItem;
        action = () => _removeItem(productId);
      }
    } else if (issue.code == kCityMarketMismatchCode &&
        cityNameForMarket(issue.marketCode) != null) {
      icon = Icons.location_city_outlined;
      label = l10n.p12ChangeCity;
      action = () async {
        final changed = await switchCustomerMarket(context, issue.marketCode!);
        if (!mounted || !changed) return;
        setState(() => _issue = null);
        _growthQuoteKey = null;
        _scheduleGrowthQuote(immediate: true);
      };
    } else if (issue.isCityScopeError) {
      icon = Icons.location_off_outlined;
      label = l10n.addressFormEditTitle;
      action = _onChangeAddress;
    }
    return CheckoutIssueCard(
      icon: icon,
      message: _issueMessage(issue),
      actionLabel: label,
      onAction: action,
    );
  }

  /// Refusals checkout explains itself; false for anything else.
  bool _handleKnownOrderFailure(PaymentFailure state) {
    final details = state.details ?? <String, dynamic>{};
    final parsed = parseApiErrorResult(
      {...details, if (state.code != null) 'code': state.code},
      statusCode: state.statusCode,
    );
    if (parsed.isOutstandingDues) {
      unawaited(_loadDues());
      _showDuesDialog(amount: parsed.amount, currency: parsed.currency);
      return true;
    }
    if (parsed.isStoreUnavailable ||
        parsed.isItemSoldOut ||
        parsed.isCityScopeError) {
      setState(() => _setIssue(parsed));
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(_issueMessage(parsed)),
          backgroundColor: Colors.red,
        ),
      );
      return true;
    }
    return false;
  }

  /// Validates the recipient; returns the `gift` order details or null
  /// (errors are shown on the fields and in a snackbar).
  Map<String, dynamic>? _validatedGift() {
    final l10n = context.l10n;
    final plan = _giftPhonePlan;
    final name = _giftNameController.text.trim();
    final phone = plan.normalize(_giftPhoneController.text);
    final nameError = name.isEmpty ? l10n.p9GiftNameRequired : null;
    final phoneError =
        phone == null ? l10n.p9GiftPhoneInvalid(plan.dialPrefix) : null;
    setState(() {
      _giftNameError = nameError;
      _giftPhoneError = phoneError;
    });
    final firstError = nameError ?? phoneError;
    if (firstError != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(firstError), backgroundColor: Colors.red),
      );
      return null;
    }
    final message = _giftMessageController.text.trim();
    return <String, dynamic>{
      'recipient_name': name,
      'recipient_phone': phone,
      if (message.isNotEmpty) 'gift_message': message,
    };
  }

  int? get _requestedRedeemPoints {
    if (_giftMode) return null;
    if (!_redeemPoints || !_growth.rewardsEnabled) return null;
    return _redeemPointsAmount > 0 ? _redeemPointsAmount : null;
  }

  CheckoutQuoteRequest? _currentGrowthRequest() {
    final vendorId = _vendorId;
    final lat = _deliveryLatitude;
    final lng = _deliveryLongitude;
    if (vendorId == null || lat == null || lng == null) return null;
    final items = _orderItems();
    if (items.isEmpty) return null;
    return CheckoutQuoteRequest(
      vendorId: vendorId,
      branchId: _branchId,
      items: items,
      deliveryAddress: _deliveryAddress.trim(),
      deliveryLatitude: lat,
      deliveryLongitude: lng,
      couponCode: _growth.promoCodesEnabled ? _appliedPromoCode : null,
      redeemPoints: _requestedRedeemPoints,
    );
  }

  /// Debounced re-quote whenever cart, address, coupon or points change.
  void _scheduleGrowthQuote({bool immediate = false}) {
    _growthQuoteDebounce?.cancel();
    if (!mounted || !_quoteEnabled) return;
    _growthQuotePending = true;
    _growthQuoteDebounce = Timer(
      immediate ? Duration.zero : const Duration(milliseconds: 450),
      _refreshGrowthQuote,
    );
  }

  Future<void> _refreshGrowthQuote() async {
    if (!mounted) return;
    final request =
        _quoteEnabled ? _currentGrowthRequest() : null;
    if (request == null) {
      setState(() => _growthQuotePending = false);
      return;
    }
    final key = request.cacheKey;
    if (_growthQuote != null && _growthQuoteKey == key) {
      setState(() => _growthQuotePending = false);
      return;
    }
    final requestId = ++_growthQuoteRequestId;
    final outcome = await _growthRepository.fetchCheckoutQuoteOutcome(request);
    final quote = outcome.quote;
    if (!mounted || requestId != _growthQuoteRequestId) return;
    // A newer change may have been scheduled while this was in flight.
    final stillPending = _growthQuoteDebounce?.isActive ?? false;
    if (quote == null) {
      // Fall back to the client-side display; explain refusals checkout
      // can fix (store closed / busy, sold-out item, wrong city).
      final error = outcome.error;
      setState(() {
        _growthQuote = null;
        _growthQuoteKey = null;
        _growthQuotePending = stillPending;
        if (error != null &&
            (error.isStoreUnavailable ||
                error.isItemSoldOut ||
                error.isCityScopeError)) {
          _setIssue(error);
        }
      });
      return;
    }
    final coupon = quote.coupon;
    final couponRejected =
        coupon != null && !coupon.valid && _appliedPromoCode != null;
    final invalidMessage = context.l10n.growthPromoInvalid;
    setState(() {
      _growthQuote = quote;
      _growthQuoteKey = key;
      _growthQuotePending = stillPending;
      _clearResolvedIssue(soldOutToo: true);
      if (couponRejected) {
        // Code became invalid (e.g. cart dropped below a minimum).
        _promoMessage = coupon.message ?? invalidMessage;
        _promoMessageIsError = true;
        _appliedPromoCode = null;
      }
    });
    // Keep the requested points in step with what the server allows
    // (max_redeemable does not depend on the request, so this settles).
    final maxPoints = quote.points.maxRedeemable;
    var pointsChanged = false;
    if (_redeemPoints && maxPoints != _redeemPointsAmount) {
      setState(() {
        if (maxPoints <= 0) {
          _redeemPoints = false;
          _redeemPointsAmount = 0;
        } else {
          _redeemPointsAmount = maxPoints;
        }
      });
      pointsChanged = true;
    }
    if (couponRejected || pointsChanged) _scheduleGrowthQuote(immediate: true);
  }

  void _applyPendingPromo() {
    if (!mounted) return;
    final controller = growthControllerOf(context);
    if (controller == null || !controller.promoCodesEnabled) return;
    final code = controller.takePendingPromoCode();
    if (code != null) _applyPromo(code);
  }

  Future<void> _applyPromo(String code) async {
    final trimmed = code.trim().toUpperCase();
    if (trimmed.isEmpty || !_growth.promoCodesEnabled) return;
    setState(() {
      _promoApplying = true;
      _promoMessage = null;
    });
    final result = await _growthRepository.previewPromo(
      code: trimmed,
      subtotal: _subtotal,
      vendorId: _vendorId,
    );
    if (!mounted) return;
    final l10n = context.l10n;
    setState(() {
      _promoApplying = false;
      if (result.valid) {
        _appliedPromoCode = result.code.toUpperCase();
        _promoMessage = result.message ?? l10n.growthPromoApplied;
        _promoMessageIsError = false;
      } else {
        _promoMessage = result.message ?? l10n.growthPromoInvalid;
        _promoMessageIsError = true;
      }
    });
    if (result.valid) _scheduleGrowthQuote(immediate: true);
  }

  void _removePromo() {
    setState(() {
      _appliedPromoCode = null;
      _promoMessage = null;
      _promoMessageIsError = false;
    });
    _scheduleGrowthQuote(immediate: true);
  }

  void _onRedeemPointsChanged(bool value) {
    final max = _growthQuote?.points.maxRedeemable ?? 0;
    setState(() {
      _redeemPoints = value && max > 0;
      _redeemPointsAmount = _redeemPoints ? max : 0;
    });
    _scheduleGrowthQuote(immediate: true);
  }

  String _productId(Map<String, dynamic> item) {
    final id = item['productId'] ?? item['product_id'] ?? item['id'];
    return id?.toString() ?? '';
  }

  int _quantityOf(Map<String, dynamic> item) {
    final quantity = item['quantity'];
    if (quantity is int) return quantity;
    return int.tryParse(quantity?.toString() ?? '') ?? 1;
  }

  double get _subtotal {
    return _cartItems.fold<double>(0, (sum, item) {
      final price = (item['price'] ?? 0.0).toDouble();
      return sum + price * _quantityOf(item);
    });
  }

  double get _quotedDeliveryFee {
    final quote = _deliveryFeeQuote;
    if (quote == null || !quote.isUsable) return 0;
    return quote.deliveryFee < 0 ? 0 : quote.deliveryFee;
  }

  double get _clientTotal => _subtotal + _tipAmount + _quotedDeliveryFee;

  /// Display total. Uses the server quote when available (tip is not part
  /// of the quote, so it is added on top), else the pre-Phase-2 math.
  double get _total {
    final quote = _activeGrowthQuote;
    if (quote == null) return _clientTotal;
    return quote.total + _tipAmount;
  }

  bool get _hasValidQuote =>
      _deliveryFeeQuote != null &&
      _deliveryFeeQuote!.isUsable &&
      !_quoteLoading &&
      _quoteError == null;

  String _formatMoney(double amount) {
    final quote = _deliveryFeeQuote;
    final symbol = quote?.currencySymbol.trim();
    if (symbol != null && symbol.isNotEmpty) {
      return '$symbol${amount.toStringAsFixed(2)}';
    }
    final code = quote?.currency.trim();
    if (code != null && code.isNotEmpty) {
      return formatMoneyAmount(amount, currency: code);
    }
    // ETB / unknown → identical to the previous 'ETB x.xx'.
    return formatMoneyAmount(amount, currency: _displayCurrency);
  }

  void _syncSharedCart(String productId, int quantity) {
    if (_cart.productFor(productId) != null) {
      _cart.setQuantity(productId, quantity);
    }
  }

  void _incrementItem(String productId) {
    final index = _cartItems.indexWhere((item) => _productId(item) == productId);
    if (index < 0) return;
    setState(() {
      final next = _quantityOf(_cartItems[index]) + 1;
      _cartItems[index]['quantity'] = next;
      _syncSharedCart(productId, next);
    });
    _scheduleGrowthQuote();
  }

  void _decrementItem(String productId) {
    final index = _cartItems.indexWhere((item) => _productId(item) == productId);
    if (index < 0) return;
    final current = _quantityOf(_cartItems[index]);
    if (current <= 1) {
      _removeItem(productId);
      return;
    }
    setState(() {
      final next = current - 1;
      _cartItems[index]['quantity'] = next;
      _syncSharedCart(productId, next);
    });
    _scheduleGrowthQuote();
  }

  void _removeItem(String productId) {
    setState(() {
      _cartItems.removeWhere((item) => _productId(item) == productId);
      _syncSharedCart(productId, 0);
      if ((_issue?.isItemSoldOut ?? false) &&
          _issue!.productId?.toString() == productId) {
        _issue = null;
      }
    });
    if (_cartItems.isEmpty && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(context.l10n.cartEmpty)),
      );
      Navigator.of(context).pop();
      return;
    }
    _scheduleGrowthQuote();
  }

  Future<void> _loadDeliveryAddress() async {
    final saved = await SavedLocationService.getSavedLocationData();
    final savedAddress = saved?['address'] as String?;
    if (savedAddress != null && savedAddress.isNotEmpty) {
      if (mounted) {
        setState(() {
          _deliveryAddress = savedAddress;
          _deliveryLatitude = (saved?['latitude'] as num?)?.toDouble();
          _deliveryLongitude = (saved?['longitude'] as num?)?.toDouble();
        });
        await _refreshDeliveryFeeQuote();
      }
      return;
    }
    try {
      final position = await LocationService.getCurrentPosition();
      final current = await LocationService.getCurrentLocationAddress();
      if (mounted) {
        setState(() {
          _deliveryAddress =
              current.isNotEmpty ? current : 'Select delivery address';
          _deliveryLatitude = position?.latitude;
          _deliveryLongitude = position?.longitude;
        });
        await _refreshDeliveryFeeQuote();
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _deliveryAddress = 'Select delivery address';
          _deliveryLatitude = null;
          _deliveryLongitude = null;
          _invalidateQuote(error: 'Choose a delivery location with coordinates.');
        });
      }
    }
  }

  void _invalidateQuote({String? error, bool retryable = false}) {
    _deliveryFeeQuote = null;
    _quoteCacheKey = null;
    _quoteError = error;
    _quoteRetryable = retryable;
    _quoteLoading = false;
  }

  Future<int?> _resolveBranchId() async {
    final cached = _branchId ?? _cart.selectedBranchId;
    if (cached != null && cached > 0) {
      _branchId = cached;
      return cached;
    }

    final vendorId = _vendorId;
    final lat = _deliveryLatitude;
    final lng = _deliveryLongitude;
    if (vendorId == null || lat == null || lng == null) return null;

    try {
      final branches =
          await _branchesRepository.getBranches(vendorId: vendorId);
      final nearest = pickNearestActiveBranch(
        branches: branches,
        latitude: lat,
        longitude: lng,
      );
      if (nearest == null) return null;
      _branchId = nearest.id;
      _branchName = nearest.name;
      _cart.setSelectedBranchId(nearest.id);
      return nearest.id;
    } catch (_) {
      return null;
    }
  }

  Future<void> _refreshDeliveryFeeQuote({bool force = false}) async {
    final lat = _deliveryLatitude;
    final lng = _deliveryLongitude;
    final address = _deliveryAddress.trim();

    if (lat == null || lng == null || address.isEmpty) {
      if (mounted) {
        setState(() {
          _invalidateQuote(
            error: 'Choose a delivery location with valid coordinates.',
          );
        });
      }
      return;
    }

    final requestId = ++_quoteRequestId;
    if (mounted) {
      setState(() {
        _quoteLoading = true;
        _quoteError = null;
        _quoteRetryable = false;
      });
    }

    final branchId = await _resolveBranchId();
    if (!mounted || requestId != _quoteRequestId) return;

    if (branchId == null || branchId <= 0) {
      setState(() {
        _invalidateQuote(
          error:
              'No delivery branch is available for this restaurant. Try another store.',
          retryable: true,
        );
      });
      return;
    }

    final cacheKey = deliveryFeeQuoteCacheKey(
      branchId: branchId,
      latitude: lat,
      longitude: lng,
      address: address,
    );

    final existing = _deliveryFeeQuote;
    if (!force &&
        existing != null &&
        existing.isUsable &&
        _quoteCacheKey == cacheKey) {
      if (mounted) {
        setState(() {
          _quoteLoading = false;
          _quoteError = null;
        });
      }
      return;
    }

    try {
      final quote = await _checkoutRepository.quoteDeliveryFee(
        branchId: branchId,
        deliveryAddress: address,
        deliveryLatitude: lat,
        deliveryLongitude: lng,
      );
      if (!mounted || requestId != _quoteRequestId) return;
      setState(() {
        _deliveryFeeQuote = quote;
        _quoteCacheKey = cacheKey;
        _quoteLoading = false;
        _quoteError = null;
        _quoteRetryable = false;
        _branchName = quote.restaurant?.name ?? _branchName;
        _clearResolvedIssue();
      });
      _scheduleGrowthQuote(immediate: true);
    } on DeliveryFeeQuoteException catch (e) {
      if (!mounted || requestId != _quoteRequestId) return;
      final l10n = context.l10n;
      final refusal = parseApiErrorResult(
        {...?e.details, if (e.code != null) 'code': e.code},
        statusCode: e.statusCode,
      );
      setState(() {
        _deliveryFeeQuote = null;
        _quoteCacheKey = null;
        _quoteLoading = false;
        _quoteRetryable = e.isRetryableNetwork || e.isBranchUnavailable;
        if (e.isUnauthenticated) {
          _quoteError = l10n.p12ErrSessionExpired;
        } else if (refusal.isStoreUnavailable || refusal.isCityScopeError) {
          // Store closed / busy, or the address is outside the city.
          _setIssue(refusal);
          _quoteError = _issueMessage(refusal);
          _quoteRetryable = refusal.isStoreUnavailable;
        } else if (e.isBranchUnavailable) {
          _quoteError =
              'This restaurant branch is not available for delivery. Please choose another branch or store.';
          _branchId = null;
          _cart.setSelectedBranchId(null);
        } else if (e.isBranchLocationUnavailable) {
          _quoteError =
              'Delivery pricing is temporarily unavailable for this restaurant.';
          _quoteRetryable = false;
        } else if (e.isValidation || e.errors != null) {
          _quoteError =
              'Please select a valid delivery location with coordinates.';
        } else {
          _quoteError = localizedApiErrorMessage(
            l10n,
            statusCode: e.statusCode,
            message: e.message,
            fallback: 'Unable to calculate delivery fee. Tap Retry.',
          );
          _quoteRetryable = true;
        }
      });
    } catch (_) {
      if (!mounted || requestId != _quoteRequestId) return;
      setState(() {
        _deliveryFeeQuote = null;
        _quoteCacheKey = null;
        _quoteLoading = false;
        _quoteRetryable = true;
        _quoteError = context.l10n.p12ErrNetwork;
      });
    }
  }

  int? get _vendorId {
    if (_cartItems.isEmpty) return null;
    final first = _cartItems.first;
    final vid = first['vendor_id'];
    if (vid is int) return vid;
    if (vid != null) return int.tryParse(vid.toString());
    return null;
  }

  // Phase 2: promo codes are shown only when GET /growth/config reports
  // promo_codes.enabled. Codes are validated by POST /customer/growth/
  // promo-preview and priced by POST /customer/checkout/quote; the order is
  // sent with `coupon_code` and the server recomputes every discount.

  void _onChangeAddress() async {
    final Map<String, dynamic>? result =
        await Navigator.push<Map<String, dynamic>>(
      context,
      MaterialPageRoute(
        builder: (context) => MapLocationScreen(
          currentLocation: _deliveryAddress,
        ),
      ),
    );

    final newAddress = result?['address'] as String?;
    final latitude = (result?['latitude'] as num?)?.toDouble();
    final longitude = (result?['longitude'] as num?)?.toDouble();
    if (newAddress != null && newAddress.isNotEmpty) {
      if (latitude != null && longitude != null) {
        await SavedLocationService.saveLocationData(
          address: newAddress,
          latitude: latitude,
          longitude: longitude,
        );
      } else {
        await SavedLocationService.saveAddress(newAddress);
      }
      if (mounted) {
        setState(() {
          _deliveryAddress = newAddress;
          _deliveryLatitude = latitude;
          _deliveryLongitude = longitude;
          _invalidateQuote();
          if (_issue?.isCityScopeError ?? false) _issue = null;
        });
        await _refreshDeliveryFeeQuote(force: true);
        if (!mounted) return;

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(context.l10n.addressUpdatedTo(newAddress)),
            backgroundColor: AppColors.primaryColor,
          ),
        );
      }
    }
  }

  void _onConfirmOrder(BuildContext blocContext) {
    final issue = _issue;
    if (_orderBlocked) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            issue != null && !issue.isOutstandingDues
                ? _issueMessage(issue)
                : storeUnavailableMessage(context.l10n, _storeStatus),
          ),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }
    if (_hasDues && _isCashMethod(_selectedPaymentMethod) && !_giftMode) {
      _showDuesDialog();
      return;
    }
    if (_quoteLoading) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Calculating delivery fee…'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    if (!_hasValidQuote) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            _quoteError ??
                'Delivery fee is required before placing the order.',
          ),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    final List<Map<String, dynamic>> orderItems = _orderItems();

    if (orderItems.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(context.l10n.addValidProductsToCart),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    if (_deliveryLatitude == null || _deliveryLongitude == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(context.l10n.chooseDeliveryLocationFromMap),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    if (_selectedPaymentMethod == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(context.l10n.paymentSelectMethodFirst),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    if (!isAllowedPaymentMethodCode(_selectedPaymentMethod)) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(context.l10n.paymentMethodUnavailable),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    Map<String, dynamic>? gift;
    if (_giftMode) {
      if (_isCashMethod(_selectedPaymentMethod)) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(context.l10n.p9GiftNoCash),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }
      gift = _validatedGift();
      if (gift == null) return;
    }

    if (paymentMethodNeedsDetailsForm(_selectedPaymentMethod)) {
      final phoneError = validatePaymentPhone(
        _paymentDetails['phone']?.toString(),
        _selectedPaymentMethod!,
      );
      if (phoneError != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(phoneError), backgroundColor: Colors.red),
        );
        return;
      }
      if (_selectedPaymentMethod == 'ebirr') {
        final provider = _paymentDetails['provider']?.toString();
        if (provider != 'kaafi' && provider != 'coop') {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(context.l10n.selectEbirrProvider),
              backgroundColor: Colors.red,
            ),
          );
          return;
        }
      }
    }

    final vendorId = _vendorId;
    if (vendorId == null || vendorId <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(context.l10n.unableToDetermineStore),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    final branchId = _branchId;
    if (branchId == null || branchId <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Unable to determine restaurant branch.'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    final initiateDetails = buildInitiatePaymentDetails(
      paymentMethodCode: _selectedPaymentMethod!,
      collectedDetails: _paymentDetails,
      orderId: 0,
    );

    blocContext.read<PaymentBloc>().add(
          ProcessPaymentEvent(
            paymentMethod: _selectedPaymentMethod!,
            amount: _total,
            orderId: '0',
            paymentDetails: {
              ...initiateDetails,
              'order_details': {
                'vendor_id': vendorId,
                'branch_id': branchId,
                'items': orderItems,
                'tax_amount': 0.0,
                'discount_amount': 0.0,
                'delivery_address': _deliveryAddress,
                'delivery_location': _deliveryAddress,
                'delivery_latitude': _deliveryLatitude!,
                'delivery_longitude': _deliveryLongitude!,
                'service_type': 'restaurant',
                'notes': _notesController.text.trim().isEmpty
                    ? null
                    : _notesController.text.trim(),
                'subtotal': _subtotal,
                // Comparison only — never trusted by the backend as fee authority.
                'quoted_delivery_fee': _activeGrowthQuote?.deliveryFee ??
                    _quotedDeliveryFee,
                // Phase 2 inputs; the server validates and prices them.
                if (_growth.promoCodesEnabled && _appliedPromoCode != null)
                  'coupon_code': _appliedPromoCode,
                // Only when the toggle is visible (server quote present).
                if (_requestedRedeemPoints != null &&
                    _activeGrowthQuote != null)
                  'redeem_points': _requestedRedeemPoints,
                // Phase 6: recipient → POST /customer/gift-orders.
                if (gift != null) 'gift': gift,
              },
            },
          ),
        );
  }

  List<Map<String, dynamic>> _orderItems() {
    return _cartItems
        .map((item) {
          final productId =
              item['productId'] ?? item['product_id'] ?? item['id'];
          final quantity = item['quantity'] ?? 1;
          final pid = productId is int
              ? productId
              : int.tryParse(productId.toString()) ?? 0;
          final qty = quantity is int
              ? quantity
              : int.tryParse(quantity.toString()) ?? 1;
          final variantRaw =
              item['variant_id'] ?? item['variantId'] ?? item['variant'];
          final variantId = variantRaw is int
              ? variantRaw
              : int.tryParse(variantRaw?.toString() ?? '');
          return <String, dynamic>{
            'product_id': pid,
            'quantity': qty,
            if (variantId != null && variantId > 0) 'variant_id': variantId,
          };
        })
        .where((e) => (e['product_id'] as int) > 0)
        .toList();
  }

  int get _itemCount {
    return _cartItems.fold<int>(
      0,
      (sum, item) => sum + _quantityOf(item),
    );
  }

  /// Promo / points / free-delivery widgets; all empty when features are off.
  List<Widget> _growthSections(BuildContext context, GrowthConfig growth) {
    final l10n = context.l10n;
    final quote = _activeGrowthQuote;
    final sections = <Widget>[];

    if (growth.freeDeliveryEnabled && quote != null) {
      final free = quote.freeDelivery;
      if (free.showHint) {
        sections.add(FreeDeliveryHint(
          remainingLabel: _formatMoney(free.remaining),
          progress: free.progress,
        ));
      } else if (free.enabled && free.applied) {
        sections.add(const FreeDeliveryUnlockedBanner());
      }
    }

    if (_showPlusUpsell) {
      sections.add(PlusUpsellBanner(onTap: _openPlus));
    }

    if (growth.promoCodesEnabled) {
      sections.add(CheckoutSectionCard(
        icon: Icons.local_offer_outlined,
        title: l10n.growthPromoTitle,
        subtitle: l10n.growthPromoSubtitle,
        child: GrowthPromoCodeSection(
          appliedCode: _appliedPromoCode,
          applying: _promoApplying,
          message: _promoMessage,
          messageIsError: _promoMessageIsError,
          onApply: _applyPromo,
          onRemove: _removePromo,
        ),
      ));
    }

    // Points: shown when rewards are on and the server says some can be
    // redeemed (balance ≥ minimum is enforced server-side via max_redeemable).
    final points = _growthQuote?.points;
    if (growth.rewardsEnabled &&
        !_giftMode &&
        points != null &&
        points.balance >= growth.rewardsMinRedeemPoints &&
        points.maxRedeemable > 0) {
      final redeemable = points.maxRedeemable;
      final value = _redeemPoints && quote != null && quote.pointsDiscount > 0
          ? quote.pointsDiscount
          : pointsToEtb(
              redeemable,
              redeemPoints: growth.rewardsRedeemPoints,
              redeemValue: growth.rewardsRedeemValue,
            );
      sections.add(Padding(
        padding: const EdgeInsets.only(bottom: 16),
        child: GrowthPointsToggle(
          points: redeemable,
          amountLabel: _formatMoney(value),
          value: _redeemPoints,
          onChanged: _onRedeemPointsChanged,
        ),
      ));
    }
    return sections;
  }

  @override
  Widget build(BuildContext context) {
    final growth = growthConfigOf(context);
    final growthQuote = _activeGrowthQuote;
    return BlocProvider(
      create: (context) => PaymentBloc(
        paymentRepository: PaymentRepository(
          paymentDataProvider: PaymentDataProvider(
            apiService: ApiService.instance,
          ),
        ),
        checkoutRepository: _checkoutRepository,
      )..add(const GetPaymentMethodsEvent()),
      child: Builder(
        builder: (blocContext) => Scaffold(
          backgroundColor: Theme.of(context).scaffoldBackgroundColor,
          extendBodyBehindAppBar: true,
          appBar: AppBar(
            backgroundColor: Colors.transparent,
            elevation: 0,
            surfaceTintColor: Colors.transparent,
            leading: Padding(
              padding: const EdgeInsets.only(left: 4),
              child: IconButton(
                style: IconButton.styleFrom(
                  backgroundColor:
                      AppColors.lightOnPrimary.withValues(alpha: 0.2),
                ),
                icon: const Icon(Icons.arrow_back_ios_new_rounded,
                    color: AppColors.lightOnPrimary, size: 18),
                onPressed: () => Navigator.of(context).pop(),
              ),
            ),
            title: const Text(
              'Checkout',
              style: TextStyle(
                color: AppColors.lightOnPrimary,
                fontWeight: FontWeight.w700,
              ),
            ),
            centerTitle: true,
          ),
          bottomNavigationBar: BlocBuilder<PaymentBloc, PaymentState>(
            builder: (context, state) {
              return CheckoutBottomBar(
                total: _total,
                totalLabel: _formatMoney(_total),
                isLoading: state is PaymentLoading,
                enabled: _hasValidQuote &&
                    !_orderBlocked &&
                    state is! PaymentLoading,
                confirmLabel: _storeBlocked
                    ? context.l10n.p12StoreOrderingPaused
                    : _quoteLoading
                        ? 'Calculating…'
                        : (!_hasValidQuote ? 'Waiting for fee' : null),
                onConfirm: () => _onConfirmOrder(blocContext),
                currency: _displayCurrency,
              );
            },
          ),
          body: BlocListener<PaymentBloc, PaymentState>(
            listener: (context, state) {
              if (state is PaymentMethodsLoaded) {
                setState(() {
                  _paymentMethods = state.paymentMethods.isNotEmpty
                      ? state.paymentMethods
                      : List.from(kDefaultAllowedPaymentMethods);
                  _loadingMethods = false;
                  if (_selectedPaymentMethod != null &&
                      !_paymentMethods.any(
                        (m) => m['id'] == _selectedPaymentMethod,
                      )) {
                    _selectedPaymentMethod = null;
                    _paymentDetails = {};
                  }
                });
              } else if (state is PaymentInitiated) {
                if (state.deliveryFeeUpdated) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text(
                        'Delivery fee updated for the selected address.',
                      ),
                      backgroundColor: AppColors.primaryColor,
                    ),
                  );
                }
                CartService().clear();
                final giftName = state.giftRecipientName;
                if (state.isGift) GiftSession.instance.clear();
                Navigator.of(context).pushReplacement(
                  MaterialPageRoute(
                    builder: (_) => PaymentInitiateResultScreen(
                      result: state.result,
                      orderId: state.orderId,
                      banner: giftName == null
                          ? null
                          : GiftPlacedBanner(recipientName: giftName),
                    ),
                  ),
                );
              } else if (state is PaymentOrderNeedsAttention) {
                // Order exists; keep the customer on it (refreshes totals /
                // status) instead of a generic failure + duplicate risk.
                openOrderAfterPaymentIssue(
                  context,
                  issue: state.issue,
                  orderId: state.orderId,
                );
              } else if (state is PaymentSuccess) {
                CartService().clear();
                Navigator.of(context).pushReplacement(
                  MaterialPageRoute(
                    builder: (_) => PaymentInitiateResultScreen(
                      result: PaymentInitiateResult(
                        isSuccess: true,
                        uiMode: PaymentInitiateUiMode.success,
                        status: 'completed',
                        message: state.message,
                        transactionId: state.transactionId,
                      ),
                      orderId: state.transactionId,
                    ),
                  ),
                );
              } else if (state is PaymentFailure &&
                  GiftSession.unavailableCodes.contains(state.code)) {
                // Gifting is off / not migrated: hide it and keep the cart.
                unawaited(GiftSession.instance.markUnavailable());
                setState(() {
                  _giftMode = false;
                  _giftNameError = null;
                  _giftPhoneError = null;
                });
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(context.l10n.p9GiftUnavailable),
                    backgroundColor: Colors.red,
                  ),
                );
              } else if (state is PaymentFailure &&
                  !_loadingMethods &&
                  _handleKnownOrderFailure(state)) {
                // Explained above (store, sold out, dues, city).
              } else if (state is PaymentFailure) {
                if (_loadingMethods) {
                  setState(() {
                    _loadingMethods = false;
                    _paymentMethods =
                        List.from(kDefaultAllowedPaymentMethods);
                  });
                } else {
                  // Network / server failures in the app language; messages
                  // that mention an order number stay as written.
                  final text = state.error.contains('#')
                      ? state.error
                      : localizedApiErrorMessage(
                          context.l10n,
                          statusCode: state.statusCode,
                          message: state.error,
                        );
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(text),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              }
            },
            child: CustomScrollView(
              slivers: [
                SliverToBoxAdapter(
                  child: CheckoutHeroHeader(
                    itemCount: _itemCount,
                    subtotal: _subtotal,
                    currency: _displayCurrency,
                  ),
                ),
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
                  sliver: SliverList(
                    delegate: SliverChildListDelegate([
                      if (_storeBlocked && _storeStatus != null)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 16),
                          child: StoreStatusBanner(status: _storeStatus!),
                        ),
                      if (_issue != null &&
                          !_issue!.isStoreUnavailable &&
                          !_issue!.isOutstandingDues)
                        _issueCard(_issue!),
                      if (_hasDues && !_giftMode)
                        ParcelDuesBanner(
                          dues: _dues!,
                          message: context.l10n.p12DuesCheckoutBody,
                          onPayNow: _openTopUpForDues,
                        ),
                      if (_giftMode && GiftSession.instance.market != null)
                        GiftModeBanner(
                          marketName: GiftSession.instance.market!.name,
                          onStop: _stopGift,
                        ),
                      CheckoutSectionCard(
                        icon: Icons.shopping_basket_outlined,
                        title: 'Your items',
                        subtitle:
                            '${_cartItems.length} product${_cartItems.length == 1 ? '' : 's'} in cart',
                        child: Column(
                          children: _cartItems.map((item) {
                            final productId = _productId(item);
                            return CheckoutProductCard(
                              productId: productId,
                              productName:
                                  item['name'] ?? 'Unknown Product',
                              productImage: item['image'] ?? '',
                              quantity: _quantityOf(item),
                              price: (item['price'] ?? 0.0).toDouble(),
                              onIncrement: () => _incrementItem(productId),
                              onDecrement: () => _decrementItem(productId),
                              onRemove: () => _removeItem(productId),
                              currency: _displayCurrency,
                            );
                          }).toList(),
                        ),
                      ),
                      CheckoutSectionCard(
                        icon: Icons.location_on_outlined,
                        title: 'Delivery',
                        subtitle: _branchName != null
                            ? 'From $_branchName'
                            : 'Where should we bring your order?',
                        child: DeliveryAddressSection(
                          currentAddress: _deliveryAddress,
                          onChangeAddress: _onChangeAddress,
                        ),
                      ),
                      if (_showGiftSection)
                        CheckoutSectionCard(
                          icon: Icons.card_giftcard_rounded,
                          title: context.l10n.p9GiftSectionTitle,
                          subtitle: context.l10n.p9GiftSectionSubtitle,
                          accentColor: AppColors.brandOrange,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              SwitchListTile.adaptive(
                                key: const ValueKey('gift-toggle'),
                                contentPadding: EdgeInsets.zero,
                                value: _giftMode,
                                onChanged: _setGiftMode,
                                title: Text(context.l10n.p9GiftToggle),
                              ),
                              if (_giftMode)
                                GiftRecipientForm(
                                  nameController: _giftNameController,
                                  phoneController: _giftPhoneController,
                                  messageController: _giftMessageController,
                                  phonePlan: _giftPhonePlan,
                                  nameError: _giftNameError,
                                  phoneError: _giftPhoneError,
                                  onChanged: () {
                                    if (_giftNameError != null ||
                                        _giftPhoneError != null) {
                                      setState(() {
                                        _giftNameError = null;
                                        _giftPhoneError = null;
                                      });
                                    }
                                  },
                                ),
                            ],
                          ),
                        ),
                      CheckoutSectionCard(
                        icon: Icons.edit_note_outlined,
                        title: 'Order notes',
                        subtitle: 'Optional — help us find you faster',
                        child: NotesSection(
                          notesController: _notesController,
                        ),
                      ),
                      CheckoutSectionCard(
                        icon: Icons.volunteer_activism_outlined,
                        title: 'Tip your rider',
                        subtitle: 'Show appreciation for great service',
                        accentColor: AppColors.secondaryColor,
                        child: TipSection(
                          currentTip: _tipAmount,
                          currency: _displayCurrency,
                          onTipChanged: (value) {
                            setState(() => _tipAmount = value);
                          },
                        ),
                      ),
                      // Phase 2: promo code, points and free-delivery hint
                      // (each hidden unless enabled by GET /growth/config).
                      ..._growthSections(context, growth),
                      CheckoutSectionCard(
                        icon: Icons.account_balance_wallet_outlined,
                        title: 'Payment method',
                        subtitle: 'Choose how you want to pay',
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            PaymentMethodGridSection(
                              selectedId: _selectedPaymentMethod,
                              methods: _visiblePaymentMethods,
                              isLoading: _loadingMethods,
                              onSelected: (id) => setState(() {
                                _selectedPaymentMethod = id;
                                _paymentDetails = {};
                                _useHpp = false;
                                _ebirrProvider = 'kaafi';
                              }),
                            ),
                            if (_selectedPaymentMethod != null)
                              PaymentDetailsForm(
                                key: ValueKey(_selectedPaymentMethod),
                                paymentMethodCode: _selectedPaymentMethod!,
                                ebirrProvider: _ebirrProvider,
                                useHpp: _useHpp,
                                onEbirrProviderChanged: (v) =>
                                    setState(() => _ebirrProvider = v),
                                onUseHppChanged: (v) =>
                                    setState(() => _useHpp = v),
                                onChanged: (details) {
                                  _paymentDetails = details;
                                },
                              ),
                            // The API converts a wallet in another currency
                            // but does not return the converted amount.
                            if (_giftMode &&
                                _selectedPaymentMethod == 'wallet')
                              Padding(
                                padding: const EdgeInsets.only(top: 8),
                                child: Text(
                                  context.l10n.p9GiftWalletNote,
                                  style: TextStyle(
                                    fontSize: 12.5,
                                    color: Theme.of(context)
                                        .colorScheme
                                        .onSurfaceVariant,
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                      CheckoutSectionCard(
                        icon: Icons.receipt_outlined,
                        title: 'Order summary',
                        child: OrderSummarySection(
                          subtotal: growthQuote?.subtotal ?? _subtotal,
                          tipAmount: _tipAmount,
                          total: _total,
                          deliveryFee: growthQuote?.deliveryFee ??
                              _deliveryFeeQuote?.deliveryFee,
                          formattedDeliveryFee: growthQuote != null
                              ? null
                              : _deliveryFeeQuote?.formattedDeliveryFee,
                          deliveryFeeBeforeDiscounts:
                              growthQuote?.deliveryFeeBeforeDiscounts,
                          couponDiscount: growthQuote?.couponDiscount ?? 0,
                          couponCode: growthQuote?.coupon?.code,
                          pointsDiscount: growthQuote?.pointsDiscount ?? 0,
                          plusFreeDelivery: growthQuote?.plusApplied ?? false,
                          setDeliveryIncluded:
                              growthQuote?.setDeliveryIncluded ?? false,
                          deliveryNote: _setDeliveryNote(growthQuote),
                          currencyCode:
                              _deliveryFeeQuote?.currency.trim().isNotEmpty ==
                                      true
                                  ? _deliveryFeeQuote!.currency
                                  : growthQuote?.currency,
                          currencySymbol: _deliveryFeeQuote?.currencySymbol,
                          deliveryFeeLoading: _quoteLoading,
                          deliveryFeeError: _quoteError,
                          onRetryDeliveryFee: _quoteRetryable
                              ? () => _refreshDeliveryFeeQuote(force: true)
                              : null,
                          distanceKm: _deliveryFeeQuote?.distanceKm,
                          estimatedDurationMinutes:
                              _deliveryFeeQuote?.estimatedDurationMinutes,
                        ),
                      ),
                    ]),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _growthQuoteDebounce?.cancel();
    PlusController.instance.removeListener(_onPlusChanged);
    _notesController.dispose();
    _giftNameController.dispose();
    _giftPhoneController.dispose();
    _giftMessageController.dispose();
    super.dispose();
  }
}
