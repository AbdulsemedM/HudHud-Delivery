import 'package:flutter/material.dart';
import 'package:hudhud_delivery/app/services/cart_service.dart';
import 'package:hudhud_delivery/app/services/guest_browse_service.dart';
import 'package:hudhud_delivery/core/l10n/context_l10n.dart';
import 'package:hudhud_delivery/features/checkout/presentation/screen/checkout_screen.dart';
import 'package:hudhud_delivery/features/guest/utils/guest_sign_in_prompt.dart';

Future<void> openCheckoutFromCart(
  BuildContext context, {
  int? fallbackVendorId,
}) async {
  final cart = CartService();
  if (cart.isEmpty) return;

  if (GuestBrowseService().isGuestBrowseMode) {
    await showGuestSignInRequiredDialog(
      context,
      message: context.l10n.guestSignInRequiredCheckout,
    );
    return;
  }

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
