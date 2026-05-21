import 'package:flutter/material.dart';

import 'package:flutter_bloc/flutter_bloc.dart';



import '../../../../core/theme/app_colors.dart';

import '../../bloc/categories_bloc.dart';

import '../../model/category_tree_model.dart';

import '../../model/categories_products_model.dart';

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



  @override

  Widget build(BuildContext context) {

    return Scaffold(

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

            final isLoading = state is FetchCategoriesProductsLoading &&

                !state.isLoadingMore;

            final isLoadingMore = state is FetchCategoriesProductsLoading &&

                state.isLoadingMore;



            return Stack(

              children: [

                RefreshIndicator(

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

                        const SizedBox(height: 8),

                        ProductSearchField(

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

                                  fontSize: 12, color: Colors.grey[600]),

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

                              child: CircularProgressIndicator(),

                            ),

                          )

                        else if (state is FetchCategoriesProductsFailure)

                          Center(

                            child: Padding(

                              padding: const EdgeInsets.all(32.0),

                              child: Column(

                                children: [

                                  Text(

                                    'Error: ${state.errorMessage}',

                                    style: const TextStyle(color: Colors.red),

                                  ),

                                  const SizedBox(height: 16),

                                  ElevatedButton(

                                    onPressed: _fetchProducts,

                                    child: const Text('Retry'),

                                  ),

                                ],

                              ),

                            ),

                          )

                        else ...[

                          Padding(

                            padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),

                            child: Row(

                              children: [

                                Icon(Icons.grid_view_rounded,

                                    size: 20, color: Colors.grey[700]),

                                const SizedBox(width: 8),

                                Text(

                                  'Products',

                                  style: TextStyle(

                                    fontSize: 17,

                                    fontWeight: FontWeight.w600,

                                    color: Colors.grey[800],

                                  ),

                                ),

                              ],

                            ),

                          ),

                          if (_filteredProducts.isEmpty)

                            Padding(

                              padding: const EdgeInsets.all(32),

                              child: Center(

                                child: Text(

                                  'No products found',

                                  style: TextStyle(color: Colors.grey[600]),

                                ),

                              ),

                            )

                          else

                            ListView.builder(

                              shrinkWrap: true,

                              physics: const NeverScrollableScrollPhysics(),

                              padding:

                                  const EdgeInsets.symmetric(horizontal: 16),

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

                                  discountPrice: product

                                              .discount_price?.isNotEmpty ==

                                          true

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

                                    ? const CircularProgressIndicator()

                                    : TextButton(

                                        onPressed: () => _fetchProducts(

                                          page: _currentPage + 1,

                                          loadMore: true,

                                        ),

                                        child: const Text('Load more'),

                                      ),

                              ),

                            ),

                        ],

                        if (_totalItems > 0) const SizedBox(height: 80),

                      ],

                    ),

                  ),

                ),

                if (_totalItems > 0)

                  Positioned(

                    left: 0,

                    right: 0,

                    bottom: 0,

                    child: Container(

                      padding: const EdgeInsets.symmetric(

                          horizontal: 24, vertical: 16),

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

                                onPressed: () {

                                  final List<Map<String, dynamic>> cartItems =

                                      _cartItems.entries.map((entry) {

                                    final productId = entry.key;

                                    final quantity = entry.value;

                                    final product =

                                        _filteredProducts.firstWhere(

                                      (p) => p.id.toString() == productId,

                                      orElse: () => _products.firstWhere(

                                        (p) => p.id.toString() == productId,

                                        orElse: () => throw Exception(

                                            'Product not found'),

                                      ),

                                    );



                                    return {

                                      'id': product.id,

                                      'productId': product.id,

                                      'product_id': product.id,

                                      'vendor_id': product.vendor_id,

                                      'name': product.name,

                                      'image': product.image_path,

                                      'price': double.tryParse(

                                              product.price ?? '0') ??

                                          0.0,

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

                                },

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

          },

        ),

      ),

    );

  }

}


