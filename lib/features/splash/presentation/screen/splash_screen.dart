import 'package:flutter/material.dart';
import 'package:hudhud_delivery/app/services/auth_service.dart';
import 'package:hudhud_delivery/app/services/startup_location_service.dart';
import 'package:hudhud_delivery/core/theme/app_colors.dart';
import 'package:hudhud_delivery/features/login/presentation/screen/login_screen.dart';
import 'package:hudhud_delivery/features/dashboard/presentation/screen/dashboard_screen.dart';
import '../widgets/splash_widget.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
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
    final screenHeight = MediaQuery.of(context).size.height;

    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [AppColors.primaryColor, AppColors.primaryDarkColor],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              SizedBox(height: screenHeight * 0.28),
              const SplashLogo(),
              const SizedBox(height: AppColors.spaceLG),
              const SplashTagline(),
              const Spacer(),
              SizedBox(
                height: screenHeight * 0.15,
                child: const Center(
                  child: LoadingIndicator(),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
