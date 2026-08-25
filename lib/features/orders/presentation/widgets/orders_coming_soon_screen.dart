import 'package:flutter/material.dart';
import 'package:hudhud_delivery/app/navigation/dashboard_navigation.dart';
import 'package:hudhud_delivery/core/l10n/context_l10n.dart';
import 'package:hudhud_delivery/core/theme/app_colors.dart';
import 'package:hudhud_delivery/features/home/presentation/theme/home_colors.dart';
import 'package:hudhud_delivery/features/login/presentation/theme/auth_screen_colors.dart';
import 'package:hudhud_delivery/features/login/presentation/widgets/auth_gradient_button.dart';
import 'package:lottie/lottie.dart';

/// Full-tab placeholder while marketplace order history is not launched yet.
class OrdersComingSoonScreen extends StatefulWidget {
  const OrdersComingSoonScreen({super.key});

  @override
  State<OrdersComingSoonScreen> createState() => _OrdersComingSoonScreenState();
}

class _OrdersComingSoonScreenState extends State<OrdersComingSoonScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _fade;
  late final Animation<double> _slide;
  late final Animation<double> _heroScale;

  static const _brandOrange = AuthScreenColors.orange;
  static const _brandViolet = HomeColors.violet;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );
    _fade = CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic);
    _slide = Tween<double>(begin: 24, end: 0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic),
    );
    _heroScale = Tween<double>(begin: 0.88, end: 1).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOutBack),
    );
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _openCourierOnHome() {
    DashboardNavigation.instance.goToHome(refreshHome: true);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;

    return Stack(
      fit: StackFit.expand,
      children: [
        DecoratedBox(
          decoration: BoxDecoration(
            gradient: RadialGradient(
              center: Alignment(0, -0.45),
              radius: 1.15,
              colors: [
                _brandViolet.withValues(alpha: 0.28),
                HomeColors.backgroundOf(context),
              ],
            ),
          ),
        ),
        Positioned(
          top: 40,
          right: -20,
          child: _GlowOrb(color: _brandOrange, size: 130, opacity: 0.16),
        ),
        Positioned(
          bottom: 100,
          left: -40,
          child: _GlowOrb(color: _brandViolet, size: 110, opacity: 0.14),
        ),
        Positioned(
          top: 160,
          left: 24,
          child: _GlowOrb(color: _brandOrange, size: 64, opacity: 0.1),
        ),
        FadeTransition(
          opacity: _fade,
          child: AnimatedBuilder(
            animation: _slide,
            builder: (context, child) {
              return Transform.translate(
                offset: Offset(0, _slide.value),
                child: child,
              );
            },
            child: SingleChildScrollView(
              padding: EdgeInsets.fromLTRB(24, 20, 24, 32),
              child: Column(
                children: [
                  ScaleTransition(
                    scale: _heroScale,
                    child: _OrdersHero(
                      title: l10n.navOrderHistory,
                    ),
                  ),
                  SizedBox(height: 28),
                  Container(
                    padding:
                        EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          _brandOrange.withValues(alpha: 0.22),
                          _brandViolet.withValues(alpha: 0.22),
                        ],
                      ),
                      borderRadius: BorderRadius.circular(999),
                      border: Border.all(
                        color: _brandOrange.withValues(alpha: 0.45),
                      ),
                    ),
                    child: Text(
                      l10n.serviceComingSoonBadge,
                      style: TextStyle(
                        color: _brandOrange,
                        fontWeight: FontWeight.w700,
                        fontSize: 12,
                        letterSpacing: 0.8,
                      ),
                    ),
                  ),
                  SizedBox(height: 22),
                  Text(
                    l10n.ordersComingSoonTitle,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: HomeColors.textPrimaryOf(context),
                      fontSize: 26,
                      fontWeight: FontWeight.w800,
                      height: 1.2,
                      letterSpacing: -0.3,
                    ),
                  ),
                  SizedBox(height: 12),
                  Text(
                    l10n.ordersComingSoonSubtitle,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: HomeColors.textMutedOf(context),
                      fontSize: 15,
                      height: 1.55,
                    ),
                  ),
                  SizedBox(height: 28),
                  _FeaturePreviewRow(
                    items: [
                      _FeaturePreview(
                        icon: Icons.local_shipping_outlined,
                        label: l10n.ordersComingSoonTeaser1,
                        color: _brandOrange,
                      ),
                      _FeaturePreview(
                        icon: Icons.replay_rounded,
                        label: l10n.ordersComingSoonTeaser2,
                        color: _brandViolet,
                      ),
                      _FeaturePreview(
                        icon: Icons.receipt_long_outlined,
                        label: l10n.ordersComingSoonTeaser3,
                        color: AuthScreenColors.lavender,
                      ),
                    ],
                  ),
                  SizedBox(height: 28),
                  _ProgressCard(
                    steps: [
                      l10n.ordersComingSoonStep1,
                      l10n.ordersComingSoonStep2,
                      l10n.ordersComingSoonStep3,
                    ],
                  ),
                  SizedBox(height: 32),
                  AuthGradientButton(
                    label: l10n.ordersComingSoonCta,
                    onPressed: _openCourierOnHome,
                  ),
                  SizedBox(height: 12),
                  Text(
                    l10n.ordersComingSoonFootnote,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: HomeColors.textMutedOf(context).withValues(alpha: 0.85),
                      fontSize: 12,
                      height: 1.4,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _OrdersHero extends StatelessWidget {
  const _OrdersHero({required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Stack(
          alignment: Alignment.center,
          clipBehavior: Clip.none,
          children: [
            Container(
              width: 172,
              height: 172,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: AuthScreenColors.orange.withValues(alpha: 0.32),
                    blurRadius: 40,
                    spreadRadius: 2,
                  ),
                  BoxShadow(
                    color: HomeColors.violet.withValues(alpha: 0.24),
                    blurRadius: 48,
                    spreadRadius: -4,
                  ),
                ],
              ),
            ),
            Container(
              width: 152,
              height: 152,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(36),
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    HomeColors.surfaceElevatedOf(context),
                    HomeColors.surfaceOf(context),
                  ],
                ),
                border: Border.all(
                  color: HomeColors.violet.withValues(alpha: 0.35),
                ),
              ),
              child: Stack(
                alignment: Alignment.center,
                children: [
                  Icon(
                    Icons.receipt_long_rounded,
                    size: 64,
                    color: HomeColors.violet.withValues(alpha: 0.95),
                  ),
                  Positioned(
                    bottom: 28,
                    right: 32,
                    child: Container(
                      padding: EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: AuthScreenColors.orange,
                        borderRadius: BorderRadius.circular(10),
                        boxShadow: [
                          BoxShadow(
                            color: AuthScreenColors.orange
                                .withValues(alpha: 0.45),
                            blurRadius: 12,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Icon(
                        Icons.inventory_2_outlined,
                        size: 18,
                        color: AppColors.lightOnPrimary,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Positioned(
              bottom: -6,
              right: -6,
              child: SizedBox(
                width: 52,
                height: 52,
                child: Lottie.asset(
                  'assets/animations/browse.json',
                  repeat: true,
                  errorBuilder: (_, __, ___) => Icon(
                    Icons.auto_awesome_rounded,
                    color: AuthScreenColors.orange,
                    size: 28,
                  ),
                ),
              ),
            ),
          ],
        ),
        SizedBox(height: 14),
        Text(
          title,
          style: TextStyle(
            color: HomeColors.textSecondaryOf(context),
            fontSize: 13,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.4,
          ),
        ),
      ],
    );
  }
}

class _FeaturePreviewRow extends StatelessWidget {
  const _FeaturePreviewRow({required this.items});

  final List<_FeaturePreview> items;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        for (var i = 0; i < items.length; i++) ...[
          if (i > 0) SizedBox(width: 10),
          Expanded(child: items[i]),
        ],
      ],
    );
  }
}

class _FeaturePreview extends StatelessWidget {
  const _FeaturePreview({
    required this.icon,
    required this.label,
    required this.color,
  });

  final IconData icon;
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 10, vertical: 14),
      decoration: BoxDecoration(
        color: HomeColors.surfaceOf(context),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withValues(alpha: 0.28)),
      ),
      child: Column(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: color.withValues(alpha: 0.14),
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          SizedBox(height: 10),
          Text(
            label,
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: HomeColors.textSecondaryOf(context),
              fontSize: 11,
              fontWeight: FontWeight.w600,
              height: 1.25,
            ),
          ),
        ],
      ),
    );
  }
}

class _ProgressCard extends StatelessWidget {
  const _ProgressCard({required this.steps});

  final List<String> steps;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.fromLTRB(18, 18, 18, 16),
      decoration: BoxDecoration(
        color: HomeColors.surfaceOf(context).withValues(alpha: 0.85),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: HomeColors.borderOf(context)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          for (var i = 0; i < steps.length; i++) ...[
            if (i > 0) SizedBox(height: 12),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 26,
                  height: 26,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: i == 0
                        ? const LinearGradient(
                            colors: AuthScreenColors.signInGradient,
                          )
                        : null,
                    color: i == 0
                        ? null
                        : HomeColors.surfaceElevatedOf(context),
                    border: i == 0
                        ? null
                        : Border.all(
                            color: HomeColors.violet.withValues(alpha: 0.35),
                          ),
                  ),
                  alignment: Alignment.center,
                  child: i == 0
                      ? Icon(Icons.check_rounded, size: 14, color: AppColors.lightOnPrimary)
                      : Text(
                          '${i + 1}',
                          style: TextStyle(
                            color: HomeColors.textMutedOf(context).withValues(alpha: 0.9),
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                ),
                SizedBox(width: 12),
                Expanded(
                  child: Padding(
                    padding: EdgeInsets.only(top: 4),
                    child: Text(
                      steps[i],
                      style: TextStyle(
                        color: i == 0
                            ? HomeColors.textPrimaryOf(context)
                            : HomeColors.textMutedOf(context),
                        fontSize: 13,
                        fontWeight:
                            i == 0 ? FontWeight.w600 : FontWeight.w500,
                        height: 1.35,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ],
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
