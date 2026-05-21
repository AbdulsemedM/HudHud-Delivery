import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hudhud_delivery/app/services/auth_service.dart';
import 'package:hudhud_delivery/core/theme/app_colors.dart';
import 'package:hudhud_delivery/features/categories/model/categories_products_model.dart';
import 'package:hudhud_delivery/features/delivery/presentation/screens/product_detail_screen.dart';
import 'package:hudhud_delivery/features/login/presentation/screen/login_screen.dart';
import 'package:hudhud_delivery/features/wishlist/bloc/wishlist_bloc.dart';
import 'package:hudhud_delivery/l10n/app_localizations.dart';

class WishlistScreen extends StatefulWidget {
  const WishlistScreen({super.key});

  @override
  State<WishlistScreen> createState() => _WishlistScreenState();
}

class _WishlistScreenState extends State<WishlistScreen> {
  final AuthService _auth = AuthService();
  int? _userId;
  bool _resolvingUser = true;

  @override
  void initState() {
    super.initState();
    _resolveUser();
  }

  Future<void> _resolveUser() async {
    final user = await _auth.getStoredUser();
    if (!mounted) return;
    final id = user?.id;
    setState(() {
      _userId = id;
      _resolvingUser = false;
    });
    if (id != null) {
      context.read<WishlistBloc>().add(LoadWishlistEvent(userId: id));
    }
  }

  Future<void> _onRefresh() async {
    final id = _userId;
    if (id == null) return;
    context.read<WishlistBloc>().add(RefreshWishlistEvent(userId: id));
    await context.read<WishlistBloc>().stream.firstWhere(
          (s) => s is WishlistLoaded || s is WishlistError,
        );
  }

  String _priceLabel(CategoriesProductsModel p) {
    final formatted = p.formatted_price ?? p.current_price;
    if (formatted != null && formatted.isNotEmpty) return formatted;
    final raw = p.price;
    if (raw != null && raw.isNotEmpty) return 'ETB $raw';
    return '—';
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    if (_resolvingUser) {
      return Scaffold(
        appBar: AppBar(
          title: Text(l10n.settingsWishlist),
        ),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    if (_userId == null) {
      return Scaffold(
        appBar: AppBar(
          title: Text(l10n.settingsWishlist),
        ),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.favorite_border,
                    size: 64, color: cs.onSurfaceVariant),
                const SizedBox(height: 16),
                Text(
                  l10n.wishlistSignInTitle,
                  textAlign: TextAlign.center,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  l10n.wishlistSignInSubtitle,
                  textAlign: TextAlign.center,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: cs.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 24),
                FilledButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const LoginScreen()),
                    ).then((_) {
                      if (context.mounted) _resolveUser();
                    });
                  },
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.primaryColor,
                    foregroundColor: Colors.white,
                  ),
                  child: Text(l10n.actionSignIn),
                ),
              ],
            ),
          ),
        ),
      );
    }

    final userId = _userId!;

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.settingsWishlist),
      ),
      body: BlocBuilder<WishlistBloc, WishlistState>(
        builder: (context, state) {
          if (state is WishlistLoading) {
            return const Center(child: CircularProgressIndicator());
          }
          if (state is WishlistError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      l10n.wishlistLoadError,
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      state.message,
                      textAlign: TextAlign.center,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: cs.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: 16),
                    FilledButton(
                      onPressed: () {
                        context.read<WishlistBloc>().add(
                              LoadWishlistEvent(userId: userId),
                            );
                      },
                      child: Text(l10n.actionRetry),
                    ),
                  ],
                ),
              ),
            );
          }
          if (state is! WishlistLoaded) {
            return const SizedBox.shrink();
          }
          final items = state.items;
          if (items.isEmpty) {
            return RefreshIndicator(
              onRefresh: _onRefresh,
              child: ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                children: [
                  SizedBox(
                    height: MediaQuery.of(context).size.height * 0.5,
                    child: Center(
                      child: Padding(
                        padding: const EdgeInsets.all(24),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.favorite_border,
                              size: 56,
                              color: cs.onSurfaceVariant,
                            ),
                            const SizedBox(height: 16),
                            Text(
                              l10n.wishlistEmptyTitle,
                              textAlign: TextAlign.center,
                              style: theme.textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              l10n.wishlistEmptySubtitle,
                              textAlign: TextAlign.center,
                              style: theme.textTheme.bodyMedium?.copyWith(
                                color: cs.onSurfaceVariant,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            );
          }

          return RefreshIndicator(
            onRefresh: _onRefresh,
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(vertical: 8),
              itemCount: items.length,
              itemBuilder: (context, index) {
                final product = items[index];
                final pid = product.id;
                if (pid == null) return const SizedBox.shrink();

                return Material(
                  color: cs.surface,
                  child: ListTile(
                    contentPadding:
                        const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    leading: ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: _WishlistProductThumb(
                          imageUrl: product.image_path ?? ''),
                    ),
                    title: Text(
                      product.name ?? '',
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    subtitle: Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _priceLabel(product),
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: AppColors.primaryColor,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          if (!product.canOrder) ...[
                            const SizedBox(height: 4),
                            Text(
                              'Unavailable',
                              style: theme.textTheme.labelSmall?.copyWith(
                                color: cs.onSurfaceVariant,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                    trailing: IconButton(
                      icon: Icon(Icons.delete_outline,
                          color: cs.onSurfaceVariant),
                      tooltip: l10n.actionDelete,
                      onPressed: () {
                        context.read<WishlistBloc>().add(
                              RemoveWishlistEvent(
                                userId: userId,
                                productId: pid,
                              ),
                            );
                      },
                    ),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => ProductDetailScreen(productId: pid),
                        ),
                      );
                    },
                  ),
                );
              },
            ),
          );
        },
      ),
    );
  }
}

class _WishlistProductThumb extends StatelessWidget {
  final String imageUrl;

  const _WishlistProductThumb({required this.imageUrl});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    const size = 72.0;
    if (imageUrl.isEmpty) {
      return Container(
        width: size,
        height: size,
        color: cs.surfaceContainerHighest,
        child: Icon(Icons.image_not_supported_outlined,
            color: cs.onSurfaceVariant),
      );
    }
    if (imageUrl.startsWith('http')) {
      return Image.network(
        imageUrl,
        width: size,
        height: size,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => Container(
          width: size,
          height: size,
          color: cs.surfaceContainerHighest,
          child: Icon(Icons.broken_image_outlined, color: cs.onSurfaceVariant),
        ),
      );
    }
    return Image.asset(
      imageUrl,
      width: size,
      height: size,
      fit: BoxFit.cover,
      errorBuilder: (_, __, ___) => Container(
        width: size,
        height: size,
        color: cs.surfaceContainerHighest,
        child: Icon(Icons.broken_image_outlined, color: cs.onSurfaceVariant),
      ),
    );
  }
}
