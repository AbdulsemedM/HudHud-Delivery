import 'package:flutter/material.dart';
import 'package:hudhud_delivery/core/l10n/context_l10n.dart';
import 'package:hudhud_delivery/core/theme/service_tab_palette.dart';
import 'package:hudhud_delivery/features/home/presentation/theme/home_colors.dart';
import 'package:lottie/lottie.dart';

/// Warm placeholder for Home service tabs that are not launched yet.
class ServiceComingSoonScreen extends StatefulWidget {
  const ServiceComingSoonScreen({super.key, required this.mode});

  final HomeServiceMode mode;

  @override
  State<ServiceComingSoonScreen> createState() => _ServiceComingSoonScreenState();
}

class _ServiceComingSoonScreenState extends State<ServiceComingSoonScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _fade;
  late final Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 650),
    );
    _fade = CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic);
    _scale = Tween<double>(begin: 0.92, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOutBack),
    );
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final spec = _specFor(context, widget.mode);

    return Stack(
      fit: StackFit.expand,
      children: [
        DecoratedBox(
          decoration: BoxDecoration(
            gradient: RadialGradient(
              center: const Alignment(0, -0.35),
              radius: 1.1,
              colors: [
                spec.brand.withValues(alpha: 0.22),
                HomeColors.background,
              ],
            ),
          ),
        ),
        Positioned(
          top: 48,
          right: -24,
          child: _GlowOrb(color: spec.brand, size: 120, opacity: 0.18),
        ),
        Positioned(
          bottom: 72,
          left: -36,
          child: _GlowOrb(color: spec.brand, size: 96, opacity: 0.12),
        ),
        Positioned(
          top: 140,
          left: 28,
          child: _GlowOrb(color: spec.brand, size: 56, opacity: 0.1),
        ),
        FadeTransition(
          opacity: _fade,
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(24, 28, 24, 32),
            child: Column(
              children: [
                ScaleTransition(
                  scale: _scale,
                  child: _HeroTile(spec: spec),
                ),
                const SizedBox(height: 28),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                  decoration: BoxDecoration(
                    color: spec.brand.withValues(alpha: 0.16),
                    borderRadius: BorderRadius.circular(999),
                    border: Border.all(
                      color: spec.brand.withValues(alpha: 0.45),
                    ),
                  ),
                  child: Text(
                    spec.badge,
                    style: TextStyle(
                      color: spec.brand,
                      fontWeight: FontWeight.w700,
                      fontSize: 12,
                      letterSpacing: 0.6,
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                Text(
                  spec.title,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: HomeColors.textPrimary,
                    fontSize: 24,
                    fontWeight: FontWeight.w800,
                    height: 1.25,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  spec.subtitle,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: HomeColors.textMuted,
                    fontSize: 15,
                    height: 1.5,
                  ),
                ),
                const SizedBox(height: 28),
                Wrap(
                  alignment: WrapAlignment.center,
                  spacing: 10,
                  runSpacing: 10,
                  children: [
                    for (final teaser in spec.teasers)
                      _TeaserChip(label: teaser, color: spec.brand),
                  ],
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  _ComingSoonSpec _specFor(BuildContext context, HomeServiceMode mode) {
    final l10n = context.l10n;
    switch (mode) {
      case HomeServiceMode.foodGroceries:
        return _ComingSoonSpec(
          brand: ServiceTabPalette.foodGroceries,
          assetPath: 'assets/images/home_service_tabs/food_groceries.png',
          fallbackIcon: Icons.restaurant_rounded,
          badge: l10n.serviceComingSoonBadge,
          title: l10n.foodComingSoonTitle,
          subtitle: l10n.foodComingSoonSubtitle,
          teasers: [l10n.foodComingSoonTeaser1, l10n.foodComingSoonTeaser2],
        );
      case HomeServiceMode.taxi:
        return _ComingSoonSpec(
          brand: ServiceTabPalette.taxi,
          assetPath: 'assets/images/home_service_tabs/taxi.png',
          fallbackIcon: Icons.local_taxi_rounded,
          badge: l10n.serviceComingSoonBadge,
          title: l10n.taxiComingSoonTitle,
          subtitle: l10n.taxiComingSoonSubtitle,
          teasers: [l10n.taxiComingSoonTeaser1, l10n.taxiComingSoonTeaser2],
        );
      case HomeServiceMode.handyman:
        return _ComingSoonSpec(
          brand: ServiceTabPalette.handyman,
          assetPath: 'assets/images/home_service_tabs/handyman.png',
          fallbackIcon: Icons.handyman_rounded,
          badge: l10n.serviceComingSoonBadge,
          title: l10n.handymanComingSoonTitle,
          subtitle: l10n.handymanComingSoonSubtitle,
          teasers: [
            l10n.handymanComingSoonTeaser1,
            l10n.handymanComingSoonTeaser2,
          ],
        );
      case HomeServiceMode.courier:
        return _ComingSoonSpec(
          brand: ServiceTabPalette.courier,
          assetPath: 'assets/images/home_service_tabs/courier.png',
          fallbackIcon: Icons.inventory_2_rounded,
          badge: l10n.serviceComingSoonBadge,
          title: l10n.featureCourierTitle,
          subtitle: l10n.featureCourierDesc,
          teasers: const [],
        );
    }
  }
}

class _ComingSoonSpec {
  const _ComingSoonSpec({
    required this.brand,
    required this.assetPath,
    required this.fallbackIcon,
    required this.badge,
    required this.title,
    required this.subtitle,
    required this.teasers,
  });

  final Color brand;
  final String assetPath;
  final IconData fallbackIcon;
  final String badge;
  final String title;
  final String subtitle;
  final List<String> teasers;
}

class _HeroTile extends StatelessWidget {
  const _HeroTile({required this.spec});

  final _ComingSoonSpec spec;

  @override
  Widget build(BuildContext context) {
    return Stack(
      alignment: Alignment.center,
      clipBehavior: Clip.none,
      children: [
        Container(
          width: 168,
          height: 168,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: spec.brand.withValues(alpha: 0.35),
                blurRadius: 36,
                spreadRadius: 4,
              ),
            ],
          ),
        ),
        Container(
          width: 148,
          height: 148,
          decoration: BoxDecoration(
            color: spec.brand.withValues(alpha: 0.14),
            borderRadius: BorderRadius.circular(32),
            border: Border.all(color: spec.brand.withValues(alpha: 0.35)),
          ),
          padding: const EdgeInsets.all(22),
          child: Image.asset(
            spec.assetPath,
            fit: BoxFit.contain,
            errorBuilder: (_, __, ___) => Icon(
              spec.fallbackIcon,
              size: 56,
              color: spec.brand,
            ),
          ),
        ),
        Positioned(
          bottom: -8,
          right: -8,
          child: SizedBox(
            width: 52,
            height: 52,
            child: Lottie.asset(
              'assets/animations/browse.json',
              repeat: true,
              errorBuilder: (_, __, ___) => Icon(
                Icons.auto_awesome_rounded,
                color: spec.brand,
                size: 28,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _TeaserChip extends StatelessWidget {
  const _TeaserChip({required this.label, required this.color});

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: HomeColors.surface,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color.withValues(alpha: 0.28)),
      ),
      child: Text(
        label,
        style: const TextStyle(
          color: HomeColors.textSecondary,
          fontSize: 13,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

class _GlowOrb extends StatelessWidget {
  const _GlowOrb({
    required this.color,
    required this.size,
    required this.opacity,
  });

  final Color color;
  final double size;
  final double opacity;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: color.withValues(alpha: opacity),
      ),
    );
  }
}
