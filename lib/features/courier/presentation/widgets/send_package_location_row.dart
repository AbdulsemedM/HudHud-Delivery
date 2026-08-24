import 'package:flutter/material.dart';
import 'package:hudhud_delivery/features/home/presentation/theme/home_colors.dart';

/// Compact pickup/dropoff row for the Instant Delivery booking sheet.
class SendPackageLocationRow extends StatelessWidget {
  const SendPackageLocationRow({
    super.key,
    required this.icon,
    required this.text,
    required this.onTap,
    this.isPlaceholder = false,
  });

  final IconData icon;
  final String text;
  final VoidCallback onTap;
  final bool isPlaceholder;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 10),
        child: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: HomeColors.surfaceElevated,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, size: 20, color: HomeColors.textPrimary),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                text,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  color: isPlaceholder
                      ? HomeColors.textMuted
                      : HomeColors.textPrimary,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
