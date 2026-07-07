import 'package:flutter/material.dart';
import 'package:hudhud_delivery/app/navigation/fcm_order_navigation.dart';
import 'package:hudhud_delivery/app/services/auth_service.dart';
import 'package:hudhud_delivery/app/services/guest_browse_service.dart';
import 'package:hudhud_delivery/app/services/fcm_service.dart';
import 'package:hudhud_delivery/app/services/startup_location_service.dart';
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
      await Future.wait([
        _authService.initialize(),
        StartupLocationService.fetchFreshOnAppLaunch(),
      ]);

      // Cold start from FCM: resolve order and open after dashboard (or after login).
      try {
        final initialMsg = await FcmService().getInitialMessage();
        final id = parseOrderIdFromFcmPayload(initialMsg, localPayload: null);
        if (id != null) {
          PendingFcmOrderNavigation.setPending(id);
        }
      } catch (_) {
        // FCM not initialized (e.g. Firebase unavailable)
      }

      // Wait for minimum splash screen duration (3 seconds)
      await Future.delayed(Duration(seconds: 3));

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
      await Future.delayed(Duration(seconds: 3));
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
    final screenWidth = MediaQuery.of(context).size.width;
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
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
                  return Container(color: theme.colorScheme.surfaceContainerHighest);
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
                        color: theme.colorScheme.surfaceContainerHighest,
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
