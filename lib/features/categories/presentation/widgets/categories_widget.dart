import 'dart:ui';

import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
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
            child: ClipRRect(
              borderRadius: BorderRadius.circular(24),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
                child: Material(
                  color: Colors.white.withValues(alpha: 0.25),
                  borderRadius: BorderRadius.circular(24),
                  child: InkWell(
                    onTap: onBack,
                    borderRadius: BorderRadius.circular(24),
                    child: const Padding(
                      padding: EdgeInsets.all(10),
                      child: Icon(
                        Icons.arrow_back_ios_new_rounded,
                        color: Colors.white,
                        size: 20,
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
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 2.5),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.2),
                          blurRadius: 12,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: ClipOval(
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
                                  errorBuilder: (_, __, ___) => _iconPlaceholder(),
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
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                            letterSpacing: -0.3,
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
                                  fontSize: 13,
                                  fontWeight: FontWeight.w500,
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
                              fontSize: 12,
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
            colors: [
              AppColors.primaryColor.withValues(alpha: 0.92),
              AppColors.primaryColor,
              AppColors.primaryDarkColor,
            ],
          ),
        ),
      );

  Widget _iconPlaceholder() => Container(
        color: Colors.white.withValues(alpha: 0.3),
        child: const Icon(
          Icons.category_rounded,
          size: 32,
          color: Colors.white70,
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
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 10,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      height: MediaQuery.of(context).size.height * 0.6,
      child: Column(
        children: [
          // Modal Header with handle and title
          Container(
            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 20),
            decoration: BoxDecoration(
              color: Colors.grey[50],
              borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
            ),
            child: Column(
              children: [
                // Handle bar
                Container(
                  width: 40,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 12),
                  decoration: BoxDecoration(
                    color: Colors.grey[400],
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                // Modal Title
                Text(
                  'Product Details',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                        color: Colors.grey[700],
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
                      borderRadius: BorderRadius.circular(12),
                      image: DecorationImage(
                        image: product.image_path!.startsWith('http')
                            ? NetworkImage(product.image_path!) as ImageProvider
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
                      color: Colors.grey.shade200,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.block, size: 18, color: Colors.grey[700]),
                        const SizedBox(width: 8),
                        Text(
                          'Currently unavailable',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: Colors.grey[800],
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
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),

                // Price Section
                Row(
                  children: [
                    if (product.discount_price != null &&
                        product.discount_price!.isNotEmpty) ...[
                      Text(
                        '\$${product.discount_price}',
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Colors.green,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        '\$${product.price ?? '0'}',
                        style: const TextStyle(
                          fontSize: 16,
                          decoration: TextDecoration.lineThrough,
                          color: Colors.grey,
                        ),
                      ),
                    ] else ...[
                      Text(
                        '\$${product.price ?? '0'}',
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 16),

                // Description
                if (product.description != null &&
                    product.description!.isNotEmpty) ...[
                  const Text(
                    'Description',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    product.description!,
                    style: const TextStyle(fontSize: 16),
                  ),
                  const SizedBox(height: 16),
                ],

                // Preparation Time
                if (product.preparation_time != null) ...[
                  _buildInfoRow('Preparation Time',
                      '${product.preparation_time} minutes', Icons.timer),
                  const SizedBox(height: 12),
                ],

                // Nutrition Info
                if (product.calories != null || product.protein != null) ...[
                  const Text(
                    'Nutrition Information',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.grey[100],
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        if (product.calories != null)
                          Column(
                            children: [
                              const Icon(Icons.local_fire_department,
                                  color: Colors.orange),
                              const SizedBox(height: 4),
                              Text('${product.calories}',
                                  style: const TextStyle(
                                      fontWeight: FontWeight.bold)),
                              const Text('Calories',
                                  style: TextStyle(fontSize: 12)),
                            ],
                          ),
                        if (product.protein != null)
                          Column(
                            children: [
                              const Icon(Icons.fitness_center,
                                  color: Colors.blue),
                              const SizedBox(height: 4),
                              Text('${product.protein}g',
                                  style: const TextStyle(
                                      fontWeight: FontWeight.bold)),
                              const Text('Protein',
                                  style: TextStyle(fontSize: 12)),
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
                  const Text(
                    'Ingredients',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
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
                              color: Colors.green[100],
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              ingredient,
                              style: TextStyle(color: Colors.green[800]),
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
                  const Text(
                    'Allergens',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
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
                              color: Colors.red[100],
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.warning,
                                    size: 16, color: Colors.red[800]),
                                const SizedBox(width: 4),
                                Text(
                                  allergen,
                                  style: TextStyle(color: Colors.red[800]),
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
                  const Text(
                    'Available Add-ons',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Column(
                    children: product.addons!
                        .map(
                          (addon) => Container(
                            margin: const EdgeInsets.only(bottom: 8),
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              border: Border.all(color: Colors.grey[300]!),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Row(
                              children: [
                                Icon(Icons.add_circle_outline,
                                    color: Colors.blue[600]),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Text(
                                    addon,
                                    style: const TextStyle(fontSize: 16),
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
                  const Text(
                    'Product Details',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  if (product.sku != null)
                    _buildInfoRow('SKU', product.sku!, Icons.qr_code),
                  if (product.quantity != null)
                    _buildInfoRow('Available Quantity', '${product.quantity}',
                        Icons.inventory),
                  const SizedBox(height: 20),
                ],

                // Close Button
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () => Navigator.pop(context),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF4A148C),
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: const Text(
                      'Close',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
      )],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value, IconData icon) {
    return Row(
      children: [
        Icon(icon, size: 20, color: Colors.grey[600]),
        const SizedBox(width: 8),
        Text(
          '$label: ',
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(fontSize: 16),
          ),
        ),
      ],
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
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.tune_rounded, size: 20, color: AppColors.primaryColor),
              SizedBox(width: 8),
              Text(
                'Filter',
                style: TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w600,
                  color: AppColors.lightTextPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: filters.map((filter) {
              final isSelected = selectedFilters.contains(filter);
              return GestureDetector(
                onTap: () {
                  List<String> newSelectedFilters = List.from(selectedFilters);
                  if (isSelected) {
                    newSelectedFilters.remove(filter);
                  } else {
                    newSelectedFilters.add(filter);
                  }
                  onFiltersChanged(newSelectedFilters);
                },
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  decoration: BoxDecoration(
                    color: isSelected ? AppColors.primaryColor : Colors.grey[50],
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(
                      color: isSelected ? AppColors.primaryColor : Colors.grey[300]!,
                      width: 1.5,
                    ),
                    boxShadow: isSelected
                        ? [
                            BoxShadow(
                              color: AppColors.primaryColor.withValues(alpha: 0.3),
                              spreadRadius: 1,
                              blurRadius: 4,
                              offset: const Offset(0, 2),
                            ),
                          ]
                        : null,
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (isSelected) ...[
                        const Icon(
                          Icons.check_circle,
                          color: Colors.white,
                          size: 16,
                        ),
                        const SizedBox(width: 6),
                      ],
                      Text(
                        filter,
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight:
                              isSelected ? FontWeight.w600 : FontWeight.w500,
                          color: isSelected ? Colors.white : Colors.black87,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }).toList(),
          ),
          if (selectedFilters.isNotEmpty) ...[
            const SizedBox(height: 12),
            GestureDetector(
              onTap: () => onFiltersChanged([]),
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.red[50],
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: Colors.red[200]!),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.clear_all,
                      color: Colors.red[600],
                      size: 16,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      'Clear All Filters',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.red[600],
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
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
                image: DecorationImage(
                  image: product.image_path != null &&
                          product.image_path!.isNotEmpty
                      ? (product.image_path!.startsWith('http')
                          ? NetworkImage(product.image_path!) as ImageProvider
                          : AssetImage(product.image_path!))
                      : const AssetImage('assets/images/cook_nature.jpg'),
                  fit: BoxFit.cover,
                ),
              ),
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
                                '\$${product.discount_price}',
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.green,
                                ),
                              ),
                              Text(
                                '\$${product.price ?? '0'}',
                                style: const TextStyle(
                                  fontSize: 12,
                                  decoration: TextDecoration.lineThrough,
                                  color: Colors.grey,
                                ),
                              ),
                            ] else ...[
                              Text(
                                '\$${product.price ?? '0'}',
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
  });

  @override
  Widget build(BuildContext context) {
    final canOrder = product?.canOrder ?? true;
    return GestureDetector(
        onTap: onTap,
        child: Opacity(
          opacity: canOrder ? 1 : 0.6,
          child: Container(
          padding: const EdgeInsets.all(16),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Image.network(
                  imageUrl,
                  width: 80,
                  height: 80,
                  fit: BoxFit.cover,
                  color: canOrder ? null : Colors.grey,
                  colorBlendMode: canOrder ? null : BlendMode.saturation,
                  errorBuilder: (context, error, stackTrace) {
                    return Container(
                      width: 80,
                      height: 80,
                      color: Colors.grey[300],
                      child: const Icon(Icons.image_not_supported),
                    );
                  },
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      description,
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[600],
                      ),
                    ),
                    if (!canOrder) ...[
                      const SizedBox(height: 6),
                      Text(
                        'Unavailable',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: Colors.grey[700],
                        ),
                      ),
                    ],
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              if (discountPrice != null) ...[
                                Flexible(
                                  child: Text(
                                    'ETB$discountPrice',
                                    style: const TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.orange,
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Flexible(
                                  child: Text(
                                    'ETB$price',
                                    style: const TextStyle(
                                      fontSize: 14,
                                      decoration: TextDecoration.lineThrough,
                                      color: Colors.grey,
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ] else
                                Flexible(
                                  child: Text(
                                    'ETB$price',
                                    style: const TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 8),
                        if (product != null && product!.id != null)
                          WishlistToggleButton(
                            product: product!,
                            size: 20,
                          ),
                        const SizedBox(width: 4),
                        if (!isAdded)
                          TextButton(
                            onPressed: canOrder ? onAddPressed : null,
                            style: TextButton.styleFrom(
                              backgroundColor: canOrder
                                  ? const Color(0xFFFFEEE5)
                                  : Colors.grey.shade200,
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 16, vertical: 8),
                              disabledForegroundColor: Colors.grey,
                            ),
                            child: Text(
                              canOrder ? 'ADD' : 'UNAVAILABLE',
                              style: TextStyle(
                                color: canOrder ? Colors.orange : Colors.grey,
                                fontWeight: FontWeight.bold,
                                fontSize: canOrder ? null : 11,
                              ),
                            ),
                          )
                        else
                          Container(
                            decoration: BoxDecoration(
                              border: Border.all(color: Colors.grey[300]!),
                              borderRadius: BorderRadius.circular(4),
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
                                  onPressed:
                                      canOrder ? onIncrementPressed : null,
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
                              color: Colors.orange,
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
        ),
        ));
  }
}
