import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';
import 'package:shimmer/shimmer.dart';
import 'package:hudhud_delivery/app/navigation/cart_navigation.dart';
import 'package:hudhud_delivery/app/services/cart_service.dart';
import 'package:hudhud_delivery/core/api/api_service.dart';
import 'package:hudhud_delivery/core/l10n/context_l10n.dart';
import 'package:hudhud_delivery/core/theme/app_colors.dart';
import 'package:hudhud_delivery/core/utils/money_format.dart';
import 'package:hudhud_delivery/features/categories/data/data_provider/categories_data_provider.dart';
import 'package:hudhud_delivery/features/categories/data/repository/categories_repository.dart';
import 'package:hudhud_delivery/features/categories/model/categories_products_model.dart';
import 'package:hudhud_delivery/features/home/presentation/theme/home_colors.dart';
import 'package:hudhud_delivery/features/wishlist/presentation/widgets/wishlist_toggle_button.dart';

class ProductDetailScreen extends StatefulWidget {
  final int productId;

  const ProductDetailScreen({
    super.key,
    required this.productId,
  });

  @override
  State<ProductDetailScreen> createState() => _ProductDetailScreenState();
}

class _ProductDetailScreenState extends State<ProductDetailScreen> {
  final CategoriesRepository _repository = CategoriesRepository(
    categoriesDataProvider:
        CategoriesDataProvider(apiService: ApiService.instance),
  );
  final CartService _cart = CartService();

  CategoriesProductsModel? _product;
  bool _loading = true;
  String? _error;
  int? _selectedVariantId;
  final Set<int> _selectedModifierIds = {};

  @override
  void initState() {
    super.initState();
    _loadProduct();
  }

  List<Map<String, dynamic>> get _variants {
    final options = _product?.options;
    if (options == null) return const [];
    final raw = options['variants'] ?? options['variant_options'];
    if (raw is! List) return const [];
    return raw
        .whereType<Map>()
        .map((e) => Map<String, dynamic>.from(e))
        .toList();
  }

  List<Map<String, dynamic>> get _modifierOptions {
    final options = _product?.options;
    if (options == null) return const [];
    final groups = options['modifier_groups'] ?? options['modifiers'];
    if (groups is! List) return const [];
    final out = <Map<String, dynamic>>[];
    for (final group in groups) {
      if (group is! Map) continue;
      final opts = group['options'] ?? group['modifier_options'];
      if (opts is! List) continue;
      for (final opt in opts) {
        if (opt is Map) out.add(Map<String, dynamic>.from(opt));
      }
    }
    return out;
  }

  CategoriesProductsModel _productForCart(CategoriesProductsModel product) {
    final baseOptions = Map<String, dynamic>.from(product.options ?? {});
    if (_selectedVariantId != null) {
      baseOptions['variant_id'] = _selectedVariantId;
    }
    if (_selectedModifierIds.isNotEmpty) {
      baseOptions['modifier_option_ids'] = _selectedModifierIds.toList();
    }
    return product.copyWith(options: baseOptions);
  }

  Future<void> _loadProduct() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final product = await _repository.getProductById(widget.productId);
      if (!mounted) return;
      setState(() {
        _product = product;
        _loading = false;
        if (product == null) _error = context.l10n.productNotFound;
      });
    } catch (e) {
      setState(() {
        _loading = false;
        _error = e.toString();
      });
    }
  }

  Future<void> _addToCart() async {
    final product = _product;
    if (product == null) return;
    if (!product.canOrder) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(context.l10n.productUnavailable),
          backgroundColor: Theme.of(context).colorScheme.error,
        ),
      );
      return;
    }
    if (_variants.isNotEmpty && _selectedVariantId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a variant')),
      );
      return;
    }
    final cartProduct = _productForCart(product);
    var result = _cart.addProduct(cartProduct);
    if (result == CartAddResult.differentVendor) {
      final replace = await _confirmReplaceCart();
      if (!mounted || replace != true) return;
      result = _cart.addProduct(cartProduct, replaceIfDifferentVendor: true);
    }
    if (result != CartAddResult.added || !mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('${product.name ?? 'Product'} added to cart'),
        action: SnackBarAction(
          label: 'Checkout',
          onPressed: () => openCheckoutFromCart(
            context,
            fallbackVendorId: product.vendor_id,
          ),
        ),
      ),
    );
  }

  Future<bool?> _confirmReplaceCart() {
    final l10n = context.l10n;
    return showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.cartDifferentVendorTitle),
        content: Text(l10n.cartDifferentVendorMessage),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(l10n.cartKeepCurrentAction),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(l10n.cartReplaceAction),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final dark = HomeColors.isDark(context);
    final ink = HomeColors.textPrimaryOf(context);

    return ListenableBuilder(
      listenable: _cart,
      builder: (context, _) {
        final product = _product;
        final cartQuantity = _cart.quantityFor(product?.id);
        final canOrder = product?.canOrder ?? false;

        return Scaffold(
          backgroundColor: HomeColors.backgroundOf(context),
          appBar: AppBar(
            backgroundColor: HomeColors.backgroundOf(context),
            surfaceTintColor: Colors.transparent,
            elevation: 0,
            scrolledUnderElevation: 0,
            centerTitle: true,
            leading: IconButton(
              icon: Icon(Icons.arrow_back_rounded, color: ink, size: 26),
              onPressed: () => Navigator.pop(context),
            ),
            actions: [
              if (product != null && product.id != null)
                Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: WishlistToggleButton(product: product, size: 24),
                ),
            ],
            title: Text(
              product?.name ?? 'Product',
              style: TextStyle(
                fontSize: 19,
                fontWeight: FontWeight.w800,
                letterSpacing: -0.3,
                color: ink,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          bottomNavigationBar: _cart.isEmpty
              ? null
              : _CartCheckoutBar(
                  totalItems: _cart.totalItems,
                  subtotal: _cart.subtotal,
                  onCheckout: () => openCheckoutFromCart(
                    context,
                    fallbackVendorId: product?.vendor_id,
                  ),
                ),
          body: _loading
              ? const _ProductDetailShimmer()
              : _error != null
                  ? _ProductErrorState(
                      message: _error!,
                      onRetry: _loadProduct,
                    )
                  : product == null
                      ? _ProductErrorState(
                          message: l10n.productNotFound,
                          onRetry: _loadProduct,
                        )
                      : SingleChildScrollView(
                          padding: const EdgeInsets.fromLTRB(16, 4, 16, 0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              Container(
                                height: 280,
                                decoration: BoxDecoration(
                                  color: HomeColors.surfaceOf(context),
                                  borderRadius: BorderRadius.circular(24),
                                  boxShadow: AppColors.softShadow(context),
                                ),
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(24),
                                  child: product.image_path != null &&
                                          product.image_path!.isNotEmpty
                                      ? Image.network(
                                          product.image_path!,
                                          height: 280,
                                          width: double.infinity,
                                          fit: BoxFit.cover,
                                          errorBuilder: (_, __, ___) =>
                                              _imagePlaceholder(context),
                                        )
                                      : _imagePlaceholder(context),
                                ),
                              ),
                              const SizedBox(height: 16),
                              Container(
                                padding: const EdgeInsets.all(18),
                                decoration: BoxDecoration(
                                  color: HomeColors.surfaceOf(context),
                                  borderRadius: BorderRadius.circular(24),
                                  border: dark
                                      ? Border.all(
                                          color: HomeColors.borderOf(context),
                                        )
                                      : null,
                                  boxShadow: AppColors.softShadow(context),
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      product.name ?? 'Product',
                                      style: TextStyle(
                                        fontSize: 24,
                                        height: 1.2,
                                        fontWeight: FontWeight.w800,
                                        letterSpacing: -0.5,
                                        color: ink,
                                      ),
                                    ),
                                    const SizedBox(height: 10),
                                    Wrap(
                                      crossAxisAlignment:
                                          WrapCrossAlignment.center,
                                      spacing: 10,
                                      runSpacing: 4,
                                      children: [
                                        Text(
                                          formatEtbPriceString(
                                            product.formatted_price ??
                                                product.price,
                                          ),
                                          style: TextStyle(
                                            fontSize: 26,
                                            fontWeight: FontWeight.w800,
                                            letterSpacing: -0.5,
                                            color: ink,
                                          ),
                                        ),
                                        if (product.is_on_discount == true &&
                                            product.formatted_original_price !=
                                                null)
                                          Text(
                                            formatEtbPriceString(
                                              product.formatted_original_price,
                                            ),
                                            style: TextStyle(
                                              fontSize: 15,
                                              fontWeight: FontWeight.w600,
                                              color: HomeColors.textMutedOf(
                                                context,
                                              ),
                                              decoration:
                                                  TextDecoration.lineThrough,
                                            ),
                                          ),
                                      ],
                                    ),
                                    if (product.description != null &&
                                        product.description!.isNotEmpty) ...[
                                      const SizedBox(height: 14),
                                      Text(
                                        product.description!,
                                        style: TextStyle(
                                          fontSize: 15,
                                          height: 1.5,
                                          fontWeight: FontWeight.w500,
                                          color: HomeColors.textSecondaryOf(
                                            context,
                                          ),
                                        ),
                                      ),
                                    ],
                                    if (_variants.isNotEmpty) ...[
                                      const SizedBox(height: 22),
                                      const _OptionsLabel(
                                        icon: Icons.tune_rounded,
                                        text: 'Options',
                                      ),
                                      const SizedBox(height: 10),
                                      Wrap(
                                        spacing: 8,
                                        runSpacing: 8,
                                        children: _variants.map((variant) {
                                          final id = variant['id'] is int
                                              ? variant['id'] as int
                                              : int.tryParse(
                                                  '${variant['id']}',
                                                );
                                          final label = variant['name']
                                                  ?.toString() ??
                                              variant['label']?.toString() ??
                                              'Option';
                                          final selected = id != null &&
                                              id == _selectedVariantId;
                                          return _OptionPill(
                                            label: label,
                                            selected: selected,
                                            onTap: id == null
                                                ? null
                                                : () => setState(
                                                      () => _selectedVariantId =
                                                          id,
                                                    ),
                                          );
                                        }).toList(),
                                      ),
                                    ],
                                    if (_modifierOptions.isNotEmpty) ...[
                                      const SizedBox(height: 18),
                                      const _OptionsLabel(
                                        icon: Icons.add_circle_rounded,
                                        text: 'Add-ons',
                                      ),
                                      const SizedBox(height: 10),
                                      Wrap(
                                        spacing: 8,
                                        runSpacing: 8,
                                        children: _modifierOptions.map((opt) {
                                          final id = opt['id'] is int
                                              ? opt['id'] as int
                                              : int.tryParse('${opt['id']}');
                                          final label =
                                              opt['name']?.toString() ??
                                                  opt['label']?.toString() ??
                                                  'Add-on';
                                          final selected = id != null &&
                                              _selectedModifierIds.contains(id);
                                          return _OptionPill(
                                            label: label,
                                            selected: selected,
                                            showCheck: true,
                                            onTap: id == null
                                                ? null
                                                : () {
                                                    setState(() {
                                                      if (!selected) {
                                                        _selectedModifierIds
                                                            .add(id);
                                                      } else {
                                                        _selectedModifierIds
                                                            .remove(id);
                                                      }
                                                    });
                                                  },
                                          );
                                        }).toList(),
                                      ),
                                    ],
                                    const SizedBox(height: 24),
                                    if (cartQuantity > 0)
                                      _CartQuantityControls(
                                        quantity: cartQuantity,
                                        onDecrement: () => _cart.decrement(
                                          product.id!.toString(),
                                        ),
                                        onIncrement: canOrder
                                            ? () => _cart.increment(
                                                  product.id!.toString(),
                                                )
                                            : null,
                                      )
                                    else
                                      SizedBox(
                                        width: double.infinity,
                                        height: 56,
                                        child: FilledButton.icon(
                                          onPressed:
                                              canOrder ? _addToCart : null,
                                          icon: const Icon(
                                            Icons.add_shopping_cart_rounded,
                                            size: 24,
                                          ),
                                          label: Text(l10n.actionAddToCart),
                                          style: FilledButton.styleFrom(
                                            backgroundColor:
                                                AppColors.brandOrange,
                                            foregroundColor: Colors.white,
                                            disabledBackgroundColor:
                                                HomeColors.surfaceElevatedOf(
                                              context,
                                            ),
                                            disabledForegroundColor:
                                                HomeColors.textMutedOf(context),
                                            textStyle: const TextStyle(
                                              fontSize: 17,
                                              fontWeight: FontWeight.w800,
                                            ),
                                            shape: RoundedRectangleBorder(
                                              borderRadius:
                                                  BorderRadius.circular(18),
                                            ),
                                          ),
                                        ),
                                      ),
                                  ],
                                ),
                              ),
                              SizedBox(height: _cart.isEmpty ? 24 : 104),
                            ],
                          ),
                        ),
        );
      },
    );
  }

  Widget _imagePlaceholder(BuildContext context) {
    final dark = HomeColors.isDark(context);
    return Container(
      height: 280,
      color: dark ? AppColors.orangeTintDark : AppColors.orangeTint,
      child: const Icon(
        Icons.shopping_bag_rounded,
        size: 80,
        color: AppColors.brandOrange,
      ),
    );
  }
}

class _OptionsLabel extends StatelessWidget {
  const _OptionsLabel({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 20, color: HomeColors.violetOf(context)),
        const SizedBox(width: 8),
        Text(
          text,
          style: TextStyle(
            fontSize: 17,
            fontWeight: FontWeight.w800,
            letterSpacing: -0.2,
            color: HomeColors.textPrimaryOf(context),
          ),
        ),
      ],
    );
  }
}

/// Large selectable option pill (indigo when selected).
class _OptionPill extends StatelessWidget {
  const _OptionPill({
    required this.label,
    required this.selected,
    required this.onTap,
    this.showCheck = false,
  });

  final String label;
  final bool selected;
  final VoidCallback? onTap;
  final bool showCheck;

  @override
  Widget build(BuildContext context) {
    final indigo = HomeColors.violetOf(context);
    return Material(
      color: selected ? indigo : HomeColors.surfaceOf(context),
      shape: StadiumBorder(
        side: BorderSide(
          color: selected ? indigo : HomeColors.borderOf(context),
          width: 1.4,
        ),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: 46),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (showCheck || selected) ...[
                  Icon(
                    selected
                        ? Icons.check_circle_rounded
                        : Icons.add_circle_outline_rounded,
                    size: 20,
                    color: selected
                        ? Colors.white
                        : HomeColors.textMutedOf(context),
                  ),
                  const SizedBox(width: 6),
                ],
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: selected
                        ? Colors.white
                        : HomeColors.textPrimaryOf(context),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _CartQuantityControls extends StatelessWidget {
  final int quantity;
  final VoidCallback onDecrement;
  final VoidCallback? onIncrement;

  const _CartQuantityControls({
    required this.quantity,
    required this.onDecrement,
    this.onIncrement,
  });

  @override
  Widget build(BuildContext context) {
    final dark = HomeColors.isDark(context);
    Widget roundButton(IconData icon, VoidCallback? onTap) => Material(
          color: onTap == null
              ? AppColors.brandOrange.withValues(alpha: 0.4)
              : AppColors.brandOrange,
          shape: const CircleBorder(),
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            onTap: onTap,
            child: SizedBox(
              width: 46,
              height: 46,
              child: Icon(icon, color: Colors.white, size: 24),
            ),
          ),
        );
    return Container(
      height: 58,
      padding: const EdgeInsets.symmetric(horizontal: 6),
      decoration: BoxDecoration(
        color: dark ? AppColors.orangeTintDark : AppColors.orangeTint,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Row(
        children: [
          roundButton(Icons.remove_rounded, onDecrement),
          Expanded(
            child: Text(
              '$quantity in cart',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w800,
                color: HomeColors.textPrimaryOf(context),
              ),
            ),
          ),
          roundButton(Icons.add_rounded, onIncrement),
        ],
      ),
    );
  }
}

class _CartCheckoutBar extends StatelessWidget {
  final int totalItems;
  final double subtotal;
  final VoidCallback onCheckout;

  const _CartCheckoutBar({
    required this.totalItems,
    required this.subtotal,
    required this.onCheckout,
  });

  @override
  Widget build(BuildContext context) {
    final dark = HomeColors.isDark(context);
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
      decoration: BoxDecoration(
        color: HomeColors.surfaceOf(context),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        border: dark
            ? Border(top: BorderSide(color: HomeColors.borderOf(context)))
            : null,
        boxShadow: dark
            ? null
            : const [
                BoxShadow(
                  color: AppColors.lightShadow,
                  blurRadius: 18,
                  offset: Offset(0, -6),
                ),
              ],
      ),
      child: SafeArea(
        top: false,
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: dark ? AppColors.orangeTintDark : AppColors.orangeTint,
                borderRadius: BorderRadius.circular(15),
              ),
              child: const Icon(
                Icons.shopping_bag_rounded,
                color: AppColors.brandOrange,
                size: 24,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'TOTAL ITEMS: $totalItems',
                    style: TextStyle(
                      color: HomeColors.textMutedOf(context),
                      fontSize: 12.5,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.3,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'ETB ${subtotal.toStringAsFixed(1)}',
                    maxLines: 1,
                    style: TextStyle(
                      color: HomeColors.textPrimaryOf(context),
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      letterSpacing: -0.3,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 10),
            SizedBox(
              height: 52,
              child: FilledButton(
                onPressed: onCheckout,
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.brandOrange,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 18),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'Go to Checkout',
                      style: TextStyle(
                        fontWeight: FontWeight.w800,
                        fontSize: 15,
                      ),
                    ),
                    SizedBox(width: 6),
                    Icon(Icons.arrow_forward_rounded, size: 20),
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

class _ProductDetailShimmer extends StatelessWidget {
  const _ProductDetailShimmer();

  @override
  Widget build(BuildContext context) {
    final base = HomeColors.surfaceElevatedOf(context);
    final highlight = HomeColors.surfaceOf(context);
    Widget block({double? w, required double h, double r = 8}) => Container(
          width: w,
          height: h,
          decoration: BoxDecoration(
            color: base,
            borderRadius: BorderRadius.circular(r),
          ),
        );

    return Shimmer.fromColors(
      baseColor: base,
      highlightColor: highlight,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 4, 16, 0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            block(h: 280, r: 24),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: highlight,
                borderRadius: BorderRadius.circular(24),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  block(w: 200, h: 24),
                  const SizedBox(height: 12),
                  block(w: 120, h: 24),
                  const SizedBox(height: 16),
                  block(h: 60),
                  const SizedBox(height: 24),
                  block(h: 56, r: 18),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ProductErrorState extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;

  const _ProductErrorState({
    required this.message,
    required this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Lottie.asset('assets/animations/browse.json', width: 180),
            const SizedBox(height: 16),
            Text(
              message,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w800,
                color: HomeColors.textPrimaryOf(context),
              ),
            ),
            const SizedBox(height: 24),
            SizedBox(
              height: 56,
              child: FilledButton.icon(
                onPressed: onRetry,
                icon: const Icon(Icons.refresh_rounded, size: 22),
                label: Text(l10n.actionTryAgain),
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.brandOrange,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 28),
                  textStyle: const TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w800,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(18),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
