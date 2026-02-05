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
import '../../../payment/presentation/screen/payment_screen.dart';

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

  @override
  void initState() {
    super.initState();
    _loadDeliveryAddress();
  }

  Future<void> _loadDeliveryAddress() async {
    // 1. Try saved address
    final saved = await SavedLocationService.getSavedAddress();
    if (saved != null && saved.isNotEmpty) {
      if (mounted) {
        setState(() => _deliveryAddress = saved);
      }
      return;
    }
    // 2. Fallback to current GPS location
    try {
      final current = await LocationService.getCurrentLocationAddress();
      if (mounted) {
        setState(() {
          _deliveryAddress =
              current.isNotEmpty ? current : 'Select delivery address';
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() => _deliveryAddress = 'Select delivery address');
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
    final String? newAddress = await Navigator.push<String>(
      context,
      MaterialPageRoute(
        builder: (context) => MapLocationScreen(
          currentLocation: _deliveryAddress,
        ),
      ),
    );

    // Update address if user selected a new one
    if (newAddress != null && newAddress.isNotEmpty) {
      await SavedLocationService.saveAddress(newAddress);
      if (mounted) {
        setState(() {
          _deliveryAddress = newAddress;
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

  void _onConfirmOrder() {
    // Prepare order items for API: [{product_id: int, quantity: int}]
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

    // Generate temporary order ID (replaced by server order ID after creation)
    final String orderId = 'ORDER_${DateTime.now().millisecondsSinceEpoch}';

    // Prepare order details for POST /api/customer/orders
    final Map<String, dynamic> orderDetails = {
      'vendor_id': _vendorId,
      'items': orderItems,
      'tax_amount': 0.0,
      'discount_amount': 0.0,
      'delivery_address': _deliveryAddress,
      'notes': _notesController.text.trim().isEmpty
          ? null
          : _notesController.text.trim(),
      'subtotal': widget.subtotal,
      'tip_amount': _tipAmount,
    };

    // Navigate to payment screen
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => PaymentScreen(
          orderId: orderId,
          totalAmount: _total,
          orderDetails: orderDetails,
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
      child: Scaffold(
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
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(state.message),
                  backgroundColor: Colors.green,
                ),
              );
              // Navigate back or to order confirmation screen
              Navigator.of(context).pop();
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

                // Promo Code Section
                PromoCodeSection(
                  onPromoCodeApplied: _onPromoCodeApplied,
                ),

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
                    });
                  },
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
                      onPressed: _onConfirmOrder,
                      isLoading: state is CheckoutLoading,
                    );
                  },
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
