import 'package:flutter/material.dart';
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
                  cs.primary.withValues(alpha: 0.26),
                  Color.lerp(cs.surface, cs.primary, 0.06)!
                      .withValues(alpha: 0.96),
                ]
              : [
                  cs.primary.withValues(alpha: 0.20),
                  Color.lerp(cs.surface, cs.primary, 0.04)!
                      .withValues(alpha: 0.98),
                ],
        ),
      ),
      child: SizedBox(
        height: 100,
        child: ListView.separated(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 12),
          itemCount: items.length,
          separatorBuilder: (_, __) => const SizedBox(width: 10),
          itemBuilder: (context, index) {
            final spec = items[index];
            final isSelected = spec.mode == selected;
            return _ServiceTile(
              spec: spec,
              selected: isSelected,
              onTap: () => onSelected(spec.mode),
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
    required this.selected,
    required this.onTap,
  });

  final _TabSpec spec;
  final bool selected;
  final VoidCallback onTap;

  static const double _tileWidth = 88;
  static const double _tileHeight = 96;
  static const double _imageBoxHeight = 54;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    final bg = selected
        ? cs.primary
        : Color.lerp(cs.surface, cs.primary, theme.brightness == Brightness.dark ? 0.14 : 0.11)!;
    final border = selected
        ? cs.primary
        : (Color.lerp(cs.outlineVariant, cs.primary, 0.35) ?? cs.outlineVariant)
            .withValues(alpha: 0.55);
    final labelColor = selected ? Colors.white : cs.onSurface;

    // Use Material + InkWell + Container — not [Ink], which can fail to paint
    // [Image.asset] children correctly in some cases.
    return SizedBox(
      width: _tileWidth,
      height: _tileHeight,
      child: Material(
        color: Colors.transparent,
        clipBehavior: Clip.antiAlias,
        borderRadius: BorderRadius.circular(20),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(20),
          child: Container(
            width: _tileWidth,
            decoration: BoxDecoration(
              color: bg,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: border, width: selected ? 0 : 1),
              boxShadow: selected
                  ? [
                      BoxShadow(
                        color: cs.primary.withValues(alpha: 0.35),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      ),
                    ]
                  : [
                      BoxShadow(
                        color: cs.primary.withValues(alpha: 0.12),
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
                      child: _TabArtwork(spec: spec, selected: selected),
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
    required this.child,
  });

  final bool selected;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;

    final Color wellColor = selected
        ? Colors.white.withValues(alpha: isDark ? 0.26 : 0.32)
        : cs.primary.withValues(alpha: isDark ? 0.26 : 0.20);

    return DecoratedBox(
      decoration: BoxDecoration(
        color: wellColor,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: (selected ? Colors.white : cs.primary)
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
  });

  final _TabSpec spec;
  final bool selected;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final iconColor = selected ? Colors.white : cs.primary;

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
