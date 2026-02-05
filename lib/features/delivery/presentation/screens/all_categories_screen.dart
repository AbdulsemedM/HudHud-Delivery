import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hudhud_delivery/core/api/api_service.dart';
import 'package:hudhud_delivery/core/theme/app_colors.dart';
import 'package:hudhud_delivery/features/categories/bloc/categories_bloc.dart';
import 'package:hudhud_delivery/features/categories/data/data_provider/categories_data_provider.dart';
import 'package:hudhud_delivery/features/categories/data/repository/categories_repository.dart';
import 'package:hudhud_delivery/features/categories/model/category_tree_model.dart';
import 'package:hudhud_delivery/features/categories/presentation/screens/categories_screen.dart';

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
          CategoriesBloc(repository)..add(FetchCategoriesTreeEvent()),
      child: const _AllCategoriesBody(),
    );
  }
}

class _AllCategoriesBody extends StatelessWidget {
  const _AllCategoriesBody();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.lightBackground,
      appBar: AppBar(
        title: const Text(
          'Browse Categories',
          style: TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 18,
            color: AppColors.lightTextPrimary,
          ),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        scrolledUnderElevation: 2,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
          color: AppColors.lightTextPrimary,
          onPressed: () => Navigator.pop(context),
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(
            color: AppColors.lightBorder.withOpacity(0.5),
            height: 1,
          ),
        ),
      ),
      body: BlocBuilder<CategoriesBloc, CategoriesState>(
        buildWhen: (prev, curr) =>
            curr is FetchCategoriesTreeLoading ||
            curr is FetchCategoriesTreeSuccess ||
            curr is FetchCategoriesTreeFailure,
        builder: (context, state) {
          if (state is FetchCategoriesTreeLoading) {
            return const _LoadingState();
          }
          if (state is FetchCategoriesTreeFailure) {
            return _ErrorState(
              message: state.errorMessage,
              onRetry: () => context
                  .read<CategoriesBloc>()
                  .add(FetchCategoriesTreeEvent()),
            );
          }
          if (state is FetchCategoriesTreeSuccess) {
            final roots = state.categoriesTree;
            if (roots.isEmpty) {
              return const _EmptyState();
            }
            return _CategoriesGrid(
              categories: roots,
              onCategoryTap: (category) => _onCategoryTap(context, category),
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
    return CustomScrollView(
      slivers: [
        SliverPadding(
          padding: const EdgeInsets.all(16),
          sliver: SliverGrid(
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              childAspectRatio: 0.9,
            ),
            delegate: SliverChildBuilderDelegate(
              (context, index) => _CategorySkeleton(),
              childCount: 6,
            ),
          ),
        ),
      ],
    );
  }
}

class _CategorySkeleton extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
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
        children: [
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              color: Colors.grey[200],
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          const SizedBox(height: 12),
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 16),
            height: 12,
            decoration: BoxDecoration(
              color: Colors.grey[200],
              borderRadius: BorderRadius.circular(4),
            ),
          ),
          const SizedBox(height: 6),
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 24),
            height: 10,
            decoration: BoxDecoration(
              color: Colors.grey[100],
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
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: AppColors.lightTextPrimary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              message,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                color: AppColors.lightTextSecondary,
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
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: AppColors.lightTextDisabled.withOpacity(0.2),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.category_outlined,
                size: 56,
                color: AppColors.lightTextDisabled,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'No categories yet',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: AppColors.lightTextPrimary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Check back later for new categories',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                color: AppColors.lightTextSecondary,
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
  final void Function(CategoryTreeModel) onCategoryTap;

  const _CategoriesGrid({
    required this.categories,
    required this.onCategoryTap,
  });

  @override
  Widget build(BuildContext context) {
    return CustomScrollView(
      slivers: [
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 20, 16, 8),
            child: Text(
              '${categories.length} categories',
              style: TextStyle(
                fontSize: 13,
                color: AppColors.lightTextSecondary,
              ),
            ),
          ),
        ),
        SliverPadding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          sliver: SliverGrid(
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              childAspectRatio: 0.88,
            ),
            delegate: SliverChildBuilderDelegate(
              (context, index) {
                final category = categories[index];
                return _CategoryCard(
                  category: category,
                  onTap: () => onCategoryTap(category),
                );
              },
              childCount: categories.length,
            ),
          ),
        ),
        const SliverToBoxAdapter(child: SizedBox(height: 24)),
      ],
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
    final icon = _iconFromMeta(category.meta);
    final imageUrl = category.displayImageUrl;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.06),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(
                flex: 3,
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Center(
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: imageUrl != null && imageUrl.isNotEmpty
                          ? Image.network(
                              imageUrl,
                              width: double.infinity,
                              height: double.infinity,
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
              Expanded(
                flex: 2,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        category.name,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: AppColors.lightTextPrimary,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      if (category.productsCount > 0) ...[
                        const SizedBox(height: 4),
                        Text(
                          '${category.productsCount} products',
                          style: TextStyle(
                            fontSize: 12,
                            color: AppColors.lightTextSecondary,
                          ),
                        ),
                      ],
                    ],
                  ),
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
