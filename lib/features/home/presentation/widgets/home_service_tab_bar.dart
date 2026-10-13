import 'package:flutter/material.dart';
import 'package:hudhud_delivery/core/l10n/context_l10n.dart';
import 'package:hudhud_delivery/core/theme/app_colors.dart';
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

    final effectiveSelected =
        selected == HomeServiceMode.taxi || selected == HomeServiceMode.handyman
            ? HomeServiceMode.courier
            : selected;

    return KeyedSubtree(
      key: tourKeys?.serviceTabsKey,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 4),
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
  final String assetPath;
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
                      child: Image.asset(
                        spec.assetPath,
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
                Positioned(
                  left: 14,
                  top: 14,
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    width: 24,
                    height: 24,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: selected
                          ? Colors.white
                          : Colors.transparent,
                      border: Border.all(
                        color: selected
                            ? Colors.white
                            : HomeColors.textMutedOf(context)
                                .withValues(alpha: 0.5),
                        width: 2,
                      ),
                    ),
                    child: selected
                        ? Icon(Icons.check_rounded, size: 16, color: spec.glow)
                        : null,
                  ),
                ),
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
