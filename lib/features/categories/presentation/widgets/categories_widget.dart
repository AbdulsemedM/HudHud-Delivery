import 'dart:ui';

import 'package:flutter/material.dart';

import '../../../../core/l10n/context_l10n.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/money_format.dart';
import '../../../home/presentation/theme/home_colors.dart';
import '../../model/categories_products_model.dart';
import '../../../wishlist/presentation/widgets/wishlist_toggle_button.dart';

/// Beautiful category detail header: hero image, gradient overlay, frosted back,
/// category name, product count, and optional description.
class CategoryDetailHeader extends StatelessWidget {
  final String name;
  final String imageUrl;
  final int? productsCount;
  final String? description;
  final VoidCallback onBack;

  const CategoryDetailHeader({
    super.key,
    required this.name,
    required this.imageUrl,
    this.productsCount,
    this.description,
    required this.onBack,
  });

  @override
  Widget build(BuildContext context) {
    final hasImage = imageUrl.isNotEmpty;
    return SizedBox(
      height: 220,
      child: Stack(
        fit: StackFit.expand,
        children: [
          // Background: image or gradient
          if (hasImage && imageUrl.startsWith('http'))
            Image.network(
              imageUrl,
              fit: BoxFit.cover,
              width: double.infinity,
              height: double.infinity,
              errorBuilder: (_, __, ___) => _gradientFallback(),
            )
          else if (hasImage)
            Image.asset(
              imageUrl,
              fit: BoxFit.cover,
              width: double.infinity,
              height: double.infinity,
              errorBuilder: (_, __, ___) => _gradientFallback(),
            )
          else
            _gradientFallback(),
          // Gradient overlay for readability
          Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.black.withValues(alpha: 0.15),
                    Colors.black.withValues(alpha: 0.4),
                    Colors.black.withValues(alpha: 0.82),
                  ],
                ),
              ),
            ),
          ),
          // Frosted back button
          Positioned(
            top: MediaQuery.of(context).padding.top + 8,
            left: 8,
            child: ClipOval(
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
                child: Material(
                  color: Colors.black.withValues(alpha: 0.28),
                  child: InkWell(
                    onTap: onBack,
                    child: const SizedBox(
                      width: 48,
                      height: 48,
                      child: Icon(
                        Icons.arrow_back_rounded,
                        color: Colors.white,
                        size: 26,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
          // Bottom content: icon, name, meta
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  // Category icon/avatar
                  Container(
                    width: 64,
                    height: 64,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: Colors.white, width: 2.5),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.2),
                          blurRadius: 12,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(17),
                      child: hasImage && imageUrl.startsWith('http')
                          ? Image.network(
                              imageUrl,
                              fit: BoxFit.cover,
                              width: 64,
                              height: 64,
                              errorBuilder: (_, __, ___) => _iconPlaceholder(),
                            )
                          : hasImage
                              ? Image.asset(
                                  imageUrl,
                                  fit: BoxFit.cover,
                                  width: 64,
                                  height: 64,
                                  errorBuilder: (_, __, ___) =>
                                      _iconPlaceholder(),
                                )
                              : _iconPlaceholder(),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          name,
                          style: const TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.w800,
                            color: Colors.white,
                            letterSpacing: -0.5,
                            shadows: [
                              Shadow(
                                color: Colors.black26,
                                offset: Offset(0, 1),
                                blurRadius: 4,
                              ),
                            ],
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        if (productsCount != null && productsCount! > 0) ...[
                          const SizedBox(height: 6),
                          Row(
                            children: [
                              Icon(
                                Icons.inventory_2_outlined,
                                size: 16,
                                color: Colors.white.withValues(alpha: 0.95),
                              ),
                              const SizedBox(width: 6),
                              Text(
                                '$productsCount ${productsCount == 1 ? 'product' : 'products'}',
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w700,
                                  color: Colors.white.withValues(alpha: 0.95),
                                ),
                              ),
                            ],
                          ),
                        ],
                        if (description != null && description!.isNotEmpty) ...[
                          const SizedBox(height: 6),
                          Text(
                            description!,
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                              color: Colors.white.withValues(alpha: 0.9),
                              height: 1.35,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _gradientFallback() => Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: AppColors.brandHeroGradient,
          ),
        ),
      );

  Widget _iconPlaceholder() => Container(
        color: AppColors.orangeTint,
        alignment: Alignment.center,
        child: Text(
          name.trim().isEmpty
              ? '?'
              : name.trim().characters.first.toUpperCase(),
          style: const TextStyle(
            fontSize: 26,
            fontWeight: FontWeight.w800,
            color: AppColors.brandOrange,
          ),
        ),
      );
}

class CategoryHeader extends StatelessWidget {
  final String imageUrl;
  final VoidCallback onBackPressed;
  final String categoryLogo;

  const CategoryHeader({
    super.key,
    required this.imageUrl,
    required this.onBackPressed,
    required this.categoryLogo,
  });

  @override
  Widget build(BuildContext context) {
    final logoUrl = categoryLogo.isNotEmpty ? categoryLogo : imageUrl;
    return Stack(
      children: [
        Container(
          height: 200,
          width: double.infinity,
          decoration: BoxDecoration(
            image: DecorationImage(
              image: imageUrl.isNotEmpty && imageUrl.startsWith('http')
                  ? NetworkImage(imageUrl) as ImageProvider
                  : imageUrl.isNotEmpty
                      ? AssetImage(imageUrl) as ImageProvider
                      : const AssetImage('assets/images/categories.jpg')
                          as ImageProvider,
              fit: BoxFit.cover,
            ),
          ),
        ),
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
        Positioned(
          bottom: -20,
          left: 16,
          child: CircleAvatar(
            radius: 25,
            backgroundColor: Colors.white,
            backgroundImage: logoUrl.startsWith('http')
                ? NetworkImage(logoUrl) as ImageProvider
                : AssetImage(logoUrl) as ImageProvider,
          ),
        ),
      ],
    );
  }
}

class ProductDetailsModal extends StatelessWidget {
  final CategoriesProductsModel product;

  const ProductDetailsModal({super.key, required this.product});

  @override
  Widget build(BuildContext context) {
    final ink = HomeColors.textPrimaryOf(context);
    final muted = HomeColors.textMutedOf(context);
    final sectionStyle = TextStyle(
      fontSize: 18,
      fontWeight: FontWeight.w800,
      letterSpacing: -0.3,
      color: ink,
    );
    final dark = HomeColors.isDark(context);
    return Container(
      decoration: BoxDecoration(
        color: HomeColors.surfaceOf(context),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
      ),
      height: MediaQuery.of(context).size.height * 0.6,
      child: Column(
        children: [
          // Modal Header with handle and title
          Container(
            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 20),
            decoration: const BoxDecoration(
              borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
            ),
            child: Column(
              children: [
                // Handle bar
                Container(
                  width: 40,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 12),
                  decoration: BoxDecoration(
                    color: HomeColors.borderOf(context),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                // Modal Title
                Text(
                  'Product Details',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    color: muted,
                  ),
                ),
              ],
            ),
          ),
          // Modal Content
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Product Image
                  if (product.image_path != null &&
                      product.image_path!.isNotEmpty)
                    Container(
                      height: 200,
                      width: double.infinity,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(20),
                        image: DecorationImage(
                          image: product.image_path!.startsWith('http')
                              ? NetworkImage(product.image_path!)
                                  as ImageProvider
                              : AssetImage(product.image_path!),
                          fit: BoxFit.cover,
                        ),
                      ),
                    ),
                  const SizedBox(height: 16),

                  if (!product.canOrder) ...[
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 10),
                      decoration: BoxDecoration(
                        color: HomeColors.surfaceElevatedOf(context),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.block_rounded, size: 20, color: muted),
                          const SizedBox(width: 8),
                          Text(
                            'Currently unavailable',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                              color: ink,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),
                  ],

                  // Product Name
                  Text(
                    product.name ?? 'Unknown Product',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.w800,
                      letterSpacing: -0.5,
                      color: ink,
                    ),
                  ),
                  const SizedBox(height: 8),

                  // Price Section
                  Row(
                    children: [
                      if (product.discount_price != null &&
                          product.discount_price!.isNotEmpty) ...[
                        Text(
                          formatEtbPriceString(product.discount_price),
                          style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.w800,
                            color: ink,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          formatEtbPriceString(product.price),
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                            decoration: TextDecoration.lineThrough,
                            color: muted,
                          ),
                        ),
                      ] else ...[
                        Text(
                          formatEtbPriceString(product.price),
                          style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.w800,
                            color: ink,
                          ),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Description
                  if (product.description != null &&
                      product.description!.isNotEmpty) ...[
                    Text('Description', style: sectionStyle),
                    const SizedBox(height: 8),
                    Text(
                      product.description!,
                      style: TextStyle(
                        fontSize: 15,
                        height: 1.5,
                        fontWeight: FontWeight.w500,
                        color: HomeColors.textSecondaryOf(context),
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],

                  // Preparation Time
                  if (product.preparation_time != null) ...[
                    _buildInfoRow(
                        context,
                        'Preparation Time',
                        '${product.preparation_time} minutes',
                        Icons.timer_rounded),
                    const SizedBox(height: 12),
                  ],

                  // Nutrition Info
                  if (product.calories != null || product.protein != null) ...[
                    Text('Nutrition Information', style: sectionStyle),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: HomeColors.surfaceElevatedOf(context),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: [
                          if (product.calories != null)
                            Column(
                              children: [
                                const Icon(Icons.local_fire_department_rounded,
                                    color: AppColors.brandOrange),
                                const SizedBox(height: 4),
                                Text('${product.calories}',
                                    style: const TextStyle(
                                        fontWeight: FontWeight.bold)),
                                Text(context.l10n.calories,
                                    style: const TextStyle(fontSize: 12)),
                              ],
                            ),
                          if (product.protein != null)
                            Column(
                              children: [
                                Icon(Icons.fitness_center_rounded,
                                    color: HomeColors.violetOf(context)),
                                const SizedBox(height: 4),
                                Text('${product.protein}g',
                                    style: const TextStyle(
                                        fontWeight: FontWeight.bold)),
                                Text(context.l10n.protein,
                                    style: const TextStyle(fontSize: 12)),
                              ],
                            ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],

                  // Ingredients
                  if (product.ingredients != null &&
                      product.ingredients!.isNotEmpty) ...[
                    Text('Ingredients', style: sectionStyle),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: product.ingredients!
                          .map(
                            (ingredient) => Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 12, vertical: 6),
                              decoration: BoxDecoration(
                                color: AppColors.successColor
                                    .withValues(alpha: dark ? 0.2 : 0.1),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Text(
                                ingredient,
                                style: const TextStyle(
                                  color: AppColors.successColor,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                          )
                          .toList(),
                    ),
                    const SizedBox(height: 16),
                  ],

                  // Allergens
                  if (product.allergens != null &&
                      product.allergens!.isNotEmpty) ...[
                    Text('Allergens', style: sectionStyle),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: product.allergens!
                          .map(
                            (allergen) => Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 12, vertical: 6),
                              decoration: BoxDecoration(
                                color: AppColors.errorColor
                                    .withValues(alpha: dark ? 0.2 : 0.1),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(Icons.warning_rounded,
                                      size: 16, color: AppColors.errorColor),
                                  const SizedBox(width: 4),
                                  Text(
                                    allergen,
                                    style: const TextStyle(
                                      color: AppColors.errorColor,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          )
                          .toList(),
                    ),
                    const SizedBox(height: 16),
                  ],

                  // Addons
                  if (product.addons != null && product.addons!.isNotEmpty) ...[
                    Text('Available Add-ons', style: sectionStyle),
                    const SizedBox(height: 8),
                    Column(
                      children: product.addons!
                          .map(
                            (addon) => Container(
                              margin: const EdgeInsets.only(bottom: 8),
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                border: Border.all(
                                  color: HomeColors.borderOf(context),
                                ),
                                borderRadius: BorderRadius.circular(14),
                              ),
                              child: Row(
                                children: [
                                  Icon(Icons.add_circle_rounded,
                                      color: HomeColors.violetOf(context)),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Text(
                                      addon,
                                      style: TextStyle(
                                        fontSize: 15,
                                        fontWeight: FontWeight.w600,
                                        color: ink,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          )
                          .toList(),
                    ),
                    const SizedBox(height: 16),
                  ],

                  // Additional Info
                  if (product.sku != null || product.quantity != null) ...[
                    Text('Product Details', style: sectionStyle),
                    const SizedBox(height: 8),
                    if (product.sku != null)
                      _buildInfoRow(
                          context, 'SKU', product.sku!, Icons.qr_code_rounded),
                    if (product.quantity != null)
                      _buildInfoRow(context, 'Available Quantity',
                          '${product.quantity}', Icons.inventory_2_rounded),
                    const SizedBox(height: 20),
                  ],

                  // Close Button
                  SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(context),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: ink,
                        side: BorderSide(color: HomeColors.borderOf(context)),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(18),
                        ),
                      ),
                      child: const Text(
                        'Close',
                        style: TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          )
        ],
      ),
    );
  }

  Widget _buildInfoRow(
    BuildContext context,
    String label,
    String value,
    IconData icon,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Icon(icon, size: 22, color: HomeColors.violetOf(context)),
          const SizedBox(width: 10),
          Text(
            '$label: ',
            style: TextStyle(
              fontWeight: FontWeight.w600,
              fontSize: 15,
              color: HomeColors.textMutedOf(context),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w800,
                color: HomeColors.textPrimaryOf(context),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class CategoryInfo extends StatelessWidget {
  final String name;
  final int totalProducts;
  final VoidCallback onFavoritePressed;

  const CategoryInfo({
    super.key,
    required this.name,
    required this.totalProducts,
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
          Text(
            '$totalProducts Products Available',
            style: const TextStyle(
              fontSize: 14,
              color: Colors.grey,
            ),
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
        color: const Color(0xFFFFEEE5),
        borderRadius: BorderRadius.circular(8),
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
            activeThumbColor: Colors.orange,
          ),
        ],
      ),
    );
  }
}

class ProductFilters extends StatelessWidget {
  final List<String> filters;
  final List<String> selectedFilters;
  final ValueChanged<List<String>> onFiltersChanged;

  const ProductFilters({
    super.key,
    required this.filters,
    required this.selectedFilters,
    required this.onFiltersChanged,
  });

  @override
  Widget build(BuildContext context) {
    if (filters.isEmpty) return const SizedBox.shrink();
    final indigo = HomeColors.violetOf(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.tune_rounded, size: 22, color: indigo),
              const SizedBox(width: 8),
              Text(
                'Filter',
                style: TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.2,
                  color: HomeColors.textPrimaryOf(context),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: filters.map((filter) {
              final isSelected = selectedFilters.contains(filter);
              return Material(
                color: isSelected ? indigo : HomeColors.surfaceOf(context),
                shape: StadiumBorder(
                  side: BorderSide(
                    color: isSelected ? indigo : HomeColors.borderOf(context),
                    width: 1.4,
                  ),
                ),
                clipBehavior: Clip.antiAlias,
                child: InkWell(
                  onTap: () {
                    List<String> newSelectedFilters =
                        List.from(selectedFilters);
                    if (isSelected) {
                      newSelectedFilters.remove(filter);
                    } else {
                      newSelectedFilters.add(filter);
                    }
                    onFiltersChanged(newSelectedFilters);
                  },
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(minHeight: 44),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (isSelected) ...[
                            const Icon(
                              Icons.check_circle_rounded,
                              color: Colors.white,
                              size: 18,
                            ),
                            const SizedBox(width: 6),
                          ],
                          Text(
                            filter,
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                              color: isSelected
                                  ? Colors.white
                                  : HomeColors.textPrimaryOf(context),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
          if (selectedFilters.isNotEmpty) ...[
            const SizedBox(height: 8),
            TextButton.icon(
              onPressed: () => onFiltersChanged([]),
              style: TextButton.styleFrom(
                foregroundColor: HomeColors.textMutedOf(context),
                minimumSize: const Size(48, 44),
                padding: const EdgeInsets.symmetric(horizontal: 8),
              ),
              icon: const Icon(Icons.clear_all_rounded, size: 20),
              label: const Text(
                'Clear All Filters',
                style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class ProductCard extends StatelessWidget {
  final CategoriesProductsModel product;
  final VoidCallback? onTap;

  const ProductCard({super.key, required this.product, this.onTap});

  @override
  Widget build(BuildContext context) {
    final canOrder = product.canOrder;
    return GestureDetector(
      onTap: onTap,
      child: Opacity(
        opacity: canOrder ? 1 : 0.65,
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.grey.withValues(alpha: 0.1),
                spreadRadius: 1,
                blurRadius: 4,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Product Image
              Stack(
                children: [
                  Container(
                    height: 120,
                    width: double.infinity,
                    decoration: BoxDecoration(
                      borderRadius:
                          const BorderRadius.vertical(top: Radius.circular(12)),
                      color: Colors.grey[200],
                      image: product.image_path != null &&
                              product.image_path!.isNotEmpty
                          ? DecorationImage(
                              image: product.image_path!.startsWith('http')
                                  ? NetworkImage(product.image_path!)
                                      as ImageProvider
                                  : AssetImage(product.image_path!),
                              fit: BoxFit.cover,
                            )
                          : null,
                    ),
                    child: product.image_path == null ||
                            product.image_path!.isEmpty
                        ? const Center(
                            child: Icon(
                              Icons.shopping_bag_outlined,
                              size: 40,
                              color: Colors.grey,
                            ),
                          )
                        : null,
                  ),
                  if (!canOrder)
                    Positioned(
                      top: 8,
                      left: 8,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.black.withValues(alpha: 0.65),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: const Text(
                          'Unavailable',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                ],
              ),

              // Product Info
              Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      product.name ?? 'Unknown Product',
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    if (product.description != null &&
                        product.description!.isNotEmpty)
                      Text(
                        product.description!,
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[600],
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              if (product.discount_price != null &&
                                  product.discount_price!.isNotEmpty) ...[
                                Text(
                                  formatEtbPriceString(product.discount_price),
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.green,
                                  ),
                                ),
                                Text(
                                  formatEtbPriceString(product.price),
                                  style: const TextStyle(
                                    fontSize: 12,
                                    decoration: TextDecoration.lineThrough,
                                    color: Colors.grey,
                                  ),
                                ),
                              ] else ...[
                                Text(
                                  formatEtbPriceString(product.price),
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: canOrder
                                ? const Color(0xFF4A148C)
                                : Colors.grey.shade400,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Icon(
                            canOrder ? Icons.add : Icons.block,
                            color: Colors.white,
                            size: 20,
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
      ),
    );
  }
}

class ProductItem extends StatelessWidget {
  final CategoriesProductsModel? product;
  final String name;
  final String description;
  final String imageUrl;
  final String price;
  final String? discountPrice;
  final bool isAdded;
  final VoidCallback onAddPressed;
  final VoidCallback? onRemovePressed;
  final VoidCallback onDecrementPressed;
  final VoidCallback onIncrementPressed;
  final int quantity;
  final VoidCallback? onTap;

  /// Outer spacing around the card (16px gutters by default).
  final EdgeInsetsGeometry margin;

  const ProductItem({
    super.key,
    this.product,
    required this.name,
    required this.description,
    required this.imageUrl,
    required this.price,
    this.discountPrice,
    required this.isAdded,
    required this.onAddPressed,
    this.onRemovePressed,
    required this.onDecrementPressed,
    required this.onIncrementPressed,
    required this.quantity,
    this.onTap,
    this.margin = const EdgeInsets.fromLTRB(16, 0, 16, 12),
  });

  @override
  Widget build(BuildContext context) {
    final canOrder = product?.canOrder ?? true;
    final dark = HomeColors.isDark(context);
    final ink = HomeColors.textPrimaryOf(context);
    final muted = HomeColors.textMutedOf(context);
    final radius = BorderRadius.circular(20);

    Widget imageFallback() => Container(
          width: 92,
          height: 92,
          color: dark ? AppColors.orangeTintDark : AppColors.orangeTint,
          child: const Icon(
            Icons.fastfood_rounded,
            color: AppColors.brandOrange,
            size: 34,
          ),
        );

    return Padding(
      padding: margin,
      child: DecoratedBox(
        decoration: BoxDecoration(
          borderRadius: radius,
          boxShadow: AppColors.softShadow(context),
        ),
        child: Material(
          color: HomeColors.surfaceOf(context),
          shape: RoundedRectangleBorder(
            borderRadius: radius,
            side: dark
                ? BorderSide(color: HomeColors.borderOf(context))
                : BorderSide.none,
          ),
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            onTap: onTap,
            child: Opacity(
              opacity: canOrder ? 1 : 0.6,
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(16),
                      child: imageUrl.isEmpty
                          ? imageFallback()
                          : Image.network(
                              imageUrl,
                              width: 92,
                              height: 92,
                              fit: BoxFit.cover,
                              color: canOrder ? null : Colors.grey,
                              colorBlendMode:
                                  canOrder ? null : BlendMode.saturation,
                              errorBuilder: (context, error, stackTrace) =>
                                  imageFallback(),
                            ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(
                                child: Text(
                                  name,
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    fontSize: 16,
                                    height: 1.25,
                                    fontWeight: FontWeight.w800,
                                    letterSpacing: -0.2,
                                    color: ink,
                                  ),
                                ),
                              ),
                              if (product != null && product!.id != null)
                                WishlistToggleButton(
                                  product: product!,
                                  size: 22,
                                ),
                            ],
                          ),
                          if (description.isNotEmpty) ...[
                            const SizedBox(height: 2),
                            Text(
                              description,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontSize: 13.5,
                                height: 1.3,
                                fontWeight: FontWeight.w500,
                                color: muted,
                              ),
                            ),
                          ],
                          if (!canOrder) ...[
                            const SizedBox(height: 6),
                            Text(
                              'Unavailable',
                              style: TextStyle(
                                fontSize: 12.5,
                                fontWeight: FontWeight.w800,
                                color: muted,
                              ),
                            ),
                          ],
                          const SizedBox(height: 10),
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              Expanded(
                                child: Wrap(
                                  crossAxisAlignment: WrapCrossAlignment.center,
                                  spacing: 6,
                                  children: [
                                    Text(
                                      formatEtbPriceString(
                                        discountPrice ?? price,
                                      ),
                                      style: TextStyle(
                                        fontSize: 17,
                                        fontWeight: FontWeight.w800,
                                        letterSpacing: -0.3,
                                        color: ink,
                                      ),
                                    ),
                                    if (discountPrice != null)
                                      Text(
                                        formatEtbPriceString(price),
                                        style: TextStyle(
                                          fontSize: 13,
                                          fontWeight: FontWeight.w600,
                                          decoration:
                                              TextDecoration.lineThrough,
                                          color: muted,
                                        ),
                                      ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 8),
                              if (!isAdded)
                                _AddPill(
                                  canOrder: canOrder,
                                  onPressed: canOrder ? onAddPressed : null,
                                )
                              else
                                _QuantityStepper(
                                  quantity: quantity,
                                  onDecrement: onDecrementPressed,
                                  onIncrement:
                                      canOrder ? onIncrementPressed : null,
                                ),
                            ],
                          ),
                          if (isAdded)
                            Align(
                              alignment: Alignment.centerRight,
                              child: TextButton.icon(
                                onPressed: onRemovePressed,
                                style: TextButton.styleFrom(
                                  foregroundColor: muted,
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 6,
                                  ),
                                  minimumSize: const Size(48, 40),
                                ),
                                icon: const Icon(
                                  Icons.delete_outline_rounded,
                                  size: 18,
                                ),
                                label: const Text(
                                  'REMOVE',
                                  style: TextStyle(
                                    fontSize: 12.5,
                                    fontWeight: FontWeight.w800,
                                    letterSpacing: 0.3,
                                  ),
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// White-on-orange "ADD" pill (grey when the product can't be ordered).
class _AddPill extends StatelessWidget {
  const _AddPill({required this.canOrder, required this.onPressed});

  final bool canOrder;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 44,
      child: FilledButton.icon(
        onPressed: onPressed,
        style: FilledButton.styleFrom(
          backgroundColor: AppColors.brandOrange,
          foregroundColor: Colors.white,
          disabledBackgroundColor: HomeColors.surfaceElevatedOf(context),
          disabledForegroundColor: HomeColors.textMutedOf(context),
          padding: const EdgeInsets.fromLTRB(12, 0, 16, 0),
          shape: const StadiumBorder(),
        ),
        icon: Icon(
          canOrder ? Icons.add_rounded : Icons.block_rounded,
          size: 20,
        ),
        label: Text(
          canOrder ? 'ADD' : 'UNAVAILABLE',
          style: TextStyle(
            fontWeight: FontWeight.w800,
            fontSize: canOrder ? 14 : 12,
            letterSpacing: 0.3,
          ),
        ),
      ),
    );
  }
}

/// Compact − qty + stepper with orange round buttons.
class _QuantityStepper extends StatelessWidget {
  const _QuantityStepper({
    required this.quantity,
    required this.onDecrement,
    required this.onIncrement,
  });

  final int quantity;
  final VoidCallback onDecrement;
  final VoidCallback? onIncrement;

  @override
  Widget build(BuildContext context) {
    final dark = HomeColors.isDark(context);
    Widget round(IconData icon, VoidCallback? onTap) => Material(
          color: onTap == null
              ? AppColors.brandOrange.withValues(alpha: 0.4)
              : AppColors.brandOrange,
          shape: const CircleBorder(),
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            onTap: onTap,
            child: SizedBox(
              width: 36,
              height: 36,
              child: Icon(icon, size: 20, color: Colors.white),
            ),
          ),
        );
    return Container(
      height: 44,
      padding: const EdgeInsets.symmetric(horizontal: 4),
      decoration: BoxDecoration(
        color: dark ? AppColors.orangeTintDark : AppColors.orangeTint,
        borderRadius: BorderRadius.circular(AppColors.radiusFull),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          round(Icons.remove_rounded, onDecrement),
          SizedBox(
            width: 32,
            child: Text(
              quantity.toString(),
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w800,
                color: HomeColors.textPrimaryOf(context),
              ),
            ),
          ),
          round(Icons.add_rounded, onIncrement),
        ],
      ),
    );
  }
}
