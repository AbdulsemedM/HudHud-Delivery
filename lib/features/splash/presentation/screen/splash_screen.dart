import 'package:flutter/material.dart';
import 'package:hudhud_delivery/app/navigation/fcm_order_navigation.dart';
import 'package:hudhud_delivery/app/services/auth_service.dart';
import 'package:hudhud_delivery/app/services/guest_browse_service.dart';
import 'package:hudhud_delivery/app/services/fcm_service.dart';
import 'package:hudhud_delivery/app/services/startup_location_service.dart';
import 'package:hudhud_delivery/core/theme/app_colors.dart';
import 'package:hudhud_delivery/features/dashboard/presentation/screen/dashboard_screen.dart';
import '../widgets/splash_widget.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  _SplashScreenState createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  final AuthService _authService = AuthService();

  @override
  void initState() {
    super.initState();
    _checkAuthenticationAndNavigate();
  }

  Future<void> _checkAuthenticationAndNavigate() async {
    try {
      await Future.wait([
        _authService.initialize(),
        StartupLocationService.fetchFreshOnAppLaunch(),
      ]);

      try {
        final initialMsg = await FcmService().getInitialMessage();
        final id = parseOrderIdFromFcmPayload(initialMsg, localPayload: null);
        if (id != null) {
          PendingFcmOrderNavigation.setPending(id);
        }
      } catch (_) {}

      await Future.delayed(const Duration(seconds: 3));

      final isAuthenticated = await _authService.isAuthenticated();
      await GuestBrowseService().configureBrowseSession(
        isAuthenticated: isAuthenticated,
      );

      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => const DashboardScreen(),
          ),
        );
      }
    } catch (e) {
      await Future.delayed(const Duration(seconds: 3));
      await GuestBrowseService().enterGuestBrowseMode();
      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => const DashboardScreen(),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [AppColors.primaryColor, AppColors.primaryDarkColor],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Stack(
          children: [
            Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: const [
                  SplashLogo(),
                  SizedBox(height: 12),
                  SplashTagline(),
                ],
              ),
            ),
            Positioned(
              left: 0,
              right: 0,
              bottom: screenHeight * 0.15,
              child: const Center(child: LoadingIndicator()),
            ),
          ],
        ),
      ),
    );
  }
}
