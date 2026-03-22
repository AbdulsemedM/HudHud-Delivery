import 'package:flutter/material.dart';
import 'package:hudhud_delivery/app/services/auth_service.dart';
import 'package:hudhud_delivery/features/categories/model/categories_products_model.dart';
import 'package:hudhud_delivery/features/wishlist/data/wishlist_repository.dart';

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
  final WishlistRepository _repo = WishlistRepository();
  final AuthService _auth = AuthService();

  int? _userId;
  bool _loading = true;
  bool _wishlisted = false;

  @override
  void initState() {
    super.initState();
    _bootstrap();
  }

  Future<void> _bootstrap() async {
    final user = await _auth.getStoredUser();
    final userId = user?.id;
    final productId = widget.product.id;
    if (!mounted) return;

    if (userId == null || productId == null) {
      setState(() {
        _userId = userId;
        _loading = false;
        _wishlisted = false;
      });
      return;
    }

    final isSaved = await _repo.isWishlisted(userId: userId, productId: productId);
    if (!mounted) return;
    setState(() {
      _userId = userId;
      _loading = false;
      _wishlisted = isSaved;
    });
  }

  Future<void> _toggle() async {
    final userId = _userId;
    final productId = widget.product.id;
    if (userId == null || productId == null) return;

    setState(() {
      _loading = true;
      _wishlisted = !_wishlisted;
    });

    try {
      await _repo.toggleWishlist(userId: userId, product: widget.product);
      if (!mounted) return;
      setState(() => _loading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(_wishlisted ? 'Added to wishlist' : 'Removed from wishlist'),
          duration: const Duration(milliseconds: 900),
        ),
      );
    } catch (_) {
      // Re-sync on failure
      final isSaved = await _repo.isWishlisted(userId: userId, productId: productId);
      if (!mounted) return;
      setState(() {
        _loading = false;
        _wishlisted = isSaved;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final productId = widget.product.id;
    final disabled = _userId == null || productId == null;

    return IconButton(
      tooltip: _wishlisted ? 'Remove from wishlist' : 'Add to wishlist',
      onPressed: disabled || _loading ? null : _toggle,
      icon: _loading
          ? SizedBox(
              width: widget.size,
              height: widget.size,
              child: const CircularProgressIndicator(strokeWidth: 2),
            )
          : Icon(
              _wishlisted ? Icons.favorite : Icons.favorite_border,
              color: widget.color ?? (_wishlisted ? Colors.red : Colors.grey[700]),
              size: widget.size,
            ),
    );
  }
}

