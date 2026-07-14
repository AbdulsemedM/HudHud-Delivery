import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hudhud_delivery/app/services/auth_service.dart';
import 'package:hudhud_delivery/core/utils/snackbar_util.dart';
import 'package:hudhud_delivery/features/categories/model/categories_products_model.dart';
import 'package:hudhud_delivery/features/delivery/presentation/screens/product_detail_screen.dart';
import 'package:hudhud_delivery/features/login/presentation/screen/login_screen.dart';
import 'package:hudhud_delivery/features/login/presentation/theme/auth_screen_colors.dart';
import 'package:hudhud_delivery/features/settings/presentation/widgets/auth_feedback.dart';
import 'package:hudhud_delivery/features/settings/presentation/widgets/profile_dark_page.dart';
import 'package:hudhud_delivery/features/wishlist/bloc/wishlist_bloc.dart';
import 'package:hudhud_delivery/features/wishlist/model/wishlist_item_model.dart';
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

  String _priceLabel(CategoriesProductsModel? p) {
    if (p == null) return '—';
    final formatted = p.formatted_price ?? p.current_price;
    if (formatted != null && formatted.isNotEmpty) return formatted;
    final raw = p.price;
    if (raw != null && raw.isNotEmpty) return 'ETB $raw';
    return '—';
  }

  Future<void> _showShareDialog() async {
    final l10n = AppLocalizations.of(context)!;
    final emailController = TextEditingController();
    final result = await AuthModal.dialog<bool>(
      context: context,
      builder: (ctx) => AuthAlertDialog(
        title: l10n.wishlistShareTitle,
        content: TextField(
          controller: emailController,
          keyboardType: TextInputType.emailAddress,
          decoration: InputDecoration(
            labelText: l10n.sosEmail,
          ),
        ),
        actions: [
          AuthDialogAction(
            label: l10n.actionCancel,
            onPressed: () => Navigator.pop(ctx, false),
          ),
          AuthDialogAction(
            label: l10n.actionOk,
            filled: true,
            onPressed: () => Navigator.pop(ctx, true),
          ),
        ],
      ),
    );
    if (result != true || !mounted) return;
    final email = emailController.text.trim();
    if (email.isEmpty) return;
    context.read<WishlistBloc>().add(ShareWishlistEvent(email: email));
  }

  Future<void> _showNotesSheet(WishlistItemModel item) async {
    final l10n = AppLocalizations.of(context)!;
    final controller = TextEditingController(text: item.notes ?? '');
    final saved = await AuthModal.sheet<bool>(
      context: context,
      isScrollControlled: true,
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(
          left: 16,
          right: 16,
          top: 16,
          bottom: MediaQuery.of(ctx).viewInsets.bottom + 16,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: AuthScreenColors.surfaceBorder,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            TextField(
              controller: controller,
              maxLines: 3,
              decoration: InputDecoration(
                hintText: l10n.wishlistNotesHint,
              ),
            ),
            const SizedBox(height: 12),
            FilledButton(
              onPressed: () => Navigator.pop(ctx, true),
              style: FilledButton.styleFrom(
                backgroundColor: AuthScreenColors.orange,
                foregroundColor: Colors.black,
                shape: const StadiumBorder(),
              ),
              child: Text(l10n.actionSave),
            ),
          ],
        ),
      ),
    );
    if (saved != true || !mounted) return;
    context.read<WishlistBloc>().add(
          UpdateWishlistNotesEvent(
            wishlistId: item.id,
            notes: controller.text.trim(),
          ),
        );
  }

  void _checkPriceDrops() {
    context.read<WishlistBloc>().add(const CheckPriceDropsEvent());
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    if (_resolvingUser) {
      return ProfileDarkPage(
        title: l10n.settingsWishlist,
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    if (_userId == null) {
      return ProfileDarkPage(
        title: l10n.settingsWishlist,
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(
                  Icons.favorite_border,
                  size: 64,
                  color: AuthScreenColors.textMuted,
                ),
                const SizedBox(height: 16),
                Text(
                  l10n.wishlistSignInTitle,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: AuthScreenColors.textPrimary,
                    fontWeight: FontWeight.w600,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  l10n.wishlistSignInSubtitle,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: AuthScreenColors.textSecondary,
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
                    backgroundColor: AuthScreenColors.orange,
                    foregroundColor: Colors.black,
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

    return BlocListener<WishlistBloc, WishlistState>(
      listener: (context, state) {
        if (state is WishlistLoaded && state.lastShareResult != null) {
          SnackbarUtil.showSuccess(
            context,
            l10n.wishlistShareSuccess,
          );
        }
        if (state is WishlistShareSuccess) {
          SnackbarUtil.showSuccess(context, l10n.wishlistShareSuccess);
        }
        if (state is WishlistPriceDropsChecked) {
          final msg = state.result.totalDrops > 0
              ? '${l10n.wishlistPriceDropsTitle}: ${state.result.totalDrops}'
              : l10n.wishlistPriceDropsEmpty;
          SnackbarUtil.showSuccess(context, msg);
        }
        if (state is WishlistLoaded && state.priceDropsResult != null) {
          final drops = state.priceDropsResult!;
          final msg = drops.totalDrops > 0
              ? '${l10n.wishlistPriceDropsTitle}: ${drops.totalDrops}'
              : l10n.wishlistPriceDropsEmpty;
          SnackbarUtil.showSuccess(context, msg);
        }
      },
      child: ProfileDarkPage(
        title: l10n.settingsWishlist,
        actions: [
          IconButton(
            icon: const Icon(Icons.trending_down),
            tooltip: l10n.wishlistPriceDropsTitle,
            onPressed: _checkPriceDrops,
          ),
          IconButton(
            icon: const Icon(Icons.share_outlined),
            tooltip: l10n.wishlistShareTitle,
            onPressed: _showShareDialog,
          ),
        ],
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
                        style: const TextStyle(
                          color: AuthScreenColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        state.message,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          color: AuthScreenColors.textSecondary,
                          fontSize: 12,
                        ),
                      ),
                      const SizedBox(height: 16),
                      FilledButton(
                        onPressed: () {
                          context.read<WishlistBloc>().add(
                                LoadWishlistEvent(userId: userId),
                              );
                        },
                        style: FilledButton.styleFrom(
                          backgroundColor: AuthScreenColors.orange,
                          foregroundColor: Colors.black,
                        ),
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
                              const Icon(
                                Icons.favorite_border,
                                size: 56,
                                color: AuthScreenColors.textMuted,
                              ),
                              const SizedBox(height: 16),
                              Text(
                                l10n.wishlistEmptyTitle,
                                textAlign: TextAlign.center,
                                style: const TextStyle(
                                  color: AuthScreenColors.textPrimary,
                                  fontWeight: FontWeight.w600,
                                  fontSize: 16,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                l10n.wishlistEmptySubtitle,
                                textAlign: TextAlign.center,
                                style: const TextStyle(
                                  color: AuthScreenColors.textSecondary,
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
                  final item = items[index];
                  final product = item.product;
                  final pid = item.productId;
                  if (pid <= 0) return const SizedBox.shrink();

                  return Material(
                    color: AuthScreenColors.surface,
                    child: ListTile(
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                      leading: ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: _WishlistProductThumb(
                          imageUrl: product?.image_path ?? '',
                        ),
                      ),
                      title: Text(
                        product?.name ?? '',
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: AuthScreenColors.textPrimary,
                          fontWeight: FontWeight.w600,
                          fontSize: 14,
                        ),
                      ),
                      subtitle: Padding(
                        padding: const EdgeInsets.only(top: 4),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              _priceLabel(product),
                              style: const TextStyle(
                                color: AuthScreenColors.orange,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            if (item.notes != null &&
                                item.notes!.trim().isNotEmpty) ...[
                              const SizedBox(height: 4),
                              Text(
                                item.notes!,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  color: AuthScreenColors.textSecondary,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                            if (item.priceDrop?.hasDropped == true) ...[
                              const SizedBox(height: 4),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 2,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.green.withValues(alpha: 0.12),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Text(
                                  l10n.wishlistPriceDropsTitle,
                                  style: TextStyle(
                                    color: Colors.green.shade400,
                                    fontWeight: FontWeight.w600,
                                    fontSize: 11,
                                  ),
                                ),
                              ),
                            ],
                            if (product != null && !product.canOrder) ...[
                              const SizedBox(height: 4),
                              const Text(
                                'Unavailable',
                                style: TextStyle(
                                  color: AuthScreenColors.textMuted,
                                  fontWeight: FontWeight.w600,
                                  fontSize: 11,
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            icon: const Icon(
                              Icons.note_alt_outlined,
                              color: AuthScreenColors.textMuted,
                            ),
                            tooltip: l10n.wishlistNotesHint,
                            onPressed: () => _showNotesSheet(item),
                          ),
                          IconButton(
                            icon: const Icon(
                              Icons.delete_outline,
                              color: AuthScreenColors.textMuted,
                            ),
                            tooltip: l10n.actionDelete,
                            onPressed: () {
                              context.read<WishlistBloc>().add(
                                    RemoveWishlistEvent(
                                      userId: userId,
                                      wishlistId: item.id,
                                      productId: pid,
                                    ),
                                  );
                            },
                          ),
                        ],
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
      ),
    );
  }
}

class _WishlistProductThumb extends StatelessWidget {
  final String imageUrl;

  const _WishlistProductThumb({required this.imageUrl});

  @override
  Widget build(BuildContext context) {
    const size = 72.0;
    if (imageUrl.isEmpty) {
      return Container(
        width: size,
        height: size,
        color: AuthScreenColors.surfaceBorder,
        child: const Icon(
          Icons.image_not_supported_outlined,
          color: AuthScreenColors.textMuted,
        ),
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
          color: AuthScreenColors.surfaceBorder,
          child: const Icon(
            Icons.broken_image_outlined,
            color: AuthScreenColors.textMuted,
          ),
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
        color: AuthScreenColors.surfaceBorder,
        child: const Icon(
          Icons.broken_image_outlined,
          color: AuthScreenColors.textMuted,
        ),
      ),
    );
  }
}
