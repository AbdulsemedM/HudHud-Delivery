import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:hudhud_delivery/core/api/api_service.dart';
import 'package:hudhud_delivery/core/l10n/context_l10n.dart';
import 'package:hudhud_delivery/core/theme/app_colors.dart';
import 'package:hudhud_delivery/core/widgets/section_header.dart';
import 'package:hudhud_delivery/features/categories/model/categories_products_model.dart';
import 'package:hudhud_delivery/features/delivery/presentation/screens/all_categories_screen.dart';
import 'package:hudhud_delivery/features/delivery/presentation/screens/product_detail_screen.dart';
import 'package:hudhud_delivery/features/delivery/presentation/screens/store_detail_screen.dart';
import 'package:hudhud_delivery/features/orders/data/models/vendor_model.dart';
import 'package:hudhud_delivery/features/products/data/products_data_provider.dart';
import 'package:hudhud_delivery/features/products/data/products_repository.dart';
import 'package:hudhud_delivery/features/products/model/popular_product_model.dart';
import 'package:hudhud_delivery/features/products/presentation/screens/product_search_results_screen.dart';
import 'package:hudhud_delivery/features/vendors/data/data_provider/vendors_data_provider.dart';
import 'package:hudhud_delivery/features/vendors/data/repository/vendors_repository.dart';
import 'package:shimmer/shimmer.dart';
import 'category_stores_screen.dart';

class DeliveryFeedScreen extends StatefulWidget {
  const DeliveryFeedScreen({super.key});

  @override
  State<DeliveryFeedScreen> createState() => _DeliveryFeedScreenState();
}

class _DeliveryFeedScreenState extends State<DeliveryFeedScreen> {
  String _selectedLocation = 'London Hall';
  String _selectedTime = 'Now';

  List<VendorModel> _vendors = [];
  List<CategoriesProductsModel> _featuredProducts = [];
  List<PopularProductModel> _popularProducts = [];
  bool _vendorsLoading = true;
  bool _featuredLoading = false;
  bool _popularLoading = true;
  String? _vendorsError;
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
    _loadFeaturedProducts();
    _loadPopularProducts();
  }

  Future<void> _refreshAll() async {
    await Future.wait([
      _loadVendors(),
      _loadFeaturedProducts(),
      _loadPopularProducts(),
    ]);
  }

  Future<void> _loadPopularProducts() async {
    setState(() => _popularLoading = true);
    try {
      final list = await _productsRepository.getPopularProducts();
      if (mounted) {
        setState(() {
          _popularProducts = list;
          _popularLoading = false;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _popularProducts = [];
          _popularLoading = false;
        });
      }
    }
  }

  Future<void> _loadFeaturedProducts() async {
    setState(() => _featuredLoading = true);
    try {
      final list = await _productsRepository.getFeaturedProducts(limit: 10);
      setState(() {
        _featuredProducts = list;
        _featuredLoading = false;
      });
    } catch (_) {
      if (mounted) setState(() => _featuredLoading = false);
    }
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
    final l10n = context.l10n;

    return Scaffold(
      backgroundColor: colorScheme.surface,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _DeliveryHeader(
              location: _selectedLocation,
              time: _selectedTime,
              onLocationTap: () {},
              onTimeTap: () {},
              onFilterTap: () {},
            ),
            _DeliveryPillSearchBar(
              hint: l10n.searchStoresHint,
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const ProductSearchResultsScreen(),
                  ),
                );
              },
            ),
            Expanded(
              child: RefreshIndicator(
                onRefresh: _refreshAll,
                color: AppColors.primaryColor,
                child: CustomScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  slivers: [
                    SliverPadding(
                      padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                      sliver: SliverToBoxAdapter(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Expanded(
                                  child: _CategoryCard(
                                    title: 'Grocery',
                                    icon: Icons.shopping_basket_rounded,
                                    isLarge: true,
                                    hasPromo: true,
                                    onTap: () {
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (context) =>
                                              CategoryStoresScreen(
                                            categoryName: 'Grocery',
                                            categoryIcon:
                                                Icons.shopping_basket,
                                          ),
                                        ),
                                      );
                                    },
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: _CategoryCard(
                                    title: 'American',
                                    icon: Icons.fastfood_rounded,
                                    isLarge: true,
                                    onTap: () {
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (context) =>
                                              CategoryStoresScreen(
                                            categoryName: 'American',
                                            categoryIcon: Icons.fastfood,
                                          ),
                                        ),
                                      );
                                    },
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            Row(
                              children: [
                                Expanded(
                                  child: _CategoryCard(
                                    title: 'Convenience',
                                    icon: Icons.shopping_bag_rounded,
                                    isLarge: false,
                                    onTap: () {
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (context) =>
                                              CategoryStoresScreen(
                                            categoryName: 'Convenience stores',
                                            categoryIcon: Icons.shopping_bag,
                                          ),
                                        ),
                                      );
                                    },
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: _CategoryCard(
                                    title: 'Alcohol',
                                    icon: Icons.local_drink_rounded,
                                    isLarge: false,
                                    onTap: () {},
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: _CategoryCard(
                                    title: 'Pet Supplies',
                                    icon: Icons.pets_rounded,
                                    isLarge: false,
                                    onTap: () {},
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: _CategoryCard(
                                    title: 'More',
                                    icon: Icons.more_horiz_rounded,
                                    isLarge: false,
                                    onTap: () {
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (context) =>
                                              const AllCategoriesScreen(),
                                        ),
                                      );
                                    },
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                    if (_featuredLoading)
                      const SliverToBoxAdapter(child: _FeaturedShimmer())
                    else if (_featuredProducts.isNotEmpty)
                      SliverPadding(
                        padding: const EdgeInsets.fromLTRB(16, 20, 16, 0),
                        sliver: SliverToBoxAdapter(
                          child: SectionHeader(title: l10n.featured),
                        ),
                      )
                    else
                      const SliverToBoxAdapter(child: SizedBox.shrink()),
                    if (!_featuredLoading && _featuredProducts.isNotEmpty)
                      SliverToBoxAdapter(
                        child: SizedBox(
                          height: 190,
                          child: ListView.separated(
                            scrollDirection: Axis.horizontal,
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            itemCount: _featuredProducts.length,
                            separatorBuilder: (_, __) =>
                                const SizedBox(width: 12),
                            itemBuilder: (context, index) {
                              final p = _featuredProducts[index];
                              return _FeaturedProductCard(
                                product: p,
                                onTap: () {
                                  if (p.id != null) {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (_) => ProductDetailScreen(
                                          productId: p.id!,
                                        ),
                                      ),
                                    );
                                  }
                                },
                              );
                            },
                          ),
                        ),
                      ),
                    if (_popularLoading)
                      const SliverToBoxAdapter(child: _PopularShimmer())
                    else if (_popularProducts.isNotEmpty) ...[
                      SliverPadding(
                        padding: const EdgeInsets.fromLTRB(16, 24, 16, 0),
                        sliver: SliverToBoxAdapter(
                          child: SectionHeader(title: l10n.browseCategories),
                        ),
                      ),
                      SliverPadding(
                        padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                        sliver: SliverList(
                          delegate: SliverChildBuilderDelegate(
                            (context, index) {
                              final item = _popularProducts[index];
                              return Padding(
                                padding: const EdgeInsets.only(bottom: 16),
                                child: _PopularProductCard(
                                  item: item,
                                  onTap: () {
                                    final productId = item.product.id;
                                    if (productId == null) return;
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (_) => ProductDetailScreen(
                                          productId: productId,
                                        ),
                                      ),
                                    );
                                  },
                                ),
                              );
                            },
                            childCount: _popularProducts.length,
                          ),
                        ),
                      ),
                    ],
                    if (_vendorsLoading)
                      const SliverToBoxAdapter(child: _VendorsShimmer())
                    else if (_vendorsError == null && _vendors.isNotEmpty) ...[
                      SliverPadding(
                        padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                        sliver: SliverToBoxAdapter(
                          child: SectionHeader(
                            title: l10n.browseDelivery,
                            onSeeAll: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => const AllCategoriesScreen(),
                                ),
                              );
                            },
                          ),
                        ),
                      ),
                      SliverToBoxAdapter(
                        child: SizedBox(
                          height: 130,
                          child: ListView.builder(
                            scrollDirection: Axis.horizontal,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 8,
                            ),
                            itemCount: _vendors.take(12).length,
                            itemBuilder: (context, index) {
                              final v = _vendors[index];
                              return Padding(
                                padding:
                                    const EdgeInsets.symmetric(horizontal: 4),
                                child: _VendorSliderCard(
                                  name: v.name,
                                  avatarUrl: v.avatar.isNotEmpty
                                      ? v.avatar
                                      : 'assets/images/categories.jpg',
                                  onTap: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) => StoreDetailScreen(
                                          storeName: v.name,
                                          storeImage: v.avatar.isNotEmpty
                                              ? v.avatar
                                              : null,
                                          vendorId: v.id,
                                          vendor: v,
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
                    const SliverToBoxAdapter(child: SizedBox(height: 32)),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DeliveryPillSearchBar extends StatelessWidget {
  const _DeliveryPillSearchBar({
    required this.hint,
    required this.onTap,
  });

  final String hint;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final muted = isDark ? AppColors.mutedDark : AppColors.mutedLight;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 48,
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        padding: const EdgeInsets.symmetric(horizontal: 16),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1E1E1E) : const Color(0xFFF4F4F4),
          borderRadius: BorderRadius.circular(AppColors.rFull),
        ),
        child: Row(
          children: [
            Icon(Icons.search_rounded, color: muted, size: 20),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                hint,
                style: TextStyle(fontSize: 14, color: muted),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DeliveryHeader extends StatelessWidget {
  final String location;
  final String time;
  final VoidCallback onLocationTap;
  final VoidCallback onTimeTap;
  final VoidCallback onFilterTap;

  const _DeliveryHeader({
    required this.location,
    required this.time,
    required this.onLocationTap,
    required this.onTimeTap,
    required this.onFilterTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final muted = isDark ? AppColors.mutedDark : AppColors.mutedLight;
    final l10n = context.l10n;

    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 4, 16, 0),
      child: Row(
        children: [
          IconButton(
            icon: Icon(Icons.arrow_back_ios_new_rounded,
                color: theme.colorScheme.onSurface, size: 20),
            onPressed: () => Navigator.pop(context),
          ),
          Expanded(
            child: GestureDetector(
              onTap: onLocationTap,
              behavior: HitTestBehavior.opaque,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(
                        Icons.location_on_rounded,
                        color: AppColors.primaryColor,
                        size: 14,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        l10n.yourLocation,
                        style: TextStyle(fontSize: 11, color: muted),
                      ),
                    ],
                  ),
                  GestureDetector(
                    onTap: onTimeTap,
                    child: Row(
                      children: [
                        Flexible(
                          child: Text(
                            '$time • $location',
                            style: const TextStyle(
                              color: AppColors.primaryColor,
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const Icon(
                          Icons.keyboard_arrow_down_rounded,
                          color: AppColors.primaryColor,
                          size: 18,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          GestureDetector(
            onTap: onFilterTap,
            child: Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF1E1E1E) : const Color(0xFFF4F4F4),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                Icons.tune_rounded,
                color: theme.colorScheme.onSurface,
                size: 22,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _CategoryCard extends StatelessWidget {
  final String title;
  final IconData icon;
  final bool isLarge;
  final bool hasPromo;
  final VoidCallback onTap;

  const _CategoryCard({
    required this.title,
    required this.icon,
    this.isLarge = false,
    this.hasPromo = false,
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
        borderRadius: BorderRadius.circular(AppColors.r12),
        child: Container(
          height: isLarge ? 120 : 100,
          decoration: BoxDecoration(
            color: colorScheme.surface,
            borderRadius: BorderRadius.circular(AppColors.r12),
            border: Border.all(
              color: colorScheme.outlineVariant.withValues(alpha: 0.6),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.06),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Stack(
            children: [
              if (hasPromo)
                Positioned(
                  top: 8,
                  left: 8,
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppColors.successColor,
                      borderRadius: BorderRadius.circular(AppColors.rFull),
                    ),
                    child: Text(
                      'Promo',
                      style: textTheme.labelSmall?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
              Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(icon, size: isLarge ? 36 : 28, color: AppColors.primaryColor),
                    const SizedBox(height: 8),
                    Text(
                      title,
                      style: textTheme.labelLarge?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                      textAlign: TextAlign.center,
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
}

class _FeaturedProductCard extends StatelessWidget {
  const _FeaturedProductCard({
    required this.product,
    required this.onTap,
  });

  final CategoriesProductsModel product;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final imageUrl = product.image_path;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppColors.r12),
        child: SizedBox(
          width: 150,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(AppColors.r12),
                child: imageUrl != null && imageUrl.isNotEmpty
                    ? CachedNetworkImage(
                        imageUrl: imageUrl,
                        width: 150,
                        height: 110,
                        fit: BoxFit.cover,
                        placeholder: (_, __) => Container(
                          width: 150,
                          height: 110,
                          color: colorScheme.surfaceContainerHighest,
                        ),
                        errorWidget: (_, __, ___) => Container(
                          width: 150,
                          height: 110,
                          color: colorScheme.surfaceContainerHighest,
                          child: Icon(
                            Icons.shopping_bag_outlined,
                            color: colorScheme.onSurfaceVariant,
                          ),
                        ),
                      )
                    : Container(
                        width: 150,
                        height: 110,
                        color: colorScheme.surfaceContainerHighest,
                        child: Icon(
                          Icons.shopping_bag_outlined,
                          color: colorScheme.onSurfaceVariant,
                        ),
                      ),
              ),
              const SizedBox(height: 8),
              Text(
                product.name ?? '',
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.labelLarge?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              Text(
                '${context.l10n.currencyEtb} ${product.formatted_price ?? product.price ?? ''}',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: AppColors.primaryColor,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PopularProductCard extends StatelessWidget {
  const _PopularProductCard({
    required this.item,
    required this.onTap,
  });

  final PopularProductModel item;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final imageUrl = item.displayImage;
    final promoText = item.promoLabel;
    final shopName = item.shopName;
    final rating = item.shopRating;
    final deliveryFee = item.deliveryFee;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppColors.r12),
        child: Container(
          decoration: BoxDecoration(
            color: colorScheme.surface,
            borderRadius: BorderRadius.circular(AppColors.r12),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.06),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Stack(
                children: [
                  ClipRRect(
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(AppColors.r12),
                      topRight: Radius.circular(AppColors.r12),
                    ),
                    child: imageUrl.startsWith('http')
                        ? CachedNetworkImage(
                            imageUrl: imageUrl,
                            height: 180,
                            width: double.infinity,
                            fit: BoxFit.cover,
                            placeholder: (_, __) => Container(
                              height: 180,
                              color: colorScheme.surfaceContainerHighest,
                            ),
                            errorWidget: (_, __, ___) => _imagePlaceholder(
                              colorScheme,
                              height: 180,
                            ),
                          )
                        : _imagePlaceholder(colorScheme, height: 180),
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
                          color: AppColors.successColor,
                          borderRadius: BorderRadius.circular(AppColors.rFull),
                        ),
                        child: Text(
                          promoText,
                          style: theme.textTheme.labelSmall?.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.w700,
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
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${context.l10n.currencyEtb} ${item.displayPrice}',
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w700,
                        color: AppColors.primaryColor,
                      ),
                    ),
                    if (shopName != null && shopName.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(
                        shopName,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: colorScheme.onSurfaceVariant,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        if (rating > 0) ...[
                          Icon(Icons.star_rounded,
                              size: 16, color: AppColors.ratingFilled),
                          const SizedBox(width: 4),
                          Text(
                            rating.toStringAsFixed(1),
                            style: theme.textTheme.bodyMedium?.copyWith(
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(width: 12),
                        ],
                        if (deliveryFee > 0)
                          Text(
                            '${context.l10n.currencyEtb} $deliveryFee delivery',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: colorScheme.onSurfaceVariant,
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

  Widget _imagePlaceholder(ColorScheme colorScheme, {required double height}) {
    return Container(
      height: height,
      color: colorScheme.surfaceContainerHighest,
      child: Icon(
        Icons.shopping_bag_outlined,
        size: 50,
        color: colorScheme.onSurfaceVariant,
      ),
    );
  }
}

class _VendorSliderCard extends StatelessWidget {
  const _VendorSliderCard({
    required this.name,
    required this.avatarUrl,
    required this.onTap,
  });

  final String name;
  final String avatarUrl;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final colorScheme = Theme.of(context).colorScheme;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppColors.r12),
        child: SizedBox(
          width: 100,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 72,
                height: 72,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.1),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: ClipOval(
                  child: avatarUrl.startsWith('http')
                      ? CachedNetworkImage(
                          imageUrl: avatarUrl,
                          fit: BoxFit.cover,
                          placeholder: (_, __) => _avatarPlaceholder(colorScheme),
                          errorWidget: (_, __, ___) =>
                              _avatarPlaceholder(colorScheme),
                        )
                      : Image.asset(
                          avatarUrl,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) =>
                              _avatarPlaceholder(colorScheme),
                        ),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                name,
                style: textTheme.bodySmall?.copyWith(
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

  Widget _avatarPlaceholder(ColorScheme colorScheme) {
    return Container(
      color: colorScheme.surfaceContainerHighest,
      child: Icon(
        Icons.storefront_rounded,
        size: 32,
        color: colorScheme.onSurfaceVariant,
      ),
    );
  }
}

class _FeaturedShimmer extends StatelessWidget {
  const _FeaturedShimmer();

  @override
  Widget build(BuildContext context) {
    final colors = _shimmerColors(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Shimmer.fromColors(
            baseColor: colors.base,
            highlightColor: colors.highlight,
            child: Container(
              height: 20,
              width: 100,
              decoration: BoxDecoration(
                color: colors.block,
                borderRadius: BorderRadius.circular(6),
              ),
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: 190,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: 4,
              separatorBuilder: (_, __) => const SizedBox(width: 12),
              itemBuilder: (_, __) => Shimmer.fromColors(
                baseColor: colors.base,
                highlightColor: colors.highlight,
                child: Container(
                  width: 150,
                  decoration: BoxDecoration(
                    color: colors.block,
                    borderRadius: BorderRadius.circular(AppColors.r12),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _PopularShimmer extends StatelessWidget {
  const _PopularShimmer();

  @override
  Widget build(BuildContext context) {
    final colors = _shimmerColors(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 24, 16, 0),
      child: Column(
        children: List.generate(
          2,
          (_) => Padding(
            padding: const EdgeInsets.only(bottom: 16),
            child: Shimmer.fromColors(
              baseColor: colors.base,
              highlightColor: colors.highlight,
              child: Container(
                height: 240,
                decoration: BoxDecoration(
                  color: colors.block,
                  borderRadius: BorderRadius.circular(AppColors.r12),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _VendorsShimmer extends StatelessWidget {
  const _VendorsShimmer();

  @override
  Widget build(BuildContext context) {
    final colors = _shimmerColors(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      child: SizedBox(
        height: 130,
        child: ListView.builder(
          scrollDirection: Axis.horizontal,
          itemCount: 6,
          itemBuilder: (_, __) => Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: Shimmer.fromColors(
              baseColor: colors.base,
              highlightColor: colors.highlight,
              child: Column(
                children: [
                  Container(
                    width: 72,
                    height: 72,
                    decoration: BoxDecoration(
                      color: colors.block,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    width: 70,
                    height: 10,
                    decoration: BoxDecoration(
                      color: colors.block,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

({Color base, Color highlight, Color block}) _shimmerColors(
  BuildContext context,
) {
  final isDark = Theme.of(context).brightness == Brightness.dark;
  return (
    base: isDark ? const Color(0xFF2B2B2B) : Colors.grey[300]!,
    highlight: isDark ? const Color(0xFF3A3A3A) : Colors.grey[100]!,
    block: isDark ? const Color(0xFF1F1F1F) : Colors.white,
  );
}
