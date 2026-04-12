import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:hudhud_delivery/core/api/api_service.dart';
import 'package:hudhud_delivery/core/theme/app_colors.dart';
import 'package:hudhud_delivery/features/categories/model/categories_products_model.dart';
import 'package:hudhud_delivery/features/categories/presentation/widgets/categories_widget.dart';
import 'package:hudhud_delivery/features/checkout/presentation/screen/checkout_screen.dart';
import 'package:hudhud_delivery/features/delivery/presentation/screens/product_detail_screen.dart';
import 'package:hudhud_delivery/features/orders/data/models/vendor_model.dart';
import 'package:hudhud_delivery/features/vendors/data/data_provider/vendors_data_provider.dart';
import 'package:hudhud_delivery/features/vendors/data/repository/vendors_repository.dart';

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
  final TextEditingController _searchController = TextEditingController();

  List<CategoriesProductsModel> _products = [];
  bool _productsLoading = false;
  String? _productsError;
  late final VendorsRepository _vendorsRepository;

  /// Cart: productId -> quantity (same pattern as categories screen).
  final Map<String, int> _cartItems = {};

  @override
  void initState() {
    super.initState();
    _vendorsRepository = VendorsRepository(
      vendorsDataProvider: VendorsDataProvider(apiService: ApiService.instance),
    );
    if (widget.vendorId != null) {
      _loadVendorProducts();
    }
  }

  Future<void> _loadVendorProducts() async {
    final vendorId = widget.vendorId;
    if (vendorId == null) return;
    setState(() {
      _productsLoading = true;
      _productsError = null;
    });
    try {
      final list = await _vendorsRepository.getVendorProducts(vendorId);
      setState(() {
        _products = list;
        _productsLoading = false;
      });
    } catch (e) {
      setState(() {
        _productsError = e.toString();
        _productsLoading = false;
      });
    }
  }

  void _addToCart(String productId) {
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
      try {
        final product = _products.firstWhere(
          (p) => p.id.toString() == productId,
        );
        final price = product.discount_price?.isNotEmpty == true
            ? double.tryParse(product.discount_price!) ?? 0
            : double.tryParse(product.price ?? '0') ?? 0;
        total += price * quantity;
      } catch (_) {}
    });
    return total;
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
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
            // Search Bar
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: BorderRadius.circular(12),
                ),
                child: TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    hintText: 'Search stores and produ...',
                    hintStyle: TextStyle(color: Colors.grey[600]),
                    prefixIcon: Icon(
                      Icons.search,
                      color: Colors.grey[600],
                    ),
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                  ),
                ),
              ),
            ),
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
                  : _productsLoading
                      ? const Center(child: CircularProgressIndicator())
                      : _productsError != null
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
                          : _products.isEmpty
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
                      color: Colors.black.withOpacity(0.3),
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
    for (final p in _products) {
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
              if (widget.storeImage != null && widget.storeImage!.isNotEmpty)
                ClipRRect(
                  child: Image.network(
                    widget.storeImage!,
                    height: 150,
                    width: double.infinity,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => const SizedBox.shrink(),
                  ),
                )
              else
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
              const SizedBox(height: 24),
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
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 10,
                    offset: const Offset(0, -5),
                  ),
                ],
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      const Icon(
                        Icons.shopping_bag_outlined,
                        color: Colors.white,
                      ),
                      const SizedBox(width: 12),
                      Text(
                        'TOTAL ITEMS: $_totalItems',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                  Row(
                    children: [
                      Text(
                        'ETB${_totalPrice.toStringAsFixed(1)}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(width: 16),
                      TextButton(
                        onPressed: _goToCart,
                        style: TextButton.styleFrom(
                          backgroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 8,
                          ),
                        ),
                        child: Text(
                          'Go to Checkout',
                          style: TextStyle(
                            color: AppColors.primaryColor,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }

  void _goToCart() {
    final List<Map<String, dynamic>> cartItems = _cartItems.entries.map((entry) {
      final productId = entry.key;
      final quantity = entry.value;
      final product = _products.firstWhere(
        (p) => p.id.toString() == productId,
      );
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
  final VendorModel vendor;
  final VoidCallback onBack;

  const _VendorDetailHeader({
    required this.vendor,
    required this.onBack,
  });

  @override
  Widget build(BuildContext context) {
    final hasBanner = vendor.bannerPath != null && vendor.bannerPath!.isNotEmpty;
    final logoUrl = vendor.avatar.isNotEmpty ? vendor.avatar : null;

    return SizedBox(
      height: 200,
      child: Stack(
        children: [
          // Banner or gradient background
          Container(
            height: 200,
            width: double.infinity,
            decoration: BoxDecoration(
              gradient: hasBanner
                  ? null
                  : LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        AppColors.primaryColor.withOpacity(0.85),
                        AppColors.primaryColor,
                        AppColors.primaryDarkColor,
                      ],
                    ),
            ),
            child: hasBanner
                ? Image.network(
                    vendor.bannerPath!,
                    fit: BoxFit.cover,
                    width: double.infinity,
                    height: double.infinity,
                    errorBuilder: (_, __, ___) => _gradientFallback(),
                  )
                : _gradientFallback(),
          ),
          // Dark overlay for readability
          Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.black.withOpacity(0.2),
                    Colors.black.withOpacity(0.5),
                    Colors.black.withOpacity(0.75),
                  ],
                ),
              ),
            ),
          ),
          // Back button
          Positioned(
            top: 8,
            left: 8,
            child: ClipRRect(
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
                child: Material(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(24),
                  child: InkWell(
                    onTap: onBack,
                    borderRadius: BorderRadius.circular(24),
                    child: const Padding(
                      padding: EdgeInsets.all(10),
                      child: Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white, size: 20),
                    ),
                  ),
                ),
              ),
            ),
          ),
          // Bottom content: logo + name + details
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 24, 20, 20),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  // Logo
                  Container(
                    width: 72,
                    height: 72,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 3),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.25),
                          blurRadius: 12,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: ClipOval(
                      child: logoUrl != null && logoUrl.startsWith('http')
                          ? Image.network(
                              logoUrl,
                              fit: BoxFit.cover,
                              width: 72,
                              height: 72,
                              errorBuilder: (_, __, ___) => _logoPlaceholder(),
                            )
                          : _logoPlaceholder(),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          vendor.name,
                          style: const TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                            letterSpacing: -0.5,
                            shadows: [
                              Shadow(color: Colors.black26, offset: Offset(0, 1), blurRadius: 4),
                            ],
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        if (vendor.cuisineType != null && vendor.cuisineType!.isNotEmpty) ...[
                          const SizedBox(height: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.25),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              vendor.cuisineType!,
                              style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ],
                        if (vendor.openingTime != null || vendor.closingTime != null) ...[
                          const SizedBox(height: 6),
                          Row(
                            children: [
                              Icon(Icons.schedule_rounded, size: 14, color: Colors.white.withOpacity(0.9)),
                              const SizedBox(width: 4),
                              Text(
                                '${vendor.openingTime ?? '—'} – ${vendor.closingTime ?? '—'}',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.white.withOpacity(0.95),
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ],
                        if (vendor.description != null && vendor.description!.isNotEmpty) ...[
                          const SizedBox(height: 6),
                          Text(
                            vendor.description!,
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.white.withOpacity(0.9),
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
            AppColors.primaryColor.withOpacity(0.9),
            AppColors.primaryColor,
            AppColors.primaryDarkColor,
          ],
        ),
      ),
    );

  Widget _logoPlaceholder() => Container(
      color: Colors.white.withOpacity(0.3),
      child: const Icon(Icons.store_rounded, size: 36, color: Colors.white70),
    );
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
                        color: Colors.black.withOpacity(0.2),
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
                  style: TextStyle(
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
