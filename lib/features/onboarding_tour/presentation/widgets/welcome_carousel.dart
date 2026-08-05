import 'package:flutter/material.dart';
import 'package:hudhud_delivery/core/l10n/context_l10n.dart';
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
        secondaryIcon: Icons.local_shipping_rounded,
      ),
      _CarouselSlide(
        title: l10n.onboardingFoodTitle,
        description: l10n.onboardingFoodDescription,
        color: ServiceTabPalette.foodGroceries,
        icon: Icons.restaurant_rounded,
        secondaryIcon: Icons.shopping_basket_rounded,
      ),
      _CarouselSlide(
        title: l10n.onboardingCourierTitle,
        description: l10n.onboardingCourierDescription,
        color: ServiceTabPalette.courier,
        icon: Icons.inventory_2_rounded,
        secondaryIcon: Icons.local_shipping_outlined,
      ),
      _CarouselSlide(
        title: l10n.onboardingTaxiTitle,
        description: l10n.onboardingTaxiDescription,
        color: ServiceTabPalette.taxi,
        icon: Icons.local_taxi_rounded,
        secondaryIcon: Icons.route_rounded,
      ),
      _CarouselSlide(
        title: l10n.onboardingHandymanTitle,
        description: l10n.onboardingHandymanDescription,
        color: ServiceTabPalette.handyman,
        icon: Icons.handyman_rounded,
        secondaryIcon: Icons.build_circle_outlined,
      ),
    ];

    final isLastPage = _currentPage == slides.length - 1;

    return Material(
      color: HomeColors.background,
      child: SafeArea(
        child: Column(
          children: [
            Align(
              alignment: AlignmentDirectional.centerEnd,
              child: TextButton(
                onPressed: _skip,
                child: Text(
                  l10n.actionSkip,
                  style: const TextStyle(
                    color: HomeColors.textMuted,
                    fontWeight: FontWeight.w600,
                  ),
                ),
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
            const SizedBox(height: 16),
            _PageDots(
              count: slides.length,
              current: _currentPage,
              activeColor: slides[_currentPage].color,
            ),
            const SizedBox(height: 24),
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
              child: SizedBox(
                width: double.infinity,
                height: 52,
                child: FilledButton(
                  onPressed: () => _goNext(slides.length),
                  style: FilledButton.styleFrom(
                    backgroundColor: slides[_currentPage].color,
                    foregroundColor: Colors.black87,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  child: Text(
                    isLastPage ? l10n.onboardingGetStarted : l10n.actionNext,
                    style: const TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 16,
                    ),
                  ),
                ),
              ),
            ),
          ],
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
    required this.secondaryIcon,
  });

  final String title;
  final String description;
  final Color color;
  final IconData icon;
  final IconData secondaryIcon;
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
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _Illustration(
                color: slide.color,
                primaryIcon: slide.icon,
                secondaryIcon: slide.secondaryIcon,
              ),
              const SizedBox(height: 36),
              Text(
                slide.title,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.w800,
                  color: HomeColors.textPrimary,
                  height: 1.2,
                ),
              ),
              const SizedBox(height: 14),
              Text(
                slide.description,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 15,
                  height: 1.5,
                  color: HomeColors.textSecondary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Illustration extends StatefulWidget {
  const _Illustration({
    required this.color,
    required this.primaryIcon,
    required this.secondaryIcon,
  });

  final Color color;
  final IconData primaryIcon;
  final IconData secondaryIcon;

  @override
  State<_Illustration> createState() => _IllustrationState();
}

class _IllustrationState extends State<_Illustration>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pulseController;
  late final Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2200),
    )..repeat(reverse: true);
    _scale = Tween<double>(begin: 0.96, end: 1.04).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ScaleTransition(
      scale: _scale,
      child: SizedBox(
        width: 180,
        height: 180,
        child: Stack(
          alignment: Alignment.center,
          children: [
            Container(
              width: 180,
              height: 180,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    widget.color.withValues(alpha: 0.35),
                    widget.color.withValues(alpha: 0.05),
                  ],
                ),
              ),
            ),
            Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                color: widget.color.withValues(alpha: 0.18),
                borderRadius: BorderRadius.circular(32),
                border: Border.all(
                  color: widget.color.withValues(alpha: 0.45),
                  width: 1.5,
                ),
                boxShadow: [
                  BoxShadow(
                    color: widget.color.withValues(alpha: 0.25),
                    blurRadius: 24,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: Icon(
                widget.primaryIcon,
                size: 56,
                color: widget.color,
              ),
            ),
            Positioned(
              right: 18,
              bottom: 18,
              child: Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: HomeColors.surfaceElevated,
                  shape: BoxShape.circle,
                  border: Border.all(color: widget.color.withValues(alpha: 0.5)),
                ),
                child: Icon(
                  widget.secondaryIcon,
                  size: 22,
                  color: widget.color,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PageDots extends StatelessWidget {
  const _PageDots({
    required this.count,
    required this.current,
    required this.activeColor,
  });

  final int count;
  final int current;
  final Color activeColor;

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
          width: isActive ? 22 : 8,
          height: 8,
          decoration: BoxDecoration(
            color: isActive
                ? activeColor
                : HomeColors.textMuted.withValues(alpha: 0.35),
            borderRadius: BorderRadius.circular(8),
          ),
        );
      }),
    );
  }
}
