import 'package:flutter/material.dart';
import 'package:hudhud_delivery/core/theme/app_colors.dart';
import 'package:hudhud_delivery/features/restaurants/presentation/screens/restaurant_screen.dart';
import 'package:hudhud_delivery/core/widgets/custom_text_field.dart';

class SearchRestaurantBar extends StatelessWidget {
  const SearchRestaurantBar({super.key});

  @override
  Widget build(BuildContext context) {
    return CustomTextFieldStyles.searchField(
      hintText: 'Search restaurants by name',
    );
  }
}

class HotPicksSection extends StatelessWidget {
  const HotPicksSection({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Hot Picks in your area',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),
        SizedBox(
          height: 120,
          child: ListView(
            scrollDirection: Axis.horizontal,
            children: [
              RestaurantCircleCard(
                imageAsset: 'assets/images/cook_nature.jpg',
                name: 'Cook Nature',
                rating: 4.3,
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (context) => const RestaurantScreen()),
                  );
                },
              ),
              RestaurantCircleCard(
                imageAsset: 'assets/images/taco_bell.png',
                name: 'Taco Bell',
                rating: 4.3,
              ),
              RestaurantCircleCard(
                imageAsset: 'assets/images/food_point.jpg',
                name: 'Food Point',
                rating: 4.3,
              ),
              RestaurantCircleCard(
                imageAsset: 'assets/images/kalzbrgr.png',
                name: 'Kalzbrgr',
                rating: 4.3,
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class RestaurantCircleCard extends StatelessWidget {
  final String imageAsset;
  final String name;
  final double rating;
  final Function()? onTap;

  const RestaurantCircleCard({
    super.key,
    required this.imageAsset,
    required this.name,
    required this.rating,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 100,
        margin: const EdgeInsets.only(right: 16),
        padding: const EdgeInsets.symmetric(vertical: 8),
        decoration: BoxDecoration(
          color: colorScheme.surface,
          borderRadius: BorderRadius.circular(AppColors.radiusLG),
          border: Border.all(color: colorScheme.outline.withOpacity(0.2)),
        ),
        child: Column(
          children: [
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: colorScheme.outline.withOpacity(0.15)),
              ),
              child: ClipOval(
                child: Image.asset(imageAsset, fit: BoxFit.cover),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              name,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: colorScheme.onSurface,
              ),
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  rating.toString(),
                  style: TextStyle(
                    fontSize: 12,
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
                Icon(Icons.star_rounded, color: AppColors.ratingFilled, size: 14),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class RestaurantListItem extends StatelessWidget {
  final String imageAsset;
  final String name;
  final double rating;
  final double avgPrice;
  final int deliveryTime;

  const RestaurantListItem({
    super.key,
    required this.imageAsset,
    required this.name,
    required this.rating,
    required this.avgPrice,
    required this.deliveryTime,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(AppColors.radiusLG),
        border: Border.all(color: colorScheme.outline.withOpacity(0.2)),
      ),
      child: Row(
        children: [
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: colorScheme.outline.withOpacity(0.15)),
            ),
            child: ClipOval(
              child: Image.asset(
                imageAsset,
                fit: BoxFit.cover,
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: colorScheme.onSurface,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'ETB ${avgPrice.toStringAsFixed(0)} • Avg Price • $deliveryTime Mins Delivery',
                  style: TextStyle(
                    fontSize: 13,
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
          Row(
            children: [
              Text(
                rating.toString(),
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: colorScheme.onSurface,
                ),
              ),
              Icon(Icons.star_rounded, color: AppColors.ratingFilled, size: 16),
            ],
          ),
        ],
      ),
    );
  }
}
