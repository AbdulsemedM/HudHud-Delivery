import 'package:flutter/material.dart';

import 'package:hudhud_delivery/core/l10n/context_l10n.dart';
import 'package:hudhud_delivery/core/theme/app_colors.dart';
import 'package:hudhud_delivery/core/utils/money_format.dart';
import 'package:hudhud_delivery/features/delivery/presentation/screens/product_detail_screen.dart';
import 'package:hudhud_delivery/features/delivery/presentation/screens/store_detail_screen.dart';
import 'package:hudhud_delivery/features/home/presentation/theme/home_colors.dart';

import '../../data/models/hudhud_set.dart';
import 'growth_network_image.dart';

/// Small "Delivery included" badge shown on every set card.
class SetDeliveryIncludedBadge extends StatelessWidget {
  const SetDeliveryIncludedBadge({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
      decoration: BoxDecoration(
        color: AppColors.brandOrange,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.delivery_dining_rounded,
              size: 13, color: Colors.white),
          const SizedBox(width: 3),
          Flexible(
            child: Text(
              context.l10n.p5SetDeliveryIncluded,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 11.5,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Horizontal "HudHud Sets" row. Renders nothing when [page] has no items.
class HudHudSetRow extends StatelessWidget {
  const HudHudSetRow({super.key, required this.page});

  final HudHudSetsPage page;

  @override
  Widget build(BuildContext context) {
    final items = page.items;
    if (items.isEmpty) return const SizedBox.shrink();
    final l10n = context.l10n;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 24, 16, 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                l10n.p5SetsTitle,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.4,
                  color: HomeColors.textPrimaryOf(context),
                ),
              ),
              const SizedBox(height: 2),
              Text(
                '${l10n.p5SetsSubtitle} · ${l10n.p5SetsMaxPerOrder(page.maxPerOrder)}',
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: HomeColors.textMutedOf(context),
                ),
              ),
            ],
          ),
        ),
        SizedBox(
          height: 224,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: items.length,
            separatorBuilder: (_, __) => const SizedBox(width: 12),
            itemBuilder: (context, index) => SizedBox(
              width: 164,
              child: HudHudSetCard(item: items[index]),
            ),
          ),
        ),
      ],
    );
  }
}

/// Set card: image, name, vendor, price, "Delivery included" badge.
///
/// Tap → product detail (the app's normal add-to-cart flow, including the
/// "different restaurant" confirmation). Tap on the vendor line → store.
class HudHudSetCard extends StatelessWidget {
  const HudHudSetCard({super.key, required this.item});

  final HudHudSetItem item;

  void _openProduct(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ProductDetailScreen(productId: item.productId),
      ),
    );
  }

  void _openVendor(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => StoreDetailScreen(
          storeName: item.vendorName.isNotEmpty
              ? item.vendorName
              : context.l10n.growthStoreFallbackName,
          vendorId: item.vendorId,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final dark = HomeColors.isDark(context);
    final radius = BorderRadius.circular(18);
    final vendorName = item.vendorName.isNotEmpty
        ? item.vendorName
        : l10n.growthStoreFallbackName;
    final price = formatMoneyAmount(item.price, currency: item.currency);
    final imagePath = item.imagePath;
    final image = item.imageUrl ??
        (imagePath != null && imagePath.startsWith('http') ? imagePath : null);
    return Semantics(
      button: true,
      label: '${item.name}, $vendorName, $price, ${l10n.p5SetDeliveryIncluded}',
      child: DecoratedBox(
        decoration: BoxDecoration(
          borderRadius: radius,
          boxShadow: AppColors.softShadow(context),
        ),
        child: Material(
          color: HomeColors.surfaceOf(context),
          shape: RoundedRectangleBorder(
            borderRadius: radius,
            side: dark
                ? BorderSide(color: HomeColors.borderOf(context))
                : BorderSide.none,
          ),
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            onTap: () => _openProduct(context),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      GrowthNetworkImage(
                        url: image,
                        icon: Icons.lunch_dining_rounded,
                        memCacheWidth: 360,
                      ),
                      const Positioned(
                        left: 8,
                        top: 8,
                        right: 8,
                        child: Align(
                          alignment: Alignment.centerLeft,
                          child: SetDeliveryIncludedBadge(),
                        ),
                      ),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(10, 8, 10, 4),
                  child: Text(
                    item.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 14.5,
                      fontWeight: FontWeight.w800,
                      color: HomeColors.textPrimaryOf(context),
                    ),
                  ),
                ),
                InkWell(
                  onTap: () => _openVendor(context),
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(10, 2, 10, 2),
                    child: Text(
                      vendorName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: HomeColors.textMutedOf(context),
                      ),
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(10, 2, 10, 10),
                  child: Text(
                    price,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w800,
                      color: AppColors.brandOrange,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
