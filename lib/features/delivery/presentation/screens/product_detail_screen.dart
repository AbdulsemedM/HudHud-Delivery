import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';
import 'package:shimmer/shimmer.dart';
import 'package:hudhud_delivery/core/api/api_service.dart';
import 'package:hudhud_delivery/core/l10n/context_l10n.dart';
import 'package:hudhud_delivery/core/theme/app_colors.dart';
import 'package:hudhud_delivery/features/categories/data/data_provider/categories_data_provider.dart';
import 'package:hudhud_delivery/features/categories/data/repository/categories_repository.dart';
import 'package:hudhud_delivery/features/categories/model/categories_products_model.dart';
import 'package:hudhud_delivery/features/wishlist/presentation/widgets/wishlist_toggle_button.dart';

class ProductDetailScreen extends StatefulWidget {
  final int productId;

  const ProductDetailScreen({
    super.key,
    required this.productId,
  });

  @override
  State<ProductDetailScreen> createState() => _ProductDetailScreenState();
}

class _ProductDetailScreenState extends State<ProductDetailScreen> {
  final CategoriesRepository _repository = CategoriesRepository(
    categoriesDataProvider:
        CategoriesDataProvider(apiService: ApiService.instance),
  );

  CategoriesProductsModel? _product;
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadProduct();
  }

  Future<void> _loadProduct() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final product = await _repository.getProductById(widget.productId);
      if (!mounted) return;
      setState(() {
        _product = product;
        _loading = false;
        if (product == null) _error = context.l10n.productNotFound;
      });
    } catch (e) {
      setState(() {
        _loading = false;
        _error = e.toString();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final l10n = context.l10n;

    return Scaffold(
      backgroundColor: colorScheme.surface,
      appBar: AppBar(
        backgroundColor: colorScheme.surface,
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new_rounded,
              color: colorScheme.onSurface, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          if (_product != null && _product!.id != null)
            WishlistToggleButton(product: _product!, size: 22),
        ],
        title: Text(
          _product?.name ?? 'Product',
          style: textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w600,
            color: colorScheme.onSurface,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(
            color: colorScheme.outline.withValues(alpha: 0.2),
            height: 1,
          ),
        ),
      ),
      body: _loading
          ? const _ProductDetailShimmer()
          : _error != null
              ? _ProductErrorState(
                  message: _error!,
                  onRetry: _loadProduct,
                )
              : _product == null
                  ? _ProductErrorState(
                      message: l10n.productNotFound,
                      onRetry: _loadProduct,
                    )
                  : SingleChildScrollView(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          if (_product!.image_path != null &&
                              _product!.image_path!.isNotEmpty)
                            ClipRRect(
                              child: Image.network(
                                _product!.image_path!,
                                height: 280,
                                width: double.infinity,
                                fit: BoxFit.cover,
                                errorBuilder: (_, __, ___) =>
                                    _imagePlaceholder(colorScheme),
                              ),
                            )
                          else
                            _imagePlaceholder(colorScheme),
                          Padding(
                            padding: const EdgeInsets.all(AppColors.spaceMD),
                            child: Container(
                              padding: const EdgeInsets.all(AppColors.spaceMD),
                              decoration: BoxDecoration(
                                color: colorScheme.surface,
                                borderRadius:
                                    BorderRadius.circular(AppColors.radiusLG),
                                border: Border.all(
                                  color: colorScheme.outline.withValues(alpha: 0.2),
                                ),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    _product!.name ?? 'Product',
                                    style: textTheme.headlineSmall?.copyWith(
                                      fontWeight: FontWeight.bold,
                                      color: colorScheme.onSurface,
                                    ),
                                  ),
                                  const SizedBox(height: 12),
                                  Row(
                                    children: [
                                      Text(
                                        '${l10n.currencyEtb} ${_product!.formatted_price ?? _product!.price ?? '0'}',
                                        style: const TextStyle(
                                          fontSize: 22,
                                          fontWeight: FontWeight.bold,
                                          color: AppColors.primaryColor,
                                        ),
                                      ),
                                      if (_product!.is_on_discount == true &&
                                          _product!.formatted_original_price !=
                                              null) ...[
                                        const SizedBox(width: 12),
                                        Text(
                                          _product!.formatted_original_price!,
                                          style: textTheme.bodyMedium?.copyWith(
                                            color: colorScheme.onSurfaceVariant,
                                            decoration:
                                                TextDecoration.lineThrough,
                                          ),
                                        ),
                                      ],
                                    ],
                                  ),
                                  if (_product!.description != null &&
                                      _product!.description!.isNotEmpty) ...[
                                    const SizedBox(height: 16),
                                    Text(
                                      _product!.description!,
                                      style: textTheme.bodyMedium?.copyWith(
                                        color: colorScheme.onSurfaceVariant,
                                        height: 1.5,
                                      ),
                                    ),
                                  ],
                                  const SizedBox(height: 24),
                                  SizedBox(
                                    width: double.infinity,
                                    height: AppColors.buttonHeightMD,
                                    child: FilledButton.icon(
                                      onPressed: () {},
                                      icon: const Icon(Icons.add_shopping_cart),
                                      label: const Text('Add to cart'),
                                      style: FilledButton.styleFrom(
                                        backgroundColor: AppColors.primaryColor,
                                        foregroundColor: Colors.white,
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(
                                            AppColors.radiusLG,
                                          ),
                                        ),
                                      ),
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

  Widget _imagePlaceholder(ColorScheme colorScheme) {
    return Container(
      height: 280,
      color: colorScheme.surfaceContainerHighest,
      child: Icon(Icons.shopping_bag_outlined,
          size: 80, color: colorScheme.onSurfaceVariant),
    );
  }
}

class _ProductDetailShimmer extends StatelessWidget {
  const _ProductDetailShimmer();

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final base = isDark ? AppColors.darkSurfaceVariant : AppColors.lightBorder;
    final highlight =
        isDark ? AppColors.darkBorder : AppColors.lightInputFill;
    final block = Theme.of(context).colorScheme.surface;

    return Shimmer.fromColors(
      baseColor: base,
      highlightColor: highlight,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(height: 280, color: block),
          Padding(
            padding: const EdgeInsets.all(AppColors.spaceMD),
            child: Container(
              padding: const EdgeInsets.all(AppColors.spaceMD),
              decoration: BoxDecoration(
                color: block,
                borderRadius: BorderRadius.circular(AppColors.radiusLG),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    height: 24,
                    width: 200,
                    decoration: BoxDecoration(
                      color: block,
                      borderRadius: BorderRadius.circular(6),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Container(
                    height: 20,
                    width: 120,
                    decoration: BoxDecoration(
                      color: block,
                      borderRadius: BorderRadius.circular(6),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Container(
                    height: 60,
                    decoration: BoxDecoration(
                      color: block,
                      borderRadius: BorderRadius.circular(6),
                    ),
                  ),
                  const SizedBox(height: 24),
                  Container(
                    height: AppColors.buttonHeightMD,
                    decoration: BoxDecoration(
                      color: block,
                      borderRadius: BorderRadius.circular(AppColors.radiusLG),
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
}

class _ProductErrorState extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;

  const _ProductErrorState({
    required this.message,
    required this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final colorScheme = Theme.of(context).colorScheme;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Lottie.asset('assets/animations/browse.json', width: 180),
            const SizedBox(height: 16),
            Text(
              message,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                color: colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 24),
            FilledButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh_rounded, size: 18),
              label: Text(l10n.actionTryAgain),
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.primaryColor,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppColors.radiusLG),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
