import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';
import 'package:lottie/lottie.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../models/user_model.dart';

/// Card showing email and phone verification status with optional Verify buttons.
class VerificationStatusCard extends StatelessWidget {
  final UserModel user;
  final VoidCallback onVerifyEmail;
  final VoidCallback onVerifyPhone;

  const VerificationStatusCard({
    super.key,
    required this.user,
    required this.onVerifyEmail,
    required this.onVerifyPhone,
  });

  @override
  Widget build(BuildContext context) {
    final emailVerified = user.isEmailVerified;
    final phoneVerified = user.isPhoneVerified;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Verification status',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: Colors.grey[700],
            ),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Icon(
                emailVerified ? Icons.check_circle : Icons.cancel,
                size: 18,
                color: emailVerified ? Colors.green : Colors.orange,
              ),
              const SizedBox(width: 6),
              Text(
                'Email: ${emailVerified ? 'Verified' : 'Not verified'}',
                style: TextStyle(
                  fontSize: 13,
                  color: Colors.grey[800],
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Row(
            children: [
              Icon(
                phoneVerified ? Icons.check_circle : Icons.cancel,
                size: 18,
                color: phoneVerified ? Colors.green : Colors.orange,
              ),
              const SizedBox(width: 6),
              Text(
                'Phone: ${phoneVerified ? 'Verified' : 'Not verified'}',
                style: TextStyle(
                  fontSize: 13,
                  color: Colors.grey[800],
                ),
              ),
            ],
          ),
          if (!emailVerified || !phoneVerified) ...[
            const SizedBox(height: 12),
            if (!emailVerified)
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: onVerifyEmail,
                  icon: const Icon(Icons.mark_email_read_outlined, size: 18),
                  label: const Text('Verify Email'),
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.primaryColor,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 10),
                  ),
                ),
              ),
            if (!emailVerified && !phoneVerified) const SizedBox(height: 8),
            if (!phoneVerified)
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: onVerifyPhone,
                  icon: const Icon(Icons.phone_android_outlined, size: 18),
                  label: const Text('Verify Phone'),
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.primaryColor,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 10),
                  ),
                ),
              ),
          ],
        ],
      ),
    );
  }
}

class UserProfileHeader extends StatelessWidget {
  final String name;
  final String location;
  final bool isLoadingLocation;
  final VoidCallback onLocationTap;

  const UserProfileHeader({
    super.key,
    required this.name,
    required this.location,
    this.isLoadingLocation = false,
    required this.onLocationTap,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        // Location section
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    Icons.location_on,
                    color: AppColors.primaryColor,
                    size: 18,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    'Your Location',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              GestureDetector(
                onTap: onLocationTap,
                child: Row(
                  children: [
                    Flexible(
                      child: isLoadingLocation
                          ? SizedBox(
                              width: 12,
                              height: 12,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(
                                AppColors.primaryColor,
                              ),
                              ),
                            )
                          : Text(
                              location,
                            style: TextStyle(
                              color: AppColors.primaryColor,
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                            ),
                              overflow: TextOverflow.ellipsis,
                              maxLines: 1,
                            ),
                    ),
                    const SizedBox(width: 4),
                    Icon(
                      Icons.arrow_drop_down,
                      color: AppColors.primaryColor,
                      size: 18,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        // Profile picture and notification
        Row(
          children: [
            const CircleAvatar(
              radius: 20,
              backgroundImage: AssetImage('assets/images/profile.png'),
            ),
            const SizedBox(width: 12),
            IconButton(
              icon: const Icon(
                Icons.notifications_outlined,
                color: Colors.black,
              ),
              onPressed: () {},
            ),
          ],
        ),
      ],
    );
  }
}

// Order Tracking Card with gradient
class OrderTrackingCard extends StatelessWidget {
  final String riderName;
  final String message;
  final VoidCallback onViewMap;

  const OrderTrackingCard({
    super.key,
    required this.riderName,
    required this.message,
    required this.onViewMap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFF6F81BF), // Blue
            Color(0xFFFF5A00), // Orange
          ],
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Hello ${riderName}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Track your Order Now!',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              const Text(
                'HUDHUD\ndelivery',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
                textAlign: TextAlign.right,
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            message,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 12,
            ),
          ),
          const SizedBox(height: 16),
          Align(
            alignment: Alignment.bottomRight,
            child: ElevatedButton(
              onPressed: onViewMap,
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.white,
              foregroundColor: AppColors.primaryColor,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
              child: const Text('View Map'),
            ),
          ),
        ],
      ),
    );
  }
}

// Service Card for the 2x2 grid
class ServiceCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  const ServiceCard({
    super.key,
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.1),
              spreadRadius: 1,
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            // Title and Icon in a row
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Title in orange, bold
                Expanded(
                  child: Text(
                    title,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.orange,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                // Icon on the right
                Icon(
                  icon,
                  color: color,
                  size: 32,
                ),
              ],
            ),
            const SizedBox(height: 6),
            // Description in dark grey - full text
            Text(
              subtitle,
              style: TextStyle(
                fontSize: 13,
                color: Colors.grey[700],
                height: 1.4,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// Deals Section
class DealsSection extends StatelessWidget {
  final VoidCallback onClaim;

  const DealsSection({
    super.key,
    required this.onClaim,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFFF5A00), // #FF5A00
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Left section - Visual (woman on bicycle with delivery bag)
          SizedBox(
            width: 100,
            height: 100,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Image.asset(
                'assets/images/ChatGPT Image Jun 6, 2025, 09_19_43 PM 1.png',
                fit: BoxFit.cover,
              ),
            ),
          ),
          const SizedBox(width: 16),
          // Right section - Text and button
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  'Deals on deals',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 4),
                const Text(
                  'Get upto 50% off on your first Courier delivery fee!',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          // Claim button
          ElevatedButton(
            onPressed: onClaim,
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.white,
              foregroundColor: AppColors.primaryColor,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: const Text(
              'Claim',
              style: TextStyle(
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// History Item
class HistoryItem extends StatelessWidget {
  final String orderId;
  final String recipient;
  final String location;
  final String dateTime;
  final String status;

  const HistoryItem({
    super.key,
    required this.orderId,
    required this.recipient,
    required this.location,
    required this.dateTime,
    required this.status,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Order ID in dark green
              Text(
                orderId,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF2E7D32), // Dark green
                ),
              ),
              // Status badge in dark green
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: const Color(0xFF2E7D32), // Dark green
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  status,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          // Recipient text in grey
          Text(
            'Receipient: $recipient',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[700],
            ),
          ),
          const SizedBox(height: 12),
          // Motorcycle icon and location with "Drop off"
          Row(
            children: [
              // Motorcycle icon (light blue outline)
              Container(
                width: 20,
                height: 20,
                decoration: BoxDecoration(
                  color: Colors.white,
                  border: Border.all(
                    color: const Color(0xFF64B5F6), // Light blue
                    width: 1.5,
                  ),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Icon(
                  Icons.two_wheeler,
                  size: 12,
                  color: const Color(0xFF64B5F6), // Light blue
                ),
              ),
              const SizedBox(width: 8),
              // Location pin icon in green
              Icon(
                Icons.location_on,
                size: 16,
                color: const Color(0xFF4CAF50), // Green
              ),
              const SizedBox(width: 4),
              Text(
                'Drop off',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[600],
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          // Location in dark green
          Text(
            location,
            style: const TextStyle(
              fontSize: 12,
              color: Color(0xFF2E7D32), // Dark green
            ),
          ),
          const SizedBox(height: 6),
          // Date and time in grey
          Text(
            dateTime,
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey[600],
            ),
          ),
        ],
      ),
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
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: isDarkMode ? Theme.of(context).cardColor : backgroundColor,
          borderRadius: BorderRadius.circular(12),
        ),
        child:
            Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          Expanded(
            flex: 2,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: Theme.of(context).textTheme.titleLarge?.color,
                  ),
                  overflow: TextOverflow.ellipsis,
                  maxLines: 1,
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: TextStyle(
                    fontSize: 12,
                    color: Theme.of(context).textTheme.bodySmall?.color,
                  ),
                  overflow: TextOverflow.ellipsis,
                  maxLines: 2,
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Container(
            decoration: BoxDecoration(
              color: isDarkMode ? Colors.grey[800] : Colors.grey[300],
              borderRadius: BorderRadius.circular(30),
            ),
            child: Image.asset(
              imagePath,
              width: 48,
              height: 48,
              fit: BoxFit.cover,
            ),
          ),
        ]),
      ),
    );
  }
}

// Shimmer loading widget for service categories
class ServiceCategoryShimmer extends StatelessWidget {
  const ServiceCategoryShimmer({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(12),
      ),
      child: Shimmer.fromColors(
        baseColor: Colors.grey[300]!,
        highlightColor: Colors.grey[100]!,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              flex: 2,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: double.infinity,
                    height: 18,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    width: 120,
                    height: 12,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(30),
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
            Lottie.asset('assets/animations/browse.json', width: 200),
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
