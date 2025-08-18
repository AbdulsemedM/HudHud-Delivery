import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:hudhud_delivery/features/settings/presentation/screen/edit_profile_screen.dart';
import 'package:hudhud_delivery/controllers/theme_controller.dart';
import 'package:hudhud_delivery/app/services/auth_service.dart';
import 'package:hudhud_delivery/features/login/presentation/screen/login_screen.dart';
import '../widgets/setting_widget.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  Future<void> _handleLogout(BuildContext context) async {
    try {
      // Show confirmation dialog
      final shouldLogout = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Logout'),
          content: const Text('Are you sure you want to logout?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('Logout'),
            ),
          ],
        ),
      );

      if (shouldLogout == true) {
        // Clear all stored data
        final authService = AuthService();
        await authService.clearAllData();

        // Navigate to login screen and clear navigation stack
        if (context.mounted) {
          Navigator.of(context).pushAndRemoveUntil(
            MaterialPageRoute(builder: (context) => const LoginScreen()),
            (route) => false,
          );
        }
      }
    } catch (e) {
      // Show error message
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error during logout: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SettingsHeader(),
              const SizedBox(height: 24),
              const Text(
                'Settings',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 24),
              AccountSettingsSection(
                name: 'Samara Mehmood',
                phone: '+92-3069278009',
                email: 'alma.lawson@example.com',
                onEditTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const EditProfileScreen(),
                    ),
                  );
                },
              ),
              const SizedBox(height: 24),
              const Text(
                'General',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 16),
              SettingsSection(
                title: '',
                items: [
                  SettingsItem(
                    icon: Icons.payment,
                    title: 'Payment Methods',
                    onTap: () {},
                  ),
                  SettingsItem(
                    icon: Icons.share,
                    title: 'Refer friends and family',
                    onTap: () {},
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Consumer<ThemeController>(
                builder: (context, themeController, child) {
                  return ThemeToggleItem(
                    icon: themeController.themeModeIcon,
                    title: 'Theme Mode',
                    subtitle: themeController.themeModeDisplayName,
                    isDarkMode: themeController.isDarkMode,
                    onToggle: () async {
                      await themeController.toggleTheme();
                    },
                  );
                },
              ),
              const SizedBox(height: 24),
              const Text(
                'Support',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 16),
              SettingsSection(
                title: '',
                items: [
                  SettingsItem(
                    icon: Icons.headset_mic_outlined,
                    title: 'Contact us',
                    onTap: () {},
                  ),
                  SettingsItem(
                    icon: Icons.info_outline,
                    title: 'About us',
                    onTap: () {},
                  ),
                  SettingsItem(
                    icon: Icons.lock_outline,
                    title: 'Privacy Policy',
                    onTap: () {},
                  ),
                  SettingsItem(
                    icon: Icons.description_outlined,
                    title: 'Terms of Services',
                    onTap: () {},
                  ),
                ],
              ),
              const SizedBox(height: 24),
              const Text(
                'Setting',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 16),
              SettingsSection(
                title: '',
                items: [
                  SettingsItem(
                    icon: Icons.payment,
                    title: 'Update Password',
                    onTap: () {},
                  ),
                  SettingsItem(
                    icon: Icons.language,
                    title: 'Language',
                    onTap: () {},
                  ),
                  SettingsItem(
                    icon: Icons.logout,
                    title: 'Logout',
                    onTap: () async {
                      await _handleLogout(context);
                    },
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
