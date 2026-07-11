import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:hudhud_delivery/core/l10n/context_l10n.dart';
import 'package:hudhud_delivery/core/theme/service_tab_palette.dart';

export 'package:hudhud_delivery/core/theme/service_tab_palette.dart'
    show HomeServiceMode;

/// Klik-style horizontal strip: rounded tiles, image + label, selected primary fill.
class HomeServiceTabBar extends StatelessWidget {
  const HomeServiceTabBar({
    super.key,
    required this.selected,
    required this.onSelected,
  });

  final HomeServiceMode selected;
  final ValueChanged<HomeServiceMode> onSelected;

  static const String _foodPng = 'assets/images/home_service_tabs/food_groceries.png';
  static const String _courierPng = 'assets/images/home_service_tabs/courier.png';
  static const String _taxiPng = 'assets/images/home_service_tabs/taxi.png';
  static const String _handymanPng = 'assets/images/home_service_tabs/handyman.png';

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;
    // Strip tint follows the selected service; each tile uses its own brand (food = app orange).
    final stripAccent = ServiceTabPalette.seedFor(selected);

    final items = <_TabSpec>[
      _TabSpec(
        mode: HomeServiceMode.foodGroceries,
        label: l10n.featureFoodGroceries,
        assetPath: _foodPng,
        fallbackIcon: Icons.restaurant_rounded,
      ),
      _TabSpec(
        mode: HomeServiceMode.courier,
        label: l10n.featureCourierTitle,
        assetPath: _courierPng,
        fallbackIcon: Icons.inventory_2_rounded,
      ),
      _TabSpec(
        mode: HomeServiceMode.taxi,
        label: l10n.featureTaxiTitle,
        assetPath: _taxiPng,
        fallbackIcon: Icons.local_taxi_rounded,
      ),
      _TabSpec(
        mode: HomeServiceMode.handyman,
        label: l10n.featureHandymanTitle,
        assetPath: _handymanPng,
        fallbackIcon: Icons.handyman_rounded,
      ),
    ];

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: isDark
              ? [
                  stripAccent.withValues(alpha: 0.26),
                  Color.lerp(cs.surface, stripAccent, 0.06)!
                      .withValues(alpha: 0.96),
                ]
              : [
                  stripAccent.withValues(alpha: 0.20),
                  Color.lerp(cs.surface, stripAccent, 0.04)!
                      .withValues(alpha: 0.98),
                ],
        ),
      ),
      child: SizedBox(
        height: 100,
        child: LayoutBuilder(
          builder: (context, constraints) {
            final tiles = <Widget>[
              for (final spec in items)
                _ServiceTile(
                  spec: spec,
                  brand: ServiceTabPalette.seedFor(spec.mode),
                  selected: spec.mode == selected,
                  onTap: () => onSelected(spec.mode),
                ),
            ];
            // Space-around when all four tiles fit; scroll on very narrow widths.
            const minWidthForPackedRow =
                _ServiceTile.tileWidth * 4 + 8; // ~360pt
            if (constraints.maxWidth >= minWidthForPackedRow) {
              return Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: tiles,
              );
            }
            return ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 12),
              children: [
                for (var i = 0; i < tiles.length; i++) ...[
                  if (i > 0) const SizedBox(width: 10),
                  tiles[i],
                ],
              ],
            );
          },
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
  });

  final HomeServiceMode mode;
  final String label;
  final String assetPath;
  final IconData fallbackIcon;
}

class _ServiceTile extends StatelessWidget {
  const _ServiceTile({
    required this.spec,
    required this.brand,
    required this.selected,
    required this.onTap,
  });

  final _TabSpec spec;
  /// Per-service accent (food & groceries = [AppColors.primaryColor]).
  final Color brand;
  final bool selected;
  final VoidCallback onTap;

  static const double tileWidth = 88;
  static const double _tileHeight = 96;
  static const double _imageBoxHeight = 54;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    final bg = selected
        ? brand
        : Color.lerp(cs.surface, brand, theme.brightness == Brightness.dark ? 0.14 : 0.11)!;
    final border = selected
        ? brand
        : (Color.lerp(cs.outlineVariant, brand, 0.35) ?? cs.outlineVariant)
            .withValues(alpha: 0.55);
    final labelColor = selected ? Colors.white : cs.onSurface;

    // Use Material + InkWell + Container — not [Ink], which can fail to paint
    // [Image.asset] children correctly in some cases.
    return SizedBox(
      width: tileWidth,
      height: _tileHeight,
      child: Material(
        color: Colors.transparent,
        clipBehavior: Clip.antiAlias,
        borderRadius: BorderRadius.circular(20),
        child: InkWell(
          onTap: () {
            HapticFeedback.selectionClick();
            onTap();
          },
          borderRadius: BorderRadius.circular(20),
          child: Container(
            width: tileWidth,
            decoration: BoxDecoration(
              color: bg,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: border, width: selected ? 0 : 1),
              boxShadow: selected
                  ? [
                      BoxShadow(
                        color: brand.withValues(alpha: 0.35),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      ),
                    ]
                  : [
                      BoxShadow(
                        color: brand.withValues(alpha: 0.12),
                        blurRadius: 10,
                        offset: const Offset(0, 2),
                      ),
                    ],
            ),
            padding: const EdgeInsets.fromLTRB(6, 8, 6, 6),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              mainAxisSize: MainAxisSize.max,
              children: [
                SizedBox(
                  height: _imageBoxHeight,
                  width: double.infinity,
                  child: Center(
                    child: _IconImageWell(
                      selected: selected,
                      brand: brand,
                      child: _TabArtwork(
                        spec: spec,
                        selected: selected,
                        brand: brand,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  spec.label,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.center,
                  style: theme.textTheme.labelSmall?.copyWith(
                    fontWeight: FontWeight.w600,
                    fontSize: 10.5,
                    height: 1.05,
                    color: labelColor,
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

/// Brighter soft well behind each tab image (selected = light lift on primary).
class _IconImageWell extends StatelessWidget {
  const _IconImageWell({
    required this.selected,
    required this.brand,
    required this.child,
  });

  final bool selected;
  final Color brand;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final Color wellColor = selected
        ? Colors.white.withValues(alpha: isDark ? 0.26 : 0.32)
        : brand.withValues(alpha: isDark ? 0.26 : 0.20);

    return DecoratedBox(
      decoration: BoxDecoration(
        color: wellColor,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: (selected ? Colors.white : brand)
                .withValues(alpha: selected ? 0.14 : 0.12),
            blurRadius: selected ? 8 : 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(4),
        child: child,
      ),
    );
  }
}

/// Loads tab PNG; falls back to icon if missing.
class _TabArtwork extends StatelessWidget {
  const _TabArtwork({
    required this.spec,
    required this.selected,
    required this.brand,
  });

  final _TabSpec spec;
  final bool selected;
  final Color brand;

  @override
  Widget build(BuildContext context) {
    final iconColor = selected ? Colors.white : brand;

    return Image.asset(
      spec.assetPath,
      fit: BoxFit.contain,
      alignment: Alignment.center,
      gaplessPlayback: true,
      filterQuality: FilterQuality.medium,
      errorBuilder: (_, __, ___) => Icon(
        spec.fallbackIcon,
        size: 34,
        color: iconColor,
      ),
    );
  }
}
