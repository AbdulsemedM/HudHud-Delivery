import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';
import 'package:lottie/lottie.dart';
import 'package:hudhud_delivery/core/l10n/context_l10n.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/avatar_util.dart';
import '../../../../models/user_model.dart';

/// Shown when the user lands on the Home tab and email or phone is not verified.
class AccountVerificationPromptDialog extends StatelessWidget {
  final UserModel user;
  final VoidCallback onDismiss;
  final VoidCallback onVerifyEmail;
  final VoidCallback onVerifyPhone;

  const AccountVerificationPromptDialog({
    super.key,
    required this.user,
    required this.onDismiss,
    required this.onVerifyEmail,
    required this.onVerifyPhone,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final needEmail = !user.isEmailVerified;
    final needPhone = !user.isPhoneVerified;
    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: Text(l10n.accountVerificationBannerTitle),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (needEmail) ...[
              Text(
                l10n.accountVerificationEmailSubtitle,
                style: theme.textTheme.bodyMedium,
              ),
              const SizedBox(height: 12),
              FilledButton.icon(
                onPressed: onVerifyEmail,
                icon: const Icon(Icons.mark_email_read_outlined, size: 20),
                label: Text(l10n.verifyEmail),
              ),
              if (needPhone) const SizedBox(height: 16),
            ],
            if (needPhone) ...[
              Text(
                l10n.accountVerificationPhoneSubtitle,
                style: theme.textTheme.bodyMedium,
              ),
              const SizedBox(height: 12),
              FilledButton.icon(
                onPressed: onVerifyPhone,
                icon: const Icon(Icons.phone_android_outlined, size: 20),
                label: Text(l10n.verifyPhone),
              ),
            ],
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: onDismiss,
          child: Text(l10n.dealsModalClose),
        ),
      ],
    );
  }
}

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
    final l10n = context.l10n;
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final emailVerified = user.isEmailVerified;
    final phoneVerified = user.isPhoneVerified;

    if (emailVerified && phoneVerified) {
      return const SizedBox.shrink();
    }

    return Container(
      padding: const EdgeInsets.all(AppColors.spaceMD),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(AppColors.radiusLG),
        border: Border.all(
          color: colorScheme.outline.withValues(alpha: 0.2),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            l10n.verificationStatus,
            style: textTheme.labelLarge?.copyWith(fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: AppColors.spaceMD),
          Row(
            children: [
              if (!emailVerified)
                Expanded(
                  child: FilledButton.icon(
                    onPressed: onVerifyEmail,
                    icon: const Icon(Icons.mark_email_read_outlined, size: 18),
                    label: Text(l10n.verifyEmail),
                    style: FilledButton.styleFrom(
                      backgroundColor: AppColors.primaryColor,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 10),
                    ),
                  ),
                ),
              if (!emailVerified && !phoneVerified)
                const SizedBox(width: AppColors.spaceMD),
              if (!phoneVerified)
                Expanded(
                  child: FilledButton.icon(
                    onPressed: onVerifyPhone,
                    icon: const Icon(Icons.phone_android_outlined, size: 18),
                    label: Text(l10n.verifyPhone),
                    style: FilledButton.styleFrom(
                      backgroundColor: AppColors.primaryColor,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 10),
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class UserProfileHeader extends StatefulWidget {
  final String name;
  final String location;
  final bool isLoadingLocation;
  final VoidCallback onLocationTap;
  final VoidCallback onNotificationsTap;
  final UserModel? user;

  const UserProfileHeader({
    super.key,
    required this.name,
    required this.location,
    this.isLoadingLocation = false,
    required this.onLocationTap,
    required this.onNotificationsTap,
    this.user,
  });

  @override
  State<UserProfileHeader> createState() => _UserProfileHeaderState();
}

class _UserProfileHeaderState extends State<UserProfileHeader>
    with SingleTickerProviderStateMixin {
  late AnimationController _chevronController;

  @override
  void initState() {
    super.initState();
    _chevronController = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );
  }

  @override
  void dispose() {
    _chevronController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Row(
      children: [
        Container(
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(color: Colors.white, width: 2.5),
            boxShadow: [
              BoxShadow(
                color: colorScheme.shadow.withValues(alpha: 0.12),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: CircleAvatar(
            radius: 22,
            backgroundColor: AppColors.primaryColor,
            backgroundImage: getDisplayAvatarUrl(widget.user) != null
                ? NetworkImage(getDisplayAvatarUrl(widget.user)!)
                : const AssetImage('assets/images/profile.png')
                    as ImageProvider,
          ),
        ),
        const SizedBox(width: AppColors.spaceMD),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                widget.name,
                style: textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 2),
              GestureDetector(
                onTap: () {
                  _chevronController.forward(from: 0).then((_) {
                    _chevronController.reverse();
                  });
                  widget.onLocationTap();
                },
                child: Row(
                  children: [
                    const Icon(
                      Icons.location_on_rounded,
                      color: AppColors.primaryColor,
                      size: 16,
                    ),
                    const SizedBox(width: 4),
                    Flexible(
                      child: widget.isLoadingLocation
                          ? const SizedBox(
                              width: 12,
                              height: 12,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: AppColors.primaryColor,
                              ),
                            )
                          : Text(
                              widget.location.isEmpty
                                  ? l10n.yourLocation
                                  : widget.location,
                              style: textTheme.bodySmall?.copyWith(
                                color: AppColors.primaryColor,
                                fontWeight: FontWeight.w600,
                              ),
                              overflow: TextOverflow.ellipsis,
                              maxLines: 1,
                            ),
                    ),
                    RotationTransition(
                      turns: Tween<double>(begin: 0, end: 0.5)
                          .animate(_chevronController),
                      child: const Icon(
                        Icons.chevron_right_rounded,
                        color: AppColors.primaryColor,
                        size: 18,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF1E1E1E) : const Color(0xFFF4F4F4),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Stack(
            alignment: Alignment.center,
            children: [
              IconButton(
                icon: Icon(
                  Icons.notifications_outlined,
                  color: colorScheme.onSurface,
                  size: 22,
                ),
                onPressed: widget.onNotificationsTap,
              ),
              Positioned(
                top: 10,
                right: 10,
                child: Container(
                  width: 8,
                  height: 8,
                  decoration: const BoxDecoration(
                    color: AppColors.primaryColor,
                    shape: BoxShape.circle,
                  ),
                ),
              ),
            ],
          ),
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
                    'Hello $riderName',
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
                padding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
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

// Service Card for the 2x2 grid - single accent color, clean and professional
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
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: colorScheme.surface,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: colorScheme.outline.withValues(alpha: 0.28), width: 1),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.08),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.max,
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.primaryColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: AppColors.primaryColor, size: 22),
              ),
              const SizedBox(height: 10),
              Text(
                title,
                style: textTheme.titleSmall?.copyWith(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  letterSpacing: -0.2,
                ),
              ),
              const SizedBox(height: 2),
              Flexible(
                child: Text(
                  subtitle,
                  style: textTheme.bodySmall?.copyWith(
                    fontSize: 11,
                    color: colorScheme.onSurface.withValues(alpha: 0.7),
                    height: 1.3,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// Order History Empty State - professional empty state when no orders
class OrderHistoryEmptyState extends StatelessWidget {
  final VoidCallback? onBrowseTap;

  const OrderHistoryEmptyState({super.key, this.onBrowseTap});

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            spreadRadius: 1,
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: colorScheme.onSurface.withValues(alpha: 0.12),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.receipt_long_outlined,
              size: 48,
              color: colorScheme.onSurface.withValues(alpha: 0.55),
            ),
          ),
          const SizedBox(height: 20),
          Text(
            l10n.orderHistoryEmptyTitle,
            style: textTheme.titleMedium?.copyWith(
              fontSize: 18,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            l10n.orderHistoryEmptyHint,
            textAlign: TextAlign.center,
            style: textTheme.bodyMedium?.copyWith(
              fontSize: 14,
            ),
          ),
          if (onBrowseTap != null) ...[
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: onBrowseTap,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primaryColor,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: Text(l10n.browseDelivery),
              ),
            ),
          ],
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
  final VoidCallback? onTap;

  const HistoryItem({
    super.key,
    required this.orderId,
    required this.recipient,
    required this.location,
    required this.dateTime,
    required this.status,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final child = Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colorScheme.surface,
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
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
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
            style: textTheme.bodyMedium?.copyWith(
              fontSize: 14,
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
                child: const Icon(
                  Icons.two_wheeler,
                  size: 12,
                  color: Color(0xFF64B5F6), // Light blue
                ),
              ),
              const SizedBox(width: 8),
              // Location pin icon in green
              const Icon(
                Icons.location_on,
                size: 16,
                color: Color(0xFF4CAF50), // Green
              ),
              const SizedBox(width: 4),
              Text(
                'Drop off',
                style: textTheme.bodySmall?.copyWith(
                  fontSize: 12,
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
            style: textTheme.bodySmall?.copyWith(
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
    if (onTap != null) {
      return GestureDetector(onTap: onTap, child: child);
    }
    return child;
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

class ShimmerListView extends StatelessWidget {
  final int itemCount;

  const ShimmerListView({super.key, this.itemCount = 3});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final baseColor = isDark ? const Color(0xFF2A2A2A) : const Color(0xFFE0E0E0);
    final highlightColor =
        isDark ? const Color(0xFF3A3A3A) : const Color(0xFFF5F5F5);

    return Column(
      children: List.generate(itemCount, (index) {
        return Padding(
          padding: const EdgeInsets.only(bottom: AppColors.spaceMD),
          child: Shimmer.fromColors(
            baseColor: baseColor,
            highlightColor: highlightColor,
            child: Container(
              height: 88,
              decoration: BoxDecoration(
                color: baseColor,
                borderRadius: BorderRadius.circular(AppColors.radiusLG),
              ),
            ),
          ),
        );
      }),
    );
  }
}

class SectionHeader extends StatelessWidget {
  final String title;
  final String actionLabel;
  final VoidCallback? onAction;

  const SectionHeader({
    super.key,
    required this.title,
    required this.actionLabel,
    this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text(
          title,
          style: Theme.of(context).textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w600,
              ),
        ),
        const Spacer(),
        if (onAction != null)
          TextButton(
            onPressed: onAction,
            style: TextButton.styleFrom(
              foregroundColor: AppColors.primaryColor,
              textStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
            ),
            child: Text(actionLabel),
          ),
      ],
    );
  }
}
