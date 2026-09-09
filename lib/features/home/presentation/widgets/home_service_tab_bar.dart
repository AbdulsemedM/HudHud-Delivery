import 'package:flutter/material.dart';
import 'package:hudhud_delivery/core/l10n/context_l10n.dart';
import 'package:hudhud_delivery/core/theme/service_tab_palette.dart';
import 'package:hudhud_delivery/features/home/presentation/theme/home_colors.dart';
import 'package:hudhud_delivery/features/onboarding_tour/presentation/onboarding_tour_keys.dart';

export 'package:hudhud_delivery/core/theme/service_tab_palette.dart'
    show HomeServiceMode;

/// Primary home service tiles: Send Package | Delivery.
/// Taxi / Handyman deferred to a future release.
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

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;

    final courier = _TabSpec(
      mode: HomeServiceMode.courier,
      label: l10n.homeSendPackage,
      assetPath: 'assets/images/home_service_tabs/courier.png',
      fallbackIcon: Icons.inventory_2_rounded,
      brand: ServiceTabPalette.courier,
      unselectedWell: const Color(0xFF2A2040),
    );
    final delivery = _TabSpec(
      mode: HomeServiceMode.foodGroceries,
      label: l10n.homeTabDelivery,
      assetPath: 'assets/images/home_service_tabs/food_groceries.png',
      fallbackIcon: Icons.restaurant_rounded,
      brand: ServiceTabPalette.foodGroceries,
      unselectedWell: const Color(0xFF3A2418),
    );

    final effectiveSelected =
        selected == HomeServiceMode.taxi || selected == HomeServiceMode.handyman
            ? HomeServiceMode.courier
            : selected;

    return KeyedSubtree(
      key: tourKeys?.serviceTabsKey,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 4, 12, 8),
        child: Row(
          children: [
            Expanded(
              child: _ServiceTile(
                key: tourKeys?.courierTabKey,
                spec: courier,
                selected: effectiveSelected == HomeServiceMode.courier,
                onTap: () => onSelected(HomeServiceMode.courier),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _ServiceTile(
                key: tourKeys?.foodTabKey,
                spec: delivery,
                selected: effectiveSelected == HomeServiceMode.foodGroceries,
                onTap: () => onSelected(HomeServiceMode.foodGroceries),
              ),
            ),
          ],
        ),
      ),
    );
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
    final labelColor = selected
        ? HomeColors.textPrimaryOf(context)
        : HomeColors.textMutedOf(context);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            AspectRatio(
              aspectRatio: 1.7,
              child: Container(
                decoration: BoxDecoration(
                  color: bg,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: selected
                      ? [
                          BoxShadow(
                            color: spec.brand.withValues(alpha: 0.35),
                            blurRadius: 10,
                            offset: const Offset(0, 3),
                          ),
                        ]
                      : null,
                ),
                padding: const EdgeInsets.all(10),
                child: Image.asset(
                  spec.assetPath,
                  fit: BoxFit.contain,
                  gaplessPlayback: true,
                  errorBuilder: (_, __, ___) => Icon(
                    spec.fallbackIcon,
                    size: 36,
                    color: selected
                        ? Theme.of(context).colorScheme.onPrimary
                        : spec.brand,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 6),
            Text(
              spec.label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                fontSize: 13,
                color: labelColor,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
