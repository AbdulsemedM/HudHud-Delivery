import 'package:flutter/material.dart';

import 'package:hudhud_delivery/core/l10n/context_l10n.dart';
import 'package:hudhud_delivery/core/theme/app_colors.dart';
import 'package:hudhud_delivery/features/home/presentation/theme/home_colors.dart';

import '../../data/models/sponsored.dart';
import '../sponsored_actions.dart';
import 'growth_network_image.dart';

/// Small "Sponsored" label shown on every ad card.
class SponsoredLabel extends StatelessWidget {
  const SponsoredLabel({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.62),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        context.l10n.p3Sponsored,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 11.5,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.2,
        ),
      ),
    );
  }
}

/// Horizontal row of sponsored vendor cards (home feed / search results).
/// Renders nothing when [items] is empty.
class SponsoredVendorRow extends StatelessWidget {
  const SponsoredVendorRow({
    super.key,
    required this.items,
    this.padding = const EdgeInsets.only(top: 16),
  });

  final List<SponsoredItem> items;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: padding,
      child: SizedBox(
        height: 176,
        child: ListView.separated(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          itemCount: items.length,
          separatorBuilder: (_, __) => const SizedBox(width: 12),
          itemBuilder: (context, index) => SizedBox(
            width: 150,
            child: SponsoredVendorCard(item: items[index]),
          ),
        ),
      ),
    );
  }
}

/// Vendor card with a "Sponsored" label; tap → click report + store.
class SponsoredVendorCard extends StatelessWidget {
  const SponsoredVendorCard({super.key, required this.item});

  final SponsoredItem item;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final dark = HomeColors.isDark(context);
    final radius = BorderRadius.circular(18);
    final parts = <String>[
      if (item.rating != null && item.rating! > 0)
        '★ ${item.rating!.toStringAsFixed(1)}',
      if (item.isOpen == false) l10n.growthClosed,
    ];
    final meta = parts.isEmpty ? null : parts.join(' · ');
    final name = item.vendorName.isNotEmpty
        ? item.vendorName
        : l10n.growthStoreFallbackName;
    return Semantics(
      button: true,
      label: '$name, ${l10n.p3Sponsored}',
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
            onTap: () => openSponsoredItem(context, item),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      GrowthNetworkImage(
                        url: item.imageUrl,
                        icon: Icons.storefront_rounded,
                        memCacheWidth: 360,
                      ),
                      const Positioned(
                        left: 8,
                        top: 8,
                        child: SponsoredLabel(),
                      ),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(10, 8, 10, 10),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 14.5,
                          fontWeight: FontWeight.w800,
                          color: HomeColors.textPrimaryOf(context),
                        ),
                      ),
                      if (meta != null) ...[
                        const SizedBox(height: 2),
                        Text(
                          meta,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: HomeColors.textMutedOf(context),
                          ),
                        ),
                      ],
                    ],
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
