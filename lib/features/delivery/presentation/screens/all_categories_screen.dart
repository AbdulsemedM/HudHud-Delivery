import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shimmer/shimmer.dart';
import 'package:hudhud_delivery/core/api/api_service.dart';
import 'package:hudhud_delivery/core/l10n/context_l10n.dart';
import 'package:hudhud_delivery/core/theme/app_colors.dart';
import 'package:hudhud_delivery/core/widgets/fallback_network_image.dart';
import 'package:hudhud_delivery/features/categories/bloc/categories_bloc.dart';
import 'package:hudhud_delivery/features/categories/data/data_provider/categories_data_provider.dart';
import 'package:hudhud_delivery/features/categories/data/repository/categories_repository.dart';
import 'package:hudhud_delivery/features/categories/model/category_tree_model.dart';
import 'package:hudhud_delivery/features/categories/presentation/screens/categories_screen.dart';
import 'package:hudhud_delivery/features/delivery/presentation/screens/product_detail_screen.dart';
import 'package:hudhud_delivery/features/delivery/presentation/screens/store_detail_screen.dart';
import 'package:hudhud_delivery/features/home/presentation/theme/home_colors.dart';
import 'package:hudhud_delivery/features/orders/data/models/vendor_model.dart';
import 'package:hudhud_delivery/features/products/data/products_data_provider.dart';
import 'package:hudhud_delivery/features/products/data/products_repository.dart';
import 'package:hudhud_delivery/features/products/model/popular_product_model.dart';
import 'package:hudhud_delivery/features/products/presentation/screens/product_search_results_screen.dart';
import 'package:hudhud_delivery/features/products/presentation/widgets/product_search_field.dart';
import 'package:hudhud_delivery/features/vendors/data/data_provider/vendors_data_provider.dart';
import 'package:hudhud_delivery/features/vendors/data/repository/vendors_repository.dart';

class AllCategoriesScreen extends StatelessWidget {
  /// When true (e.g. home Food & groceries tab), no [Scaffold] app bar — fills parent only.
  const AllCategoriesScreen({super.key, this.embedded = false});

  final bool embedded;

  @override
  Widget build(BuildContext context) {
    final repository = CategoriesRepository(
      categoriesDataProvider: CategoriesDataProvider(
        apiService: ApiService.instance,
      ),
    );
    final productsRepository = ProductsRepository(
      productsDataProvider: ProductsDataProvider(apiService: ApiService.instance),
    );
    return BlocProvider(
      create: (context) => CategoriesBloc(repository, productsRepository)
        ..add(FetchCategoriesListEvent()),
      child: _AllCategoriesBody(embedded: embedded),
    );
  }
}

class _AllCategoriesBody extends StatefulWidget {
  const _AllCategoriesBody({required this.embedded});

  final bool embedded;

  @override
  State<_AllCategoriesBody> createState() => _AllCategoriesBodyState();
}

class _AllCategoriesBodyState extends State<_AllCategoriesBody> {
  bool _showAllCategories = false;

  List<VendorModel> _vendors = [];
  bool _vendorsLoading = true;
  String? _vendorsError;
  List<PopularProductModel> _popularProducts = [];
  bool _popularLoading = true;
  late final VendorsRepository _vendorsRepository;
  late final ProductsRepository _productsRepository;

  @override
  void initState() {
    super.initState();
    _vendorsRepository = VendorsRepository(
      vendorsDataProvider: VendorsDataProvider(apiService: ApiService.instance),
    );
    _productsRepository = ProductsRepository(
      productsDataProvider: ProductsDataProvider(apiService: ApiService.instance),
    );
    _loadVendors();
    _loadPopularProducts();
  }

  Future<void> _onPullToRefresh() async {
    if (!mounted) return;
    context.read<CategoriesBloc>().add(FetchCategoriesListEvent());
    await Future.wait([
      _loadVendors(),
      _loadPopularProducts(),
    ]);
  }

  Future<void> _loadVendors() async {
    if (!mounted) return;
    setState(() {
      _vendorsLoading = true;
      _vendorsError = null;
    });
    try {
      final list = await _vendorsRepository.getVendors(page: 1);
      if (!mounted) return;
      setState(() {
        _vendors = list;
        _vendorsLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _vendorsError = e.toString();
        _vendorsLoading = false;
      });
    }
  }

  Future<void> _loadPopularProducts() async {
    if (!mounted) return;
    setState(() => _popularLoading = true);
    try {
      final list = await _productsRepository.getPopularProducts();
      if (!mounted) return;
      if (kDebugMode) {
        debugPrint('Popular products loaded: ${list.length}');
      }
      setState(() {
        _popularProducts = list;
        _popularLoading = false;
      });
    } catch (e, st) {
      if (kDebugMode) {
        debugPrint('Popular products failed: $e\n$st');
      }
      if (!mounted) return;
      setState(() {
        _popularProducts = [];
        _popularLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final textTheme = theme.textTheme;
    final embedded = widget.embedded;
    final searchHint = embedded
        ? context.l10n.homeSearchHint
        : 'Search products everywhere';

    final gridBody = BlocBuilder<CategoriesBloc, CategoriesState>(
      buildWhen: (prev, curr) =>
          curr is FetchCategoriesListLoading ||
          curr is FetchCategoriesListSuccess ||
          curr is FetchCategoriesListFailure,
      builder: (context, state) {
        if (state is FetchCategoriesListLoading) {
          return const _LoadingState();
        }
        if (state is FetchCategoriesListFailure) {
          // Still show popular products when categories fail — don't hide the section.
          if (_popularLoading || _popularProducts.isNotEmpty) {
            return _CategoriesGrid(
              categories: const [],
              showAll: true,
              vendors: _vendors,
              vendorsLoading: _vendorsLoading,
              vendorsError: _vendorsError,
              popularProducts: _popularProducts,
              popularLoading: _popularLoading,
              onCategoryTap: (category) => _onCategoryTap(context, category),
              onShowMore: () => setState(() => _showAllCategories = true),
              usePullToRefresh: true,
              onPullToRefresh: _onPullToRefresh,
              embedded: embedded,
              categoriesError: state.errorMessage,
              onCategoriesRetry: () => context
                  .read<CategoriesBloc>()
                  .add(FetchCategoriesListEvent()),
            );
          }
          return _ErrorState(
            message: state.errorMessage,
            onRetry: () =>
                context.read<CategoriesBloc>().add(FetchCategoriesListEvent()),
          );
        }
        if (state is FetchCategoriesListSuccess) {
          final categories = state.result.items;
          if (categories.isEmpty &&
              !_popularLoading &&
              _popularProducts.isEmpty) {
            return const _EmptyState();
          }
          return _CategoriesGrid(
            categories: categories,
            showAll: _showAllCategories,
            vendors: _vendors,
            vendorsLoading: _vendorsLoading,
            vendorsError: _vendorsError,
            popularProducts: _popularProducts,
            popularLoading: _popularLoading,
            onCategoryTap: (category) => _onCategoryTap(context, category),
            onShowMore: () => setState(() => _showAllCategories = true),
            usePullToRefresh: true,
            onPullToRefresh: _onPullToRefresh,
            embedded: embedded,
          );
        }
        // Initial / other states: still surface popular if already loaded.
        if (_popularLoading || _popularProducts.isNotEmpty) {
          return _CategoriesGrid(
            categories: const [],
            showAll: true,
            vendors: _vendors,
            vendorsLoading: _vendorsLoading,
            vendorsError: _vendorsError,
            popularProducts: _popularProducts,
            popularLoading: _popularLoading,
            onCategoryTap: (category) => _onCategoryTap(context, category),
            onShowMore: () => setState(() => _showAllCategories = true),
            usePullToRefresh: true,
            onPullToRefresh: _onPullToRefresh,
            embedded: embedded,
          );
        }
        return const SizedBox.shrink();
      },
    );

    final body = Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SizedBox(height: 8),
        ProductSearchField(
          hint: searchHint,
          readOnly: true,
          fillColor: embedded ? HomeColors.surfaceElevated : null,
          hintColor: embedded ? HomeColors.textMuted : null,
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => const ProductSearchResultsScreen(),
              ),
            );
          },
          onSearchChanged: (_) {},
        ),
        const SizedBox(height: 8),
        Expanded(child: gridBody),
      ],
    );

    if (embedded) {
      final themed = Theme(
        data: HomeColors.darkTheme(theme),
        child: ColoredBox(
          color: HomeColors.background,
          child: body,
        ),
      );
      return themed;
    }

    return Scaffold(
      backgroundColor: colorScheme.surface,
      appBar: AppBar(
        title: Text(
          'All categories',
          style: textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w600,
            fontSize: 18,
          ),
        ),
        backgroundColor: colorScheme.surface,
        elevation: 0,
        scrolledUnderElevation: 2,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
          color: colorScheme.onSurface,
          onPressed: () => Navigator.pop(context),
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(
            color: colorScheme.outline.withValues(alpha: 0.35),
            height: 1,
          ),
        ),
      ),
      body: body,
    );
  }

  void _onCategoryTap(BuildContext context, CategoryTreeModel category) {
    final categoriesBloc = context.read<CategoriesBloc>();
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => BlocProvider.value(
          value: categoriesBloc,
          child: CategoriesScreen(
            categoryId: category.id,
            categoryName: category.name,
            categoryImage: category.displayImageUrl ?? '',
            category: category,
          ),
        ),
      ),
    );
  }
}

class _LoadingState extends StatelessWidget {
  const _LoadingState();

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final shimmerBase = isDark ? const Color(0xFF2B2B2B) : Colors.grey[300]!;
    final shimmerHighlight = isDark ? const Color(0xFF3A3A3A) : Colors.grey[100]!;
    final blockColor = isDark ? const Color(0xFF1F1F1F) : Colors.white;
    return Shimmer.fromColors(
      baseColor: shimmerBase,
      highlightColor: shimmerHighlight,
      child: CustomScrollView(
        slivers: [
          // Categories title
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 20, 16, 8),
              child: Container(
                height: 24,
                width: 160,
                decoration: BoxDecoration(
                  color: blockColor,
                  borderRadius: BorderRadius.circular(6),
                ),
              ),
            ),
          ),
          // Categories grid
          SliverPadding(
            padding: const EdgeInsets.all(16),
            sliver: SliverGrid(
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 4,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
                childAspectRatio: 0.72,
              ),
              delegate: SliverChildBuilderDelegate(
                (context, index) => _CategorySkeleton(),
                childCount: 8,
              ),
            ),
          ),
          const SliverToBoxAdapter(child: SizedBox(height: 8)),
          // Vendors section title
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
              child: Container(
                height: 20,
                width: 140,
                decoration: BoxDecoration(
                  color: blockColor,
                  borderRadius: BorderRadius.circular(6),
                ),
              ),
            ),
          ),
          // Vendors horizontal row
          SliverToBoxAdapter(
            child: SizedBox(
              height: 130,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 12),
                itemCount: 6,
                itemBuilder: (context, index) {
                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 72,
                          height: 72,
                          decoration: BoxDecoration(
                            color: blockColor,
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Container(
                          width: 70,
                          height: 10,
                          decoration: BoxDecoration(
                            color: blockColor,
                            borderRadius: BorderRadius.circular(4),
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
          ),
          const SliverToBoxAdapter(child: SizedBox(height: 16)),
          // Most Popular title
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
              child: Container(
                height: 20,
                width: 160,
                decoration: BoxDecoration(
                  color: blockColor,
                  borderRadius: BorderRadius.circular(6),
                ),
              ),
            ),
          ),
          // Popular Orders card skeletons
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            sliver: SliverList(
              delegate: SliverChildBuilderDelegate(
                (context, index) => Padding(
                  padding: const EdgeInsets.only(bottom: 16),
                  child: _PopularOrderSkeleton(),
                ),
                childCount: 3,
              ),
            ),
          ),
          const SliverToBoxAdapter(child: SizedBox(height: 24)),
        ],
      ),
    );
  }
}

class _PopularOrderSkeleton extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardColor = isDark ? const Color(0xFF1F1F1F) : Colors.white;
    return Container(
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            height: 160,
            width: double.infinity,
            decoration: BoxDecoration(
              color: cardColor,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(12),
                topRight: Radius.circular(12),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  height: 16,
                  width: 180,
                  decoration: BoxDecoration(
                    color: cardColor,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
                const SizedBox(height: 8),
                Container(
                  height: 12,
                  width: 220,
                  decoration: BoxDecoration(
                    color: cardColor,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _CategorySkeleton extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardColor = isDark ? const Color(0xFF1F1F1F) : Colors.white;
    return Container(
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: cardColor,
              borderRadius: BorderRadius.circular(10),
            ),
          ),
          const SizedBox(height: 6),
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 8),
            height: 8,
            decoration: BoxDecoration(
              color: cardColor,
              borderRadius: BorderRadius.circular(4),
            ),
          ),
          const SizedBox(height: 4),
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 12),
            height: 6,
            decoration: BoxDecoration(
              color: cardColor,
              borderRadius: BorderRadius.circular(4),
            ),
          ),
        ],
      ),
    );
  }
}

class _ErrorState extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;

  const _ErrorState({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final textTheme = theme.textTheme;
    final colorScheme = theme.colorScheme;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppColors.errorColor.withValues(alpha: 0.08),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.error_outline_rounded,
                size: 48,
                color: AppColors.errorColor,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'Something went wrong',
              style: textTheme.titleMedium?.copyWith(
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              message,
              textAlign: TextAlign.center,
              style: textTheme.bodyMedium?.copyWith(
                fontSize: 14,
                color: colorScheme.onSurface.withValues(alpha: 0.75),
                height: 1.4,
              ),
            ),
            const SizedBox(height: 24),
            FilledButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh_rounded, size: 18),
              label: const Text('Try again'),
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.primaryColor,
                foregroundColor: Colors.white,
                padding:
                    const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final textTheme = theme.textTheme;
    final colorScheme = theme.colorScheme;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: colorScheme.onSurface.withValues(alpha: 0.12),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.category_outlined,
                size: 56,
                color: colorScheme.onSurface.withValues(alpha: 0.55),
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'No categories yet',
              style: textTheme.titleMedium?.copyWith(
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Check back later for new categories',
              textAlign: TextAlign.center,
              style: textTheme.bodyMedium?.copyWith(
                fontSize: 14,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CategoriesGrid extends StatelessWidget {
  final List<CategoryTreeModel> categories;
  final bool showAll;
  final List<VendorModel> vendors;
  final bool vendorsLoading;
  final String? vendorsError;
  final List<PopularProductModel> popularProducts;
  final bool popularLoading;
  final void Function(CategoryTreeModel) onCategoryTap;
  final VoidCallback onShowMore;
  final bool usePullToRefresh;
  final Future<void> Function() onPullToRefresh;
  final bool embedded;
  final String? categoriesError;
  final VoidCallback? onCategoriesRetry;

  const _CategoriesGrid({
    required this.categories,
    required this.showAll,
    required this.vendors,
    required this.vendorsLoading,
    required this.vendorsError,
    required this.popularProducts,
    required this.popularLoading,
    required this.onCategoryTap,
    required this.onShowMore,
    this.usePullToRefresh = false,
    required this.onPullToRefresh,
    this.embedded = false,
    this.categoriesError,
    this.onCategoriesRetry,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final textTheme = theme.textTheme;
    final displayCategories = showAll ? categories : categories.take(3).toList();
    final hasMore = categories.length > 3 && !showAll;
    final titleColor = embedded ? HomeColors.textPrimary : null;
    final accentColor = embedded ? HomeColors.orange : AppColors.primaryColor;

    TextStyle? sectionTitle(TextStyle? base, {double? fontSize}) =>
        base?.copyWith(
          fontSize: fontSize,
          fontWeight: FontWeight.bold,
          color: titleColor,
        );

    final popularSlivers = <Widget>[
      if (popularLoading) ...[
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
            child: Text(
              'Most Popular',
              style: sectionTitle(textTheme.titleLarge, fontSize: 20),
            ),
          ),
        ),
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          sliver: SliverList(
            delegate: SliverChildBuilderDelegate(
              (_, __) => Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: _PopularOrderSkeleton(),
              ),
              childCount: 2,
            ),
          ),
        ),
      ] else if (popularProducts.isNotEmpty) ...[
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    'Most Popular',
                    style: sectionTitle(textTheme.titleLarge, fontSize: 20),
                  ),
                ),
                if (embedded)
                  Text(
                    'View all',
                    style: textTheme.labelLarge?.copyWith(
                      color: accentColor,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
              ],
            ),
          ),
        ),
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          sliver: SliverList(
            delegate: SliverChildBuilderDelegate(
              (context, index) {
                final item = popularProducts[index];
                return Padding(
                  padding: const EdgeInsets.only(bottom: 16),
                  child: _PopularProductCard(
                    item: item,
                    embedded: embedded,
                    onTap: () {
                      final productId = item.product.id;
                      if (productId == null) return;
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => ProductDetailScreen(
                            productId: productId,
                          ),
                        ),
                      );
                    },
                    onShopTap: item.shopId != null
                        ? () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => StoreDetailScreen(
                                  storeName: item.shopName ?? 'Store',
                                  storeImage: item.shopLogoUrl,
                                  vendorId: item.shopId,
                                ),
                              ),
                            );
                          }
                        : null,
                  ),
                );
              },
              childCount: popularProducts.length,
            ),
          ),
        ),
      ],
    ];

    final view = CustomScrollView(
      physics: usePullToRefresh
          ? const AlwaysScrollableScrollPhysics()
          : null,
      slivers: [
        if (categoriesError != null) ...[
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Could not load categories',
                    style: sectionTitle(textTheme.titleMedium, fontSize: 16),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    categoriesError!,
                    style: textTheme.bodySmall?.copyWith(
                      color: embedded ? HomeColors.textMuted : null,
                    ),
                  ),
                  if (onCategoriesRetry != null) ...[
                    const SizedBox(height: 8),
                    TextButton(
                      onPressed: onCategoriesRetry,
                      child: const Text('Retry'),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ] else if (categories.isNotEmpty) ...[
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 20, 16, 8),
              child: Text(
                showAll ? 'All categories' : 'Categories',
                style: sectionTitle(textTheme.titleLarge, fontSize: 20),
              ),
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            sliver: SliverGrid(
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 4,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
                // Taller cells so product PNGs show full height with contain.
                childAspectRatio: 0.72,
              ),
              delegate: SliverChildBuilderDelegate(
                (context, index) {
                  if (hasMore && index == 3) {
                    return _MoreButton(onTap: onShowMore, embedded: embedded);
                  }
                  final category = displayCategories[index];
                  return _CategoryCard(
                    category: category,
                    onTap: () => onCategoryTap(category),
                    embedded: embedded,
                  );
                },
                childCount: hasMore ? 4 : displayCategories.length,
              ),
            ),
          ),
        ],
        const SliverToBoxAdapter(child: SizedBox(height: 8)),
        if (vendorsLoading) ...[
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
              child: Text(
                'Browse by store',
                style: sectionTitle(textTheme.titleMedium, fontSize: 18),
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: SizedBox(
              height: 130,
              child: _VendorsSliderShimmer(),
            ),
          ),
        ] else if (vendorsError != null || vendors.isEmpty) ...[
          // Hide section for cleaner UI
        ] else ...[
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      'Browse by store',
                      style: sectionTitle(textTheme.titleMedium, fontSize: 18),
                    ),
                  ),
                  if (embedded)
                    Text(
                      'View all',
                      style: textTheme.labelLarge?.copyWith(
                        color: accentColor,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                ],
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: SizedBox(
              height: 130,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 12),
                itemCount: vendors.length,
                itemBuilder: (context, index) {
                  final vendor = vendors[index];
                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    child: _VendorSliderCard(
                      name: vendor.name,
                      avatarUrl: vendor.avatar,
                      embedded: embedded,
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => StoreDetailScreen(
                              storeName: vendor.name,
                              storeImage:
                                  vendor.avatar.isNotEmpty ? vendor.avatar : null,
                              vendorId: vendor.id,
                              vendor: vendor,
                            ),
                          ),
                        );
                      },
                    ),
                  );
                },
              ),
            ),
          ),
        ],
        const SliverToBoxAdapter(child: SizedBox(height: 16)),
        ...popularSlivers,
        const SliverToBoxAdapter(child: SizedBox(height: 24)),
      ],
    );
    if (usePullToRefresh) {
      return RefreshIndicator(
        color: embedded ? HomeColors.orange : AppColors.primaryColor,
        onRefresh: onPullToRefresh,
        child: view,
      );
    }
    return view;
  }
}

class _VendorsSliderShimmer extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final shimmerBase = isDark ? const Color(0xFF2B2B2B) : Colors.grey[300]!;
    final shimmerHighlight = isDark ? const Color(0xFF3A3A3A) : Colors.grey[100]!;
    final blockColor = isDark ? const Color(0xFF1F1F1F) : Colors.white;
    return Shimmer.fromColors(
      baseColor: shimmerBase,
      highlightColor: shimmerHighlight,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        itemCount: 6,
        itemBuilder: (context, index) {
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 72,
                  height: 72,
                  decoration: BoxDecoration(
                    color: blockColor,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(height: 8),
                Container(
                  width: 70,
                  height: 10,
                  decoration: BoxDecoration(
                    color: blockColor,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _VendorSliderCard extends StatelessWidget {
  final String name;
  final String avatarUrl;
  final VoidCallback onTap;
  final bool embedded;

  const _VendorSliderCard({
    required this.name,
    required this.avatarUrl,
    required this.onTap,
    this.embedded = false,
  });

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          width: 100,
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 72,
                height: 72,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: embedded
                      ? Border.all(color: HomeColors.border)
                      : null,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: embedded ? 0.35 : 0.1),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: ClipOval(
                  child: avatarUrl.isNotEmpty &&
                          (avatarUrl.startsWith('http') ||
                              avatarUrl.contains('/storage/'))
                      ? FallbackNetworkImage(
                          url: avatarUrl,
                          fit: BoxFit.cover,
                          errorBuilder: (_) => _avatarPlaceholder(),
                        )
                      : (avatarUrl.isNotEmpty
                            ? Image.asset(
                                avatarUrl,
                                fit: BoxFit.cover,
                                errorBuilder: (_, __, ___) =>
                                    _avatarPlaceholder(),
                              )
                            : _avatarPlaceholder()),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                name,
                style: textTheme.bodySmall?.copyWith(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: embedded ? HomeColors.textPrimary : null,
                ),
                maxLines: 2,
                textAlign: TextAlign.center,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _avatarPlaceholder() {
    return Container(
      color: embedded ? HomeColors.surfaceElevated : Colors.grey[200],
      child: Icon(
        Icons.store_rounded,
        size: 36,
        color: embedded ? HomeColors.textMuted : Colors.grey,
      ),
    );
  }
}

class _PopularProductCard extends StatelessWidget {
  final PopularProductModel item;
  final VoidCallback onTap;
  final VoidCallback? onShopTap;
  final bool embedded;

  const _PopularProductCard({
    required this.item,
    required this.onTap,
    this.onShopTap,
    this.embedded = false,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final imageUrl = item.displayImage;
    final shopName = item.shopName;
    final rating = item.shopRating;
    final deliveryFee = item.deliveryFee;
    final promoText = item.promoLabel;
    final accent = embedded ? HomeColors.orange : AppColors.primaryColor;
    final cardBg = embedded ? HomeColors.surface : colorScheme.surface;
    final titleColor = embedded ? HomeColors.textPrimary : null;
    final mutedColor =
        embedded ? HomeColors.textMuted : colorScheme.onSurface.withValues(alpha: 0.72);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          decoration: BoxDecoration(
            color: cardBg,
            borderRadius: BorderRadius.circular(12),
            border: embedded ? Border.all(color: HomeColors.border) : null,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: embedded ? 0.35 : 0.1),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Stack(
                children: [
                  ClipRRect(
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(12),
                      topRight: Radius.circular(12),
                    ),
                    child: imageUrl.startsWith('http')
                        ? Image.network(
                            imageUrl,
                            height: 160,
                            width: double.infinity,
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) => _imagePlaceholder(),
                          )
                        : _imagePlaceholder(),
                  ),
                  if (promoText != null)
                    Positioned(
                      top: 12,
                      left: 12,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.green,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          promoText,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
              Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.product.name ?? '',
                      style: textTheme.titleSmall?.copyWith(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: titleColor,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'ETB ${item.displayPrice}',
                      style: textTheme.titleSmall?.copyWith(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: accent,
                      ),
                    ),
                    if (shopName != null && shopName.isNotEmpty) ...[
                      const SizedBox(height: 6),
                      GestureDetector(
                        onTap: onShopTap,
                        child: Text(
                          shopName,
                          style: textTheme.bodySmall?.copyWith(
                            fontSize: 13,
                            color: accent,
                            fontWeight: FontWeight.w500,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        if (rating > 0) ...[
                          Icon(
                            Icons.star,
                            size: 16,
                            color: Colors.amber[700],
                          ),
                          const SizedBox(width: 4),
                          Text(
                            rating.toStringAsFixed(1),
                            style: textTheme.bodyMedium?.copyWith(
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                              color: titleColor,
                            ),
                          ),
                          const SizedBox(width: 12),
                        ],
                        if (deliveryFee > 0)
                          Expanded(
                            child: Text(
                              'ETB $deliveryFee delivery',
                              style: textTheme.bodySmall?.copyWith(
                                fontSize: 12,
                                color: mutedColor,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
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

  Widget _imagePlaceholder() {
    return Container(
      height: 160,
      width: double.infinity,
      color: embedded ? HomeColors.surfaceElevated : Colors.grey[200],
      child: Icon(
        Icons.shopping_bag_outlined,
        size: 48,
        color: embedded ? HomeColors.textMuted : Colors.grey,
      ),
    );
  }
}

class _MoreButton extends StatelessWidget {
  final VoidCallback onTap;
  final bool embedded;

  const _MoreButton({required this.onTap, this.embedded = false});

  @override
  Widget build(BuildContext context) {
    final accent = embedded ? HomeColors.orange : AppColors.primaryColor;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          decoration: BoxDecoration(
            color: accent.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: accent.withValues(alpha: 0.4),
              width: 1.5,
            ),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.grid_view_rounded,
                size: 36,
                color: accent,
              ),
              const SizedBox(height: 6),
              Text(
                'More',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: accent,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CategoryCard extends StatelessWidget {
  final CategoryTreeModel category;
  final VoidCallback onTap;
  final bool embedded;

  const _CategoryCard({
    required this.category,
    required this.onTap,
    this.embedded = false,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final icon = _iconFromMeta(category.meta);
    final imageUrl = category.displayImageUrl;
    final cardBg = embedded ? HomeColors.surfaceElevated : colorScheme.surface;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          decoration: BoxDecoration(
            color: cardBg,
            borderRadius: BorderRadius.circular(12),
            border: embedded ? Border.all(color: HomeColors.border) : null,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: embedded ? 0.35 : 0.1),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            children: [
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(6, 10, 6, 0),
                  child: imageUrl != null && imageUrl.isNotEmpty
                      ? Image.network(
                          imageUrl,
                          fit: BoxFit.contain,
                          alignment: Alignment.center,
                          errorBuilder: (_, __, ___) => _IconPlaceholder(
                            icon: icon,
                            embedded: embedded,
                          ),
                        )
                      : _IconPlaceholder(icon: icon, embedded: embedded),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(6, 6, 6, 10),
                child: Text(
                  category.name,
                  style: textTheme.bodySmall?.copyWith(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: embedded ? HomeColors.textPrimary : null,
                  ),
                  maxLines: 2,
                  textAlign: TextAlign.center,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  static IconData _iconFromMeta(Map<String, dynamic>? meta) {
    if (meta == null) return Icons.category_rounded;
    final name = (meta['icon'] as String?)?.toLowerCase();
    const map = {
      'tv': Icons.tv_rounded,
      'mobile': Icons.smartphone_rounded,
      'laptop': Icons.laptop_rounded,
      'tshirt': Icons.checkroom_rounded,
      'male': Icons.male_rounded,
      'female': Icons.female_rounded,
      'home': Icons.home_rounded,
      'basketball-ball': Icons.sports_basketball_rounded,
      'spa': Icons.spa_rounded,
      'book': Icons.menu_book_rounded,
      'gamepad': Icons.sports_esports_rounded,
      'shopping_bag': Icons.shopping_bag_rounded,
      'local_drink': Icons.local_drink_rounded,
      'pets': Icons.pets_rounded,
      'local_florist': Icons.local_florist_rounded,
      'shopping_basket': Icons.shopping_basket_rounded,
      'fastfood': Icons.fastfood_rounded,
      'restaurant_menu': Icons.restaurant_menu_rounded,
      'ramen_dining': Icons.ramen_dining_rounded,
      'icecream': Icons.icecream_rounded,
      'store': Icons.store_rounded,
      'directions_car': Icons.directions_car_rounded,
      'cake': Icons.cake_rounded,
    };
    return map[name ?? ''] ?? Icons.category_rounded;
  }
}

class _IconPlaceholder extends StatelessWidget {
  final IconData icon;
  final bool embedded;

  const _IconPlaceholder({required this.icon, this.embedded = false});

  @override
  Widget build(BuildContext context) {
    final accent = embedded ? HomeColors.orange : AppColors.primaryColor;
    return Container(
      width: 64,
      height: 64,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            accent.withValues(alpha: 0.15),
            (embedded ? HomeColors.orange : AppColors.primaryLightColor)
                .withValues(alpha: 0.08),
          ],
        ),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Icon(
        icon,
        size: 32,
        color: accent,
      ),
    );
  }
}
