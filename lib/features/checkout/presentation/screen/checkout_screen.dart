import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../app/services/cart_service.dart';
import '../../../../app/services/location_service.dart';
import '../../../../app/services/saved_location_service.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/api/api_service.dart';
import '../../bloc/checkout_bloc.dart';
import '../../data/data_provider/checkout_data_provider.dart';
import '../../data/repository/checkout_repository.dart';
import '../widgets/checkout_widgets.dart';
import '../../../home/presentation/screen/map_location_screen.dart';

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
  late List<Map<String, dynamic>> _cartItems;
  double _tipAmount = 0.0;
  String _deliveryAddress = 'Loading address...';
  double? _deliveryLatitude;
  double? _deliveryLongitude;
  String? _selectedPaymentMethod;

  @override
  void initState() {
    super.initState();
    _cartItems = widget.cartItems
        .map((item) => Map<String, dynamic>.from(item))
        .toList();
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
        const SnackBar(content: Text('Your cart is empty')),
      );
      Navigator.of(context).pop();
    }
  }

  Future<void> _loadDeliveryAddress() async {
    // 1. Try saved address
    final saved = await SavedLocationService.getSavedLocationData();
    final savedAddress = saved?['address'] as String?;
    if (savedAddress != null && savedAddress.isNotEmpty) {
      if (mounted) {
        setState(() {
          _deliveryAddress = savedAddress;
          _deliveryLatitude = (saved?['latitude'] as num?)?.toDouble();
          _deliveryLongitude = (saved?['longitude'] as num?)?.toDouble();
        });
      }
      return;
    }
    // 2. Fallback to current GPS location
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
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _deliveryAddress = 'Select delivery address';
          _deliveryLatitude = null;
          _deliveryLongitude = null;
        });
      }
    }
  }

  /// Vendor ID from first cart item (required for order placement).
  int? get _vendorId {
    if (_cartItems.isEmpty) return null;
    final first = _cartItems.first;
    final vid = first['vendor_id'];
    if (vid is int) return vid;
    if (vid != null) return int.tryParse(vid.toString());
    return null;
  }

  double get _total {
    return _subtotal + _tipAmount;
  }

  void _onPromoCodeApplied(String promoCode) {
    // Handle promo code logic here
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Promo code "$promoCode" applied'),
        backgroundColor: AppColors.primaryColor,
      ),
    );
  }

  void _onChangeAddress() async {
    // Navigate to map location screen
    final Map<String, dynamic>? result = await Navigator.push<Map<String, dynamic>>(
      context,
      MaterialPageRoute(
        builder: (context) => MapLocationScreen(
          currentLocation: _deliveryAddress,
        ),
      ),
    );

    // Update address if user selected a new one
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
        });
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Address updated to: $newAddress'),
            backgroundColor: AppColors.primaryColor,
          ),
        );
      }
    }
  }

  void _onConfirmOrder(BuildContext blocContext) {
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
          return {'product_id': pid, 'quantity': qty};
        })
        .where((e) => (e['product_id'] as int) > 0)
        .toList();

    if (orderItems.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please add valid products to your cart'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    if (_deliveryLatitude == null || _deliveryLongitude == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please choose a delivery location from the map'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    if (_selectedPaymentMethod == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select a payment method'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    final vendorId = _vendorId;
    if (vendorId == null || vendorId <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Unable to determine store for this order'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    blocContext.read<CheckoutBloc>().add(
          CreateOrderEvent(
            vendorId: vendorId,
            items: orderItems,
            taxAmount: 0.0,
            discountAmount: 0.0,
            deliveryAddress: _deliveryAddress,
            deliveryLocation: _deliveryAddress,
            deliveryLatitude: _deliveryLatitude!,
            deliveryLongitude: _deliveryLongitude!,
            paymentMethod: _selectedPaymentMethod!,
            notes: _notesController.text.trim().isEmpty
                ? null
                : _notesController.text.trim(),
          ),
        );
  }

  void _showOrderSuccessDialog(BuildContext ctx, Map<String, dynamic> orderData) {
    final orderId = orderData['id']?.toString() ?? '—';
    showDialog(
      context: ctx,
      barrierDismissible: false,
      builder: (_) => CheckoutSuccessDialog(
        orderId: orderId,
        onDone: () {
          Navigator.of(ctx).pop();
          Navigator.of(ctx).pop();
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
      create: (context) => CheckoutBloc(
        checkoutRepository: CheckoutRepository(
          checkoutDataProvider: CheckoutDataProvider(
            apiService: ApiService.instance,
          ),
        ),
      ),
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
                  backgroundColor: Colors.white.withValues(alpha: 0.2),
                ),
                icon: const Icon(Icons.arrow_back_ios_new_rounded,
                    color: Colors.white, size: 18),
                onPressed: () => Navigator.of(context).pop(),
              ),
            ),
            title: const Text(
              'Checkout',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w700,
              ),
            ),
            centerTitle: true,
          ),
          bottomNavigationBar: BlocBuilder<CheckoutBloc, CheckoutState>(
            builder: (context, state) {
              return CheckoutBottomBar(
                total: _total,
                isLoading: state is CheckoutLoading,
                onConfirm: () => _onConfirmOrder(blocContext),
              );
            },
          ),
          body: BlocListener<CheckoutBloc, CheckoutState>(
            listener: (context, state) {
              if (state is OrderCreatedSuccess) {
                CartService().clear();
                _showOrderSuccessDialog(context, state.orderData);
              } else if (state is CheckoutError) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(state.message),
                    backgroundColor: Colors.red,
                  ),
                );
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
                        subtitle: 'Where should we bring your order?',
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
                        child: PaymentMethodGridSection(
                          selectedId: _selectedPaymentMethod,
                          onSelected: (id) =>
                              setState(() => _selectedPaymentMethod = id),
                        ),
                      ),
                      CheckoutSectionCard(
                        icon: Icons.receipt_outlined,
                        title: 'Order summary',
                        child: OrderSummarySection(
                          subtotal: _subtotal,
                          tipAmount: _tipAmount,
                          total: _total,
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
