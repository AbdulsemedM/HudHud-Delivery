import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:hudhud_delivery/app/services/auth_service.dart';
import 'package:hudhud_delivery/app/services/guest_browse_service.dart';
import 'package:hudhud_delivery/app/services/startup_location_service.dart';
import 'package:hudhud_delivery/features/dashboard/presentation/screen/dashboard_screen.dart';
import 'package:hudhud_delivery/features/splash/presentation/theme/splash_colors.dart';
import '../widgets/splash_widget.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with TickerProviderStateMixin {
  final AuthService _authService = AuthService();

  late final AnimationController _introController;
  late final AnimationController _haloController;
  late final AnimationController _routesController;
  late final AnimationController _dotsController;

  @override
  void initState() {
    super.initState();

    _introController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    );
    _haloController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2600),
    )..repeat(reverse: true);
    _routesController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 3400),
    )..repeat(reverse: true);
    _dotsController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _introController.forward();
    });

    _checkAuthenticationAndNavigate();
  }

  @override
  void dispose() {
    _introController.dispose();
    _haloController.dispose();
    _routesController.dispose();
    _dotsController.dispose();
    super.dispose();
  }

  Future<void> _checkAuthenticationAndNavigate() async {
    try {
      await Future.wait([
        _authService.initialize(),
        StartupLocationService.fetchFreshOnAppLaunch(),
      ]);

      await Future.delayed(const Duration(seconds: 3));
      await _goToHome();
    } catch (e) {
      await Future.delayed(const Duration(seconds: 3));
      await _goToHome();
    }
  }

  /// Always open home. Use stored token when present; otherwise browse as guest.
  Future<void> _goToHome() async {
    final isAuthenticated = await _authService.isAuthenticated();
    await GuestBrowseService().configureBrowseSession(
      isAuthenticated: isAuthenticated,
    );
    if (!mounted) return;
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (context) => const DashboardScreen(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light,
        statusBarBrightness: Brightness.dark,
        systemNavigationBarColor: SplashColors.bgOuter,
        systemNavigationBarIconBrightness: Brightness.light,
      ),
      child: Scaffold(
        backgroundColor: SplashColors.bgDeep,
        body: SplashGlowBackground(
          child: SplashIntroContent(
            intro: _introController,
            halo: _haloController,
            routesTwinkle: _routesController,
            dotsBounce: _dotsController,
          ),
        ),
      ),
    );
  }
}
