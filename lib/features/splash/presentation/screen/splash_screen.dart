import 'package:flutter/material.dart';
import 'package:hudhud_delivery/app/services/auth_service.dart';
import 'package:hudhud_delivery/features/login/presentation/screen/login_screen.dart';
import 'package:hudhud_delivery/features/dashboard/presentation/screen/dashboard_screen.dart';
import '../widgets/splash_widget.dart';

class SplashScreen extends StatefulWidget {
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
      // Initialize the auth service to load cached data
      await _authService.initialize();

      // Wait for minimum splash screen duration (3 seconds)
      await Future.delayed(Duration(seconds: 3));

      // Check if user is authenticated
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
      // If there's any error, ensure minimum splash duration then navigate to login
      await Future.delayed(Duration(seconds: 3));
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
    final screenWidth = MediaQuery.of(context).size.width;

    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          // Vector background with opacity
          Positioned.fill(
            child: Opacity(
              opacity: 0.2,
              child: Image.asset(
                'assets/images/Vector.png',
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) {
                  return Container(color: Colors.grey[100]);
                },
              ),
            ),
          ),
          // Foreground content
          SafeArea(
            child: Column(
              children: [
                // Top padding
                SizedBox(height: screenHeight * 0.08),
                // Mascot image - centered and visible
                Container(
                  height: screenHeight * 0.35,
                  width: double.infinity,
                  alignment: Alignment.center,
                  child: Image.asset(
                    'assets/images/Delivery Service Retro Mascot 1 1.png',
                    width: screenWidth * 0.65,
                    fit: BoxFit.contain,
                    errorBuilder: (context, error, stackTrace) {
                      return Container(
                        width: 200,
                        height: 200,
                        color: Colors.grey[200],
                        child: Icon(Icons.image_not_supported, size: 50),
                      );
                    },
                  ),
                ),
                // Logo below mascot
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 20),
                  child: SplashLogo(),
                ),
                // Spacer to push loading indicator down
                Spacer(),
                // Loading indicator at the bottom
                Padding(
                  padding: const EdgeInsets.only(bottom: 50),
                  child: LoadingIndicator(),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
