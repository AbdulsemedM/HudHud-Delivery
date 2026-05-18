import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hudhud_delivery/core/widgets/user_avatar.dart';
import 'package:hudhud_delivery/features/orders/presentation/widgets/orders_widget.dart';
import 'package:hudhud_delivery/features/settings/presentation/screen/notifications_screen.dart';

class SettingsHeader extends StatelessWidget {
  const SettingsHeader({super.key, this.avatarUrl});

  final String? avatarUrl;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        StoryRing(
          child: UserAvatar(radius: 25, imageUrl: avatarUrl),
        ),
        IconButton(
          icon: const Icon(
            Icons.notifications_outlined,
            color: Colors.black,
            size: 28,
          ),
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute<void>(
                builder: (context) => BlocProvider(
                  create: (_) => createNotificationsBloc(),
                  child: const NotificationsScreen(),
                ),
              ),
            );
          },
        ),
      ],
    );
  }
}

class AccountSettingsSection extends StatelessWidget {
  final VoidCallback onEditTap;
  final String name;
  final String phone;
  final String email;
  final String? avatarUrl;

  const AccountSettingsSection({
    super.key,
    required this.onEditTap,
    required this.name,
    required this.phone,
    required this.email,
    this.avatarUrl,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Account Settings',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
            ),
            TextButton(
              onPressed: onEditTap,
              child: const Text(
                'Edit',
                style: TextStyle(
                  color: Colors.black,
                  fontSize: 16,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.grey[50],
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            children: [
              StoryRing(
                child: UserAvatar(radius: 30, imageUrl: avatarUrl),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      phone,
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[600],
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Icon(
                          Icons.mail_outline,
                          size: 16,
                          color: Colors.grey[600],
                        ),
                        const SizedBox(width: 8),
                        Text(
                          email,
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class SettingsSection extends StatelessWidget {
  final String title;
  final List<SettingsItem> items;

  const SettingsSection({
    super.key,
    required this.title,
    required this.items,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 16),
        Container(
          decoration: BoxDecoration(
            color: Colors.grey[50],
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            children: items,
          ),
        ),
      ],
    );
  }
}

class SettingsItem extends StatelessWidget {
  final IconData icon;
  final String title;
  final VoidCallback onTap;

  const SettingsItem({
    super.key,
    required this.icon,
    required this.title,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            Icon(
              icon,
              size: 24,
              color: Colors.grey[700],
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Text(
                title,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            Icon(
              Icons.chevron_right,
              color: Colors.grey[400],
            ),
          ],
        ),
      ),
    );
  }
}

class ThemeToggleItem extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final bool isDarkMode;
  final VoidCallback onToggle;

  const ThemeToggleItem({
    super.key,
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.isDarkMode,
    required this.onToggle,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onToggle,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            Icon(
              icon,
              size: 24,
              color: Colors.grey[700],
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
            ),
            Switch(
              value: isDarkMode,
              onChanged: (value) => onToggle(),
              activeColor: const Color(0xFF3498DB),
            ),
          ],
        ),
      ),
    );
  }
}
