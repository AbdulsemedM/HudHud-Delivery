import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:hudhud_delivery/app/services/guest_browse_service.dart';
import 'package:hudhud_delivery/core/api/api_service.dart';
import 'package:hudhud_delivery/core/theme/app_colors.dart';
import 'package:hudhud_delivery/core/widgets/fallback_network_image.dart';
import 'package:hudhud_delivery/features/categories/model/categories_products_model.dart';
import 'package:hudhud_delivery/features/categories/presentation/widgets/categories_widget.dart';
import 'package:hudhud_delivery/features/checkout/presentation/screen/checkout_screen.dart';
import 'package:hudhud_delivery/features/delivery/presentation/screens/product_detail_screen.dart';
import 'package:hudhud_delivery/features/guest/data/branches_repository.dart';
import 'package:hudhud_delivery/features/guest/model/branch_model.dart';
import 'package:hudhud_delivery/features/guest/utils/guest_sign_in_prompt.dart';
import 'package:hudhud_delivery/features/orders/data/models/vendor_model.dart';
import 'package:hudhud_delivery/l10n/app_localizations.dart';
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
  bool _featuredLoading = false;
  bool _productsLoadingMore = false;
  String? _productsError;
  late final ProductsRepository _productsRepository;
  late final BranchesRepository _branchesRepository;

  String _search = '';
  String? _minPrice;
  String? _maxPrice;
  int _currentPage = 1;
  bool _hasMore = false;

  /// Cart: productId -> quantity (same pattern as categories screen).
  final Map<String, int> _cartItems = {};

  @override
  void initState() {
    super.initState();
    _productsRepository = ProductsRepository(
      productsDataProvider:
          ProductsDataProvider(apiService: ApiService.instance),
    );
    _branchesRepository = BranchesRepository();
    if (widget.vendorId != null) {
      _loadVendorProducts();
      _loadFeaturedProducts();
      _loadBranches();
    }
  }

  Future<void> _loadFeaturedProducts() async {
    setState(() => _featuredLoading = true);
    try {
      final all = await _productsRepository.getFeaturedProducts(limit: 20);
      final vendorId = widget.vendorId;
      setState(() {
        _featuredProducts = vendorId == null
            ? all
            : all.where((p) => p.vendor_id == vendorId).toList();
        _featuredLoading = false;
      });
    } catch (_) {
      if (mounted) setState(() => _featuredLoading = false);
    }
  }

  Future<void> _loadBranches() async {
    final vendorId = widget.vendorId;
    if (vendorId == null) return;
    try {
      final branches = await _branchesRepository.getBranches(vendorId: vendorId);
      if (mounted) setState(() => _branches = branches);
    } catch (_) {}
  }

  List<CategoriesProductsModel> get _activeProducts {
    if (_selectedTab == 'Featured') return _featuredProducts;
    return _products;
  }

  bool get _isLoadingActiveProducts {
    if (_selectedTab == 'Featured') return _featuredLoading;
    return _productsLoading;
  }

  Future<void> _loadVendorProducts({int page = 1, bool loadMore = false}) async {
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
      });
    } catch (e) {
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
      final product = _productById(productId);
      if (product == null) return;
      final price = product.discount_price?.isNotEmpty == true
          ? double.tryParse(product.discount_price!) ?? 0
          : double.tryParse(product.price ?? '0') ?? 0;
      total += price * quantity;
    });
    return total;
  }

  String get _displayName => widget.vendor?.name ?? widget.storeName;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
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
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                child: Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.arrow_back),
                      onPressed: () => Navigator.pop(context),
                    ),
                    Expanded(
                      child: Text(
                        _displayName,
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                          color: Theme.of(context).colorScheme.onSurface,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            if (widget.vendorId != null) ...[
              ProductSearchField(
                hint: 'Search in $_displayName',
                onSearchChanged: _onSearchChanged,
                onFilterTap: _openPriceFilter,
              ),
              if (_minPrice != null || _maxPrice != null)
                Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                  child: Text(
                    'Price: ${_minPrice ?? '—'} – ${_maxPrice ?? '—'}',
                    style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                  ),
                ),
            ],
            const SizedBox(height: 16),
            // Category Tabs
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  _CategoryTab(
                    label: 'Featured',
                    isSelected: _selectedTab == 'Featured',
                    onTap: () {
                      setState(() {
                        _selectedTab = 'Featured';
                      });
                    },
                  ),
                  const SizedBox(width: 12),
                  _CategoryTab(
                    label: 'Categories',
                    isSelected: _selectedTab == 'Categories',
                    onTap: () {
                      setState(() {
                        _selectedTab = 'Categories';
                      });
                    },
                  ),
                  const SizedBox(width: 12),
                  _CategoryTab(
                    label: 'Orders',
                    isSelected: _selectedTab == 'Orders',
                    onTap: () {
                      if (GuestBrowseService().isGuestBrowseMode) {
                        final l10n = AppLocalizations.of(context)!;
                        showGuestSignInRequiredDialog(
                          context,
                          message: l10n.guestOrdersSignIn,
                        );
                        return;
                      }
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
                  ? _buildStaticContent()
                  : _selectedTab == 'Orders'
                      ? const Center(child: Text('No orders yet'))
                      : _isLoadingActiveProducts
                      ? const Center(child: CircularProgressIndicator())
                      : _productsError != null && _selectedTab != 'Featured'
                          ? Center(
                              child: Padding(
                                padding: const EdgeInsets.all(24),
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Text(
                                      _productsError!,
                                      textAlign: TextAlign.center,
                                      style: TextStyle(
                                        fontSize: 14,
                                        color: Colors.grey[600],
                                      ),
                                    ),
                                    const SizedBox(height: 16),
                                    TextButton(
                                      onPressed: _loadVendorProducts,
                                      child: const Text('Retry'),
                                    ),
                                  ],
                                ),
                              ),
                            )
                          : _activeProducts.isEmpty
                              ? const Center(child: Text('No products yet'))
                              : _buildProductsContent(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStaticContent() {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Container(
              height: 150,
              decoration: BoxDecoration(
                color: Colors.grey[200],
                borderRadius: BorderRadius.circular(12),
              ),
              child: Stack(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Image.asset(
                      'assets/images/categories.jpg',
                      width: double.infinity,
                      height: 150,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) {
                        return Container(color: Colors.grey[300]);
                      },
                    ),
                  ),
                  Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      color: Colors.black.withValues(alpha: 0.3),
                    ),
                    child: const Center(
                      child: Padding(
                        padding: EdgeInsets.all(16),
                        child: Text(
                          'ETB 0 Delivery Fee with selected yogurt products',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),
          _ProductSection(
            title: 'Fruits & Vegetables',
            products: [
              _Product(name: 'Organic Banana', price: 20, quantity: '1 banana', imageUrl: 'assets/images/categories.jpg'),
              _Product(name: 'Medium Hass Avocado', price: 40, quantity: '1 avocado', imageUrl: 'assets/images/categories.jpg'),
              _Product(name: 'Large Hot House Tomato', price: 104, quantity: '1 tomato', imageUrl: 'assets/images/categories.jpg'),
            ],
            onProductTap: null,
          ),
          const SizedBox(height: 24),
          _ProductSection(
            title: 'Beverages',
            products: [
              _Product(name: 'Coca-Cola Zero Sugar Cola Soda', price: 80, quantity: '12 x 12 fl oz', imageUrl: 'assets/images/categories.jpg'),
              _Product(name: 'Simply Pulp Free Orange Juice', price: 549, quantity: '52 fl oz', imageUrl: 'assets/images/categories.jpg'),
              _Product(name: 'Signature Refresh Purified Water', price: 439, quantity: '24 x 16 fl oz', imageUrl: 'assets/images/categories.jpg'),
            ],
            onProductTap: null,
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _buildProductsContent() {
    final grouped = <int?, List<CategoriesProductsModel>>{};
    for (final p in _activeProducts) {
      grouped.putIfAbsent(p.category_id, () => []).add(p);
    }
    final sections = grouped.entries.toList();
    if (sections.isEmpty) return const Center(child: Text('No products'));
    return Stack(
      children: [
        SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (widget.vendor == null &&
                  widget.storeImage != null &&
                  widget.storeImage!.isNotEmpty)
                ClipRRect(
                  child: FallbackNetworkImage(
                    url: widget.storeImage!,
                    height: 150,
                    width: double.infinity,
                    fit: BoxFit.cover,
                    errorBuilder: (_) => const SizedBox.shrink(),
                  ),
                )
              else if (widget.vendor == null)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Container(
                    height: 100,
                    decoration: BoxDecoration(
                      color: Colors.grey[200],
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Center(
                      child: Text(
                        'ETB 0 Delivery Fee with selected products',
                        style: TextStyle(
                          color: Colors.black54,
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ),
                ),
              if (widget.vendor == null) const SizedBox(height: 24),
              ...sections.map((e) {
                final title = e.key != null ? 'Category ${e.key}' : 'Products';
                return Padding(
                  padding: const EdgeInsets.only(bottom: 24),
                  child: _ProductSectionFromModel(
                    title: title,
                    products: e.value,
                    cartItems: _cartItems,
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
                        ? const CircularProgressIndicator()
                        : TextButton(
                            onPressed: () => _loadVendorProducts(
                              page: _currentPage + 1,
                              loadMore: true,
                            ),
                            child: const Text('Load more'),
                          ),
                  ),
                ),
              if (_totalItems > 0) const SizedBox(height: 80),
              const SizedBox(height: 24),
            ],
          ),
        ),
        if (_totalItems > 0)
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: Container(
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
              child: Row(
                children: [
                  const Icon(
                    Icons.shopping_bag_outlined,
                    color: Colors.white,
                    size: 22,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'TOTAL ITEMS: $_totalItems',
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
                    'ETB${_totalPrice.toStringAsFixed(1)}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                    maxLines: 1,
                  ),
                  const SizedBox(width: 8),
                  TextButton(
                    onPressed: _goToCart,
                    style: TextButton.styleFrom(
                      backgroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                      minimumSize: Size.zero,
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                    child: const FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Text(
                        'Go to Checkout',
                        style: TextStyle(
                          color: AppColors.primaryColor,
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }

  void _goToCart() async {
    if (GuestBrowseService().isGuestBrowseMode) {
      final l10n = AppLocalizations.of(context)!;
      await showGuestSignInRequiredDialog(
        context,
        message: l10n.guestSignInRequiredCheckout,
      );
      return;
    }
    final List<Map<String, dynamic>> cartItems = _cartItems.entries.map((entry) {
      final productId = entry.key;
      final quantity = entry.value;
      final product = _productById(productId);
      if (product == null) {
        throw StateError('Product not found');
      }
      final price = product.discount_price?.isNotEmpty == true
          ? double.tryParse(product.discount_price!) ?? 0.0
          : double.tryParse(product.price ?? '0') ?? 0.0;
      return {
        'id': product.id,
        'productId': product.id,
        'product_id': product.id,
        'vendor_id': product.vendor_id ?? widget.vendorId,
        'name': product.name,
        'image': product.image_path,
        'price': price,
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
            child: ClipRRect(
              borderRadius: BorderRadius.circular(24),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                child: Material(
                  color: Colors.black.withValues(alpha: 0.28),
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
                    color: Colors.white,
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
                    branches.map((b) => b.name).join(' · '),
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.white.withValues(alpha: 0.85),
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
                          color: Colors.white.withValues(alpha: 0.14),
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                            color: Colors.white.withValues(alpha: 0.22),
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
                                color: Colors.white,
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
                                      fontSize: 11,
                                      fontWeight: FontWeight.w600,
                                      color: Colors.white
                                          .withValues(alpha: 0.75),
                                      letterSpacing: 0.4,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    '${vendor.openingTime ?? '—'}  →  ${vendor.closingTime ?? '—'}',
                                    style: const TextStyle(
                                      fontSize: 15,
                                      fontWeight: FontWeight.w700,
                                      color: Colors.white,
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
                      fontSize: 13,
                      color: Colors.white.withValues(alpha: 0.88),
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
            colors: [
              AppColors.primaryLightColor,
              AppColors.primaryColor,
              AppColors.primaryDarkColor,
            ],
          ),
        ),
        child: const Center(
          child: Icon(
            Icons.storefront_rounded,
            size: 88,
            color: Colors.white38,
          ),
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
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }
}

class _CategoryTab extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _CategoryTab({
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primaryColor : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? AppColors.primaryColor : AppColors.primaryColor,
            width: 1.5,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: isSelected ? Colors.white : AppColors.primaryColor,
          ),
        ),
      ),
    );
  }
}

class _ProductSection extends StatelessWidget {
  final String title;
  final List<_Product> products;
  final void Function(int productId)? onProductTap;

  const _ProductSection({
    required this.title,
    required this.products,
    this.onProductTap,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF2C3E50),
                ),
              ),
              TextButton(
                onPressed: () {},
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text(
                      'see all',
                      style: TextStyle(
                        fontSize: 14,
                        color: Color(0xFF2C3E50),
                      ),
                    ),
                    const SizedBox(width: 4),
                    Icon(
                      Icons.arrow_forward,
                      size: 16,
                      color: Colors.grey[600],
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: 200,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: products.length,
              itemBuilder: (context, index) {
                final product = products[index];
                return Padding(
                  padding: EdgeInsets.only(
                    right: index < products.length - 1 ? 12 : 0,
                  ),
                  child: _ProductCard(product: product, onProductTap: onProductTap != null ? (_) => onProductTap!(0) : null),
                );
              },
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
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF2C3E50),
                ),
              ),
              TextButton(
                onPressed: () {},
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text('see all', style: TextStyle(fontSize: 14, color: Color(0xFF2C3E50))),
                    const SizedBox(width: 4),
                    Icon(Icons.arrow_forward, size: 16, color: Colors.grey[600]),
                  ],
                ),
              ),
            ],
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
      ),
    );
  }
}

class _Product {
  final String name;
  final int price;
  final String quantity;
  final String imageUrl;

  _Product({
    required this.name,
    required this.price,
    required this.quantity,
    required this.imageUrl,
  });
}

class _ProductCard extends StatelessWidget {
  final _Product product;
  final void Function(int)? onProductTap;

  const _ProductCard({
    required this.product,
    this.onProductTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onProductTap != null ? () => onProductTap!(0) : null,
      child: Container(
      width: 150,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Colors.grey[200]!,
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          // Product Image
          Stack(
            children: [
              ClipRRect(
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(12),
                  topRight: Radius.circular(12),
                ),
                child: Image.asset(
                  product.imageUrl,
                  width: 150,
                  height: 110,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) {
                    return Container(
                      width: 150,
                      height: 110,
                      color: Colors.grey[200],
                      child: const Icon(
                        Icons.shopping_bag,
                        size: 40,
                        color: Colors.grey,
                      ),
                    );
                  },
                ),
              ),
              // Add to cart button
              Positioned(
                top: 8,
                right: 8,
                child: Container(
                  decoration: BoxDecoration(
                    color: AppColors.primaryColor,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.2),
                        blurRadius: 4,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: IconButton(
                    icon: const Icon(
                      Icons.add,
                      color: Colors.white,
                      size: 20,
                    ),
                    onPressed: () {
                      // TODO: Add to cart
                    },
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(
                      minWidth: 36,
                      minHeight: 36,
                    ),
                  ),
                ),
              ),
            ],
          ),
          // Product Details
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  product.name,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF2C3E50),
                    height: 1.2,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  'ETB ${product.price}',
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: AppColors.primaryColor,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  product.quantity,
                  style: TextStyle(
                    fontSize: 10,
                    color: Colors.grey[600],
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    ),
    );
  }
}
