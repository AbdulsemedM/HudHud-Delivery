import 'package:flutter/material.dart';
import 'package:hudhud_delivery/core/api/api_service.dart';
import 'package:hudhud_delivery/core/l10n/context_l10n.dart';
import 'package:hudhud_delivery/features/categories/model/categories_products_model.dart';
import 'package:hudhud_delivery/features/categories/presentation/widgets/categories_widget.dart';
import 'package:hudhud_delivery/features/delivery/presentation/screens/product_detail_screen.dart';
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
  final GrowthRepository _growthRepository = GrowthRepository.create();
  List<SponsoredItem> _sponsored = const [];
  int _sponsoredRequestId = 0;

  @override
  void initState() {
    super.initState();
    _productsRepository = ProductsRepository(
      productsDataProvider: ProductsDataProvider(apiService: ApiService.instance),
    );
    _search = widget.initialSearch.trim();
    _fetch(page: 1);
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadSponsored());
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
                                  isAdded: false,
                                  quantity: 0,
                                  onAddPressed: () {},
                                  onDecrementPressed: () {},
                                  onIncrementPressed: () {},
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
