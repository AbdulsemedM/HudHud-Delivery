import 'package:flutter/material.dart';
import 'package:hudhud_delivery/core/l10n/context_l10n.dart';
import 'package:hudhud_delivery/core/theme/app_colors.dart';
import 'package:hudhud_delivery/core/theme/service_tab_palette.dart';
import 'package:hudhud_delivery/features/home/presentation/theme/home_colors.dart';
import 'package:hudhud_delivery/features/onboarding_tour/presentation/onboarding_tour_keys.dart';

export 'package:hudhud_delivery/core/theme/service_tab_palette.dart'
    show HomeServiceMode;

/// Primary home service tiles: Send Package | Delivery, and — once those
/// sectors have a live shop — Pharmacy | Spare parts.
/// Taxi / Handyman deferred to a future release.
class HomeServiceTabBar extends StatelessWidget {
  const HomeServiceTabBar({
    super.key,
    required this.selected,
    required this.onSelected,
    this.tourKeys,
    this.availableSectors = const <String>{},
  });

  final HomeServiceMode selected;
  final ValueChanged<HomeServiceMode> onSelected;
  final OnboardingTourKeys? tourKeys;

  /// Sector keys the server reports as having at least one live shop, from
  /// GET /api/public/vendors/sectors. Empty while that call is in flight or
  /// if it failed, which is the safe reading: no tile rather than a tile that
  /// opens an empty list.
  final Set<String> availableSectors;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;

    final courier = _TabSpec(
      label: l10n.homeSendPackage,
      assetPath: 'assets/images/home_service_tabs/courier.png',
      fallbackIcon: Icons.inventory_2_rounded,
      gradient: AppColors.brandHeroGradient,
      glow: AppColors.brandIndigo,
    );
    final delivery = _TabSpec(
      label: l10n.homeTabDelivery,
      assetPath: 'assets/images/home_service_tabs/food_groceries.png',
      fallbackIcon: Icons.restaurant_rounded,
      gradient: const [Color(0xFFFF7A2E), ServiceTabPalette.foodGroceries],
      glow: ServiceTabPalette.foodGroceries,
    );

    // No assetPath on purpose — see _TabSpec. A medicine icon and a car-part
    // icon say what these are far better than a borrowed basket would.
    final pharmacy = _TabSpec(
      label: l10n.homeTabPharmacy,
      assetPath: null,
      fallbackIcon: Icons.medication_rounded,
      gradient: const [Color(0xFF2FA37A), ServiceTabPalette.pharmacy],
      glow: ServiceTabPalette.pharmacy,
    );
    final spareParts = _TabSpec(
      label: l10n.homeTabSpareParts,
      assetPath: null,
      fallbackIcon: Icons.car_repair,
      gradient: const [Color(0xFF5B6B7C), ServiceTabPalette.spareParts],
      glow: ServiceTabPalette.spareParts,
    );

    final effectiveSelected =
        selected == HomeServiceMode.taxi || selected == HomeServiceMode.handyman
            ? HomeServiceMode.courier
            : selected;

    // A tile only exists once that sector has a shop behind it.
    //
    // This app once shipped nine hardcoded sector chips while production had
    // two vendors, both restaurants, so seven of them opened an empty list
    // with no explanation. /api/public/vendors/sectors exists precisely to
    // stop that: it counts only active, publicly visible vendors. Hardcoding
    // Pharmacy and Spare parts here would walk straight back into it — the
    // tile would be the most prominent thing on the home screen and would
    // lead nowhere until someone onboards a pharmacy.
    //
    // So they appear on their own when the shops do, and until then Home
    // looks exactly as it does today.
    final showPharmacy = availableSectors.contains('pharmacy');
    final showSpareParts = availableSectors.contains('spare_parts');

    final secondRow = <Widget>[
      if (showPharmacy)
        Expanded(
          child: _ServiceTile(
            spec: pharmacy,
            selected: effectiveSelected == HomeServiceMode.pharmacy,
            onTap: () => onSelected(HomeServiceMode.pharmacy),
          ),
        ),
      if (showPharmacy && showSpareParts) const SizedBox(width: 12),
      if (showSpareParts)
        Expanded(
          child: _ServiceTile(
            spec: spareParts,
            selected: effectiveSelected == HomeServiceMode.spareParts,
            onTap: () => onSelected(HomeServiceMode.spareParts),
          ),
        ),
      // Keeps a lone tile at half width rather than letting it stretch across
      // the screen and outweigh the two above it.
      if (showPharmacy != showSpareParts) ...[
        const SizedBox(width: 12),
        const Spacer(),
      ],
    ];

    return KeyedSubtree(
      key: tourKeys?.serviceTabsKey,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 4),
        child: Column(
          children: [
            Row(
              children: [
                Expanded(
                  child: _ServiceTile(
                    key: tourKeys?.courierTabKey,
                    spec: courier,
                    selected: effectiveSelected == HomeServiceMode.courier,
                    onTap: () => onSelected(HomeServiceMode.courier),
                  ),
                ),
                const SizedBox(width: 12),
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
            if (secondRow.isNotEmpty) ...[
              const SizedBox(height: 12),
              Row(children: secondRow),
            ],
          ],
        ),
      ),
    );
  }
}

class _TabSpec {
  const _TabSpec({
    required this.label,
    required this.assetPath,
    required this.fallbackIcon,
    required this.gradient,
    required this.glow,
  });

  final String label;

  /// Painted artwork for this service, or null to draw [fallbackIcon]
  /// directly. Null is not a degraded state: Pharmacy and Spare parts have no
  /// artwork yet, and borrowing another tile's PNG would put a food basket on
  /// the pharmacy tile — which is what happened when this field was required.
  final String? assetPath;

  final IconData fallbackIcon;
  final List<Color> gradient;
  final Color glow;
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

  static const double _height = 108;
  static const _radius = BorderRadius.all(Radius.circular(22));

  @override
  Widget build(BuildContext context) {
    final dark = HomeColors.isDark(context);
    final labelColor =
        selected ? Colors.white : HomeColors.textPrimaryOf(context);

    return Semantics(
      button: true,
      selected: selected,
      label: spec.label,
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 260),
          curve: Curves.easeOutCubic,
          height: _height,
          decoration: BoxDecoration(
            borderRadius: _radius,
            color: selected ? null : HomeColors.surfaceOf(context),
            gradient: selected
                ? LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: spec.gradient,
                  )
                : null,
            border: Border.all(
              color: selected
                  ? Colors.transparent
                  : HomeColors.borderOf(context),
              width: 1.2,
            ),
            boxShadow: selected && !dark
                ? [
                    BoxShadow(
                      color: spec.glow.withValues(alpha: 0.30),
                      blurRadius: 22,
                      offset: const Offset(0, 10),
                    ),
                  ]
                : AppColors.softShadow(context),
          ),
          child: ClipRRect(
            borderRadius: _radius,
            child: Stack(
              children: [
                // Soft light bloom behind the illustration.
                if (selected)
                  Positioned(
                    right: -30,
                    top: -30,
                    child: Container(
                      width: 130,
                      height: 130,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: RadialGradient(
                          colors: [
                            Colors.white.withValues(alpha: 0.22),
                            Colors.white.withValues(alpha: 0),
                          ],
                        ),
                      ),
                    ),
                  ),
                Positioned(
                  right: -6,
                  bottom: -4,
                  top: 6,
                  child: AnimatedScale(
                    duration: const Duration(milliseconds: 260),
                    curve: Curves.easeOutBack,
                    scale: selected ? 1.0 : 0.88,
                    alignment: Alignment.bottomRight,
                    child: AnimatedOpacity(
                      duration: const Duration(milliseconds: 200),
                      opacity: selected ? 1 : 0.9,
                      child: spec.assetPath == null
                          ? Icon(
                              spec.fallbackIcon,
                              size: 46,
                              color: selected ? Colors.white : spec.glow,
                            )
                          : Image.asset(
                              spec.assetPath!,
                              width: 92,
                              fit: BoxFit.contain,
                              gaplessPlayback: true,
                              errorBuilder: (_, __, ___) => Icon(
                                spec.fallbackIcon,
                                size: 44,
                                color: selected ? Colors.white : spec.glow,
                              ),
                            ),
                    ),
                  ),
                ),
                // No tick / empty circle here any more. It made these tiles
                // read as answers on a form (tester report: "Send a package"
                // looked selectable, not tappable); the filled colour already
                // shows which one is active.
                Positioned(
                  left: 14,
                  right: 84,
                  bottom: 14,
                  child: Text(
                    spec.label,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontWeight: FontWeight.w800,
                      fontSize: 16,
                      height: 1.15,
                      letterSpacing: -0.2,
                      color: labelColor,
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
