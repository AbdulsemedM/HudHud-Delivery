import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:hudhud_delivery/core/theme/system_ui_style.dart';
import 'package:hudhud_delivery/features/home/presentation/theme/home_colors.dart';
import 'package:hudhud_delivery/features/orders/presentation/widgets/orders_coming_soon_screen.dart';

/// Orders tab — marketplace order history launches later; courier lives on Home.
class OrdersScreen extends StatelessWidget {
  const OrdersScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Theme(
      data: HomeColors.themeFor(context),
      child: AnnotatedRegion<SystemUiOverlayStyle>(
        value: systemUiOverlayFor(context),
        child: Scaffold(
          backgroundColor: HomeColors.backgroundOf(context),
          body: const SafeArea(
            child: OrdersComingSoonScreen(),
          ),
        ),
      ),
    );
  }
}
