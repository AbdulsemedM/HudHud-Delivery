import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import 'package:hudhud_delivery/core/l10n/context_l10n.dart';
import 'package:hudhud_delivery/core/theme/app_colors.dart';
import 'package:hudhud_delivery/features/delivery/presentation/screens/product_detail_screen.dart';
import 'package:hudhud_delivery/features/delivery/presentation/screens/store_detail_screen.dart';

import '../data/models/home_feed.dart';
import '../growth_scope.dart';
import 'screens/home_collection_screen.dart';

/// Handles a banner tap by its action type. Unknown / invalid actions are
/// ignored (never crash).
Future<void> handleHomeFeedBannerTap(
  BuildContext context,
  HomeFeedBanner banner, {
  required List<HomeFeedCollection> collections,
}) async {
  final value = banner.actionValue?.trim() ?? '';
  switch (banner.actionType) {
    case HomeFeedActionType.vendor:
      {
        final vendorId = int.tryParse(value);
        if (vendorId == null || vendorId <= 0) return;
        await Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => StoreDetailScreen(
              storeName: banner.title.isNotEmpty
                  ? banner.title
                  : context.l10n.growthStoreFallbackName,
              vendorId: vendorId,
            ),
          ),
        );
        return;
      }
    case HomeFeedActionType.product:
      {
        final productId = int.tryParse(value);
        if (productId == null || productId <= 0) return;
        await Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => ProductDetailScreen(productId: productId),
          ),
        );
        return;
      }
    case HomeFeedActionType.collection:
      {
        HomeFeedCollection? match;
        for (final c in collections) {
          if (c.matchesKey(value)) {
            match = c;
            break;
          }
        }
        final found = match;
        if (found == null) return;
        await Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => HomeCollectionScreen(collection: found),
          ),
        );
        return;
      }
    case HomeFeedActionType.url:
      await openGrowthUrl(context, value);
      return;
    case HomeFeedActionType.promo:
      {
        if (value.isEmpty) return;
        final controller = growthControllerOf(context);
        if (controller == null || !controller.promoCodesEnabled) return;
        controller.setPendingPromoCode(value);
        ScaffoldMessenger.maybeOf(context)?.showSnackBar(
          SnackBar(
            content: Text(
              context.l10n.growthPromoSavedForCheckout(value.toUpperCase()),
            ),
            backgroundColor: AppColors.primaryColor,
          ),
        );
        return;
      }
    case HomeFeedActionType.none:
      return;
  }
}

/// Opens an http(s) link in the in-app browser, falling back to external.
Future<void> openGrowthUrl(BuildContext context, String raw) async {
  final uri = Uri.tryParse(raw.trim());
  if (uri == null || !(uri.scheme == 'https' || uri.scheme == 'http')) return;
  try {
    final ok = await launchUrl(uri, mode: LaunchMode.inAppBrowserView);
    if (ok) return;
  } catch (_) {}
  try {
    await launchUrl(uri, mode: LaunchMode.externalApplication);
  } catch (_) {}
}

/// Opens a feed item (vendor → store, product → product detail).
void openHomeFeedItem(BuildContext context, HomeFeedItem item) {
  if (item.isVendor) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => StoreDetailScreen(
          storeName: item.name.isNotEmpty
              ? item.name
              : context.l10n.growthStoreFallbackName,
          storeImage: item.imageUrl,
          vendorId: item.id,
        ),
      ),
    );
    return;
  }
  Navigator.push(
    context,
    MaterialPageRoute(builder: (_) => ProductDetailScreen(productId: item.id)),
  );
}
