import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:hudhud_delivery/app/services/auth_service.dart';
import 'package:hudhud_delivery/app/services/force_update_service.dart';
import 'package:hudhud_delivery/app/services/guest_browse_service.dart';
import 'package:hudhud_delivery/app/services/remote_config_service.dart';
import 'package:hudhud_delivery/app/services/startup_location_service.dart';
import 'package:hudhud_delivery/features/dashboard/presentation/screen/dashboard_screen.dart';
import 'package:hudhud_delivery/features/force_update/presentation/screen/force_update_screen.dart';
import 'package:hudhud_delivery/features/force_update/presentation/widgets/soft_update_dialog.dart';
import 'package:hudhud_delivery/features/login/presentation/screen/phone_enrollment_screen.dart';
import 'package:hudhud_delivery/features/login/utils/phone_enrollment_gate.dart';
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
  final ForceUpdateService _forceUpdateService = ForceUpdateService();

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
        RemoteConfigService.instance.initialize(),
      ]);
    } catch (_) {
      // Continue even if auth/location/remote-config init fails.
    }

    await Future.delayed(const Duration(seconds: 3));
    if (!mounted) return;

    ForceUpdateCheckResult? updateCheck;
    try {
      updateCheck = await _forceUpdateService.check();
      if (!mounted) return;
      if (updateCheck.required) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (_) => ForceUpdateScreen(
              currentVersion: updateCheck!.currentVersion,
              minimumSupportedVersion: updateCheck.minimumSupportedVersion,
              latestStoreVersion: updateCheck.latestStoreVersion,
            ),
          ),
        );
        return;
      }
    } catch (_) {
      // Fail open: never block the app if the force-update check errors.
    }

    // Soft prompt stays on splash so it isn't lost after pushReplacement.
    if (mounted && updateCheck?.softSuggested == true) {
      await showSoftUpdateDialog(
        context,
        currentVersion: updateCheck!.currentVersion,
        latestStoreVersion: updateCheck.latestStoreVersion,
      );
    }

    if (!mounted) return;
    await _goToHome();
  }

  /// Always open home. Use stored token when present; otherwise browse as guest.
  /// Authenticated users who still need phone enrollment are gated first.
  Future<void> _goToHome() async {
    final isAuthenticated = await _authService.isAuthenticated();
    await GuestBrowseService().configureBrowseSession(
      isAuthenticated: isAuthenticated,
    );
    if (!mounted) return;

    if (isAuthenticated) {
      final user =
          _authService.currentUser ?? await _authService.getStoredUser();
      if (!mounted) return;
      if (user != null && userNeedsPhoneEnrollment(user)) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => const PhoneEnrollmentScreen(),
          ),
        );
        return;
      }
    }

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
