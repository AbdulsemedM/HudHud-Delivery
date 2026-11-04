import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../app/services/cart_service.dart';
import '../../../../app/services/location_service.dart';
import '../../../../app/services/saved_location_service.dart';
import '../../../../core/l10n/context_l10n.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/api/api_service.dart';
import '../../../growth/data/growth_repository.dart';
import '../../../growth/data/models/checkout_quote.dart';
import '../../../growth/data/models/checkout_quote_request.dart';
import '../../../growth/data/models/growth_config.dart';
import '../../../growth/growth_scope.dart';
import '../../../growth/market_controller.dart';
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
import '../../../payment/presentation/screen/payment_initiate_result_screen.dart';
import '../../../payment/presentation/widgets/payment_details_form.dart';
import '../../data/data_provider/checkout_data_provider.dart';
import '../../data/models/delivery_fee_quote.dart';
import '../../data/repository/checkout_repository.dart';
import '../../utils/nearest_branch.dart';
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
    _loadDeliveryAddress();
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
    return growth.loaded && PlusController.instance.status.isMember;
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

  int? get _requestedRedeemPoints {
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
    final quote = await _growthRepository.fetchCheckoutQuote(request);
    if (!mounted || requestId != _growthQuoteRequestId) return;
    // A newer change may have been scheduled while this was in flight.
    final stillPending = _growthQuoteDebounce?.isActive ?? false;
    if (quote == null) {
      // Fall back to the client-side display.
      setState(() {
        _growthQuote = null;
        _growthQuoteKey = null;
        _growthQuotePending = stillPending;
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
      if (couponRejected) {
        // Code became invalid (e.g. cart dropped below a minimum).
        _promoMessage = coupon?.message ?? invalidMessage;
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
      return '$code ${amount.toStringAsFixed(2)}';
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
      });
      _scheduleGrowthQuote(immediate: true);
    } on DeliveryFeeQuoteException catch (e) {
      if (!mounted || requestId != _quoteRequestId) return;
      setState(() {
        _deliveryFeeQuote = null;
        _quoteCacheKey = null;
        _quoteLoading = false;
        _quoteRetryable = e.isRetryableNetwork || e.isBranchUnavailable;
        if (e.isUnauthenticated) {
          _quoteError = 'Your session expired. Please log in again.';
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
          _quoteError = e.message.isNotEmpty
              ? e.message
              : 'Unable to calculate delivery fee. Tap Retry.';
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
        _quoteError =
            'Unable to calculate delivery fee. Check your connection and retry.';
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
                enabled: _hasValidQuote && state is! PaymentLoading,
                confirmLabel: _quoteLoading
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
                Navigator.of(context).pushReplacement(
                  MaterialPageRoute(
                    builder: (_) => PaymentInitiateResultScreen(
                      result: state.result,
                      orderId: state.orderId,
                    ),
                  ),
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
              } else if (state is PaymentFailure) {
                if (_loadingMethods) {
                  setState(() {
                    _loadingMethods = false;
                    _paymentMethods =
                        List.from(kDefaultAllowedPaymentMethods);
                  });
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(state.error),
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
                              methods: _paymentMethods,
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
    super.dispose();
  }
}
