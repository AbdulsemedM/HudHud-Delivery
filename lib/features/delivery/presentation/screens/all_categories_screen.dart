import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shimmer/shimmer.dart';
import 'package:hudhud_delivery/core/api/api_service.dart';
import 'package:hudhud_delivery/core/theme/app_colors.dart';
import 'package:hudhud_delivery/features/categories/bloc/categories_bloc.dart';
import 'package:hudhud_delivery/features/categories/data/data_provider/categories_data_provider.dart';
import 'package:hudhud_delivery/features/categories/data/repository/categories_repository.dart';
import 'package:hudhud_delivery/features/categories/model/category_tree_model.dart';
import 'package:hudhud_delivery/features/categories/presentation/screens/categories_screen.dart';
import 'package:hudhud_delivery/features/delivery/data/mock_popular_orders.dart';
import 'package:hudhud_delivery/features/delivery/presentation/screens/store_detail_screen.dart';
import 'package:hudhud_delivery/features/orders/data/models/vendor_model.dart';
import 'package:hudhud_delivery/features/vendors/data/data_provider/vendors_data_provider.dart';
import 'package:hudhud_delivery/features/vendors/data/repository/vendors_repository.dart';

class AllCategoriesScreen extends StatelessWidget {
  const AllCategoriesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final repository = CategoriesRepository(
      categoriesDataProvider: CategoriesDataProvider(
        apiService: ApiService.instance,
      ),
    );
    return BlocProvider(
      create: (context) =>
          CategoriesBloc(repository)..add(FetchCategoriesListEvent()),
      child: const _AllCategoriesBody(),
    );
  }
}

class _AllCategoriesBody extends StatefulWidget {
  const _AllCategoriesBody();

  @override
  State<_AllCategoriesBody> createState() => _AllCategoriesBodyState();
}

class _AllCategoriesBodyState extends State<_AllCategoriesBody> {
  bool _showAllCategories = false;

  List<VendorModel> _vendors = [];
  bool _vendorsLoading = true;
  String? _vendorsError;
  late final VendorsRepository _vendorsRepository;

  @override
  void initState() {
    super.initState();
    _vendorsRepository = VendorsRepository(
      vendorsDataProvider: VendorsDataProvider(apiService: ApiService.instance),
    );
    _loadVendors();
  }

  Future<void> _loadVendors() async {
    setState(() {
      _vendorsLoading = true;
      _vendorsError = null;
    });
    try {
      final list = await _vendorsRepository.getVendors(page: 1);
      setState(() {
        _vendors = list;
        _vendorsLoading = false;
      });
    } catch (e) {
      setState(() {
        _vendorsError = e.toString();
        _vendorsLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final textTheme = theme.textTheme;
    return Scaffold(
      backgroundColor: colorScheme.background,
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
            color: colorScheme.outline.withOpacity(0.35),
            height: 1,
          ),
        ),
      ),
      body: BlocBuilder<CategoriesBloc, CategoriesState>(
        buildWhen: (prev, curr) =>
            curr is FetchCategoriesListLoading ||
            curr is FetchCategoriesListSuccess ||
            curr is FetchCategoriesListFailure,
        builder: (context, state) {
          if (state is FetchCategoriesListLoading) {
            return const _LoadingState();
          }
          if (state is FetchCategoriesListFailure) {
            return _ErrorState(
              message: state.errorMessage,
              onRetry: () => context
                  .read<CategoriesBloc>()
                  .add(FetchCategoriesListEvent()),
            );
          }
          if (state is FetchCategoriesListSuccess) {
            final categories = state.result.items;
            if (categories.isEmpty) {
              return const _EmptyState();
            }
            return _CategoriesGrid(
              categories: categories,
              showAll: _showAllCategories,
              vendors: _vendors,
              vendorsLoading: _vendorsLoading,
              vendorsError: _vendorsError,
              onCategoryTap: (category) => _onCategoryTap(context, category),
              onShowMore: () => setState(() => _showAllCategories = true),
            );
          }
          return const SizedBox.shrink();
        },
      ),
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
                childAspectRatio: 0.85,
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
          // Popular Orders title
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
            color: Colors.black.withOpacity(0.04),
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
            color: Colors.black.withOpacity(0.04),
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
                color: AppColors.errorColor.withOpacity(0.08),
                shape: BoxShape.circle,
              ),
              child: Icon(
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
                color: colorScheme.onSurface.withOpacity(0.75),
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
                color: colorScheme.onSurface.withOpacity(0.12),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.category_outlined,
                size: 56,
                color: colorScheme.onSurface.withOpacity(0.55),
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
  final void Function(CategoryTreeModel) onCategoryTap;
  final VoidCallback onShowMore;

  const _CategoriesGrid({
    required this.categories,
    required this.showAll,
    required this.vendors,
    required this.vendorsLoading,
    required this.vendorsError,
    required this.onCategoryTap,
    required this.onShowMore,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final textTheme = theme.textTheme;
    final displayCategories = showAll ? categories : categories.take(3).toList();
    final hasMore = categories.length > 3 && !showAll;

    return CustomScrollView(
      slivers: [
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 20, 16, 8),
            child: Text(
              showAll ? 'All categories' : 'Categories',
              style: textTheme.titleLarge?.copyWith(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
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
              childAspectRatio: 0.85,
            ),
            delegate: SliverChildBuilderDelegate(
              (context, index) {
                if (hasMore && index == 3) {
                  return _MoreButton(onTap: onShowMore);
                }
                final category = displayCategories[index];
                return _CategoryCard(
                  category: category,
                  onTap: () => onCategoryTap(category),
                );
              },
              childCount: hasMore ? 4 : displayCategories.length,
            ),
          ),
        ),
        const SliverToBoxAdapter(child: SizedBox(height: 8)),
        // Vendors slider (one row) - "Browse by store"
        if (vendorsLoading) ...[
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
              child: Text(
                'Browse by store',
                style: textTheme.titleMedium?.copyWith(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
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
          // Hide or minimal message - skip section for cleaner UI
        ] else ...[
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
              child: Text(
                'Browse by store',
                style: textTheme.titleMedium?.copyWith(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
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
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => StoreDetailScreen(
                              storeName: vendor.name,
                              storeImage: vendor.avatar.isNotEmpty ? vendor.avatar : null,
                              vendorId: vendor.productApiId,
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
        // Popular Orders section (mock data)
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
            child: Text(
              'Popular Orders',
              style: textTheme.titleLarge?.copyWith(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          sliver: SliverList(
            delegate: SliverChildBuilderDelegate(
              (context, index) {
                final order = mockPopularOrders[index];
                return Padding(
                  padding: const EdgeInsets.only(bottom: 16),
                  child: _PopularOrderCard(
                    name: order.name,
                    rating: order.rating,
                    deliveryFee: order.deliveryFee,
                    deliveryTime: order.deliveryTime,
                    promoText: order.promoText,
                    imageUrl: order.imageUrl,
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => StoreDetailScreen(
                            storeName: order.name,
                            storeImage: order.imageUrl,
                            vendorId: order.vendorId,
                          ),
                        ),
                      );
                    },
                  ),
                );
              },
              childCount: mockPopularOrders.length,
            ),
          ),
        ),
        const SliverToBoxAdapter(child: SizedBox(height: 24)),
      ],
    );
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

  const _VendorSliderCard({
    required this.name,
    required this.avatarUrl,
    required this.onTap,
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
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: ClipOval(
                  child: avatarUrl.isNotEmpty && avatarUrl.startsWith('http')
                      ? Image.network(
                          avatarUrl,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => _avatarPlaceholder(),
                        )
                      : (avatarUrl.isNotEmpty
                            ? Image.asset(
                                avatarUrl,
                                fit: BoxFit.cover,
                                errorBuilder: (_, __, ___) => _avatarPlaceholder(),
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
      color: Colors.grey[200],
      child: const Icon(Icons.store_rounded, size: 36, color: Colors.grey),
    );
  }
}

class _PopularOrderCard extends StatelessWidget {
  final String name;
  final double rating;
  final int deliveryFee;
  final String deliveryTime;
  final String? promoText;
  final String imageUrl;
  final VoidCallback onTap;

  const _PopularOrderCard({
    required this.name,
    required this.rating,
    required this.deliveryFee,
    required this.deliveryTime,
    this.promoText,
    required this.imageUrl,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          decoration: BoxDecoration(
            color: colorScheme.surface,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
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
                        : Image.asset(
                            imageUrl,
                            height: 160,
                            width: double.infinity,
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) => _imagePlaceholder(),
                          ),
                  ),
                  if (promoText != null)
                    Positioned(
                      top: 12,
                      left: 12,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: Colors.green,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          promoText!,
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
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            name,
                            style: textTheme.titleSmall?.copyWith(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.favorite_border),
                          iconSize: 20,
                          color: colorScheme.onSurface.withOpacity(0.65),
                          onPressed: () {},
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Icon(
                          Icons.star,
                          size: 16,
                          color: Colors.amber[700],
                        ),
                        const SizedBox(width: 4),
                        Text(
                          rating.toString(),
                          style: textTheme.bodyMedium?.copyWith(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Text(
                          'ETB $deliveryFee Delivery Fee • $deliveryTime',
                          style: textTheme.bodySmall?.copyWith(
                            fontSize: 12,
                            color: colorScheme.onSurface.withOpacity(0.72),
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
      color: Colors.grey[200],
      child: const Icon(
        Icons.restaurant,
        size: 48,
        color: Colors.grey,
      ),
    );
  }
}

class _MoreButton extends StatelessWidget {
  final VoidCallback onTap;

  const _MoreButton({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          decoration: BoxDecoration(
            color: AppColors.primaryColor.withOpacity(0.12),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: AppColors.primaryColor.withOpacity(0.4),
              width: 1.5,
            ),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.grid_view_rounded,
                size: 36,
                color: AppColors.primaryColor,
              ),
              const SizedBox(height: 6),
              Text(
                'More',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: AppColors.primaryColor,
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

  const _CategoryCard({
    required this.category,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final icon = _iconFromMeta(category.meta);
    final imageUrl = category.displayImageUrl;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          decoration: BoxDecoration(
            color: colorScheme.surface,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.only(top: 12, left: 8, right: 8),
                  child: Center(
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(10),
                      child: imageUrl != null && imageUrl.isNotEmpty
                          ? Image.network(
                              imageUrl,
                              width: double.infinity,
                              fit: BoxFit.cover,
                              errorBuilder: (_, __, ___) => _IconPlaceholder(
                                icon: icon,
                              ),
                            )
                          : _IconPlaceholder(icon: icon),
                    ),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(6, 6, 6, 12),
                child: Text(
                  category.name,
                  style: textTheme.bodySmall?.copyWith(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
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

  const _IconPlaceholder({required this.icon});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 64,
      height: 64,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppColors.primaryColor.withOpacity(0.15),
            AppColors.primaryLightColor.withOpacity(0.08),
          ],
        ),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Icon(
        icon,
        size: 32,
        color: AppColors.primaryColor,
      ),
    );
  }
}
