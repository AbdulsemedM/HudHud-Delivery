import 'package:flutter/material.dart';
import '../widgets/orders_widget.dart';

class OrdersScreen extends StatelessWidget {
  const OrdersScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final List<Map<String, String>> orders = [
      {
        'distance': '2',
        'amount': '12.00',
        'dateTime': '29 JUN | 5:00PM',
      },
      {
        'distance': '2',
        'amount': '12.00',
        'dateTime': '29 JUN | 5:00PM',
      },
      {
        'distance': '2',
        'amount': '12.00',
        'dateTime': '29 JUN | 5:00PM',
      },
      {
        'distance': '2',
        'amount': '45.00',
        'dateTime': '21 JUN | 5:00PM',
      },
    ];

    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              OrdersHeader(
                onFilterTap: () {
                  // Handle filter tap
                },
              ),
              const SizedBox(height: 24),
              OrdersTitle(
                onFilterTap: () {
                  // Handle filter tap
                },
              ),
              const SizedBox(height: 24),
              ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: orders.length,
                itemBuilder: (context, index) {
                  final order = orders[index];
                  return OrderItem(
                    distance: order['distance']!,
                    amount: order['amount']!,
                    dateTime: order['dateTime']!,
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
