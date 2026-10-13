import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/l10n/context_l10n.dart';
import '../../../../core/theme/app_colors.dart';
import '../../bloc/categories_bloc.dart';
import '../../model/category_tree_model.dart';
import '../../model/categories_products_model.dart';
import '../../../home/presentation/theme/home_colors.dart';
import '../widgets/categories_widget.dart';
import '../../../checkout/presentation/screen/checkout_screen.dart';
import '../../../delivery/presentation/screens/product_detail_screen.dart';
import '../../../products/presentation/widgets/product_price_filter_sheet.dart';
import '../../../products/presentation/widgets/product_search_field.dart';

class CategoriesScreen extends StatefulWidget {
  final int categoryId;
  final String categoryName;
  final String categoryImage;
  final CategoryTreeModel? category;

  const CategoriesScreen({
    super.key,
    required this.categoryId,
    required this.categoryName,
    required this.categoryImage,
    this.category,
  });

  @override
  State<CategoriesScreen> createState() => _CategoriesScreenState();
}

class _CategoriesScreenState extends State<CategoriesScreen> {
  final Map<String, int> _cartItems = {};
  List<CategoriesProductsModel> _products = [];
  List<CategoriesProductsModel> _filteredProducts = [];

  List<String> _availableFilters = [];
  List<String> _selectedFilters = [];

  String _search = '';
  String? _minPrice;
  String? _maxPrice;
  bool _hasMore = false;
  int _currentPage = 1;

  @override
  void initState() {
    super.initState();
    _fetchProducts();
  }

  void _fetchProducts({int page = 1, bool loadMore = false}) {
    context.read<CategoriesBloc>().add(
          FetchCategoriesProductsEvent(
            categoryId: widget.categoryId,
            search: _search.isEmpty ? null : _search,
            minPrice: _minPrice,
            maxPrice: _maxPrice,
            page: page,
            loadMore: loadMore,
          ),
        );
  }

  void _onSearchChanged(String value) {
    _search = value;
    _fetchProducts();
  }

  Future<void> _openPriceFilter() async {
    final result = await showProductPriceFilterSheet(
      context,
      initialMin: _minPrice,
      initialMax: _maxPrice,
    );
    if (result == null) return;
    setState(() {
      _minPrice = result.minPrice;
      _maxPrice = result.maxPrice;
    });
    _fetchProducts();
  }

  void _onFiltersChanged(List<String> selectedFilters) {
    setState(() {
      _selectedFilters = selectedFilters;
      _filterProducts();
    });
  }

  void _generateAvailableFilters() {
    Set<String> filters = {};

    for (var product in _products) {
      if (product.discount_price != null &&
          product.discount_price!.isNotEmpty) {
        filters.add('On Sale');
      }
      if (product.ingredients != null && product.ingredients!.isNotEmpty) {
        filters.add('With Ingredients');
      }
      if (product.allergens != null && product.allergens!.isNotEmpty) {
        filters.add('Contains Allergens');
      }
      if (product.addons != null && product.addons!.isNotEmpty) {
        filters.add('Customizable');
      }
      if (product.preparation_time != null) {
        int prepTime = int.tryParse(product.preparation_time.toString()) ?? 0;
        if (prepTime <= 15) {
          filters.add('Quick (≤15 min)');
        } else if (prepTime <= 30) {
          filters.add('Medium (16-30 min)');
        } else {
          filters.add('Slow (>30 min)');
        }
      }
      if (product.calories != null || product.protein != null) {
        filters.add('Nutrition Info');
      }
    }

    _availableFilters = filters.toList();
  }

  void _filterProducts() {
    setState(() {
      _filteredProducts = _products.toList();

      if (_selectedFilters.isNotEmpty) {
        _filteredProducts = _filteredProducts.where((product) {
          return _selectedFilters.every((filter) {
            switch (filter) {
              case 'On Sale':
                return product.discount_price != null &&
                    product.discount_price!.isNotEmpty;
              case 'With Ingredients':
                return product.ingredients != null &&
                    product.ingredients!.isNotEmpty;
              case 'Contains Allergens':
                return product.allergens != null &&
                    product.allergens!.isNotEmpty;
              case 'Customizable':
                return product.addons != null && product.addons!.isNotEmpty;
              case 'Quick (≤15 min)':
                int prepTime =
                    int.tryParse(product.preparation_time.toString()) ?? 0;
                return prepTime > 0 && prepTime <= 15;
              case 'Medium (16-30 min)':
                int prepTime =
                    int.tryParse(product.preparation_time.toString()) ?? 0;
                return prepTime > 15 && prepTime <= 30;
              case 'Slow (>30 min)':
                int prepTime =
                    int.tryParse(product.preparation_time.toString()) ?? 0;
                return prepTime > 30;
              case 'Nutrition Info':
                return product.calories != null || product.protein != null;
              default:
                return true;
            }
          });
        }).toList();
      }
    });
  }

  CategoriesProductsModel? _productById(String productId) {
    for (final p in _products) {
      if (p.id?.toString() == productId) return p;
    }
    return null;
  }

  void _addToCart(String productId) {
    final product = _productById(productId);
    if (product != null && !product.canOrder) return;
    setState(() {
      _cartItems[productId] = (_cartItems[productId] ?? 0) + 1;
    });
  }

  void _removeFromCart(String productId) {
    setState(() {
      _cartItems.remove(productId);
    });
  }

  void _incrementQuantity(String productId) {
    final product = _productById(productId);
    if (product != null && !product.canOrder) return;
    setState(() {
      _cartItems[productId] = (_cartItems[productId] ?? 0) + 1;
    });
  }

  void _decrementQuantity(String productId) {
    setState(() {
      if (_cartItems[productId] == 1) {
        _cartItems.remove(productId);
      } else {
        _cartItems[productId] = _cartItems[productId]! - 1;
      }
    });
  }

  void _showProductDetails(CategoriesProductsModel product) {
    if (product.id != null) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => ProductDetailScreen(productId: product.id!),
        ),
      );
      return;
    }
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => ProductDetailsModal(product: product),
    );
  }

  int get _totalItems =>
      _cartItems.values.fold(0, (sum, quantity) => sum + quantity);

  double get _totalPrice {
    double total = 0;
    _cartItems.forEach((productId, quantity) {
      final product = _products.firstWhere(
        (product) => product.id.toString() == productId,
        orElse: () => CategoriesProductsModel(),
      );
      if (product.id != null) {
        final price = product.discount_price?.isNotEmpty == true
            ? double.tryParse(product.discount_price!) ?? 0
            : double.tryParse(product.price ?? '0') ?? 0;
        total += price * quantity;
      }
    });
    return total;
  }

  void _goToCheckout() {
    final List<Map<String, dynamic>> cartItems =
        _cartItems.entries.map((entry) {
      final productId = entry.key;
      final quantity = entry.value;
      final product = _filteredProducts.firstWhere(
        (p) => p.id.toString() == productId,
        orElse: () => _products.firstWhere(
          (p) => p.id.toString() == productId,
          orElse: () => throw Exception('Product not found'),
        ),
      );

      return {
        'id': product.id,
        'productId': product.id,
        'product_id': product.id,
        'vendor_id': product.vendor_id,
        'name': product.name,
        'image': product.image_path,
        'price': double.tryParse(product.price ?? '0') ?? 0.0,
        'quantity': quantity,
      };
    }).toList();

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => CheckoutScreen(
          cartItems: cartItems,
          subtotal: _totalPrice,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: HomeColors.backgroundOf(context),
      body: BlocListener<CategoriesBloc, CategoriesState>(
        listener: (context, state) {
          if (state is FetchCategoriesProductsSuccess) {
            setState(() {
              _products = state.categoriesProducts;
              _hasMore = state.hasMore;
              _currentPage = state.currentPage;
              _generateAvailableFilters();
              _filterProducts();
            });
          }
        },
        child: BlocBuilder<CategoriesBloc, CategoriesState>(
          builder: (context, state) {
            final isLoading =
                state is FetchCategoriesProductsLoading && !state.isLoadingMore;
            final isLoadingMore =
                state is FetchCategoriesProductsLoading && state.isLoadingMore;

            return Stack(
              children: [
                RefreshIndicator(
                  color: AppColors.brandOrange,
                  onRefresh: () async => _fetchProducts(),
                  child: SingleChildScrollView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        CategoryDetailHeader(
                          name: widget.categoryName,
                          imageUrl: widget.categoryImage,
                          productsCount: widget.category?.productsCount ??
                              _products.length,
                          description: widget.category?.description,
                          onBack: () => Navigator.pop(context),
                        ),
                        const SizedBox(height: 16),
                        ProductSearchField(
                          fillColor: HomeColors.surfaceOf(context),
                          hintColor: HomeColors.textMutedOf(context),
                          hint: 'Search in ${widget.categoryName}',
                          onSearchChanged: _onSearchChanged,
                          onFilterTap: _openPriceFilter,
                        ),
                        if (_minPrice != null || _maxPrice != null)
                          Padding(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 16, vertical: 4),
                            child: Text(
                              'Price: ${_minPrice ?? '—'} – ${_maxPrice ?? '—'}',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                                color: HomeColors.textMutedOf(context),
                              ),
                            ),
                          ),
                        const SizedBox(height: 8),
                        ProductFilters(
                          filters: _availableFilters,
                          selectedFilters: _selectedFilters,
                          onFiltersChanged: _onFiltersChanged,
                        ),
                        if (isLoading)
                          const Center(
                            child: Padding(
                              padding: EdgeInsets.all(32.0),
                              child: CircularProgressIndicator(
                                color: AppColors.brandOrange,
                              ),
                            ),
                          )
                        else if (state is FetchCategoriesProductsFailure)
                          _CategoryMessage(
                            icon: Icons.wifi_off_rounded,
                            color: AppColors.errorColor,
                            title: 'Error: ${state.errorMessage}',
                            actionLabel: context.l10n.actionRetry,
                            onAction: _fetchProducts,
                          )
                        else ...[
                          Padding(
                            padding: const EdgeInsets.fromLTRB(16, 20, 16, 12),
                            child: Row(
                              children: [
                                Icon(
                                  Icons.grid_view_rounded,
                                  size: 22,
                                  color: HomeColors.violetOf(context),
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  'Products',
                                  style: TextStyle(
                                    fontSize: 19,
                                    fontWeight: FontWeight.w800,
                                    letterSpacing: -0.3,
                                    color: HomeColors.textPrimaryOf(context),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          if (_filteredProducts.isEmpty)
                            _CategoryMessage(
                              icon: Icons.shopping_basket_rounded,
                              color: HomeColors.violetOf(context),
                              title: 'No products found',
                            )
                          else
                            ListView.builder(
                              shrinkWrap: true,
                              physics: const NeverScrollableScrollPhysics(),
                              padding: EdgeInsets.zero,
                              itemCount: _filteredProducts.length,
                              itemBuilder: (context, index) {
                                final product = _filteredProducts[index];
                                final productId = product.id.toString();
                                final quantity = _cartItems[productId] ?? 0;
                                final isAdded = quantity > 0;

                                return ProductItem(
                                  product: product,
                                  name: product.name ?? 'Unknown Product',
                                  description: product.description ??
                                      'No description available',
                                  imageUrl: product.image_path ?? '',
                                  price: product.price ?? '0',
                                  discountPrice:
                                      product.discount_price?.isNotEmpty == true
                                          ? product.discount_price
                                          : null,
                                  isAdded: isAdded,
                                  quantity: quantity,
                                  onAddPressed: () => _addToCart(productId),
                                  onRemovePressed: () =>
                                      _removeFromCart(productId),
                                  onIncrementPressed: () =>
                                      _incrementQuantity(productId),
                                  onDecrementPressed: () =>
                                      _decrementQuantity(productId),
                                  onTap: () => _showProductDetails(product),
                                );
                              },
                            ),
                          if (_hasMore)
                            Padding(
                              padding: const EdgeInsets.all(16),
                              child: Center(
                                child: isLoadingMore
                                    ? const CircularProgressIndicator(
                                        color: AppColors.brandOrange,
                                      )
                                    : TextButton(
                                        style: TextButton.styleFrom(
                                          foregroundColor:
                                              HomeColors.violetOf(context),
                                          minimumSize: const Size(120, 48),
                                          textStyle: const TextStyle(
                                            fontSize: 15,
                                            fontWeight: FontWeight.w800,
                                          ),
                                        ),
                                        onPressed: () => _fetchProducts(
                                          page: _currentPage + 1,
                                          loadMore: true,
                                        ),
                                        child: Text(context.l10n.loadMore),
                                      ),
                              ),
                            ),
                        ],
                        if (_totalItems > 0) const SizedBox(height: 100),
                      ],
                    ),
                  ),
                ),
                if (_totalItems > 0)
                  Positioned(
                    left: 0,
                    right: 0,
                    bottom: 0,
                    child: _CategoryCheckoutBar(
                      totalItems: _totalItems,
                      totalPrice: _totalPrice,
                      onCheckout: _goToCheckout,
                    ),
                  ),
              ],
            );
          },
        ),
      ),
    );
  }
}

/// Icon + message (+ optional orange action) for empty/error states.
class _CategoryMessage extends StatelessWidget {
  const _CategoryMessage({
    required this.icon,
    required this.color,
    required this.title,
    this.actionLabel,
    this.onAction,
  });

  final IconData icon;
  final Color color;
  final String title;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    final dark = HomeColors.isDark(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(32, 24, 32, 32),
      child: Center(
        child: Column(
          children: [
            Container(
              width: 96,
              height: 96,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: color.withValues(alpha: dark ? 0.2 : 0.1),
              ),
              child: Icon(icon, size: 46, color: color),
            ),
            const SizedBox(height: 18),
            Text(
              title,
              textAlign: TextAlign.center,
              maxLines: 4,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w800,
                letterSpacing: -0.3,
                color: HomeColors.textPrimaryOf(context),
              ),
            ),
            if (actionLabel != null && onAction != null) ...[
              const SizedBox(height: 22),
              SizedBox(
                height: 56,
                child: FilledButton.icon(
                  onPressed: onAction,
                  icon: const Icon(Icons.refresh_rounded, size: 22),
                  label: Text(actionLabel!),
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.brandOrange,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 28),
                    textStyle: const TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w800,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(18),
                    ),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// Floating cart summary with a white-on-orange checkout button.
class _CategoryCheckoutBar extends StatelessWidget {
  const _CategoryCheckoutBar({
    required this.totalItems,
    required this.totalPrice,
    required this.onCheckout,
  });

  final int totalItems;
  final double totalPrice;
  final VoidCallback onCheckout;

  @override
  Widget build(BuildContext context) {
    final dark = HomeColors.isDark(context);
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
      decoration: BoxDecoration(
        color: HomeColors.surfaceOf(context),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        border: dark
            ? Border(top: BorderSide(color: HomeColors.borderOf(context)))
            : null,
        boxShadow: dark
            ? null
            : const [
                BoxShadow(
                  color: AppColors.lightShadow,
                  blurRadius: 18,
                  offset: Offset(0, -6),
                ),
              ],
      ),
      child: SafeArea(
        top: false,
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: dark ? AppColors.orangeTintDark : AppColors.orangeTint,
                borderRadius: BorderRadius.circular(15),
              ),
              child: const Icon(
                Icons.shopping_bag_rounded,
                color: AppColors.brandOrange,
                size: 24,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'TOTAL ITEMS: $totalItems',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: HomeColors.textMutedOf(context),
                      fontSize: 12.5,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.3,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'ETB ${totalPrice.toStringAsFixed(1)}',
                    maxLines: 1,
                    style: TextStyle(
                      color: HomeColors.textPrimaryOf(context),
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      letterSpacing: -0.3,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 10),
            SizedBox(
              height: 52,
              child: FilledButton(
                onPressed: onCheckout,
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.brandOrange,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 18),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                child: const FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'Go to Checkout',
                        style: TextStyle(
                          fontWeight: FontWeight.w800,
                          fontSize: 15,
                        ),
                      ),
                      SizedBox(width: 6),
                      Icon(Icons.arrow_forward_rounded, size: 20),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
