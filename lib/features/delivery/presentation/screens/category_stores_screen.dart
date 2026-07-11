import 'package:flutter/material.dart';
import 'package:hudhud_delivery/core/theme/app_colors.dart';
import 'store_detail_screen.dart';

class CategoryStoresScreen extends StatelessWidget {
  final String categoryName;
  final IconData categoryIcon;

  const CategoryStoresScreen({
    super.key,
    required this.categoryName,
    required this.categoryIcon,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Scaffold(
      backgroundColor: colorScheme.surface,
      body: SafeArea(
        child: Column(
          children: [
            _CategoryHeader(
              categoryName: categoryName,
              location: 'London Hall',
              time: 'Now',
              onLocationTap: () {},
              onTimeTap: () {},
              onFilterTap: () {},
            ),
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(AppColors.spaceMD),
                      child: Row(
                        children: [
                          Expanded(
                            child: _FeaturedStoreCard(
                              name: 'Gopuff',
                              logoText: 'gopuff',
                              logoColor: AppColors.infoColor,
                              openingTime: 'Opens at 10:00 AM',
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => const StoreDetailScreen(
                                      storeName: 'Gopuff',
                                    ),
                                  ),
                                );
                              },
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _FeaturedStoreCard(
                              name: '7Eleven',
                              logoText: '7ELEVEN',
                              logoColor: AppColors.errorColor,
                              openingTime: 'Opens at 10:00 AM',
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => const StoreDetailScreen(
                                      storeName: '7 Eleven Store',
                                    ),
                                  ),
                                );
                              },
                            ),
                          ),
                        ],
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppColors.spaceMD,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Popular Stores',
                            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                  fontWeight: FontWeight.bold,
                                  color: colorScheme.onSurface,
                                ),
                          ),
                          const SizedBox(height: AppColors.spaceMD),
                          _StoreListItem(
                            name: 'Begs & Megs',
                            openingTime: 'Opens at 08:00',
                            promoText: 'Spend US\$20, save US\$5',
                            imageUrl: 'assets/images/categories.jpg',
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => const StoreDetailScreen(
                                    storeName: 'Begs & Megs',
                                  ),
                                ),
                              );
                            },
                          ),
                          const SizedBox(height: 16),
                          _StoreListItem(
                            name: 'Pick \'n\' Save',
                            openingTime: 'Opens at 08:00',
                            imageUrl: 'assets/images/categories.jpg',
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => const StoreDetailScreen(
                                    storeName: 'Pick \'n\' Save',
                                  ),
                                ),
                              );
                            },
                          ),
                          const SizedBox(height: 16),
                          _StoreListItem(
                            name: 'Orange Inn',
                            openingTime: 'Opens at 08:00',
                            imageUrl: 'assets/images/categories.jpg',
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => const StoreDetailScreen(
                                    storeName: 'Orange Inn',
                                  ),
                                ),
                              );
                            },
                          ),
                          const SizedBox(height: 16),
                          _StoreListItem(
                            name: 'Vintage Berkeley',
                            openingTime: 'Opens at 08:00',
                            promoText: 'Spend US\$20, save US\$5',
                            imageUrl: 'assets/images/categories.jpg',
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => const StoreDetailScreen(
                                    storeName: 'Vintage Berkeley',
                                  ),
                                ),
                              );
                            },
                          ),
                          const SizedBox(height: 16),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CategoryHeader extends StatelessWidget {
  final String categoryName;
  final String location;
  final String time;
  final VoidCallback onLocationTap;
  final VoidCallback onTimeTap;
  final VoidCallback onFilterTap;

  const _CategoryHeader({
    required this.categoryName,
    required this.location,
    required this.time,
    required this.onLocationTap,
    required this.onTimeTap,
    required this.onFilterTap,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppColors.spaceMD,
        vertical: 12,
      ),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        border: Border(
          bottom: BorderSide(color: colorScheme.outline.withValues(alpha: 0.2)),
        ),
      ),
      child: Column(
        children: [
          Row(
            children: [
              IconButton(
                icon: Icon(Icons.arrow_back_ios_new_rounded,
                    color: colorScheme.onSurface, size: 20),
                onPressed: () => Navigator.pop(context),
              ),
              Expanded(
                child: Text(
                  categoryName,
                  style: textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: colorScheme.onSurface,
                  ),
                ),
              ),
              IconButton(
                icon: Icon(Icons.tune_rounded, color: colorScheme.onSurface),
                onPressed: onFilterTap,
              ),
            ],
          ),
          Material(
            color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
            borderRadius: BorderRadius.circular(AppColors.radiusFull),
            child: InkWell(
              onTap: onTimeTap,
              borderRadius: BorderRadius.circular(AppColors.radiusFull),
              child: Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.schedule_rounded,
                        size: 16, color: AppColors.primaryColor),
                    const SizedBox(width: 6),
                    Text(
                      '$time • $location',
                      style: textTheme.bodySmall?.copyWith(
                        color: colorScheme.onSurface,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    Icon(Icons.keyboard_arrow_down_rounded,
                        size: 18, color: colorScheme.onSurface),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _FeaturedStoreCard extends StatelessWidget {
  final String name;
  final String logoText;
  final Color logoColor;
  final String openingTime;
  final VoidCallback onTap;

  const _FeaturedStoreCard({
    required this.name,
    required this.logoText,
    required this.logoColor,
    required this.openingTime,
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
        borderRadius: BorderRadius.circular(AppColors.radiusLG),
        child: Ink(
          height: 140,
          padding: const EdgeInsets.all(AppColors.spaceMD),
          decoration: BoxDecoration(
            color: colorScheme.surface,
            borderRadius: BorderRadius.circular(AppColors.radiusLG),
            border: Border.all(color: colorScheme.outline.withValues(alpha: 0.2)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                logoText,
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: logoColor,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                name,
                style: textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: colorScheme.onSurface,
                ),
              ),
              const SizedBox(height: 4),
              Row(
                children: [
                  Icon(Icons.schedule_rounded,
                      size: 14, color: colorScheme.onSurfaceVariant),
                  const SizedBox(width: 4),
                  Text(
                    openingTime,
                    style: textTheme.bodySmall?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _StoreListItem extends StatelessWidget {
  final String name;
  final String openingTime;
  final String? promoText;
  final String imageUrl;
  final VoidCallback onTap;

  const _StoreListItem({
    required this.name,
    required this.openingTime,
    this.promoText,
    required this.imageUrl,
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
        borderRadius: BorderRadius.circular(AppColors.radiusLG),
        child: Ink(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: colorScheme.surface,
            borderRadius: BorderRadius.circular(AppColors.radiusLG),
            border: Border.all(color: colorScheme.outline.withValues(alpha: 0.2)),
          ),
          child: Row(
            children: [
              Container(
                width: 70,
                height: 70,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: colorScheme.outline.withValues(alpha: 0.15),
                  ),
                ),
                child: ClipOval(
                  child: Image.asset(
                    imageUrl,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => Container(
                      color: colorScheme.surfaceContainerHighest,
                      child: Icon(Icons.store_rounded,
                          size: 35, color: colorScheme.onSurfaceVariant),
                    ),
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
                      style: textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: colorScheme.onSurface,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      openingTime,
                      style: textTheme.bodySmall?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                    if (promoText != null) ...[
                      const SizedBox(height: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 3,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.successColor.withValues(alpha: 0.12),
                          borderRadius:
                              BorderRadius.circular(AppColors.radiusFull),
                          border: Border.all(
                            color: AppColors.successColor.withValues(alpha: 0.35),
                          ),
                        ),
                        child: Text(
                          promoText!,
                          style: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: AppColors.successColor,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              Icon(Icons.chevron_right_rounded,
                  color: colorScheme.onSurfaceVariant),
            ],
          ),
        ),
      ),
    );
  }
}
