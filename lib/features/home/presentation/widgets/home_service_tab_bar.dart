import 'package:flutter/material.dart';
import 'package:hudhud_delivery/core/l10n/context_l10n.dart';
import 'package:hudhud_delivery/core/theme/service_tab_palette.dart';
import 'package:hudhud_delivery/features/home/presentation/theme/home_colors.dart';
import 'package:hudhud_delivery/features/onboarding_tour/presentation/onboarding_tour_keys.dart';

export 'package:hudhud_delivery/core/theme/service_tab_palette.dart'
    show HomeServiceMode;

/// Four service tiles with brand PNG artwork on a flat dark strip.
class HomeServiceTabBar extends StatelessWidget {
  const HomeServiceTabBar({
    super.key,
    required this.selected,
    required this.onSelected,
    this.tourKeys,
  });

  final HomeServiceMode selected;
  final ValueChanged<HomeServiceMode> onSelected;
  final OnboardingTourKeys? tourKeys;

  static const String _foodPng =
      'assets/images/home_service_tabs/food_groceries.png';
  static const String _courierPng = 'assets/images/home_service_tabs/courier.png';
  static const String _taxiPng = 'assets/images/home_service_tabs/taxi.png';
  static const String _handymanPng =
      'assets/images/home_service_tabs/handyman.png';

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;

    final items = <_TabSpec>[
      _TabSpec(
        mode: HomeServiceMode.courier,
        label: l10n.homeTabCourier,
        assetPath: _courierPng,
        fallbackIcon: Icons.inventory_2_rounded,
        brand: ServiceTabPalette.courier,
        unselectedWell: const Color(0xFF2A2040),
      ),
      _TabSpec(
        mode: HomeServiceMode.foodGroceries,
        label: l10n.homeTabFood,
        assetPath: _foodPng,
        fallbackIcon: Icons.restaurant_rounded,
        brand: ServiceTabPalette.foodGroceries,
        unselectedWell: const Color(0xFF3A2418),
      ),
      _TabSpec(
        mode: HomeServiceMode.taxi,
        label: l10n.homeTabTaxi,
        assetPath: _taxiPng,
        fallbackIcon: Icons.local_taxi_rounded,
        brand: ServiceTabPalette.taxi,
        unselectedWell: const Color(0xFF2C2618),
      ),
      _TabSpec(
        mode: HomeServiceMode.handyman,
        label: l10n.homeTabHandyman,
        assetPath: _handymanPng,
        fallbackIcon: Icons.handyman_rounded,
        brand: ServiceTabPalette.handyman,
        unselectedWell: const Color(0xFF1A2438),
      ),
    ];

    return KeyedSubtree(
      key: tourKeys?.serviceTabsKey,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 4, 12, 8),
        child: Row(
          children: [
            for (var i = 0; i < items.length; i++) ...[
              if (i > 0) const SizedBox(width: 10),
              Expanded(
                child: _ServiceTile(
                  key: _tourKeyFor(items[i].mode),
                  spec: items[i],
                  selected: items[i].mode == selected,
                  onTap: () => onSelected(items[i].mode),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  GlobalKey? _tourKeyFor(HomeServiceMode mode) {
    final keys = tourKeys;
    if (keys == null) return null;
    switch (mode) {
      case HomeServiceMode.courier:
        return keys.courierTabKey;
      case HomeServiceMode.foodGroceries:
        return keys.foodTabKey;
      case HomeServiceMode.taxi:
        return keys.taxiTabKey;
      case HomeServiceMode.handyman:
        return keys.handymanTabKey;
    }
  }
}

class _TabSpec {
  const _TabSpec({
    required this.mode,
    required this.label,
    required this.assetPath,
    required this.fallbackIcon,
    required this.brand,
    required this.unselectedWell,
  });

  final HomeServiceMode mode;
  final String label;
  final String assetPath;
  final IconData fallbackIcon;
  final Color brand;
  final Color unselectedWell;
}

class _ServiceTile extends StatelessWidget {
  const _ServiceTile({
    super.key,
    required this.spec,
    required this.selected,
    required this.onTap,
  });

  final _TabSpec spec;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final bg = selected ? spec.brand : spec.unselectedWell;
    final labelColor =
        selected ? HomeColors.textPrimaryOf(context) : HomeColors.textMutedOf(context);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            AspectRatio(
              aspectRatio: 1,
              child: Container(
                decoration: BoxDecoration(
                  color: bg,
                  borderRadius: BorderRadius.circular(18),
                  boxShadow: selected
                      ? [
                          BoxShadow(
                            color: spec.brand.withValues(alpha: 0.35),
                            blurRadius: 12,
                            offset: const Offset(0, 4),
                          ),
                        ]
                      : null,
                ),
                padding: const EdgeInsets.all(14),
                child: Image.asset(
                  spec.assetPath,
                  fit: BoxFit.contain,
                  gaplessPlayback: true,
                  errorBuilder: (_, __, ___) => Icon(
                    spec.fallbackIcon,
                    size: 32,
                    color: selected
                        ? Theme.of(context).colorScheme.onPrimary
                        : spec.brand,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              spec.label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                fontSize: 12,
                color: labelColor,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
