import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
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
  double _discount = 100.0;
  double _extras = 0.0;
  double _serviceCharge = 16.90;
  double _deliveryFee = 47.00;
  String _deliveryAddress = 'KCK+MCP, Bole, Addis Ababa, Ethiopia';
  String _paymentMethod = 'card';
  int _vendorId = 7; // Default vendor ID

  double get _total {
    return widget.subtotal - _discount + _extras + _serviceCharge + _deliveryFee;
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
      setState(() {
        _deliveryAddress = newAddress;
      });
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Address updated to: $newAddress'),
          backgroundColor: AppColors.primaryColor,
        ),
      );
    }
  }

  void _onConfirmOrder() {
    // Prepare order items for API
    final List<Map<String, dynamic>> orderItems = widget.cartItems.map((item) {
      return {
        'product_id': item['productId'] ?? item['id'],
        'quantity': item['quantity'] ?? 1,
      };
    }).toList();

    // Generate temporary order ID
    final String orderId = 'ORDER_${DateTime.now().millisecondsSinceEpoch}';

    // Prepare order details for payment
    final Map<String, dynamic> orderDetails = {
      'vendor_id': _vendorId,
      'items': orderItems,
      'subtotal': widget.subtotal,
      'discount': _discount,
      'service_charge': _serviceCharge,
      'delivery_fee': _deliveryFee,
      'delivery_address': _deliveryAddress,
      'notes': _notesController.text.trim().isEmpty ? null : _notesController.text.trim(),
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
        backgroundColor: Colors.grey[50],
        appBar: AppBar(
          backgroundColor: Colors.white,
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
                const Text(
                  'Products',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: AppColors.lightTextPrimary,
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

                // Order Summary Section
                OrderSummarySection(
                  subtotal: widget.subtotal,
                  discount: _discount,
                  extras: _extras,
                  serviceCharge: _serviceCharge,
                  deliveryFee: _deliveryFee,
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