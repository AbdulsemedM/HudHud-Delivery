import 'package:flutter/material.dart';

import 'package:hudhud_delivery/app/navigation/cart_navigation.dart';
import 'package:hudhud_delivery/app/services/cart_service.dart';
import 'package:hudhud_delivery/core/l10n/context_l10n.dart';
import 'package:hudhud_delivery/core/theme/app_colors.dart';
import 'package:hudhud_delivery/l10n/app_localizations.dart';

import '../data/growth_repository.dart';
import '../data/models/reorder.dart';

/// Rebuilds the cart from a past order (`POST /customer/orders/{id}/reorder`)
/// and opens checkout.
///
/// - Single-vendor cart: asks before replacing a cart from another store.
/// - Lists items the server reported as unavailable.
/// - Never leaves the cart half-filled: items are only added after the
///   user confirms.
Future<void> runReorderFlow(
  BuildContext context, {
  required int orderId,
  GrowthRepository? repository,
}) async {
  final repo = repository ?? GrowthRepository.create();
  final l10n = context.l10n;
  final messenger = ScaffoldMessenger.maybeOf(context);

  final navigator = Navigator.of(context, rootNavigator: true);
  var progressShown = true;
  showDialog<void>(
    context: context,
    barrierDismissible: false,
    useRootNavigator: true,
    // Not dismissible by back: closeProgress() must pop exactly this route.
    builder: (_) => const PopScope(
      canPop: false,
      child: Center(
        child: CircularProgressIndicator(color: AppColors.brandOrange),
      ),
    ),
  );
  void closeProgress() {
    if (progressShown) {
      progressShown = false;
      navigator.pop();
    }
  }

  ReorderResult? fetched;
  String? errorMessage;
  try {
    fetched = await repo.reorder(orderId);
  } on GrowthException catch (e) {
    errorMessage = e.message.isNotEmpty ? e.message : null;
  } catch (_) {
    errorMessage = null;
  }
  closeProgress();
  final result = fetched;
  if (result == null) {
    messenger?.showSnackBar(
      SnackBar(
        content: Text(errorMessage ?? l10n.growthReorderFailed),
        backgroundColor: AppColors.errorColor,
      ),
    );
    return;
  }
  if (!context.mounted) return;

  if (result.items.isEmpty) {
    await _showUnavailableDialog(context, l10n, result.unavailable,
        nothingAvailable: true);
    return;
  }

  final cart = CartService();
  final vendorId = result.vendorId > 0
      ? result.vendorId
      : (result.items.first.vendorId > 0 ? result.items.first.vendorId : null);
  if (cart.conflictsWithVendor(vendorId)) {
    final replace = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.cartDifferentVendorTitle),
        content: Text(l10n.growthReorderReplaceMessage),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(l10n.cartKeepCurrentAction),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(l10n.cartReplaceAction),
          ),
        ],
      ),
    );
    if (replace != true || !context.mounted) return;
  }

  if (result.unavailable.isNotEmpty) {
    final proceed = await _showUnavailableDialog(
      context,
      l10n,
      result.unavailable,
      nothingAvailable: false,
    );
    if (proceed != true || !context.mounted) return;
  }

  var added = 0;
  for (var i = 0; i < result.items.length; i++) {
    final item = result.items[i];
    final outcome = cart.addProduct(
      item.toCartProduct(),
      quantity: item.quantity,
      // Only the first add may clear another vendor's cart (already confirmed).
      replaceIfDifferentVendor: i == 0,
    );
    if (outcome == CartAddResult.added) added++;
  }
  if (added == 0 || !context.mounted) return;

  await openCheckoutFromCart(context, fallbackVendorId: vendorId);
}

String _reasonLabel(AppLocalizations l10n, String reason) {
  switch (reason) {
    case 'out_of_stock':
      return l10n.growthReorderReasonOutOfStock;
    case 'vendor_closed':
      return l10n.growthReorderReasonVendorClosed;
    case 'removed':
      return l10n.growthReorderReasonRemoved;
    default:
      return l10n.growthReorderReasonUnavailable;
  }
}

/// Returns true when the user chose to continue with the available items.
Future<bool?> _showUnavailableDialog(
  BuildContext context,
  AppLocalizations l10n,
  List<ReorderUnavailableItem> unavailable, {
  required bool nothingAvailable,
}) {
  return showDialog<bool>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: Text(
        nothingAvailable
            ? l10n.growthReorderNothingAvailable
            : l10n.growthReorderUnavailableTitle,
      ),
      content: unavailable.isEmpty
          ? null
          : SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  for (final item in unavailable)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 4),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Icon(
                            Icons.remove_shopping_cart_outlined,
                            size: 20,
                            color: AppColors.errorColor,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              item.name.isEmpty
                                  ? _reasonLabel(l10n, item.reason)
                                  : '${item.name} — ${_reasonLabel(l10n, item.reason)}',
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            ),
      actions: nothingAvailable
          ? [
              TextButton(
                onPressed: () => Navigator.pop(ctx, false),
                child: Text(l10n.actionOk),
              ),
            ]
          : [
              TextButton(
                onPressed: () => Navigator.pop(ctx, false),
                child: Text(l10n.actionCancel),
              ),
              TextButton(
                onPressed: () => Navigator.pop(ctx, true),
                child: Text(l10n.growthReorderContinue),
              ),
            ],
    ),
  );
}
