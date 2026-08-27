import 'package:flutter/material.dart';
import 'package:hudhud_delivery/core/l10n/context_l10n.dart';
import 'package:hudhud_delivery/core/theme/service_tab_palette.dart';
import 'package:hudhud_delivery/features/home/presentation/theme/home_colors.dart';
import 'package:hudhud_delivery/features/onboarding_tour/presentation/onboarding_tour_keys.dart';

export 'package:hudhud_delivery/core/theme/service_tab_palette.dart'
    show HomeServiceMode;

/// Service tiles with brand PNG artwork. Coming-soon services stay collapsed
/// behind "More" so the home screen focuses on Send a package (courier).
class HomeServiceTabBar extends StatefulWidget {
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
  State<HomeServiceTabBar> createState() => _HomeServiceTabBarState();
}

class _HomeServiceTabBarState extends State<HomeServiceTabBar> {
  static const String _foodPng =
      'assets/images/home_service_tabs/food_groceries.png';
  static const String _courierPng = 'assets/images/home_service_tabs/courier.png';
  static const String _taxiPng = 'assets/images/home_service_tabs/taxi.png';
  static const String _handymanPng =
      'assets/images/home_service_tabs/handyman.png';

  bool _showMore = false;

  @override
  void didUpdateWidget(covariant HomeServiceTabBar oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.selected != HomeServiceMode.courier && !_showMore) {
      _showMore = true;
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;

    final courier = _TabSpec(
      mode: HomeServiceMode.courier,
      label: l10n.homeSendPackage,
      assetPath: _courierPng,
      fallbackIcon: Icons.inventory_2_rounded,
      brand: ServiceTabPalette.courier,
      unselectedWell: const Color(0xFF2A2040),
    );
    final others = <_TabSpec>[
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
      key: widget.tourKeys?.serviceTabsKey,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 4, 12, 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Expanded(
                  flex: _showMore ? 1 : 3,
                  child: _ServiceTile(
                    key: widget.tourKeys?.courierTabKey,
                    spec: courier,
                    selected: widget.selected == HomeServiceMode.courier,
                    large: !_showMore,
                    onTap: () => widget.onSelected(HomeServiceMode.courier),
                  ),
                ),
                const SizedBox(width: 10),
                if (!_showMore)
                  Expanded(
                    child: _MoreTile(
                      label: l10n.homeMoreServices,
                      onTap: () => setState(() => _showMore = true),
                    ),
                  )
                else
                  for (var i = 0; i < others.length; i++) ...[
                    if (i > 0) const SizedBox(width: 10),
                    Expanded(
                      child: _ServiceTile(
                        key: _tourKeyFor(others[i].mode),
                        spec: others[i],
                        selected: others[i].mode == widget.selected,
                        onTap: () => widget.onSelected(others[i].mode),
                      ),
                    ),
                  ],
              ],
            ),
            if (_showMore) ...[
              const SizedBox(height: 8),
              Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  onPressed: () {
                    setState(() => _showMore = false);
                    widget.onSelected(HomeServiceMode.courier);
                  },
                  child: Text(l10n.homeHideMoreServices),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  GlobalKey? _tourKeyFor(HomeServiceMode mode) {
    final keys = widget.tourKeys;
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

class _MoreTile extends StatelessWidget {
  const _MoreTile({required this.label, required this.onTap});

  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
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
                  color: const Color(0xFF2A2A32),
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: HomeColors.borderOf(context)),
                ),
                child: Icon(
                  Icons.apps_rounded,
                  size: 36,
                  color: HomeColors.textMutedOf(context),
                ),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 12,
                color: HomeColors.textMutedOf(context),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ServiceTile extends StatelessWidget {
  const _ServiceTile({
    super.key,
    required this.spec,
    required this.selected,
    required this.onTap,
    this.large = false,
  });

  final _TabSpec spec;
  final bool selected;
  final VoidCallback onTap;
  final bool large;

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
              aspectRatio: large ? 2.2 : 1,
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
                padding: EdgeInsets.all(large ? 18 : 14),
                child: Image.asset(
                  spec.assetPath,
                  fit: BoxFit.contain,
                  gaplessPlayback: true,
                  errorBuilder: (_, __, ___) => Icon(
                    spec.fallbackIcon,
                    size: large ? 48 : 32,
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
              maxLines: large ? 2 : 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                fontSize: large ? 14 : 12,
                color: labelColor,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
