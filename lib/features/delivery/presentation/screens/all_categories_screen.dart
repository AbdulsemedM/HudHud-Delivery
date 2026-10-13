import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shimmer/shimmer.dart';
import 'package:hudhud_delivery/app/services/startup_location_service.dart';
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
      productsDataProvider:
          ProductsDataProvider(apiService: ApiService.instance),
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
      productsDataProvider:
          ProductsDataProvider(apiService: ApiService.instance),
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
      final location = StartupLocationService.cached ??
          await StartupLocationService.fetchAtStartup();
      final list = await _vendorsRepository.getVendors(
        page: 1,
        latitude: location?.latitude,
        longitude: location?.longitude,
      );
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
    final embedded = widget.embedded;
    final searchHint =
        embedded ? context.l10n.homeSearchHint : 'Search products everywhere';

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
        const SizedBox(height: 12),
        _SearchBarButton(
          hint: searchHint,
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => const ProductSearchResultsScreen(),
              ),
            );
          },
        ),
        const SizedBox(height: 4),
        Expanded(child: gridBody),
      ],
    );

    final themed = Theme(
      data: HomeColors.themeFor(context),
      child: ColoredBox(
        color: HomeColors.backgroundOf(context),
        child: body,
      ),
    );
    if (embedded) return themed;

    return Scaffold(
      backgroundColor: HomeColors.backgroundOf(context),
      appBar: AppBar(
        centerTitle: true,
        title: Text(
          'All categories',
          style: TextStyle(
            fontWeight: FontWeight.w800,
            fontSize: 19,
            letterSpacing: -0.3,
            color: HomeColors.textPrimaryOf(context),
          ),
        ),
        backgroundColor: HomeColors.backgroundOf(context),
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, size: 26),
          color: HomeColors.textPrimaryOf(context),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: themed,
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

// ---------------------------------------------------------------------------
// Shared visuals
// ---------------------------------------------------------------------------

/// Tint palette cycled through for picture-less tiles (orange, indigo,
/// green, amber) so each category/store reads as its own "picture".
Color _tileAccent(BuildContext context, int index) {
  switch (index % 4) {
    case 0:
      return AppColors.brandOrange;
    case 1:
      return HomeColors.violetOf(context);
    case 2:
      return AppColors.successColor;
    default:
      return AppColors.warningColor;
  }
}

/// First letter(s) of a name for picture-less tiles ("Fresh Food" -> "FF").
String _initialsOf(String name) {
  final words =
      name.trim().split(RegExp(r'\s+')).where((w) => w.isNotEmpty).toList();
  if (words.isEmpty) return '?';
  if (words.length == 1) return words.first.characters.first.toUpperCase();
  return (words[0].characters.first + words[1].characters.first).toUpperCase();
}

/// Tinted rounded square showing either an icon or initials.
class _TintedMonogram extends StatelessWidget {
  const _TintedMonogram({
    required this.color,
    required this.label,
    this.icon,
    this.fontSize = 22,
  });

  final Color color;
  final String label;
  final IconData? icon;
  final double fontSize;

  @override
  Widget build(BuildContext context) {
    final dark = HomeColors.isDark(context);
    return Container(
      color: color.withValues(alpha: dark ? 0.2 : 0.12),
      alignment: Alignment.center,
      child: icon != null
          ? Icon(icon, color: color, size: fontSize * 1.4)
          : Text(
              label,
              maxLines: 1,
              style: TextStyle(
                fontSize: fontSize,
                fontWeight: FontWeight.w800,
                letterSpacing: -0.4,
                color: color,
              ),
            ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader(this.title);

  final String title;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 24, 16, 12),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.w800,
          letterSpacing: -0.4,
          color: HomeColors.textPrimaryOf(context),
        ),
      ),
    );
  }
}

/// Read-only 56px search pill; tapping opens the search screen.
class _SearchBarButton extends StatelessWidget {
  const _SearchBarButton({required this.hint, required this.onTap});

  final String hint;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final dark = HomeColors.isDark(context);
    final radius = BorderRadius.circular(18);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: DecoratedBox(
        decoration: BoxDecoration(
          borderRadius: radius,
          boxShadow: AppColors.softShadow(context),
        ),
        child: Material(
          color: HomeColors.surfaceOf(context),
          shape: RoundedRectangleBorder(
            borderRadius: radius,
            side: dark
                ? BorderSide(color: HomeColors.borderOf(context))
                : BorderSide.none,
          ),
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            onTap: onTap,
            child: SizedBox(
              height: 56,
              child: Row(
                children: [
                  const SizedBox(width: 16),
                  Icon(
                    Icons.search_rounded,
                    size: 26,
                    color: HomeColors.textPrimaryOf(context),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      hint,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: HomeColors.textMutedOf(context),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Loading / error / empty
// ---------------------------------------------------------------------------

class _LoadingState extends StatelessWidget {
  const _LoadingState();

  @override
  Widget build(BuildContext context) {
    final shimmerBase = HomeColors.surfaceElevatedOf(context);
    final shimmerHighlight = HomeColors.surfaceOf(context);
    final blockColor = HomeColors.surfaceElevatedOf(context);
    Widget block(double w, double h, {double r = 8}) => Container(
          width: w,
          height: h,
          decoration: BoxDecoration(
            color: blockColor,
            borderRadius: BorderRadius.circular(r),
          ),
        );
    return Shimmer.fromColors(
      baseColor: shimmerBase,
      highlightColor: shimmerHighlight,
      child: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 24, 16, 12),
              child: Align(
                alignment: Alignment.centerLeft,
                child: block(150, 22),
              ),
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            sliver: SliverGrid(
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 4,
                crossAxisSpacing: 12,
                mainAxisSpacing: 16,
                // Square tile + two lines of 13px label.
                childAspectRatio: 0.64,
              ),
              delegate: SliverChildBuilderDelegate(
                (context, index) => _CategorySkeleton(),
                childCount: 4,
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 24, 16, 12),
              child: Align(
                alignment: Alignment.centerLeft,
                child: block(170, 22),
              ),
            ),
          ),
          const SliverToBoxAdapter(
            child: SizedBox(height: 140, child: _VendorsSliderShimmerBody()),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 24, 16, 12),
              child: Align(
                alignment: Alignment.centerLeft,
                child: block(160, 22),
              ),
            ),
          ),
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
        ],
      ),
    );
  }
}

class _PopularOrderSkeleton extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final blockColor = HomeColors.surfaceElevatedOf(context);
    return Container(
      decoration: BoxDecoration(
        color: HomeColors.surfaceOf(context),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            height: 170,
            width: double.infinity,
            decoration: BoxDecoration(
              color: blockColor,
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(20),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  height: 16,
                  width: 180,
                  decoration: BoxDecoration(
                    color: blockColor,
                    borderRadius: BorderRadius.circular(6),
                  ),
                ),
                const SizedBox(height: 10),
                Container(
                  height: 12,
                  width: 120,
                  decoration: BoxDecoration(
                    color: blockColor,
                    borderRadius: BorderRadius.circular(6),
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
    final blockColor = HomeColors.surfaceElevatedOf(context);
    return Column(
      children: [
        AspectRatio(
          aspectRatio: 1,
          child: Container(
            decoration: BoxDecoration(
              color: blockColor,
              borderRadius: BorderRadius.circular(22),
            ),
          ),
        ),
        const SizedBox(height: 8),
        Container(
          margin: const EdgeInsets.symmetric(horizontal: 8),
          height: 10,
          decoration: BoxDecoration(
            color: blockColor,
            borderRadius: BorderRadius.circular(5),
          ),
        ),
      ],
    );
  }
}

class _StateMessage extends StatelessWidget {
  const _StateMessage({
    required this.icon,
    required this.color,
    required this.title,
    required this.message,
    this.actionLabel,
    this.onAction,
  });

  final IconData icon;
  final Color color;
  final String title;
  final String message;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    final dark = HomeColors.isDark(context);
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 96,
              height: 96,
              decoration: BoxDecoration(
                color: color.withValues(alpha: dark ? 0.2 : 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, size: 46, color: color),
            ),
            const SizedBox(height: 20),
            Text(
              title,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 19,
                fontWeight: FontWeight.w800,
                letterSpacing: -0.3,
                color: HomeColors.textPrimaryOf(context),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              message,
              textAlign: TextAlign.center,
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 14,
                height: 1.4,
                fontWeight: FontWeight.w600,
                color: HomeColors.textMutedOf(context),
              ),
            ),
            if (actionLabel != null && onAction != null) ...[
              const SizedBox(height: 24),
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
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(18),
                    ),
                    textStyle: const TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w800,
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

class _ErrorState extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;

  const _ErrorState({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return _StateMessage(
      icon: Icons.wifi_off_rounded,
      color: AppColors.errorColor,
      title: 'Something went wrong',
      message: message,
      actionLabel: context.l10n.actionTryAgain,
      onAction: onRetry,
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    return _StateMessage(
      icon: Icons.storefront_rounded,
      color: HomeColors.violetOf(context),
      title: 'No categories yet',
      message: 'Check back later for new categories',
    );
  }
}

// ---------------------------------------------------------------------------
// Main content
// ---------------------------------------------------------------------------

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
    final displayCategories =
        showAll ? categories : categories.take(3).toList();
    final hasMore = categories.length > 3 && !showAll;

    final popularSlivers = <Widget>[
      if (popularLoading) ...[
        const SliverToBoxAdapter(child: _SectionHeader('Most Popular')),
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          sliver: SliverList(
            delegate: SliverChildBuilderDelegate(
              (_, __) => Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: Shimmer.fromColors(
                  baseColor: HomeColors.surfaceElevatedOf(context),
                  highlightColor: HomeColors.surfaceOf(context),
                  child: _PopularOrderSkeleton(),
                ),
              ),
              childCount: 2,
            ),
          ),
        ),
      ] else if (popularProducts.isNotEmpty) ...[
        const SliverToBoxAdapter(child: _SectionHeader('Most Popular')),
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
      physics: usePullToRefresh ? const AlwaysScrollableScrollPhysics() : null,
      slivers: [
        if (categoriesError != null) ...[
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
              child: _InlineError(
                title: 'Could not load categories',
                message: categoriesError!,
                onRetry: onCategoriesRetry,
              ),
            ),
          ),
        ] else if (categories.isNotEmpty) ...[
          SliverToBoxAdapter(
            child: _SectionHeader(showAll ? 'All categories' : 'Categories'),
          ),
          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            sliver: SliverGrid(
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 4,
                crossAxisSpacing: 12,
                mainAxisSpacing: 16,
                // Square tile + two lines of 13px label.
                childAspectRatio: 0.64,
              ),
              delegate: SliverChildBuilderDelegate(
                (context, index) {
                  if (hasMore && index == 3) {
                    return _MoreButton(onTap: onShowMore, embedded: embedded);
                  }
                  final category = displayCategories[index];
                  return _CategoryCard(
                    category: category,
                    index: index,
                    onTap: () => onCategoryTap(category),
                    embedded: embedded,
                  );
                },
                childCount: hasMore ? 4 : displayCategories.length,
              ),
            ),
          ),
        ],
        if (vendorsLoading) ...[
          const SliverToBoxAdapter(child: _SectionHeader('Browse by store')),
          SliverToBoxAdapter(
            child: SizedBox(
              height: 140,
              child: _VendorsSliderShimmer(),
            ),
          ),
        ] else if (vendorsError != null || vendors.isEmpty) ...[
          // Hide section for cleaner UI
        ] else ...[
          const SliverToBoxAdapter(child: _SectionHeader('Browse by store')),
          SliverToBoxAdapter(
            child: SizedBox(
              height: 140,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: vendors.length,
                separatorBuilder: (_, __) => const SizedBox(width: 12),
                itemBuilder: (context, index) {
                  final vendor = vendors[index];
                  return _VendorSliderCard(
                    name: vendor.name,
                    avatarUrl: vendor.avatar,
                    index: index,
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
                  );
                },
              ),
            ),
          ),
        ],
        const SliverToBoxAdapter(child: SizedBox(height: 4)),
        ...popularSlivers,
        const SliverToBoxAdapter(child: SizedBox(height: 24)),
      ],
    );
    if (usePullToRefresh) {
      return RefreshIndicator(
        color: AppColors.brandOrange,
        onRefresh: onPullToRefresh,
        child: view,
      );
    }
    return view;
  }
}

/// Compact inline error card (used when categories fail but other content
/// can still be shown).
class _InlineError extends StatelessWidget {
  const _InlineError({
    required this.title,
    required this.message,
    this.onRetry,
  });

  final String title;
  final String message;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    final dark = HomeColors.isDark(context);
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: HomeColors.surfaceOf(context),
        borderRadius: BorderRadius.circular(20),
        border: dark ? Border.all(color: HomeColors.borderOf(context)) : null,
        boxShadow: AppColors.softShadow(context),
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: AppColors.errorColor.withValues(alpha: dark ? 0.2 : 0.1),
              borderRadius: BorderRadius.circular(15),
            ),
            child: const Icon(
              Icons.wifi_off_rounded,
              color: AppColors.errorColor,
              size: 24,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                    color: HomeColors.textPrimaryOf(context),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  message,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: HomeColors.textMutedOf(context),
                  ),
                ),
              ],
            ),
          ),
          if (onRetry != null) ...[
            const SizedBox(width: 8),
            IconButton.filledTonal(
              onPressed: onRetry,
              tooltip: context.l10n.actionRetry,
              style: IconButton.styleFrom(
                minimumSize: const Size(48, 48),
                backgroundColor:
                    dark ? AppColors.orangeTintDark : AppColors.orangeTint,
                foregroundColor: AppColors.brandOrange,
              ),
              icon: const Icon(Icons.refresh_rounded),
            ),
          ],
        ],
      ),
    );
  }
}

class _VendorsSliderShimmer extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Shimmer.fromColors(
      baseColor: HomeColors.surfaceElevatedOf(context),
      highlightColor: HomeColors.surfaceOf(context),
      child: const _VendorsSliderShimmerBody(),
    );
  }
}

class _VendorsSliderShimmerBody extends StatelessWidget {
  const _VendorsSliderShimmerBody();

  @override
  Widget build(BuildContext context) {
    final blockColor = HomeColors.surfaceElevatedOf(context);
    return ListView.separated(
      scrollDirection: Axis.horizontal,
      physics: const NeverScrollableScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 16),
      itemCount: 6,
      separatorBuilder: (_, __) => const SizedBox(width: 12),
      itemBuilder: (context, index) {
        return SizedBox(
          width: 92,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  color: blockColor,
                  borderRadius: BorderRadius.circular(24),
                ),
              ),
              const SizedBox(height: 10),
              Container(
                width: 70,
                height: 10,
                decoration: BoxDecoration(
                  color: blockColor,
                  borderRadius: BorderRadius.circular(5),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _VendorSliderCard extends StatelessWidget {
  final String name;
  final String avatarUrl;
  final int index;
  final VoidCallback onTap;
  final bool embedded;

  const _VendorSliderCard({
    required this.name,
    required this.avatarUrl,
    required this.onTap,
    this.index = 0,
    this.embedded = false,
  });

  @override
  Widget build(BuildContext context) {
    final dark = HomeColors.isDark(context);
    final radius = BorderRadius.circular(24);
    return Semantics(
      button: true,
      label: name,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: SizedBox(
          width: 92,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  color: HomeColors.surfaceOf(context),
                  borderRadius: radius,
                  border: dark
                      ? Border.all(color: HomeColors.borderOf(context))
                      : null,
                  boxShadow: AppColors.softShadow(context),
                ),
                child: ClipRRect(
                  borderRadius: radius,
                  child: avatarUrl.isNotEmpty &&
                          (avatarUrl.startsWith('http') ||
                              avatarUrl.contains('/storage/'))
                      ? FallbackNetworkImage(
                          url: avatarUrl,
                          width: 80,
                          height: 80,
                          fit: BoxFit.cover,
                          errorBuilder: (_) => _avatarPlaceholder(context),
                        )
                      : (avatarUrl.isNotEmpty
                          ? Image.asset(
                              avatarUrl,
                              fit: BoxFit.cover,
                              errorBuilder: (_, __, ___) =>
                                  _avatarPlaceholder(context),
                            )
                          : _avatarPlaceholder(context)),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                name,
                style: TextStyle(
                  fontSize: 13,
                  height: 1.2,
                  fontWeight: FontWeight.w700,
                  color: HomeColors.textPrimaryOf(context),
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

  Widget _avatarPlaceholder(BuildContext context) {
    return SizedBox(
      width: 80,
      height: 80,
      child: _TintedMonogram(
        color: _tileAccent(context, index),
        label: _initialsOf(name),
        fontSize: 24,
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
    final imageUrl = item.displayImage;
    final shopName = item.shopName;
    final rating = item.shopRating;
    final deliveryFee = item.deliveryFee;
    final promoText = item.promoLabel;
    final dark = HomeColors.isDark(context);
    final ink = HomeColors.textPrimaryOf(context);
    final muted = HomeColors.textMutedOf(context);
    final radius = BorderRadius.circular(20);

    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: radius,
        boxShadow: AppColors.softShadow(context),
      ),
      child: Material(
        color: HomeColors.surfaceOf(context),
        shape: RoundedRectangleBorder(
          borderRadius: radius,
          side: dark
              ? BorderSide(color: HomeColors.borderOf(context))
              : BorderSide.none,
        ),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Stack(
                children: [
                  imageUrl.startsWith('http')
                      ? Image.network(
                          imageUrl,
                          height: 170,
                          width: double.infinity,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) =>
                              _imagePlaceholder(context),
                        )
                      : _imagePlaceholder(context),
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
                          color: AppColors.successColor,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(
                              Icons.local_offer_rounded,
                              size: 14,
                              color: Colors.white,
                            ),
                            const SizedBox(width: 5),
                            Text(
                              promoText,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 12.5,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                ],
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(14, 12, 14, 14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Text(
                            item.product.name ?? '',
                            style: TextStyle(
                              fontSize: 17,
                              height: 1.25,
                              fontWeight: FontWeight.w800,
                              letterSpacing: -0.3,
                              color: ink,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Text(
                          'ETB ${item.displayPrice}',
                          style: TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.w800,
                            letterSpacing: -0.3,
                            color: ink,
                          ),
                        ),
                      ],
                    ),
                    if (shopName != null && shopName.isNotEmpty) ...[
                      const SizedBox(height: 8),
                      InkWell(
                        onTap: onShopTap,
                        borderRadius: BorderRadius.circular(8),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(vertical: 2),
                          child: Row(
                            children: [
                              Icon(
                                Icons.storefront_rounded,
                                size: 18,
                                color: HomeColors.violetOf(context),
                              ),
                              const SizedBox(width: 6),
                              Flexible(
                                child: Text(
                                  shopName,
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: HomeColors.violetOf(context),
                                    fontWeight: FontWeight.w700,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                    if (rating > 0 || deliveryFee > 0) ...[
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          if (rating > 0) ...[
                            const Icon(
                              Icons.star_rounded,
                              size: 18,
                              color: AppColors.ratingFilled,
                            ),
                            const SizedBox(width: 3),
                            Text(
                              rating.toStringAsFixed(1),
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w700,
                                color: ink,
                              ),
                            ),
                            const SizedBox(width: 14),
                          ],
                          if (deliveryFee > 0) ...[
                            Icon(
                              Icons.delivery_dining_rounded,
                              size: 18,
                              color: muted,
                            ),
                            const SizedBox(width: 4),
                            Expanded(
                              child: Text(
                                'ETB $deliveryFee delivery',
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  color: muted,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _imagePlaceholder(BuildContext context) {
    final dark = HomeColors.isDark(context);
    return Container(
      height: 170,
      width: double.infinity,
      color: dark ? AppColors.orangeTintDark : AppColors.orangeTint,
      child: const Icon(
        Icons.shopping_bag_rounded,
        size: 52,
        color: AppColors.brandOrange,
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
    final dark = HomeColors.isDark(context);
    final indigo = HomeColors.violetOf(context);
    return _TileShell(
      onTap: onTap,
      label: context.l10n.categoryMore,
      picture: Container(
        color: dark ? AppColors.indigoTintDark : AppColors.indigoTint,
        alignment: Alignment.center,
        child: Icon(Icons.grid_view_rounded, size: 32, color: indigo),
      ),
    );
  }
}

/// Picture tile + label below, used for categories and "More".
class _TileShell extends StatelessWidget {
  const _TileShell({
    required this.picture,
    required this.label,
    required this.onTap,
  });

  final Widget picture;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final dark = HomeColors.isDark(context);
    final radius = BorderRadius.circular(22);
    return Semantics(
      button: true,
      label: label,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: Column(
          children: [
            AspectRatio(
              aspectRatio: 1,
              child: Container(
                decoration: BoxDecoration(
                  color: HomeColors.surfaceOf(context),
                  borderRadius: radius,
                  border: dark
                      ? Border.all(color: HomeColors.borderOf(context))
                      : null,
                  boxShadow: AppColors.softShadow(context),
                ),
                child: ClipRRect(borderRadius: radius, child: picture),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              label,
              style: TextStyle(
                fontSize: 13,
                height: 1.2,
                fontWeight: FontWeight.w700,
                color: HomeColors.textPrimaryOf(context),
              ),
              maxLines: 2,
              textAlign: TextAlign.center,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}

class _CategoryCard extends StatelessWidget {
  final CategoryTreeModel category;
  final int index;
  final VoidCallback onTap;
  final bool embedded;

  const _CategoryCard({
    required this.category,
    required this.onTap,
    this.index = 0,
    this.embedded = false,
  });

  @override
  Widget build(BuildContext context) {
    final icon = _iconFromMeta(category.meta);
    final imageUrl = category.displayImageUrl;
    final fallback = _TintedMonogram(
      color: _tileAccent(context, index),
      label: _initialsOf(category.name),
      icon: icon,
    );

    return _TileShell(
      onTap: onTap,
      label: category.name,
      picture: imageUrl != null && imageUrl.isNotEmpty
          ? Image.network(
              imageUrl,
              fit: BoxFit.contain,
              alignment: Alignment.center,
              // Inset only real images; the fallback must fill the tile.
              frameBuilder: (_, child, __, ___) =>
                  Padding(padding: const EdgeInsets.all(8), child: child),
              errorBuilder: (_, __, ___) => fallback,
            )
          : fallback,
    );
  }

  /// Meaningful icon when the backend supplies one; otherwise null so the
  /// tile shows the category's initials.
  static IconData? _iconFromMeta(Map<String, dynamic>? meta) {
    if (meta == null) return null;
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
    return map[name ?? ''];
  }
}
