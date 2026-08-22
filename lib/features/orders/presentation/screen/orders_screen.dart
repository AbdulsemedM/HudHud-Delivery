import 'package:flutter/material.dart';
import 'package:hudhud_delivery/features/home/presentation/theme/home_colors.dart';
import 'package:hudhud_delivery/features/orders/presentation/widgets/orders_coming_soon_screen.dart';

/// Orders tab — marketplace order history launches later; courier lives on Home.
class OrdersScreen extends StatelessWidget {
  const OrdersScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Theme(
      data: HomeColors.darkTheme(Theme.of(context)),
      child: const Scaffold(
        backgroundColor: HomeColors.background,
        body: SafeArea(
          child: OrdersComingSoonScreen(),
        ),
      ),
    );
  }
}
