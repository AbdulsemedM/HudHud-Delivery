import 'package:flutter/material.dart';
import 'package:hudhud_delivery/app/services/cart_service.dart';
import 'package:hudhud_delivery/features/checkout/presentation/screen/checkout_screen.dart';

Future<void> openCheckoutFromCart(
  BuildContext context, {
  int? fallbackVendorId,
}) async {
  final cart = CartService();
  if (cart.isEmpty) return;

  if (!context.mounted) return;
  await Navigator.of(context).push<void>(
    MaterialPageRoute(
      builder: (_) => CheckoutScreen(
        cartItems: cart.toCheckoutItems(fallbackVendorId: fallbackVendorId),
        subtotal: cart.subtotal,
      ),
    ),
  );
}
