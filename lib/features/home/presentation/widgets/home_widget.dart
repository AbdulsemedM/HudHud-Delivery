import 'package:flutter/material.dart';

class UserProfileHeader extends StatelessWidget {
  final String name;
  final String location;
  final VoidCallback onLocationTap;

  const UserProfileHeader({
    super.key,
    required this.name,
    required this.location,
    required this.onLocationTap,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const CircleAvatar(
              radius: 20,
              backgroundImage: NetworkImage('https://via.placeholder.com/40'),
            ),
            const Spacer(),
            IconButton(
              icon: const Icon(
                Icons.notifications_outlined,
                color: Colors.black,
              ),
              onPressed: () {},
            ),
          ],
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            const Icon(Icons.location_on_outlined),
            const SizedBox(width: 8),
            Text(
              location,
              style: const TextStyle(
                color: Colors.black87,
                fontSize: 14,
              ),
            ),
            const Spacer(),
            TextButton(
              onPressed: onLocationTap,
              child: const Text(
                'Change',
                style: TextStyle(
                  color: Colors.orange,
                  fontSize: 14,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Text(
          'Good Evening $name',
          style: const TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        const Text(
          'What would you like to have delivered at your doorstep today? Just let us know.',
          style: TextStyle(
            color: Colors.grey,
            fontSize: 14,
          ),
        ),
      ],
    );
  }
}

class ServiceCategory extends StatelessWidget {
  final String title;
  final String subtitle;
  final String imagePath;
  final Color backgroundColor;
  final VoidCallback onTap;

  const ServiceCategory({
    super.key,
    required this.title,
    required this.subtitle,
    required this.imagePath,
    required this.backgroundColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: backgroundColor,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              subtitle,
              style: const TextStyle(
                fontSize: 12,
                color: Colors.black87,
              ),
            ),
            const Spacer(),
            Align(
              alignment: Alignment.bottomRight,
              child: Image.asset(
                imagePath,
                width: 48,
                height: 48,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class SeeAllServicesCard extends StatelessWidget {
  final VoidCallback onTap;

  const SeeAllServicesCard({
    super.key,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.pink[50],
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Image.asset(
              'assets/images/girl_laptop.png',
              height: 120,
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Looking for\nmore to shop?',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'See All Services',
                    style: TextStyle(
                      color: Colors.purple[700],
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
