 import 'package:flutter/material.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _notificationsEnabled = true;
  bool _locationEnabled = true;
  bool _darkModeEnabled = false;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Settings',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 24),
            _buildSection(
              'Notifications',
              [
                _buildSwitchTile(
                  'Push Notifications',
                  'Receive notifications about new orders',
                  _notificationsEnabled,
                  (value) {
                    setState(() {
                      _notificationsEnabled = value;
                    });
                  },
                ),
                _buildSwitchTile(
                  'Location Services',
                  'Allow app to access your location',
                  _locationEnabled,
                  (value) {
                    setState(() {
                      _locationEnabled = value;
                    });
                  },
                ),
              ],
            ),
            const SizedBox(height: 16),
            _buildSection(
              'Appearance',
              [
                _buildSwitchTile(
                  'Dark Mode',
                  'Switch to dark theme',
                  _darkModeEnabled,
                  (value) {
                    setState(() {
                      _darkModeEnabled = value;
                    });
                  },
                ),
              ],
            ),
            const SizedBox(height: 16),
            _buildSection(
              'Account',
              [
                _buildActionTile(
                  'Change Password',
                  'Update your account password',
                  Icons.lock_outline,
                  () {
                    // Handle change password
                  },
                ),
                _buildActionTile(
                  'Language',
                  'English (US)',
                  Icons.language,
                  () {
                    // Handle language change
                  },
                ),
                _buildActionTile(
                  'Privacy Policy',
                  'Read our privacy policy',
                  Icons.privacy_tip_outlined,
                  () {
                    // Handle privacy policy
                  },
                ),
                _buildActionTile(
                  'Terms of Service',
                  'Read our terms of service',
                  Icons.description_outlined,
                  () {
                    // Handle terms of service
                  },
                ),
              ],
            ),
            const SizedBox(height: 16),
            _buildSection(
              'Support',
              [
                _buildActionTile(
                  'Help Center',
                  'Get help with the app',
                  Icons.help_outline,
                  () {
                    // Handle help center
                  },
                ),
                _buildActionTile(
                  'Contact Support',
                  'Reach out to our support team',
                  Icons.support_agent_outlined,
                  () {
                    // Handle contact support
                  },
                ),
              ],
            ),
            const SizedBox(height: 16),
            _buildSection(
              'App Information',
              [
                _buildInfoTile(
                  'Version',
                  '1.0.0',
                  Icons.info_outline,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSection(String title, List<Widget> children) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Color(0xFF6C3EE9),
          ),
        ),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            children: children,
          ),
        ),
      ],
    );
  }

  Widget _buildSwitchTile(
    String title,
    String subtitle,
    bool value,
    ValueChanged<bool> onChanged,
  ) {
    return ListTile(
      title: Text(title),
      subtitle: Text(
        subtitle,
        style: TextStyle(
          color: Colors.grey[600],
          fontSize: 14,
        ),
      ),
      trailing: Switch(
        value: value,
        onChanged: onChanged,
        activeColor: const Color(0xFF6C3EE9),
      ),
    );
  }

  Widget _buildActionTile(
    String title,
    String subtitle,
    IconData icon,
    VoidCallback onTap,
  ) {
    return ListTile(
      leading: Icon(
        icon,
        color: const Color(0xFF6C3EE9),
      ),
      title: Text(title),
      subtitle: Text(
        subtitle,
        style: TextStyle(
          color: Colors.grey[600],
          fontSize: 14,
        ),
      ),
      trailing: const Icon(
        Icons.chevron_right,
        color: Colors.grey,
      ),
      onTap: onTap,
    );
  }

  Widget _buildInfoTile(
    String title,
    String subtitle,
    IconData icon,
  ) {
    return ListTile(
      leading: Icon(
        icon,
        color: const Color(0xFF6C3EE9),
      ),
      title: Text(title),
      subtitle: Text(
        subtitle,
        style: TextStyle(
          color: Colors.grey[600],
          fontSize: 14,
        ),
      ),
    );
  }
}