import 'package:flutter/material.dart';
import 'package:hudhud_delivery/features/settings/presentation/screen/edit_profile_screen.dart';
import '../widgets/setting_widget.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

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
                    onTap: () {},
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
