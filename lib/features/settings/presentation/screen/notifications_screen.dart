import 'package:flutter/material.dart';

class NotificationsScreen extends StatelessWidget {
  const NotificationsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text('Notifications'),
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Today Section
            _NotificationSection(
              title: 'Today',
              notifications: [
                _NotificationItem(
                  icon: Icons.email,
                  iconColor: Colors.yellow[700]!,
                  title: 'New message!',
                  subtitle: 'Samuel Todd',
                  time: '1h ago',
                ),
                _NotificationItem(
                  icon: Icons.credit_card,
                  iconColor: Colors.red,
                  title: 'Payment received',
                  subtitle: 'Someone just posted a new job for mechanics',
                  time: '4h ago',
                ),
              ],
            ),
            // Yesterday Section
            _NotificationSection(
              title: 'Yesterday',
              notifications: [
                _NotificationItem(
                  icon: Icons.email,
                  iconColor: Colors.yellow[700]!,
                  title: 'New message!',
                  subtitle: 'Samuel Todd',
                  time: '1d ago',
                ),
                _NotificationItem(
                  icon: Icons.inventory_2,
                  iconColor: Colors.red,
                  title: 'Courier delivery successful',
                  subtitle: 'Someone just posted a new job for mechanics',
                  time: '1d ago',
                ),
              ],
            ),
            // Older Section
            _NotificationSection(
              title: 'Older',
              notifications: [
                _NotificationItem(
                  icon: Icons.email,
                  iconColor: Colors.yellow[700]!,
                  title: 'New message!',
                  subtitle: 'Samuel Todd',
                  time: '4d ago',
                ),
                _NotificationItem(
                  icon: Icons.build,
                  iconColor: Colors.red,
                  title: 'New Job Listing!',
                  subtitle: 'Someone just posted a new job for mechanics',
                  time: '3w ago',
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _NotificationSection extends StatelessWidget {
  final String title;
  final List<_NotificationItem> notifications;

  const _NotificationSection({
    required this.title,
    required this.notifications,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Text(
              title,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Color(0xFF2C3E50),
              ),
            ),
          ),
          const SizedBox(height: 12),
          ...notifications.map((notification) => notification),
        ],
      ),
    );
  }
}

class _NotificationItem extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String title;
  final String subtitle;
  final String time;

  const _NotificationItem({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.subtitle,
    required this.time,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(
          left: BorderSide(
            color: iconColor,
            width: 4,
          ),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: iconColor.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              icon,
              color: iconColor,
              size: 24,
            ),
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
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF2C3E50),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[600],
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  time,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[500],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

