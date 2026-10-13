import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:hudhud_delivery/app/navigation/cart_navigation.dart';
import 'package:hudhud_delivery/app/services/cart_service.dart';
import 'package:hudhud_delivery/core/api/api_service.dart';
import 'package:hudhud_delivery/core/l10n/context_l10n.dart';
import 'package:hudhud_delivery/core/theme/app_colors.dart';
import 'package:hudhud_delivery/core/widgets/fallback_network_image.dart';
import 'package:hudhud_delivery/features/categories/model/categories_products_model.dart';
import 'package:hudhud_delivery/features/categories/presentation/widgets/categories_widget.dart';
import 'package:hudhud_delivery/features/delivery/presentation/screens/product_detail_screen.dart';
import 'package:hudhud_delivery/features/guest/data/branches_repository.dart';
import 'package:hudhud_delivery/features/guest/model/branch_model.dart';
import 'package:hudhud_delivery/features/home/presentation/theme/home_colors.dart';
import 'package:hudhud_delivery/features/orders/data/models/vendor_model.dart';
import 'package:hudhud_delivery/features/products/data/products_data_provider.dart';
import 'package:hudhud_delivery/features/products/data/products_repository.dart';
import 'package:hudhud_delivery/features/products/model/products_query.dart';
import 'package:hudhud_delivery/features/products/presentation/widgets/product_price_filter_sheet.dart';
import 'package:hudhud_delivery/features/products/presentation/widgets/product_search_field.dart';

class StoreDetailScreen extends StatefulWidget {
  final String storeName;
  final String? storeImage;
  final int? vendorId;

  /// When provided, a rich vendor header (banner, logo, description, hours) is shown.
  final VendorModel? vendor;

  const StoreDetailScreen({
    super.key,
    required this.storeName,
    this.storeImage,
    this.vendorId,
    this.vendor,
  });

  @override
  State<StoreDetailScreen> createState() => _StoreDetailScreenState();
}

class _StoreDetailScreenState extends State<StoreDetailScreen> {
  String _selectedTab = 'Featured';

  List<CategoriesProductsModel> _products = [];
  List<CategoriesProductsModel> _featuredProducts = [];
  List<BranchModel> _branches = [];
  bool _productsLoading = false;
  bool _productsLoadingMore = false;
  String? _productsError;
  late final ProductsRepository _productsRepository;
  late final BranchesRepository _branchesRepository;

  String _search = '';
  String? _minPrice;
  String? _maxPrice;
  int _currentPage = 1;
  bool _hasMore = false;

  /// Shared cart used by store lists and product detail screen.
  final CartService _cart = CartService();

  @override
  void initState() {
    super.initState();
    _cart.addListener(_onCartChanged);
    _productsRepository = ProductsRepository(
      productsDataProvider:
          ProductsDataProvider(apiService: ApiService.instance),
    );
    _branchesRepository = BranchesRepository();
    if (widget.vendorId != null) {
      _loadVendorProducts();
      _loadBranches();
    }
  }

  @override
  void dispose() {
    _cart.removeListener(_onCartChanged);
    super.dispose();
  }

  void _onCartChanged() {
    if (mounted) setState(() {});
  }

  void _syncFeaturedFromVendorProducts() {
    final featured = _products.where((p) => p.is_featured == true).toList();
    // Store Featured tab: prefer flagged items; otherwise show the vendor catalog.
    _featuredProducts = featured.isNotEmpty ? featured : List.of(_products);
  }

  Future<void> _loadBranches() async {
    final vendorId = widget.vendorId;
    if (vendorId == null) return;
    try {
      final branches =
          await _branchesRepository.getBranches(vendorId: vendorId);
      if (mounted) setState(() => _branches = branches);
      final active = branches
          .where((b) => b.id > 0 && (b.isActive || branches.length == 1))
          .toList();
      final candidates =
          active.isNotEmpty ? active : branches.where((b) => b.id > 0).toList();
      if (candidates.length == 1) {
        CartService().setSelectedBranchId(candidates.first.id);
      }
    } catch (_) {}
  }

  List<CategoriesProductsModel> get _activeProducts {
    if (_selectedTab == 'Featured') return _featuredProducts;
    return _products;
  }

  bool get _isLoadingActiveProducts {
    return _productsLoading;
  }

  Future<void> _loadVendorProducts(
      {int page = 1, bool loadMore = false}) async {
    final vendorId = widget.vendorId;
    if (vendorId == null) return;
    setState(() {
      if (loadMore) {
        _productsLoadingMore = true;
      } else {
        _productsLoading = true;
        _productsError = null;
      }
    });
    try {
      final result = await _productsRepository.getProducts(
        ProductsQuery.forVendor(
          vendorId,
          page: page,
          search: _search.isEmpty ? null : _search,
          minPrice: _minPrice,
          maxPrice: _maxPrice,
        ),
      );
      if (!mounted) return;
      setState(() {
        if (loadMore && page > 1) {
          _products = [..._products, ...result.items];
        } else {
          _products = result.items;
        }
        _currentPage = result.currentPage;
        _hasMore = result.hasMore;
        _productsLoading = false;
        _productsLoadingMore = false;
        _syncFeaturedFromVendorProducts();
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _productsError = e.toString();
        _productsLoading = false;
        _productsLoadingMore = false;
      });
    }
  }

  void _onSearchChanged(String value) {
    _search = value;
    _loadVendorProducts();
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
    _loadVendorProducts();
  }

  CategoriesProductsModel? _productById(String productId) {
    for (final p in _activeProducts) {
      if (p.id?.toString() == productId) return p;
    }
    for (final p in _products) {
      if (p.id?.toString() == productId) return p;
    }
    for (final p in _featuredProducts) {
      if (p.id?.toString() == productId) return p;
    }
    return null;
  }

  Future<void> _addToCart(String productId) async {
    final product = _productById(productId);
    if (product == null || !product.canOrder) return;
    var result = _cart.addProduct(product);
    if (result == CartAddResult.differentVendor) {
      final replace = await _confirmReplaceCart();
      if (!mounted || replace != true) return;
      result = _cart.addProduct(product, replaceIfDifferentVendor: true);
    }
  }

  Future<bool?> _confirmReplaceCart() {
    final l10n = context.l10n;
    return showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.cartDifferentVendorTitle),
        content: Text(l10n.cartDifferentVendorMessage),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(l10n.cartKeepCurrentAction),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(l10n.cartReplaceAction),
          ),
        ],
      ),
    );
  }

  void _removeFromCart(String productId) {
    _cart.removeProduct(productId);
  }

  Future<void> _incrementQuantity(String productId) async {
    final product = _productById(productId);
    if (product != null && !product.canOrder) return;
    if (_cart.quantityFor(int.tryParse(productId)) == 0 && product != null) {
      await _addToCart(productId);
      return;
    }
    _cart.increment(productId);
  }

  void _decrementQuantity(String productId) {
    _cart.decrement(productId);
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

  int get _totalItems => _cart.totalItems;

  double get _totalPrice => _cart.subtotal;

  String get _displayName => widget.vendor?.name ?? widget.storeName;

  @override
  Widget build(BuildContext context) {
    final ink = HomeColors.textPrimaryOf(context);
    return Scaffold(
      backgroundColor: HomeColors.backgroundOf(context),
      body: SafeArea(
        child: Column(
          children: [
            // Vendor detail header or simple app bar
            if (widget.vendor != null)
              _VendorDetailHeader(
                vendor: widget.vendor!,
                branches: _branches,
                onBack: () => Navigator.pop(context),
              )
            else
              Padding(
                padding: const EdgeInsets.fromLTRB(4, 8, 16, 8),
                child: Row(
                  children: [
                    IconButton(
                      icon:
                          Icon(Icons.arrow_back_rounded, size: 26, color: ink),
                      onPressed: () => Navigator.pop(context),
                    ),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        _displayName,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w800,
                          letterSpacing: -0.4,
                          color: ink,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            if (widget.vendorId != null) ...[
              const SizedBox(height: 12),
              ProductSearchField(
                fillColor: HomeColors.surfaceOf(context),
                hintColor: HomeColors.textMutedOf(context),
                hint: 'Search in $_displayName',
                onSearchChanged: _onSearchChanged,
                onFilterTap: _openPriceFilter,
              ),
              if (_minPrice != null || _maxPrice != null)
                Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                  child: Text(
                    'Price: ${_minPrice ?? '\u2014'} \u2013 ${_maxPrice ?? '\u2014'}',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: HomeColors.textMutedOf(context),
                    ),
                  ),
                ),
            ],
            const SizedBox(height: 16),
            // Category Tabs
            SizedBox(
              height: 48,
              child: ListView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                children: [
                  _CategoryTab(
                    label: 'Featured',
                    icon: Icons.star_rounded,
                    isSelected: _selectedTab == 'Featured',
                    onTap: () {
                      setState(() {
                        _selectedTab = 'Featured';
                      });
                    },
                  ),
                  const SizedBox(width: 8),
                  _CategoryTab(
                    label: 'Categories',
                    icon: Icons.grid_view_rounded,
                    isSelected: _selectedTab == 'Categories',
                    onTap: () {
                      setState(() {
                        _selectedTab = 'Categories';
                      });
                    },
                  ),
                  const SizedBox(width: 8),
                  _CategoryTab(
                    label: 'Orders',
                    icon: Icons.receipt_long_rounded,
                    isSelected: _selectedTab == 'Orders',
                    onTap: () {
                      setState(() {
                        _selectedTab = 'Orders';
                      });
                    },
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            // Content
            Expanded(
              child: widget.vendorId == null
                  ? const _StoreMessage(
                      icon: Icons.store_mall_directory_rounded,
                      title: 'Store not available',
                    )
                  : _selectedTab == 'Orders'
                      ? _StoreMessage(
                          icon: Icons.receipt_long_rounded,
                          title: context.l10n.noOrdersYetStore,
                        )
                      : _isLoadingActiveProducts
                          ? const Center(
                              child: CircularProgressIndicator(
                                color: AppColors.brandOrange,
                              ),
                            )
                          : _productsError != null
                              ? _StoreMessage(
                                  icon: Icons.wifi_off_rounded,
                                  color: AppColors.errorColor,
                                  title: _productsError!,
                                  actionLabel: context.l10n.actionRetry,
                                  onAction: _loadVendorProducts,
                                )
                              : _activeProducts.isEmpty
                                  ? _StoreMessage(
                                      icon: Icons.shopping_basket_rounded,
                                      title: context.l10n.noProductsYet,
                                    )
                                  : _buildProductsContent(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProductsContent() {
    final grouped = <int?, List<CategoriesProductsModel>>{};
    for (final p in _activeProducts) {
      grouped.putIfAbsent(p.category_id, () => []).add(p);
    }
    final sections = grouped.entries.toList();
    if (sections.isEmpty) {
      return _StoreMessage(
        icon: Icons.shopping_basket_rounded,
        title: context.l10n.noProducts,
      );
    }
    return Stack(
      children: [
        SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (widget.vendor == null &&
                  widget.storeImage != null &&
                  widget.storeImage!.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(20),
                    child: FallbackNetworkImage(
                      url: widget.storeImage!,
                      height: 150,
                      width: double.infinity,
                      fit: BoxFit.cover,
                      errorBuilder: (_) => const SizedBox.shrink(),
                    ),
                  ),
                )
              else if (widget.vendor == null)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Builder(
                    builder: (context) {
                      final dark = HomeColors.isDark(context);
                      return Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: dark
                              ? AppColors.orangeTintDark
                              : AppColors.orangeTint,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Row(
                          children: [
                            Container(
                              width: 48,
                              height: 48,
                              decoration: BoxDecoration(
                                color: AppColors.brandOrange,
                                borderRadius: BorderRadius.circular(15),
                              ),
                              child: const Icon(
                                Icons.delivery_dining_rounded,
                                color: Colors.white,
                                size: 26,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                'ETB 0 Delivery Fee with selected products',
                                style: TextStyle(
                                  color: HomeColors.textPrimaryOf(context),
                                  fontSize: 15,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
              if (widget.vendor == null) const SizedBox(height: 24),
              ...sections.map((e) {
                final title = e.key != null ? 'Category ${e.key}' : 'Products';
                return Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: _ProductSectionFromModel(
                    title: title,
                    products: e.value,
                    cartItems: _cart.quantities,
                    onAddToCart: _addToCart,
                    onRemoveFromCart: _removeFromCart,
                    onIncrementQuantity: _incrementQuantity,
                    onDecrementQuantity: _decrementQuantity,
                    onShowProductDetails: _showProductDetails,
                  ),
                );
              }),
              if (_hasMore && _selectedTab != 'Featured')
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Center(
                    child: _productsLoadingMore
                        ? const CircularProgressIndicator(
                            color: AppColors.brandOrange,
                          )
                        : TextButton(
                            style: TextButton.styleFrom(
                              foregroundColor: HomeColors.violetOf(context),
                              minimumSize: const Size(120, 48),
                              textStyle: const TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                            onPressed: () => _loadVendorProducts(
                              page: _currentPage + 1,
                              loadMore: true,
                            ),
                            child: Text(context.l10n.loadMore),
                          ),
                  ),
                ),
              if (_totalItems > 0) const SizedBox(height: 96),
              const SizedBox(height: 24),
            ],
          ),
        ),
        if (_totalItems > 0)
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: _StoreCheckoutBar(
              totalItems: _totalItems,
              totalPrice: _totalPrice,
              onCheckout: _goToCart,
            ),
          ),
      ],
    );
  }

  void _goToCart() {
    openCheckoutFromCart(context, fallbackVendorId: widget.vendorId);
  }
}

class _VendorDetailHeader extends StatelessWidget {
  static const double _heroHeight = 280;

  final VendorModel vendor;
  final List<BranchModel> branches;
  final VoidCallback onBack;

  const _VendorDetailHeader({
    required this.vendor,
    this.branches = const [],
    required this.onBack,
  });

  String? get _heroImageUrl {
    if (vendor.bannerPath != null && vendor.bannerPath!.isNotEmpty) {
      return vendor.bannerPath;
    }
    if (vendor.avatar.isNotEmpty && vendor.avatar.startsWith('http')) {
      return vendor.avatar;
    }
    return null;
  }

  bool get _hasHours =>
      (vendor.openingTime != null && vendor.openingTime!.isNotEmpty) ||
      (vendor.closingTime != null && vendor.closingTime!.isNotEmpty);

  @override
  Widget build(BuildContext context) {
    final heroUrl = _heroImageUrl;
    final tag = vendor.cuisineType?.trim();
    final hasTag = tag != null && tag.isNotEmpty;

    return SizedBox(
      height: _heroHeight,
      child: Stack(
        fit: StackFit.expand,
        children: [
          Positioned.fill(
            child: heroUrl != null
                ? FallbackNetworkImage(
                    url: heroUrl,
                    fit: BoxFit.cover,
                    errorBuilder: (_) => _gradientFallback(),
                  )
                : _gradientFallback(),
          ),
          Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.black.withValues(alpha: 0.15),
                    Colors.black.withValues(alpha: 0.35),
                    Colors.black.withValues(alpha: 0.82),
                  ],
                  stops: const [0.0, 0.45, 1.0],
                ),
              ),
            ),
          ),
          // Back button
          Positioned(
            top: 8,
            left: 8,
            child: ClipOval(
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                child: Material(
                  color: Colors.black.withValues(alpha: 0.3),
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
          Positioned(
            left: 16,
            right: 16,
            bottom: 20,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  vendor.name,
                  style: const TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.w800,
                    color: AppColors.lightOnPrimary,
                    height: 1.15,
                    letterSpacing: -0.8,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    if (hasTag)
                      _VendorInfoChip(
                        icon: Icons.local_offer_outlined,
                        label: tag,
                        accent: AppColors.primaryLightColor,
                      ),
                    if (vendor.status == 'active')
                      const _VendorInfoChip(
                        icon: Icons.check_circle_outline,
                        label: 'Open for orders',
                        accent: AppColors.successLightColor,
                      ),
                  ],
                ),
                if (branches.isNotEmpty) ...[
                  const SizedBox(height: 10),
                  Text(
                    branches.map((b) => b.name).join(' \u00b7 '),
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: AppColors.lightOnPrimary.withValues(alpha: 0.88),
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
                if (_hasHours) ...[
                  const SizedBox(height: 12),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(14),
                    child: BackdropFilter(
                      filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 12,
                        ),
                        decoration: BoxDecoration(
                          color:
                              AppColors.lightOnPrimary.withValues(alpha: 0.14),
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                            color: AppColors.lightOnPrimary
                                .withValues(alpha: 0.22),
                          ),
                        ),
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: AppColors.primaryColor
                                    .withValues(alpha: 0.9),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: const Icon(
                                Icons.schedule_rounded,
                                color: AppColors.lightOnPrimary,
                                size: 20,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Opening hours',
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w700,
                                      color: AppColors.lightOnPrimary
                                          .withValues(alpha: 0.75),
                                      letterSpacing: 0.4,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    '${vendor.openingTime ?? '\u2014'}  \u2192  ${vendor.closingTime ?? '\u2014'}',
                                    style: const TextStyle(
                                      fontSize: 15,
                                      fontWeight: FontWeight.w700,
                                      color: AppColors.lightOnPrimary,
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
                ],
                if (vendor.description != null &&
                    vendor.description!.isNotEmpty) ...[
                  const SizedBox(height: 10),
                  Text(
                    vendor.description!,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: AppColors.lightOnPrimary.withValues(alpha: 0.9),
                      height: 1.4,
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
    );
  }

  Widget _gradientFallback() => Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: AppColors.brandHeroGradient,
          ),
        ),
        // Watermark sits top-right so it never collides with the store name.
        child: Stack(
          children: [
            Positioned(
              right: -24,
              top: 8,
              child: Icon(
                Icons.storefront_rounded,
                size: 170,
                color: AppColors.lightOnPrimary.withValues(alpha: 0.08),
              ),
            ),
          ],
        ),
      );
}

class _VendorInfoChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color accent;

  const _VendorInfoChip({
    required this.icon,
    required this.label,
    required this.accent,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.35),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: accent.withValues(alpha: 0.55)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: accent),
          const SizedBox(width: 6),
          Text(
            label,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: AppColors.lightOnPrimary,
            ),
          ),
        ],
      ),
    );
  }
}

class _CategoryTab extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool isSelected;
  final VoidCallback onTap;

  const _CategoryTab({
    required this.label,
    required this.icon,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final indigo = HomeColors.violetOf(context);
    return Semantics(
      button: true,
      selected: isSelected,
      child: Material(
        color: isSelected ? indigo : HomeColors.surfaceOf(context),
        shape: StadiumBorder(
          side: BorderSide(
            color: isSelected ? indigo : HomeColors.borderOf(context),
          ),
        ),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(14, 0, 18, 0),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  icon,
                  size: 20,
                  color: isSelected ? Colors.white : indigo,
                ),
                const SizedBox(width: 6),
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 15,
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
  }
}

/// Centered icon + message (+ optional orange action) for empty/error states.
class _StoreMessage extends StatelessWidget {
  const _StoreMessage({
    required this.icon,
    required this.title,
    this.color,
    this.actionLabel,
    this.onAction,
  });

  final IconData icon;
  final String title;
  final Color? color;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    final dark = HomeColors.isDark(context);
    final tint = color ?? HomeColors.violetOf(context);
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(32, 16, 32, 48),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 96,
              height: 96,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: tint.withValues(alpha: dark ? 0.2 : 0.1),
              ),
              child: Icon(icon, size: 46, color: tint),
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

/// Floating cart summary with a clear white-on-orange checkout button.
class _StoreCheckoutBar extends StatelessWidget {
  const _StoreCheckoutBar({
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
                  style: TextStyle(
                    color: HomeColors.textMutedOf(context),
                    fontSize: 12.5,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.3,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
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
    );
  }
}

class _ProductSectionFromModel extends StatelessWidget {
  final String title;
  final List<CategoriesProductsModel> products;
  final Map<String, int> cartItems;
  final void Function(String productId) onAddToCart;
  final void Function(String productId) onRemoveFromCart;
  final void Function(String productId) onIncrementQuantity;
  final void Function(String productId) onDecrementQuantity;
  final void Function(CategoriesProductsModel product) onShowProductDetails;

  const _ProductSectionFromModel({
    required this.title,
    required this.products,
    required this.cartItems,
    required this.onAddToCart,
    required this.onRemoveFromCart,
    required this.onIncrementQuantity,
    required this.onDecrementQuantity,
    required this.onShowProductDetails,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Text(
            title,
            style: TextStyle(
              fontSize: 19,
              fontWeight: FontWeight.w800,
              letterSpacing: -0.3,
              color: HomeColors.textPrimaryOf(context),
            ),
          ),
        ),
        const SizedBox(height: 12),
        ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: products.length,
          itemBuilder: (context, index) {
            final product = products[index];
            final productId = product.id.toString();
            final quantity = cartItems[productId] ?? 0;
            final isAdded = quantity > 0;
            return ProductItem(
              product: product,
              name: product.name ?? 'Unknown Product',
              description: product.description ?? 'No description available',
              imageUrl: product.image_path ?? '',
              price: product.price ?? '0',
              discountPrice: product.discount_price?.isNotEmpty == true
                  ? product.discount_price
                  : null,
              isAdded: isAdded,
              quantity: quantity,
              onAddPressed: () => onAddToCart(productId),
              onRemovePressed: () => onRemoveFromCart(productId),
              onIncrementPressed: () => onIncrementQuantity(productId),
              onDecrementPressed: () => onDecrementQuantity(productId),
              onTap: () => onShowProductDetails(product),
            );
          },
        ),
      ],
    );
  }
}
