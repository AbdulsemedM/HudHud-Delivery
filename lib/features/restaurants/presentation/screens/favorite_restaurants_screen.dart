import 'package:flutter/material.dart';
import 'package:hudhud_delivery/core/l10n/context_l10n.dart';
import 'package:hudhud_delivery/core/theme/app_colors.dart';
import 'package:hudhud_delivery/core/widgets/custom_text_field.dart';

class FavoriteRestaurantsScreen extends StatelessWidget {
  const FavoriteRestaurantsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final l10n = context.l10n;

    final List<Map<String, dynamic>> favoriteRestaurants = [
      {
        'name': 'Cook Nature',
        'imageUrl': 'assets/images/cook_nature.jpg',
        'rating': 4.3,
      },
      {
        'name': 'Taco Bell',
        'imageUrl': 'assets/images/taco_bell.png',
        'rating': 4.3,
      },
      {
        'name': 'Food Point',
        'imageUrl': 'assets/images/food_point.jpg',
        'rating': 4.3,
      },
      {
        'name': 'Kalzbrgr',
        'imageUrl': 'assets/images/kalzbrgr.png',
        'rating': 4.3,
      },
    ];

    return Scaffold(
      backgroundColor: colorScheme.surface,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.all(AppColors.spaceMD),
              child: GestureDetector(
                onTap: () => Navigator.pop(context),
                child: Row(
                  children: [
                    Icon(Icons.arrow_back_ios_new_rounded,
                        size: 20, color: colorScheme.onSurface),
                    const SizedBox(width: 8),
                    Text(
                      'GO BACK',
                      style: textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w500,
                        color: colorScheme.onSurface,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppColors.spaceMD),
              child: CustomTextFieldStyles.searchField(
                hintText: l10n.searchRestaurantsHint,
              ),
            ),
            const SizedBox(height: AppColors.spaceLG),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppColors.spaceMD),
              child: Text(
                'Your Favorite Restaurants',
                style: textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: colorScheme.onSurface,
                ),
              ),
            ),
            const SizedBox(height: AppColors.spaceMD),
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: AppColors.spaceMD),
                itemCount: favoriteRestaurants.length,
                itemBuilder: (context, index) {
                  final restaurant = favoriteRestaurants[index];
                  return Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: colorScheme.surface,
                      borderRadius: BorderRadius.circular(AppColors.radiusLG),
                      border: Border.all(
                        color: colorScheme.outline.withOpacity(0.2),
                      ),
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 50,
                          height: 50,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: colorScheme.outline.withOpacity(0.15),
                            ),
                            image: DecorationImage(
                              image: AssetImage(restaurant['imageUrl']),
                              fit: BoxFit.cover,
                            ),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Text(
                            restaurant['name'],
                            style: textTheme.titleSmall?.copyWith(
                              fontWeight: FontWeight.w600,
                              color: colorScheme.onSurface,
                            ),
                          ),
                        ),
                        Row(
                          children: [
                            Text(
                              restaurant['rating'].toString(),
                              style: textTheme.bodySmall?.copyWith(
                                color: colorScheme.onSurfaceVariant,
                              ),
                            ),
                            const SizedBox(width: 4),
                            Icon(Icons.star_rounded,
                                color: AppColors.ratingFilled, size: 16),
                          ],
                        ),
                        const SizedBox(width: 12),
                        Icon(Icons.favorite_rounded,
                            color: AppColors.errorColor, size: 22),
                      ],
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
