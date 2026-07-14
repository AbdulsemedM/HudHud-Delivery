import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:hudhud_delivery/app/services/auth_service.dart';
import 'package:hudhud_delivery/app/services/startup_location_service.dart';
import 'package:hudhud_delivery/features/dashboard/presentation/screen/dashboard_screen.dart';
import 'package:hudhud_delivery/features/login/presentation/screen/login_screen.dart';
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

      final isAuthenticated = await _authService.isAuthenticated();

      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) =>
                isAuthenticated ? const DashboardScreen() : const LoginScreen(),
          ),
        );
      }
    } catch (e) {
      await Future.delayed(const Duration(seconds: 3));
      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => const LoginScreen(),
          ),
        );
      }
    }
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
