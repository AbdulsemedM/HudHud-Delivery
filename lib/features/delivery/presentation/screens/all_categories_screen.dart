import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hudhud_delivery/core/api/api_service.dart';
import 'package:hudhud_delivery/core/theme/app_colors.dart';
import 'package:hudhud_delivery/features/categories/bloc/categories_bloc.dart';
import 'package:hudhud_delivery/features/categories/data/data_provider/categories_data_provider.dart';
import 'package:hudhud_delivery/features/categories/data/repository/categories_repository.dart';
import 'package:hudhud_delivery/features/categories/model/category_tree_model.dart';
import 'category_stores_screen.dart';

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
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('All categories'),
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: BlocBuilder<CategoriesBloc, CategoriesState>(
        buildWhen: (prev, curr) =>
            curr is FetchCategoriesTreeLoading ||
            curr is FetchCategoriesTreeSuccess ||
            curr is FetchCategoriesTreeFailure,
        builder: (context, state) {
          if (state is FetchCategoriesTreeLoading) {
            return const Center(child: CircularProgressIndicator());
          }
          if (state is FetchCategoriesTreeFailure) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      state.errorMessage,
                      textAlign: TextAlign.center,
                      style: const TextStyle(color: Colors.red),
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: () => context
                          .read<CategoriesBloc>()
                          .add(FetchCategoriesTreeEvent()),
                      child: const Text('Retry'),
                    ),
                  ],
                ),
              ),
            );
          }
          if (state is FetchCategoriesTreeSuccess) {
            final roots = state.categoriesTree;
            if (roots.isEmpty) {
              return const Center(
                  child: Text('No categories available.'));
            }
            return GridView.builder(
              padding: const EdgeInsets.all(16),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 4,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
                childAspectRatio: 0.85,
              ),
              itemCount: roots.length,
              itemBuilder: (context, index) {
                final category = roots[index];
                return _CategoryTreeGridItem(
                  category: category,
                  onTap: () => _onCategoryTap(context, category),
                );
              },
            );
          }
          return const SizedBox.shrink();
        },
      ),
    );
  }

  void _onCategoryTap(BuildContext context, CategoryTreeModel category) {
    final icon = _iconFromMeta(category.meta);
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => CategoryStoresScreen(
          categoryName: category.name,
          categoryIcon: icon,
        ),
      ),
    );
  }

  static IconData _iconFromMeta(Map<String, dynamic>? meta) {
    if (meta == null) return Icons.category;
    final name = (meta['icon'] as String?)?.toLowerCase();
    const map = {
      'tv': Icons.tv,
      'mobile': Icons.smartphone,
      'laptop': Icons.laptop,
      'tshirt': Icons.checkroom,
      'male': Icons.male,
      'female': Icons.female,
      'home': Icons.home,
      'basketball-ball': Icons.sports_basketball,
      'spa': Icons.spa,
      'book': Icons.menu_book,
      'gamepad': Icons.sports_esports,
    };
    return map[name ?? ''] ?? Icons.category;
  }
}

class _CategoryTreeGridItem extends StatelessWidget {
  final CategoryTreeModel category;
  final VoidCallback onTap;

  const _CategoryTreeGridItem({
    required this.category,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final icon = _iconFromMeta(category.meta);
    final imageUrl = category.displayImageUrl;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.grey[50],
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: Colors.grey[200]!,
            width: 1,
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (imageUrl != null && imageUrl.isNotEmpty)
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Image.network(
                  imageUrl,
                  height: 40,
                  width: 40,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => Icon(
                    icon,
                    size: 32,
                    color: AppColors.primaryColor,
                  ),
                ),
              )
            else
              Icon(
                icon,
                size: 32,
                color: AppColors.primaryColor,
              ),
            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: Text(
                category.name,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: Color(0xFF2C3E50),
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }

  static IconData _iconFromMeta(Map<String, dynamic>? meta) {
    if (meta == null) return Icons.category;
    final name = (meta['icon'] as String?)?.toLowerCase();
    const map = {
      'tv': Icons.tv,
      'mobile': Icons.smartphone,
      'laptop': Icons.laptop,
      'tshirt': Icons.checkroom,
      'male': Icons.male,
      'female': Icons.female,
      'home': Icons.home,
      'basketball-ball': Icons.sports_basketball,
      'spa': Icons.spa,
      'book': Icons.menu_book,
      'gamepad': Icons.sports_esports,
    };
    return map[name ?? ''] ?? Icons.category;
  }
}
