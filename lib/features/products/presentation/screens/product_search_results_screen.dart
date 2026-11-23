import 'dart:async';

import 'package:flutter/material.dart';
import 'package:hudhud_delivery/core/api/api_service.dart';
import 'package:hudhud_delivery/core/l10n/context_l10n.dart';
import 'package:hudhud_delivery/features/categories/model/categories_products_model.dart';
import 'package:hudhud_delivery/features/categories/presentation/widgets/categories_widget.dart';
import 'package:hudhud_delivery/features/delivery/presentation/screens/product_detail_screen.dart';
import 'package:hudhud_delivery/app/services/cart_service.dart';
import 'package:hudhud_delivery/app/services/startup_location_service.dart';
import 'package:hudhud_delivery/features/growth/data/growth_repository.dart';
import 'package:hudhud_delivery/features/growth/data/models/sponsored.dart';
import 'package:hudhud_delivery/features/growth/growth_scope.dart';
import 'package:hudhud_delivery/features/growth/presentation/widgets/sponsored_widgets.dart';
import 'package:hudhud_delivery/features/products/data/products_data_provider.dart';
import 'package:hudhud_delivery/features/products/data/products_repository.dart';
import 'package:hudhud_delivery/features/products/model/products_query.dart';
import 'package:hudhud_delivery/features/products/presentation/widgets/product_price_filter_sheet.dart';
import 'package:hudhud_delivery/features/products/presentation/widgets/product_search_field.dart';
import 'package:hudhud_delivery/features/vendors/data/data_provider/vendors_data_provider.dart';
import 'package:hudhud_delivery/features/vendors/data/repository/vendors_repository.dart';
import 'package:hudhud_delivery/features/orders/data/models/vendor_model.dart';
import 'package:hudhud_delivery/features/delivery/presentation/screens/store_detail_screen.dart';

class ProductSearchResultsScreen extends StatefulWidget {
  final String initialSearch;

  const ProductSearchResultsScreen({
    super.key,
    this.initialSearch = '',
  });

  @override
  State<ProductSearchResultsScreen> createState() =>
      _ProductSearchResultsScreenState();
}

class _ProductSearchResultsScreenState extends State<ProductSearchResultsScreen> {
  late final ProductsRepository _productsRepository;
  late final VendorsRepository _vendorsRepository;

  /*
   * Shops matching what was typed.
   *
   * This screen only ever searched products, so a customer looking for a
   * restaurant they already know — which is most searches — got an empty
   * screen unless one of its dishes happened to share the name. The vendor
   * endpoint has taken a search term all along; nothing asked it.
   *
   * Fetched alongside the products rather than instead of them, and failing
   * on its own: a shop lookup that errors must not empty the product
   * results, which are the half that already worked.
   */
  List<VendorModel> _shops = const [];
  String _search = '';
  String? _minPrice;
  String? _maxPrice;
  List<CategoriesProductsModel> _products = [];
  bool _loading = false;
  bool _loadingMore = false;
  String? _error;
  int _currentPage = 1;
  bool _hasMore = false;

  // Phase 3: sponsored vendors above results (empty unless ads are on and
  // the server returns some — layout is unchanged otherwise).
  /*
   * The cart this screen adds to.
   *
   * Every callback here used to be `() {}` and the card was told
   * `isAdded: false, quantity: 0` on every rebuild, so ADD on a search
   * result did nothing at all and could not have shown it if it had.
   * Listened to, not read once, or the count on the card would not move
   * when the same product is added from somewhere else.
   */
  final CartService _cart = CartService();

  final GrowthRepository _growthRepository = GrowthRepository.create();
  List<SponsoredItem> _sponsored = const [];
  int _sponsoredRequestId = 0;

  @override
  void initState() {
    super.initState();
    _productsRepository = ProductsRepository(
      productsDataProvider: ProductsDataProvider(apiService: ApiService.instance),
    );
    _vendorsRepository = VendorsRepository(
      vendorsDataProvider: VendorsDataProvider(apiService: ApiService.instance),
    );
    _search = widget.initialSearch.trim();
    _cart.addListener(_onCartChanged);
    _fetch(page: 1);
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadSponsored());
  }

  @override
  void dispose() {
    _cart.removeListener(_onCartChanged);
    super.dispose();
  }

  void _onCartChanged() {
    if (mounted) setState(() {});
  }

  /*
   * Adding from a search result is the one place the cart's single-vendor
   * rule is actually likely to bite: these results span every shop, so the
   * next tap after adding a burger may well be a different restaurant. The
   * same confirmation the store screen uses is asked here rather than
   * silently refusing, which is what an empty callback amounted to.
   */
  Future<void> _addToCart(CategoriesProductsModel product) async {
    if (!product.canOrder) return;

    var result = _cart.addProduct(product);
    if (result == CartAddResult.differentVendor) {
      final replace = await _confirmReplaceCart();
      if (!mounted || replace != true) return;
      result = _cart.addProduct(product, replaceIfDifferentVendor: true);
    }
    if (result != CartAddResult.added || !mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('${product.name ?? 'Product'} added to cart'),
        duration: const Duration(seconds: 2),
      ),
    );
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

  Future<void> _loadSponsored() async {
    final requestId = ++_sponsoredRequestId;
    final query = _search.trim();
    final adsOn = mounted &&
        (growthControllerOf(context)?.adsEnabled ?? false);
    if (!adsOn || query.isEmpty) {
      if (mounted && _sponsored.isNotEmpty) {
        setState(() => _sponsored = const []);
      }
      return;
    }
    final location = StartupLocationService.cached;
    final items = await _growthRepository.fetchSponsored(
      placement: SponsoredPlacement.search,
      query: query,
      lat: location?.latitude,
      lng: location?.longitude,
    );
    if (!mounted || requestId != _sponsoredRequestId) return;
    setState(() => _sponsored = items);
  }

  Future<void> _fetch({required int page, bool loadMore = false}) async {
    if (loadMore) {
      setState(() => _loadingMore = true);
    } else {
      setState(() {
        _loading = true;
        _error = null;
      });
    }
    try {
      final result = await _productsRepository.getProducts(
        ProductsQuery.global(
          page: page,
          search: _search.isEmpty ? null : _search,
          minPrice: _minPrice,
          maxPrice: _maxPrice,
        ),
      );
      if (!mounted) return;
      // Only on a fresh search: paging through products must not re-ask for
      // the same shops on every Load more.
      if (!loadMore) {
        unawaited(_loadShops(_search));
      }
      setState(() {
        if (loadMore && page > 1) {
          _products = [..._products, ...result.items];
        } else {
          _products = result.items;
        }
        _currentPage = result.currentPage;
        _hasMore = result.hasMore;
        _loading = false;
        _loadingMore = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString();
        _loading = false;
        _loadingMore = false;
      });
    }
  }

  /// Shops whose name matches the term, failing on its own so a lookup that
  /// errors cannot empty the product results.
  Future<void> _loadShops(String term) async {
    final trimmed = term.trim();
    if (trimmed.length < 2) {
      if (mounted) setState(() => _shops = const []);
      return;
    }
    try {
      final shops = await _vendorsRepository.getVendors(
        page: 1,
        perPage: 10,
        search: trimmed,
      );
      if (!mounted || trimmed != _search.trim()) return;
      setState(() => _shops = shops);
    } catch (_) {
      if (mounted) setState(() => _shops = const []);
    }
  }

  void _openShop(VendorModel shop) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => StoreDetailScreen(
          storeName: shop.name,
          storeImage: shop.avatar.isNotEmpty ? shop.avatar : null,
          vendorId: shop.id,
          vendor: shop,
        ),
      ),
    );
  }

  void _onSearchChanged(String value) {
    _search = value;
    _fetch(page: 1);
    _loadSponsored();
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
    _fetch(page: 1);
  }

  void _showProductDetails(CategoriesProductsModel product) {
    if (product.id != null) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => ProductDetailScreen(productId: product.id!),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(context.l10n.searchProductsTitle),
        backgroundColor: Theme.of(context).colorScheme.surface,
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SizedBox(height: 8),
          ProductSearchField(
            hint: context.l10n.homeSearchHint,
            initialValue: widget.initialSearch,
            onSearchChanged: _onSearchChanged,
            onFilterTap: _openPriceFilter,
          ),
          if (_minPrice != null || _maxPrice != null)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              child: Text(
                'Price: ${_minPrice ?? '—'} – ${_maxPrice ?? '—'}',
                style: TextStyle(
                  fontSize: 12,
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
            ),
          // Shops first, then the things they sell. Somebody typing a
          // restaurant's name is looking for the restaurant.
          if (_shops.isNotEmpty) _ShopResultsRow(shops: _shops, onTap: _openShop),
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator())
                : _error != null
                    ? Center(
                        child: Padding(
                          padding: const EdgeInsets.all(24),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(_error!, textAlign: TextAlign.center),
                              const SizedBox(height: 16),
                              TextButton(
                                onPressed: () => _fetch(page: 1),
                                child: Text(context.l10n.actionRetry),
                              ),
                            ],
                          ),
                        ),
                      )
                    : _products.isEmpty
                        ? Center(
                            child: Text(
                              _search.isEmpty
                                  ? 'Enter a search term'
                                  : 'No products found',
                              style: TextStyle(
                                color: Theme.of(context)
                                    .colorScheme
                                    .onSurfaceVariant,
                              ),
                            ),
                          )
                        : RefreshIndicator(
                            onRefresh: () => _fetch(page: 1),
                            child: ListView.builder(
                              padding: const EdgeInsets.only(bottom: 24),
                              itemCount: _products.length +
                                  (_hasMore ? 1 : 0) +
                                  (_sponsored.isNotEmpty ? 1 : 0),
                              itemBuilder: (context, rawIndex) {
                                if (_sponsored.isNotEmpty && rawIndex == 0) {
                                  return SponsoredVendorRow(
                                    items: _sponsored,
                                    padding: const EdgeInsets.only(
                                      top: 8,
                                      bottom: 8,
                                    ),
                                  );
                                }
                                final index = _sponsored.isNotEmpty
                                    ? rawIndex - 1
                                    : rawIndex;
                                if (index == _products.length) {
                                  if (_loadingMore) {
                                    return const Padding(
                                      padding: EdgeInsets.all(16),
                                      child: Center(
                                        child: CircularProgressIndicator(),
                                      ),
                                    );
                                  }
                                  return Padding(
                                    padding: const EdgeInsets.all(16),
                                    child: Center(
                                      child: TextButton(
                                        onPressed: () => _fetch(
                                          page: _currentPage + 1,
                                          loadMore: true,
                                        ),
                                        child: Text(context.l10n.loadMore),
                                      ),
                                    ),
                                  );
                                }
                                final product = _products[index];
                                return ProductItem(
                                  product: product,
                                  name: product.name ?? 'Unknown',
                                  description:
                                      product.description ?? '',
                                  imageUrl: product.image_path ?? '',
                                  price: product.price ?? '0',
                                  discountPrice: product
                                              .discount_price?.isNotEmpty ==
                                          true
                                      ? product.discount_price
                                      : null,
                                  // Read from the cart, not hardcoded: the
                                  // card could not have shown a count even
                                  // if the buttons had done anything.
                                  isAdded: _cart.quantityFor(product.id) > 0,
                                  quantity: _cart.quantityFor(product.id),
                                  onAddPressed: () => _addToCart(product),
                                  onDecrementPressed: () => _cart
                                      .decrement(product.id.toString()),
                                  onIncrementPressed: () => _cart
                                      .increment(product.id.toString()),
                                  onTap: () => _showProductDetails(product),
                                );
                              },
                            ),
                          ),
          ),
        ],
      ),
    );
  }
}

/// The shops a search matched, above the products.
///
/// A row rather than a second list: it has to be obvious at a glance that the
/// shop you meant was found, without pushing the product results off screen
/// for everybody whose search matched a shop name by accident.
class _ShopResultsRow extends StatelessWidget {
  const _ShopResultsRow({required this.shops, required this.onTap});

  final List<VendorModel> shops;
  final void Function(VendorModel) onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
          child: Text(
            'Shops',
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
          ),
        ),
        SizedBox(
          height: 104,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: shops.length,
            separatorBuilder: (_, __) => const SizedBox(width: 12),
            itemBuilder: (context, index) {
              final shop = shops[index];
              return InkWell(
                onTap: () => onTap(shop),
                borderRadius: BorderRadius.circular(12),
                child: SizedBox(
                  width: 88,
                  child: Column(
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: shop.avatar.isNotEmpty
                            ? Image.network(
                                shop.avatar,
                                width: 64,
                                height: 64,
                                fit: BoxFit.cover,
                                errorBuilder: (_, __, ___) =>
                                    _ShopFallback(scheme: scheme),
                              )
                            : _ShopFallback(scheme: scheme),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        shop.name,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}

class _ShopFallback extends StatelessWidget {
  const _ShopFallback({required this.scheme});

  final ColorScheme scheme;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 64,
      height: 64,
      color: scheme.surfaceContainerHighest,
      child: Icon(Icons.storefront_outlined, color: scheme.onSurfaceVariant),
    );
  }
}
