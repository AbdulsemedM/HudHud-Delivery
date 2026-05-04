import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
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
  double _tipAmount = 0.0;
  String _deliveryAddress = 'Loading address...';
  double? _deliveryLatitude;
  double? _deliveryLongitude;
  String? _selectedPaymentMethod;
  String? _validatedCouponCode;
  Map<String, dynamic>? _validatedCouponData;
  static const String _serviceType = 'restaurant';

  @override
  void initState() {
    super.initState();
    _loadDeliveryAddress();
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

  /// Vendor ID from first cart item's product (all items in a category are typically from same vendor)
  int get _vendorId {
    final first = widget.cartItems.isNotEmpty ? widget.cartItems.first : null;
    if (first == null) return 7;
    final vid = first['vendor_id'];
    if (vid is int) return vid;
    if (vid != null) return int.tryParse(vid.toString()) ?? 7;
    return 7;
  }

  double get _total {
    return widget.subtotal + _tipAmount;
  }

  Future<void> _onPromoCodeApplied(String promoCode) async {
    final normalizedCode = promoCode.trim().toUpperCase();
    if (normalizedCode.isEmpty) return;

    final checkoutRepository = context.read<CheckoutBloc>().checkoutRepository;
    final result = await checkoutRepository.validateCoupon(
      code: normalizedCode,
      orderAmount: _total,
      vendorId: _vendorId,
      serviceType: _serviceType,
    );

    if (!mounted) return;

    if (result['success'] == true) {
      final dataWrapper = result['data'] as Map<String, dynamic>?;
      final couponData = dataWrapper?['data'] as Map<String, dynamic>?;
      setState(() {
        _validatedCouponCode = normalizedCode;
        _validatedCouponData = couponData;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(result['message']?.toString() ?? 'Coupon is valid!'),
          backgroundColor: AppColors.primaryColor,
        ),
      );
      return;
    }

    setState(() {
      _validatedCouponCode = null;
      _validatedCouponData = null;
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(result['message']?.toString() ?? 'Invalid coupon'),
        backgroundColor: Colors.red,
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
    final List<Map<String, dynamic>> orderItems = widget.cartItems
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

    blocContext.read<CheckoutBloc>().add(
          CreateOrderEvent(
            vendorId: _vendorId,
            items: orderItems,
            taxAmount: 0.0,
            discountAmount: 0.0,
            deliveryAddress: _deliveryAddress,
            deliveryLocation: _deliveryAddress,
            deliveryLatitude: _deliveryLatitude!,
            deliveryLongitude: _deliveryLongitude!,
            paymentMethod: _selectedPaymentMethod!,
            couponCode: _validatedCouponCode,
            serviceType: _serviceType,
            notes: _notesController.text.trim().isEmpty
                ? null
                : _notesController.text.trim(),
          ),
        );
  }

  void _showOrderSuccessDialog(BuildContext ctx, Map<String, dynamic> orderData) {
    final orderPayload = orderData['order'] is Map<String, dynamic>
        ? orderData['order'] as Map<String, dynamic>
        : orderData;
    final orderId = orderPayload['id']?.toString() ?? '—';
    final couponApplied = orderData['coupon_applied'] as Map<String, dynamic>?;
    final couponCode = couponApplied?['code']?.toString();
    final couponSaved = couponApplied?['saved']?.toString();
    showDialog(
      context: ctx,
      barrierDismissible: false,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        contentPadding: const EdgeInsets.all(24),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                color: AppColors.primaryColor.withOpacity(0.12),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.check_circle,
                color: AppColors.primaryColor,
                size: 44,
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              'Order Placed!',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              'Order #$orderId has been placed successfully.',
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 14, color: Colors.grey),
            ),
            if (couponCode != null && couponCode.isNotEmpty) ...[
              const SizedBox(height: 10),
              Text(
                couponSaved != null && couponSaved.isNotEmpty
                    ? 'Coupon $couponCode applied. You saved $couponSaved.'
                    : 'Coupon $couponCode applied successfully.',
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 13, color: Colors.green),
              ),
            ],
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primaryColor,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                onPressed: () {
                  Navigator.of(ctx).pop(); // close dialog
                  Navigator.of(ctx).pop(); // leave checkout
                },
                child: const Text(
                  'Done',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ),
            ),
          ],
        ),
      ),
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
        backgroundColor: Theme.of(context).brightness == Brightness.dark
            ? AppColors.darkBackground
            : Colors.grey[50],
        appBar: AppBar(
          backgroundColor: Theme.of(context).brightness == Brightness.dark
              ? AppColors.darkSurface
              : Colors.white,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(
              Icons.arrow_back,
              color: AppColors.lightTextPrimary,
            ),
            onPressed: () => Navigator.of(context).pop(),
          ),
          title: const Text(
            'Checkout',
            style: TextStyle(
              color: AppColors.lightTextPrimary,
              fontSize: 18,
              fontWeight: FontWeight.w600,
            ),
          ),
          centerTitle: true,
        ),
        body: BlocListener<CheckoutBloc, CheckoutState>(
          listener: (context, state) {
            if (state is OrderCreatedSuccess) {
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
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Products Section
                Text(
                  'Products',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).brightness == Brightness.dark
                        ? AppColors.darkOnSurface
                        : AppColors.lightTextPrimary,
                  ),
                ),
                const SizedBox(height: 12),
                ...widget.cartItems.map((item) {
                  return CheckoutProductCard(
                    productName: item['name'] ?? 'Unknown Product',
                    productImage: item['image'] ?? '',
                    quantity: item['quantity'] ?? 1,
                    price: (item['price'] ?? 0.0).toDouble(),
                  );
                }).toList(),

                // Delivery Address Section
                DeliveryAddressSection(
                  currentAddress: _deliveryAddress,
                  onChangeAddress: _onChangeAddress,
                ),

                // Notes Section
                NotesSection(
                  notesController: _notesController,
                ),

                // Tip Section
                TipSection(
                  currentTip: _tipAmount,
                  onTipChanged: (value) {
                    setState(() {
                      _tipAmount = value;
                      _validatedCouponCode = null;
                      _validatedCouponData = null;
                    });
                  },
                ),

                // Promo Code Section
                PromoCodeSection(
                  onPromoCodeApplied: _onPromoCodeApplied,
                ),
                if (_validatedCouponCode != null) ...[
                  const SizedBox(height: 4),
                  Text(
                    _validatedCouponData?['value_display'] != null
                        ? 'Coupon ${_validatedCouponCode!} applied (${_validatedCouponData!['value_display']}).'
                        : 'Coupon ${_validatedCouponCode!} applied.',
                    style: const TextStyle(
                      color: Colors.green,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],

                // Payment Method Grid
                PaymentMethodGridSection(
                  selectedId: _selectedPaymentMethod,
                  onSelected: (id) => setState(() => _selectedPaymentMethod = id),
                ),

                // Order Summary Section
                OrderSummarySection(
                  subtotal: widget.subtotal,
                  tipAmount: _tipAmount,
                  total: _total,
                ),

                // Confirm Order Button
                BlocBuilder<CheckoutBloc, CheckoutState>(
                  builder: (context, state) {
                    return ConfirmOrderButton(
                      onPressed: () => _onConfirmOrder(blocContext),
                      isLoading: state is CheckoutLoading,
                    );
                  },
                ),
              ],
            ),
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
