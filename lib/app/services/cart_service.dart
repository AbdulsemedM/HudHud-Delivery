import 'package:flutter/foundation.dart';
import 'package:hudhud_delivery/features/categories/model/categories_products_model.dart';

/// Outcome of attempting to add a product to the cart.
enum CartAddResult {
  added,
  unavailable,
  differentVendor,
}

/// Shared in-memory cart used across product detail, store, and checkout flows.
class CartService extends ChangeNotifier {
  static final CartService _instance = CartService._internal();
  factory CartService() => _instance;
  CartService._internal();

  final Map<String, int> _quantities = {};
  final Map<String, CategoriesProductsModel> _products = {};
  int? _selectedBranchId;

  Map<String, int> get quantities => Map.unmodifiable(_quantities);

  int get totalItems =>
      _quantities.values.fold(0, (sum, quantity) => sum + quantity);

  bool get isEmpty => _quantities.isEmpty;

  /// Restaurant branch selected for delivery-fee quote / order create.
  int? get selectedBranchId => _selectedBranchId;

  void setSelectedBranchId(int? branchId) {
    final next = (branchId != null && branchId > 0) ? branchId : null;
    if (_selectedBranchId == next) return;
    _selectedBranchId = next;
    notifyListeners();
  }

  /// Vendor id shared by all cart lines, if any product has one.
  int? get currentVendorId {
    for (final product in _products.values) {
      final id = product.vendor_id;
      if (id != null && id > 0) return id;
    }
    return null;
  }

  int quantityFor(int? productId) {
    if (productId == null) return 0;
    return _quantities[productId.toString()] ?? 0;
  }

  CategoriesProductsModel? productFor(String productId) => _products[productId];

  bool conflictsWithVendor(int? vendorId) {
    if (vendorId == null || vendorId <= 0 || isEmpty) return false;
    final current = currentVendorId;
    return current != null && current != vendorId;
  }

  /// Adds [product]. When [replaceIfDifferentVendor] is true, clears the cart
  /// first if the product belongs to another vendor.
  CartAddResult addProduct(
    CategoriesProductsModel product, {
    int quantity = 1,
    bool replaceIfDifferentVendor = false,
  }) {
    if (product.id == null || !product.canOrder || quantity < 1) {
      return CartAddResult.unavailable;
    }
    if (conflictsWithVendor(product.vendor_id)) {
      if (!replaceIfDifferentVendor) {
        return CartAddResult.differentVendor;
      }
      _quantities.clear();
      _products.clear();
      _selectedBranchId = null;
    }
    final id = product.id!.toString();
    _products[id] = product;
    _quantities[id] = (_quantities[id] ?? 0) + quantity;
    notifyListeners();
    return CartAddResult.added;
  }

  void removeProduct(String productId) {
    if (!_quantities.containsKey(productId)) return;
    _quantities.remove(productId);
    _products.remove(productId);
    notifyListeners();
  }

  void increment(String productId) {
    final product = _products[productId];
    if (product == null || !product.canOrder) return;
    _quantities[productId] = (_quantities[productId] ?? 0) + 1;
    notifyListeners();
  }

  void decrement(String productId) {
    final current = _quantities[productId];
    if (current == null) return;
    if (current <= 1) {
      removeProduct(productId);
    } else {
      _quantities[productId] = current - 1;
      notifyListeners();
    }
  }

  void setQuantity(String productId, int quantity) {
    if (!_products.containsKey(productId)) return;
    if (quantity <= 0) {
      removeProduct(productId);
      return;
    }
    _quantities[productId] = quantity;
    notifyListeners();
  }

  double unitPrice(CategoriesProductsModel product) {
    if (product.discount_price?.isNotEmpty == true) {
      return double.tryParse(product.discount_price!) ?? 0;
    }
    return double.tryParse(product.price ?? '0') ?? 0;
  }

  /// Local estimate only — never use as the payable total.
  double get subtotal {
    var total = 0.0;
    _quantities.forEach((productId, quantity) {
      final product = _products[productId];
      if (product == null) return;
      total += unitPrice(product) * quantity;
    });
    return total;
  }

  List<Map<String, dynamic>> toCheckoutItems({int? fallbackVendorId}) {
    return _quantities.entries.map((entry) {
      final product = _products[entry.key]!;
      final mapped = <String, dynamic>{
        'id': product.id,
        'productId': product.id,
        'product_id': product.id,
        'vendor_id': product.vendor_id ?? fallbackVendorId,
        'name': product.name,
        'image': product.image_path,
        'price': unitPrice(product),
        'quantity': entry.value,
      };
      final options = product.options;
      if (options != null) {
        final variantId = options['variant_id'] ?? options['id'];
        if (variantId != null) {
          final parsed = variantId is int
              ? variantId
              : int.tryParse(variantId.toString());
          if (parsed != null && parsed > 0) {
            mapped['variant_id'] = parsed;
          }
        }
        final modifiers = options['modifier_option_ids'];
        if (modifiers is List && modifiers.isNotEmpty) {
          mapped['modifier_option_ids'] = modifiers
              .map((e) => e is int ? e : int.tryParse(e.toString()))
              .whereType<int>()
              .where((id) => id > 0)
              .toList();
        }
      }
      return mapped;
    }).toList();
  }

  void clear() {
    _quantities.clear();
    _products.clear();
    _selectedBranchId = null;
    notifyListeners();
  }
}
