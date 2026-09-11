import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../app/services/cart_service.dart';
import '../../../../app/services/location_service.dart';
import '../../../../app/services/saved_location_service.dart';
import '../../../../core/l10n/context_l10n.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/api/api_service.dart';
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

  double get _total => _subtotal + _tipAmount + _quotedDeliveryFee;

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
    return 'ETB ${amount.toStringAsFixed(2)}';
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
    }
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

  void _onPromoCodeApplied(String promoCode) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(context.l10n.promoCodeApplied(promoCode)),
        backgroundColor: AppColors.primaryColor,
      ),
    );
  }

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

    final List<Map<String, dynamic>> orderItems = _cartItems
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
          return {
            'product_id': pid,
            'quantity': qty,
            if (variantId != null && variantId > 0) 'variant_id': variantId,
          };
        })
        .where((e) => (e['product_id'] as int) > 0)
        .toList();

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
                'quoted_delivery_fee': _quotedDeliveryFee,
              },
            },
          ),
        );
  }

  int get _itemCount {
    return _cartItems.fold<int>(
      0,
      (sum, item) => sum + _quantityOf(item),
    );
  }

  @override
  Widget build(BuildContext context) {
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
                          onTipChanged: (value) {
                            setState(() => _tipAmount = value);
                          },
                        ),
                      ),
                      CheckoutSectionCard(
                        icon: Icons.local_offer_outlined,
                        title: 'Promo code',
                        child: PromoCodeSection(
                          onPromoCodeApplied: _onPromoCodeApplied,
                        ),
                      ),
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
                          subtotal: _subtotal,
                          tipAmount: _tipAmount,
                          total: _total,
                          deliveryFee: _deliveryFeeQuote?.deliveryFee,
                          formattedDeliveryFee:
                              _deliveryFeeQuote?.formattedDeliveryFee,
                          currencyCode: _deliveryFeeQuote?.currency,
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
    _notesController.dispose();
    super.dispose();
  }
}
