import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';
import 'package:shimmer/shimmer.dart';
import 'package:hudhud_delivery/app/navigation/cart_navigation.dart';
import 'package:hudhud_delivery/app/services/cart_service.dart';
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
  final CartService _cart = CartService();

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

  void _addToCart() {
    final product = _product;
    if (product == null) return;
    if (!product.canOrder) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('This product is currently unavailable'),
          backgroundColor: Theme.of(context).colorScheme.error,
        ),
      );
      return;
    }
    final added = _cart.addProduct(product);
    if (!added || !mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('${product.name ?? 'Product'} added to cart'),
        action: SnackBarAction(
          label: 'Checkout',
          onPressed: () => openCheckoutFromCart(
            context,
            fallbackVendorId: product.vendor_id,
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final l10n = context.l10n;

    return ListenableBuilder(
      listenable: _cart,
      builder: (context, _) {
        final product = _product;
        final cartQuantity = _cart.quantityFor(product?.id);
        final canOrder = product?.canOrder ?? false;

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
              if (product != null && product.id != null)
                WishlistToggleButton(product: product, size: 22),
            ],
            title: Text(
              product?.name ?? 'Product',
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
          bottomNavigationBar: _cart.isEmpty
              ? null
              : _CartCheckoutBar(
                  totalItems: _cart.totalItems,
                  subtotal: _cart.subtotal,
                  onCheckout: () => openCheckoutFromCart(
                    context,
                    fallbackVendorId: product?.vendor_id,
                  ),
                ),
          body: _loading
              ? const _ProductDetailShimmer()
              : _error != null
                  ? _ProductErrorState(
                      message: _error!,
                      onRetry: _loadProduct,
                    )
                  : product == null
                      ? _ProductErrorState(
                          message: l10n.productNotFound,
                          onRetry: _loadProduct,
                        )
                      : SingleChildScrollView(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              if (product.image_path != null &&
                                  product.image_path!.isNotEmpty)
                                ClipRRect(
                                  child: Image.network(
                                    product.image_path!,
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
                                padding:
                                    const EdgeInsets.all(AppColors.spaceMD),
                                child: Container(
                                  padding:
                                      const EdgeInsets.all(AppColors.spaceMD),
                                  decoration: BoxDecoration(
                                    color: colorScheme.surface,
                                    borderRadius: BorderRadius.circular(
                                        AppColors.radiusLG),
                                    border: Border.all(
                                      color: colorScheme.outline
                                          .withValues(alpha: 0.2),
                                    ),
                                  ),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        product.name ?? 'Product',
                                        style:
                                            textTheme.headlineSmall?.copyWith(
                                          fontWeight: FontWeight.bold,
                                          color: colorScheme.onSurface,
                                        ),
                                      ),
                                      const SizedBox(height: 12),
                                      Row(
                                        children: [
                                          Text(
                                            '${l10n.currencyEtb} ${product.formatted_price ?? product.price ?? '0'}',
                                            style: const TextStyle(
                                              fontSize: 22,
                                              fontWeight: FontWeight.bold,
                                              color: AppColors.primaryColor,
                                            ),
                                          ),
                                          if (product.is_on_discount == true &&
                                              product.formatted_original_price !=
                                                  null) ...[
                                            const SizedBox(width: 12),
                                            Text(
                                              product.formatted_original_price!,
                                              style: textTheme.bodyMedium
                                                  ?.copyWith(
                                                color: colorScheme
                                                    .onSurfaceVariant,
                                                decoration:
                                                    TextDecoration.lineThrough,
                                              ),
                                            ),
                                          ],
                                        ],
                                      ),
                                      if (product.description != null &&
                                          product.description!.isNotEmpty) ...[
                                        const SizedBox(height: 16),
                                        Text(
                                          product.description!,
                                          style: textTheme.bodyMedium?.copyWith(
                                            color: colorScheme.onSurfaceVariant,
                                            height: 1.5,
                                          ),
                                        ),
                                      ],
                                      const SizedBox(height: 24),
                                      if (cartQuantity > 0)
                                        _CartQuantityControls(
                                          quantity: cartQuantity,
                                          onDecrement: () => _cart.decrement(
                                            product.id!.toString(),
                                          ),
                                          onIncrement: canOrder
                                              ? () => _cart.increment(
                                                    product.id!.toString(),
                                                  )
                                              : null,
                                        )
                                      else
                                        SizedBox(
                                          width: double.infinity,
                                          height: AppColors.buttonHeightMD,
                                          child: FilledButton.icon(
                                            onPressed:
                                                canOrder ? _addToCart : null,
                                            icon: const Icon(
                                                Icons.add_shopping_cart),
                                            label: Text(l10n.actionAddToCart),
                                            style: FilledButton.styleFrom(
                                              backgroundColor:
                                                  AppColors.primaryColor,
                                              foregroundColor: Colors.white,
                                              shape: RoundedRectangleBorder(
                                                borderRadius:
                                                    BorderRadius.circular(
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
                              SizedBox(height: _cart.isEmpty ? 16 : 96),
                            ],
                          ),
                        ),
        );
      },
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

class _CartQuantityControls extends StatelessWidget {
  final int quantity;
  final VoidCallback onDecrement;
  final VoidCallback? onIncrement;

  const _CartQuantityControls({
    required this.quantity,
    required this.onDecrement,
    this.onIncrement,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: AppColors.buttonHeightMD,
      decoration: BoxDecoration(
        border: Border.all(color: AppColors.primaryColor),
        borderRadius: BorderRadius.circular(AppColors.radiusLG),
      ),
      child: Row(
        children: [
          IconButton(
            onPressed: onDecrement,
            icon: const Icon(Icons.remove),
            color: AppColors.primaryColor,
          ),
          Expanded(
            child: Text(
              '$quantity in cart',
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontWeight: FontWeight.w600,
                color: AppColors.primaryColor,
              ),
            ),
          ),
          IconButton(
            onPressed: onIncrement,
            icon: const Icon(Icons.add),
            color: AppColors.primaryColor,
          ),
        ],
      ),
    );
  }
}

class _CartCheckoutBar extends StatelessWidget {
  final int totalItems;
  final double subtotal;
  final VoidCallback onCheckout;

  const _CartCheckoutBar({
    required this.totalItems,
    required this.subtotal,
    required this.onCheckout,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      decoration: BoxDecoration(
        color: AppColors.primaryColor,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 10,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Row(
          children: [
            const Icon(Icons.shopping_bag_outlined, color: Colors.white, size: 22),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                'TOTAL ITEMS: $totalItems',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(width: 8),
            Text(
              'ETB${subtotal.toStringAsFixed(1)}',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(width: 8),
            TextButton(
              onPressed: onCheckout,
              style: TextButton.styleFrom(
                backgroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                minimumSize: Size.zero,
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
              child: const Text(
                'Go to Checkout',
                style: TextStyle(
                  color: AppColors.primaryColor,
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                ),
              ),
            ),
          ],
        ),
      ),
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
