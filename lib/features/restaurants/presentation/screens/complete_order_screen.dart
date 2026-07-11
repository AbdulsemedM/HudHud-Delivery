import 'package:flutter/material.dart';
import 'package:hudhud_delivery/core/theme/app_colors.dart';
import '../widgets/complete_order_widget.dart';

class CompleteOrderScreen extends StatefulWidget {
  const CompleteOrderScreen({super.key});

  @override
  State<CompleteOrderScreen> createState() => _CompleteOrderScreenState();
}

class _CompleteOrderScreenState extends State<CompleteOrderScreen> {
  final TextEditingController _commentController = TextEditingController();
  bool _showCompleteOrder = false;

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  void _handleSubmit() {
    if (_commentController.text.isNotEmpty) {
      setState(() {
        _showCompleteOrder = true;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          SafeArea(
            child: SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Delivery Summary Card
                    const DeliverySummaryCard(
                      amount: 4512.00,
                      duration: '6h 22m',
                      distance: 420.00,
                      deliveryType: 'Normal Delivery',
                    ),
                    const SizedBox(height: 32),

                    // Location Points
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 4),
                      child: const Column(
                        children: [
                          LocationPoint(
                            isPickup: true,
                            location: 'XQXH+5RG',
                            details: 'Addis Ababa, Ethiopioa',
                          ),
                          LocationConnector(),
                          LocationPoint(
                            isPickup: false,
                            location: 'XQXH+5RG',
                            details: 'Addis Ababa, Ethiopioa',
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 32),

                    // Billing Details
                    const BillingDetailsTable(
                      baseFare: 12.00,
                      distanceCharges: 0.00,
                      minutesCharges: 0.00,
                      tip: 0.00,
                      total: 12.00,
                    ),
                    const SizedBox(height: 24),

                    // Driver Info
                    const DriverInfo(
                      name: 'Abdilahi Mohumed',
                      imageUrl: 'assets/images/driver.jpg',
                    ),
                    const SizedBox(height: 24),

                    // Comment Section
                    CommentSection(
                      controller: _commentController,
                      onSubmit: _handleSubmit,
                    ),
                    // Add extra padding at bottom for complete order bar
                    if (_showCompleteOrder) const SizedBox(height: 80),
                  ],
                ),
              ),
            ),
          ),
          if (_showCompleteOrder)
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                decoration: BoxDecoration(
                  color: AppColors.primaryColor,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 10,
                      offset: const Offset(0, -5),
                    ),
                  ],
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Ready to complete?',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    TextButton(
                      onPressed: () {
                        // Handle complete order
                      },
                      style: TextButton.styleFrom(
                        backgroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 24,
                          vertical: 12,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: Text(
                        'Complete My Order',
                        style: TextStyle(
                          color: AppColors.primaryColor,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}
