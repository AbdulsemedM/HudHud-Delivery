import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:hudhud_delivery/core/l10n/context_l10n.dart';
import 'package:hudhud_delivery/core/theme/app_colors.dart';
import 'package:hudhud_delivery/core/theme/service_tab_palette.dart';
import 'package:hudhud_delivery/features/home/presentation/theme/home_colors.dart';

class WelcomeCarousel extends StatefulWidget {
  const WelcomeCarousel({super.key});

  @override
  State<WelcomeCarousel> createState() => _WelcomeCarouselState();
}

class _WelcomeCarouselState extends State<WelcomeCarousel> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  static const _animationDuration = Duration(milliseconds: 380);
  static const _animationCurve = Curves.easeOutCubic;

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _goNext(int pageCount) {
    if (_currentPage >= pageCount - 1) {
      Navigator.of(context).pop(true);
      return;
    }
    _pageController.nextPage(
      duration: _animationDuration,
      curve: _animationCurve,
    );
  }

  void _skip() {
    Navigator.of(context).pop(true);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final slides = <_CarouselSlide>[
      _CarouselSlide(
        title: l10n.onboardingWelcomeTitle,
        description: l10n.onboardingWelcomeSubtitle,
        color: HomeColors.orange,
        icon: Icons.waving_hand_rounded,
      ),
      _CarouselSlide(
        title: l10n.onboardingCourierTitle,
        description: l10n.onboardingCourierDescription,
        color: ServiceTabPalette.courier,
        icon: Icons.inventory_2_rounded,
        assetPath: 'assets/images/home_service_tabs/courier.png',
      ),
      _CarouselSlide(
        title: l10n.onboardingFoodTitle,
        description: l10n.onboardingFoodDescription,
        color: ServiceTabPalette.foodGroceries,
        icon: Icons.restaurant_rounded,
        assetPath: 'assets/images/home_service_tabs/food_groceries.png',
      ),
      _CarouselSlide(
        title: l10n.onboardingTaxiTitle,
        description: l10n.onboardingTaxiDescription,
        color: ServiceTabPalette.taxi,
        icon: Icons.local_taxi_rounded,
        assetPath: 'assets/images/home_service_tabs/taxi.png',
      ),
      _CarouselSlide(
        title: l10n.onboardingHandymanTitle,
        description: l10n.onboardingHandymanDescription,
        color: ServiceTabPalette.handyman,
        icon: Icons.handyman_rounded,
        assetPath: 'assets/images/home_service_tabs/handyman.png',
      ),
    ];

    final isLastPage = _currentPage == slides.length - 1;

    return Material(
      color: HomeColors.backgroundOf(context),
      child: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 8, 0),
              child: Row(
                children: [
                  Text(
                    '${_currentPage + 1}/${slides.length}',
                    style: TextStyle(
                      color: HomeColors.textMutedOf(context),
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      fontFeatures: const [FontFeature.tabularFigures()],
                    ),
                  ),
                  const Spacer(),
                  AnimatedOpacity(
                    duration: const Duration(milliseconds: 200),
                    opacity: isLastPage ? 0 : 1,
                    child: TextButton(
                      onPressed: isLastPage ? null : _skip,
                      style: TextButton.styleFrom(
                        foregroundColor: HomeColors.textPrimaryOf(context),
                        minimumSize: const Size(64, 48),
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                        textStyle: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      child: Text(l10n.actionSkip),
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: PageView.builder(
                controller: _pageController,
                itemCount: slides.length,
                onPageChanged: (index) => setState(() => _currentPage = index),
                itemBuilder: (context, index) {
                  return _AnimatedSlideContent(
                    slide: slides[index],
                    isActive: index == _currentPage,
                  );
                },
              ),
            ),
            const SizedBox(height: 8),
            _PageDots(count: slides.length, current: _currentPage),
            const SizedBox(height: 28),
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 0, 24, 20),
              child: _PrimaryButton(
                label: isLastPage ? l10n.onboardingGetStarted : l10n.actionNext,
                icon: isLastPage
                    ? Icons.check_rounded
                    : Icons.arrow_forward_rounded,
                onPressed: () => _goNext(slides.length),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PrimaryButton extends StatelessWidget {
  const _PrimaryButton({
    required this.label,
    required this.icon,
    required this.onPressed,
  });

  final String label;
  final IconData icon;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final radius = BorderRadius.circular(18);
    final dark = HomeColors.isDark(context);
    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: radius,
        boxShadow: dark
            ? null
            : [
                BoxShadow(
                  color: AppColors.brandOrange.withValues(alpha: 0.28),
                  blurRadius: 20,
                  offset: const Offset(0, 8),
                ),
              ],
      ),
      child: SizedBox(
        width: double.infinity,
        height: 56,
        child: FilledButton(
          onPressed: onPressed,
          style: FilledButton.styleFrom(
            backgroundColor: AppColors.brandOrange,
            foregroundColor: Colors.white,
            elevation: 0,
            shape: RoundedRectangleBorder(borderRadius: radius),
          ),
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 200),
            child: Row(
              key: ValueKey(label),
              mainAxisSize: MainAxisSize.min,
              children: [
                Flexible(
                  child: Text(
                    label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 17,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Icon(icon, color: Colors.white, size: 22),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _CarouselSlide {
  const _CarouselSlide({
    required this.title,
    required this.description,
    required this.color,
    required this.icon,
    this.assetPath,
  });

  final String title;
  final String description;
  final Color color;
  final IconData icon;
  final String? assetPath;
}

class _AnimatedSlideContent extends StatefulWidget {
  const _AnimatedSlideContent({
    required this.slide,
    required this.isActive,
  });

  final _CarouselSlide slide;
  final bool isActive;

  @override
  State<_AnimatedSlideContent> createState() => _AnimatedSlideContentState();
}

class _AnimatedSlideContentState extends State<_AnimatedSlideContent>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _fade;
  late final Animation<Offset> _slideUp;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
    _fade = CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic);
    _slideUp = Tween<Offset>(
      begin: const Offset(0, 0.08),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic));
    if (widget.isActive) {
      _controller.forward();
    }
  }

  @override
  void didUpdateWidget(covariant _AnimatedSlideContent oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isActive && !oldWidget.isActive) {
      _controller.forward(from: 0);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final slide = widget.slide;

    return FadeTransition(
      opacity: _fade,
      child: SlideTransition(
        position: _slideUp,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 28),
          child: Column(
            children: [
              Expanded(
                child: Center(
                  child: LayoutBuilder(
                    builder: (context, constraints) {
                      final side = math.min(
                        math.min(constraints.maxWidth, constraints.maxHeight),
                        320.0,
                      );
                      return _Illustration(
                        size: side,
                        color: slide.color,
                        icon: slide.icon,
                        assetPath: slide.assetPath,
                      );
                    },
                  ),
                ),
              ),
              const SizedBox(height: 28),
              Text(
                slide.title,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.6,
                  color: HomeColors.textPrimaryOf(context),
                  height: 1.18,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                slide.description,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 16,
                  height: 1.5,
                  fontWeight: FontWeight.w500,
                  color: HomeColors.textSecondaryOf(context),
                ),
              ),
              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
    );
  }
}

/// Hero illustration: the service picture floating on a soft tinted disc.
class _Illustration extends StatefulWidget {
  const _Illustration({
    required this.size,
    required this.color,
    required this.icon,
    this.assetPath,
  });

  final double size;
  final Color color;
  final IconData icon;
  final String? assetPath;

  @override
  State<_Illustration> createState() => _IllustrationState();
}

class _IllustrationState extends State<_Illustration>
    with SingleTickerProviderStateMixin {
  late final AnimationController _floatController;
  late final Animation<double> _float;

  static const _welcomeAssets = [
    'assets/images/home_service_tabs/courier.png',
    'assets/images/home_service_tabs/food_groceries.png',
    'assets/images/home_service_tabs/taxi.png',
    'assets/images/home_service_tabs/handyman.png',
  ];

  static const _welcomeColors = [
    ServiceTabPalette.courier,
    ServiceTabPalette.foodGroceries,
    ServiceTabPalette.taxi,
    ServiceTabPalette.handyman,
  ];

  @override
  void initState() {
    super.initState();
    _floatController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2600),
    )..repeat(reverse: true);
    _float = Tween<double>(begin: -6, end: 6).animate(
      CurvedAnimation(parent: _floatController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _floatController.dispose();
    super.dispose();
  }

  Widget _image(String path, double size, Color fallbackColor) {
    return Image.asset(
      path,
      width: size,
      height: size,
      fit: BoxFit.contain,
      gaplessPlayback: true,
      errorBuilder: (_, __, ___) =>
          Icon(widget.icon, size: size * 0.6, color: fallbackColor),
    );
  }

  @override
  Widget build(BuildContext context) {
    final s = widget.size;
    final dark = HomeColors.isDark(context);
    final color = widget.color;
    final assetPath = widget.assetPath;

    return SizedBox(
      width: s,
      height: s,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Outer soft halo.
          Container(
            width: s,
            height: s,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: color.withValues(alpha: dark ? 0.10 : 0.07),
            ),
          ),
          // Inner tinted disc.
          Container(
            width: s * 0.74,
            height: s * 0.74,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: color.withValues(alpha: dark ? 0.18 : 0.13),
            ),
          ),
          AnimatedBuilder(
            animation: _float,
            builder: (context, child) => Transform.translate(
              offset: Offset(0, _float.value),
              child: child,
            ),
            child: assetPath != null
                ? _image(assetPath, s * 0.56, color)
                : _WelcomeCluster(
                    size: s,
                    icon: widget.icon,
                    accent: color,
                    tiles: [
                      for (var i = 0; i < _welcomeAssets.length; i++)
                        _image(
                          _welcomeAssets[i],
                          s * 0.15,
                          _welcomeColors[i],
                        ),
                    ],
                  ),
          ),
        ],
      ),
    );
  }
}

/// Welcome slide: a hero icon with the four services orbiting it.
class _WelcomeCluster extends StatelessWidget {
  const _WelcomeCluster({
    required this.size,
    required this.icon,
    required this.accent,
    required this.tiles,
  });

  final double size;
  final IconData icon;
  final Color accent;
  final List<Widget> tiles;

  @override
  Widget build(BuildContext context) {
    final center = size * 0.34;
    final tile = size * 0.25;
    final surface = HomeColors.surfaceOf(context);
    final dark = HomeColors.isDark(context);
    final border =
        dark ? Border.all(color: HomeColors.borderOf(context)) : null;
    final shadow = AppColors.softShadow(context);

    // Diagonal positions around the centre.
    const positions = [
      Alignment(-0.78, -0.78),
      Alignment(0.78, -0.78),
      Alignment(-0.78, 0.78),
      Alignment(0.78, 0.78),
    ];

    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        children: [
          Align(
            alignment: Alignment.center,
            child: Container(
              width: center,
              height: center,
              decoration: BoxDecoration(
                color: surface,
                shape: BoxShape.circle,
                border: border,
                boxShadow: shadow,
              ),
              child: Icon(icon, size: center * 0.48, color: accent),
            ),
          ),
          for (var i = 0; i < tiles.length && i < positions.length; i++)
            Align(
              alignment: positions[i],
              child: Container(
                width: tile,
                height: tile,
                padding: EdgeInsets.all(tile * 0.18),
                decoration: BoxDecoration(
                  color: surface,
                  borderRadius: BorderRadius.circular(tile * 0.32),
                  border: border,
                  boxShadow: shadow,
                ),
                child: tiles[i],
              ),
            ),
        ],
      ),
    );
  }
}

class _PageDots extends StatelessWidget {
  const _PageDots({
    required this.count,
    required this.current,
  });

  final int count;
  final int current;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(count, (index) {
        final isActive = index == current;
        return AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOutCubic,
          margin: const EdgeInsets.symmetric(horizontal: 4),
          width: isActive ? 28 : 8,
          height: 8,
          decoration: BoxDecoration(
            color: isActive
                ? AppColors.brandOrange
                : HomeColors.textMutedOf(context).withValues(alpha: 0.3),
            borderRadius: BorderRadius.circular(8),
          ),
        );
      }),
    );
  }
}
