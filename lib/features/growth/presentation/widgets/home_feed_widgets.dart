import 'dart:async';

import 'package:flutter/material.dart';

import 'package:hudhud_delivery/core/l10n/context_l10n.dart';
import 'package:hudhud_delivery/core/theme/app_colors.dart';
import 'package:hudhud_delivery/core/utils/money_format.dart';
import 'package:hudhud_delivery/features/home/presentation/theme/home_colors.dart';

import '../../data/models/home_feed.dart';
import '../../data/models/reorder.dart';
import '../home_feed_actions.dart';
import '../reorder_flow.dart';
import '../screens/home_collection_screen.dart';
import 'growth_network_image.dart';

class _GrowthSectionHeader extends StatelessWidget {
  const _GrowthSectionHeader({required this.title, this.onSeeAll});

  final String title;
  final VoidCallback? onSeeAll;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 24, 8, 12),
      child: Row(
        children: [
          Expanded(
            child: Text(
              title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w800,
                letterSpacing: -0.4,
                color: HomeColors.textPrimaryOf(context),
              ),
            ),
          ),
          if (onSeeAll != null)
            TextButton(
              onPressed: onSeeAll,
              style: TextButton.styleFrom(
                foregroundColor: AppColors.brandOrange,
                minimumSize: const Size(48, 44),
              ),
              child: Text(
                context.l10n.growthSeeAll,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

/// Auto-advancing banner carousel with page indicators.
class HomeFeedBannerCarousel extends StatefulWidget {
  const HomeFeedBannerCarousel({
    super.key,
    required this.banners,
    required this.collections,
  });

  final List<HomeFeedBanner> banners;
  final List<HomeFeedCollection> collections;

  @override
  State<HomeFeedBannerCarousel> createState() => _HomeFeedBannerCarouselState();
}

class _HomeFeedBannerCarouselState extends State<HomeFeedBannerCarousel> {
  final PageController _controller = PageController(viewportFraction: 0.92);
  Timer? _timer;
  int _page = 0;

  @override
  void initState() {
    super.initState();
    _startTimer();
  }

  @override
  void didUpdateWidget(covariant HomeFeedBannerCarousel oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.banners.length != widget.banners.length) {
      _page = 0;
      _startTimer();
    }
  }

  void _startTimer() {
    _timer?.cancel();
    if (widget.banners.length < 2) return;
    _timer = Timer.periodic(const Duration(seconds: 5), (_) {
      if (!mounted || !_controller.hasClients) return;
      final next = (_page + 1) % widget.banners.length;
      _controller.animateToPage(
        next,
        duration: const Duration(milliseconds: 350),
        curve: Curves.easeOut,
      );
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final banners = widget.banners;
    if (banners.isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(top: 16),
      child: Column(
        children: [
          AspectRatio(
            aspectRatio: 2.4,
            child: PageView.builder(
              controller: _controller,
              itemCount: banners.length,
              onPageChanged: (i) => setState(() => _page = i),
              itemBuilder: (context, index) {
                final banner = banners[index];
                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: _BannerTile(
                    banner: banner,
                    onTap: () => handleHomeFeedBannerTap(
                      context,
                      banner,
                      collections: widget.collections,
                    ),
                  ),
                );
              },
            ),
          ),
          if (banners.length > 1) ...[
            const SizedBox(height: 10),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                for (var i = 0; i < banners.length; i++)
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    margin: const EdgeInsets.symmetric(horizontal: 3),
                    width: i == _page ? 18 : 7,
                    height: 7,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(4),
                      color: i == _page
                          ? AppColors.brandOrange
                          : HomeColors.textMutedOf(context)
                              .withValues(alpha: 0.35),
                    ),
                  ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

class _BannerTile extends StatelessWidget {
  const _BannerTile({required this.banner, required this.onTap});

  final HomeFeedBanner banner;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final hasText = banner.title.isNotEmpty || (banner.subtitle ?? '').isNotEmpty;
    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: Material(
        color: HomeColors.surfaceElevatedOf(context),
        child: InkWell(
          onTap: banner.actionType == HomeFeedActionType.none ? null : onTap,
          child: Stack(
            fit: StackFit.expand,
            children: [
              GrowthNetworkImage(
                url: banner.imageUrl,
                icon: Icons.local_offer_outlined,
                memCacheWidth: 900,
              ),
              if (hasText)
                const DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.bottomCenter,
                      end: Alignment.topCenter,
                      colors: [Color(0xB3000000), Color(0x00000000)],
                    ),
                  ),
                ),
              if (hasText)
                Positioned(
                  left: 16,
                  right: 16,
                  bottom: 14,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (banner.title.isNotEmpty)
                        Text(
                          banner.title,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 19,
                            fontWeight: FontWeight.w800,
                            height: 1.15,
                          ),
                        ),
                      if ((banner.subtitle ?? '').isNotEmpty)
                        Text(
                          banner.subtitle!,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.9),
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                    ],
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Horizontal row for one curated collection, with "See all".
class HomeFeedCollectionRow extends StatelessWidget {
  const HomeFeedCollectionRow({super.key, required this.collection});

  final HomeFeedCollection collection;

  @override
  Widget build(BuildContext context) {
    final items = collection.items;
    if (items.isEmpty) return const SizedBox.shrink();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _GrowthSectionHeader(
          title: collection.title,
          onSeeAll: () => Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => HomeCollectionScreen(collection: collection),
            ),
          ),
        ),
        SizedBox(
          height: 196,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: items.length,
            separatorBuilder: (_, __) => const SizedBox(width: 12),
            itemBuilder: (context, index) => SizedBox(
              width: 150,
              child: HomeFeedItemCard(item: items[index]),
            ),
          ),
        ),
      ],
    );
  }
}

/// Vendor or product card used by collection rows and the See-all grid.
class HomeFeedItemCard extends StatelessWidget {
  const HomeFeedItemCard({super.key, required this.item});

  final HomeFeedItem item;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final dark = HomeColors.isDark(context);
    final radius = BorderRadius.circular(18);
    final String? meta;
    if (item.isVendor) {
      final parts = <String>[
        if (item.rating != null && item.rating! > 0)
          '★ ${item.rating!.toStringAsFixed(1)}',
        if (item.isOpen == false) l10n.growthClosed,
      ];
      meta = parts.isEmpty ? null : parts.join(' · ');
    } else {
      meta = item.price == null ? null : formatEtbAmount(item.price!);
    }
    return DecoratedBox(
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
          onTap: () => openHomeFeedItem(context, item),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(
                child: GrowthNetworkImage(
                  url: item.imageUrl,
                  icon: item.isVendor
                      ? Icons.storefront_rounded
                      : Icons.fastfood_rounded,
                  memCacheWidth: 360,
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(10, 8, 10, 10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.name,
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
                          color: item.isVendor
                              ? HomeColors.textMutedOf(context)
                              : AppColors.brandOrange,
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
    );
  }
}

/// "Order again" row of recent delivered orders; tap → reorder flow.
class OrderAgainRow extends StatelessWidget {
  const OrderAgainRow({super.key, required this.suggestions});

  final List<ReorderSuggestion> suggestions;

  @override
  Widget build(BuildContext context) {
    if (suggestions.isEmpty) return const SizedBox.shrink();
    final l10n = context.l10n;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _GrowthSectionHeader(title: l10n.growthOrderAgainTitle),
        SizedBox(
          height: 112,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: suggestions.length,
            separatorBuilder: (_, __) => const SizedBox(width: 12),
            itemBuilder: (context, index) =>
                _OrderAgainCard(suggestion: suggestions[index]),
          ),
        ),
      ],
    );
  }
}

class _OrderAgainCard extends StatelessWidget {
  const _OrderAgainCard({required this.suggestion});

  final ReorderSuggestion suggestion;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final dark = HomeColors.isDark(context);
    final radius = BorderRadius.circular(18);
    final title = suggestion.vendorName ??
        l10n.growthOrderAgainOrderLabel(
          suggestion.orderNumber ?? suggestion.orderId.toString(),
        );
    return SizedBox(
      width: 230,
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
            onTap: () => runReorderFlow(context, orderId: suggestion.orderId),
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Row(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(14),
                    child: SizedBox(
                      width: 56,
                      height: 56,
                      child: GrowthNetworkImage(
                        url: suggestion.vendorImageUrl,
                        icon: Icons.receipt_long_rounded,
                        memCacheWidth: 168,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 14.5,
                            fontWeight: FontWeight.w800,
                            color: HomeColors.textPrimaryOf(context),
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          formatEtbAmount(suggestion.totalAmount),
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: HomeColors.textMutedOf(context),
                          ),
                        ),
                        const SizedBox(height: 6),
                        Row(
                          children: [
                            const Icon(
                              Icons.replay_rounded,
                              size: 16,
                              color: AppColors.brandOrange,
                            ),
                            const SizedBox(width: 4),
                            Flexible(
                              child: Text(
                                l10n.growthReorderButton,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w800,
                                  color: AppColors.brandOrange,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
