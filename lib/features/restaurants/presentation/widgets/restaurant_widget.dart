import 'package:flutter/material.dart';
import 'package:hudhud_delivery/core/theme/app_colors.dart';

class RestaurantHeader extends StatelessWidget {
  final String imageUrl;
  final VoidCallback onBackPressed;
  final String restaurantLogo;

  const RestaurantHeader({
    super.key,
    required this.imageUrl,
    required this.onBackPressed,
    required this.restaurantLogo,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // Header Image
        Container(
          height: 200,
          width: double.infinity,
          decoration: BoxDecoration(
            image: DecorationImage(
              image: AssetImage(imageUrl),
              fit: BoxFit.cover,
            ),
          ),
        ),
        // Back Button
        Positioned(
          top: 16,
          left: 16,
          child: GestureDetector(
            onTap: onBackPressed,
            child: const Row(
              children: [
                Icon(Icons.arrow_back, color: Colors.black),
                SizedBox(width: 8),
                Text(
                  'GO BACK',
                  style: TextStyle(
                    color: Colors.black,
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ),
        // Restaurant Logo
        Positioned(
          bottom: -20,
          left: 16,
          child: CircleAvatar(
            radius: 25,
            backgroundColor: Colors.white,
            backgroundImage: AssetImage(restaurantLogo),
          ),
        ),
      ],
    );
  }
}

class RestaurantInfo extends StatelessWidget {
  final String name;
  final double rating;
  final int reviews;
  final double avgPrice;
  final int deliveryTime;
  final VoidCallback onFavoritePressed;

  const RestaurantInfo({
    super.key,
    required this.name,
    required this.rating,
    required this.reviews,
    required this.avgPrice,
    required this.deliveryTime,
    required this.onFavoritePressed,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 32, 16, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                name,
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              IconButton(
                icon: const Icon(Icons.favorite_border),
                onPressed: onFavoritePressed,
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Row(
                children: [
                  Text(
                    rating.toString(),
                    style: const TextStyle(
                      fontSize: 14,
                      color: Colors.grey,
                    ),
                  ),
                  const Icon(
                    Icons.star,
                    color: Colors.orange,
                    size: 16,
                  ),
                ],
              ),
              Text(
                ' $reviews+ Ratings',
                style: const TextStyle(
                  fontSize: 14,
                  color: Colors.grey,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: Colors.orange.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.monetization_on_outlined,
                      color: Colors.orange,
                      size: 16,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      'ETB ${avgPrice.toStringAsFixed(0)}',
                      style: const TextStyle(
                        fontSize: 14,
                        color: Colors.orange,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Text(
                'Avg Price',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[600],
                ),
              ),
              const SizedBox(width: 8),
              Text(
                '•',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[600],
                ),
              ),
              const SizedBox(width: 8),
              Text(
                '$deliveryTime Minutes Delivery Time',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[600],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class VegFoodToggle extends StatelessWidget {
  final bool value;
  final ValueChanged<bool> onChanged;

  const VegFoodToggle({
    super.key,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: AppColors.primaryColor.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(AppColors.radiusLG),
          border: Border.all(color: AppColors.primaryColor.withValues(alpha: 0.2)),
        ),
      child: Row(
        children: [
          const Icon(
            Icons.eco_outlined,
            color: Colors.green,
            size: 20,
          ),
          const SizedBox(width: 8),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Showing Veg food only',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                Text(
                  'You can turn this off.',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey,
                  ),
                ),
              ],
            ),
          ),
          Switch(
            value: value,
            onChanged: onChanged,
            activeThumbColor: AppColors.primaryColor,
          ),
        ],
      ),
    );
  }
}

class MenuCategories extends StatelessWidget {
  final List<String> categories;
  final int selectedIndex;
  final ValueChanged<int> onCategorySelected;

  const MenuCategories({
    super.key,
    required this.categories,
    required this.selectedIndex,
    required this.onCategorySelected,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return SizedBox(
      height: 40,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: categories.length,
        padding: const EdgeInsets.symmetric(horizontal: AppColors.spaceMD),
        itemBuilder: (context, index) {
          final isSelected = index == selectedIndex;
          return GestureDetector(
            onTap: () => onCategorySelected(index),
            child: Container(
              margin: const EdgeInsets.only(right: 12),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: isSelected
                    ? AppColors.primaryColor
                    : colorScheme.surface,
                borderRadius: BorderRadius.circular(AppColors.radiusFull),
                border: Border.all(
                  color: AppColors.primaryColor.withValues(alpha: isSelected ? 1 : 0.35),
                ),
              ),
              child: Text(
                categories[index],
                style: TextStyle(
                  fontSize: 14,
                  color: isSelected ? Colors.white : colorScheme.onSurface,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

class MenuItem extends StatelessWidget {
  final String name;
  final String description;
  final String imageUrl;
  final double price;
  final bool isAdded;
  final VoidCallback onAddPressed;
  final VoidCallback? onRemovePressed;
  final VoidCallback onDecrementPressed;
  final VoidCallback onIncrementPressed;
  final int quantity;

  const MenuItem({
    super.key,
    required this.name,
    required this.description,
    required this.imageUrl,
    required this.price,
    required this.isAdded,
    required this.onAddPressed,
    this.onRemovePressed,
    required this.onDecrementPressed,
    required this.onIncrementPressed,
    required this.quantity,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: AppColors.spaceMD, vertical: 6),
      padding: const EdgeInsets.all(AppColors.spaceMD),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(AppColors.radiusLG),
        border: Border.all(color: colorScheme.outline.withValues(alpha: 0.2)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: Image.asset(
              imageUrl,
              width: 80,
              height: 80,
              fit: BoxFit.cover,
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
                  description,
                  style: TextStyle(
                    fontSize: 14,
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'ETB${price.toStringAsFixed(1)}',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: AppColors.primaryColor,
                      ),
                    ),
                    if (!isAdded)
                      TextButton(
                        onPressed: onAddPressed,
                        style: TextButton.styleFrom(
                          backgroundColor: AppColors.primaryColor.withValues(alpha: 0.1),
                          padding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 8),
                          shape: RoundedRectangleBorder(
                            borderRadius:
                                BorderRadius.circular(AppColors.radiusFull),
                          ),
                        ),
                        child: const Text(
                          'ADD',
                          style: TextStyle(
                            color: AppColors.primaryColor,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      )
                    else
                      Container(
                        decoration: BoxDecoration(
                          border: Border.all(
                              color: colorScheme.outline.withValues(alpha: 0.3)),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          children: [
                            IconButton(
                              icon: const Icon(Icons.remove, size: 16),
                              onPressed: onDecrementPressed,
                              padding: EdgeInsets.zero,
                              constraints: const BoxConstraints(
                                minWidth: 32,
                                minHeight: 32,
                              ),
                            ),
                            Text(
                              quantity.toString(),
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            IconButton(
                              icon: const Icon(Icons.add, size: 16),
                              onPressed: onIncrementPressed,
                              padding: EdgeInsets.zero,
                              constraints: const BoxConstraints(
                                minWidth: 32,
                                minHeight: 32,
                              ),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
                if (isAdded)
                  Align(
                    alignment: Alignment.centerRight,
                    child: TextButton(
                      onPressed: onRemovePressed,
                      style: TextButton.styleFrom(
                        padding: EdgeInsets.zero,
                        minimumSize: Size.zero,
                      ),
                      child: const Text(
                        'REMOVE',
                        style: TextStyle(
                          color: AppColors.primaryColor,
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
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
