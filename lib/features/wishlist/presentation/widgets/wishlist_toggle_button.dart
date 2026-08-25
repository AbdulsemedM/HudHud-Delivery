import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hudhud_delivery/app/services/auth_service.dart';
import 'package:hudhud_delivery/features/categories/model/categories_products_model.dart';
import 'package:hudhud_delivery/features/wishlist/bloc/wishlist_bloc.dart';
import 'package:hudhud_delivery/l10n/app_localizations.dart';

class WishlistToggleButton extends StatefulWidget {
  final CategoriesProductsModel product;
  final Color? color;
  final double size;

  const WishlistToggleButton({
    super.key,
    required this.product,
    this.color,
    this.size = 22,
  });

  @override
  State<WishlistToggleButton> createState() => _WishlistToggleButtonState();
}

class _WishlistToggleButtonState extends State<WishlistToggleButton> {
  final AuthService _auth = AuthService();

  int? _userId;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _bootstrap();
  }

  Future<void> _bootstrap() async {
    final user = await _auth.getStoredUser();
    if (!mounted) return;
    final userId = user?.id;
    setState(() {
      _userId = userId;
      _loading = false;
    });
    if (userId != null) {
      final bloc = context.read<WishlistBloc>();
      if (bloc.state is! WishlistLoaded) {
        bloc.add(LoadWishlistEvent(userId: userId));
      }
    }
  }

  void _toggle() {
    final userId = _userId;
    final productId = widget.product.id;
    if (userId == null || productId == null) return;

    final bloc = context.read<WishlistBloc>();
    final state = bloc.state;
    final wasWishlisted = state is WishlistLoaded
        ? state.wishlistedProductIds.contains(productId)
        : false;

    bloc.add(ToggleWishlistEvent(userId: userId, product: widget.product));

    if (!mounted) return;
    final l10n = AppLocalizations.of(context)!;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          wasWishlisted ? l10n.wishlistRemovedSnack : l10n.wishlistAddedSnack,
        ),
        duration: const Duration(milliseconds: 900),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final productId = widget.product.id;
    final userId = _userId;
    final disabled = userId == null || productId == null;
    final colorScheme = Theme.of(context).colorScheme;

    return BlocBuilder<WishlistBloc, WishlistState>(
      builder: (context, state) {
        bool isWishlisted = false;
        if (productId != null && state is WishlistLoaded) {
          isWishlisted = state.wishlistedProductIds.contains(productId);
        }

        final muted = widget.color ??
            (isWishlisted ? Colors.red : colorScheme.onSurfaceVariant);

        final l10n = AppLocalizations.of(context)!;
        return IconButton(
          tooltip: isWishlisted
              ? l10n.wishlistTooltipRemove
              : l10n.wishlistTooltipAdd,
          onPressed: disabled || _loading ? null : _toggle,
          icon: _loading
              ? SizedBox(
                  width: widget.size,
                  height: widget.size,
                  child: const CircularProgressIndicator(strokeWidth: 2),
                )
              : Icon(
                  isWishlisted ? Icons.favorite : Icons.favorite_border,
                  color: muted,
                  size: widget.size,
                ),
        );
      },
    );
  }
}
