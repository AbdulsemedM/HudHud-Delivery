import 'package:flutter/foundation.dart';
import 'package:hudhud_delivery/features/categories/model/categories_products_model.dart';

/// Shared in-memory cart used across product detail, store, and checkout flows.
class CartService extends ChangeNotifier {
  static final CartService _instance = CartService._internal();
  factory CartService() => _instance;
  CartService._internal();

  final Map<String, int> _quantities = {};
  final Map<String, CategoriesProductsModel> _products = {};

  Map<String, int> get quantities => Map.unmodifiable(_quantities);

  int get totalItems =>
      _quantities.values.fold(0, (sum, quantity) => sum + quantity);

  bool get isEmpty => _quantities.isEmpty;

  int quantityFor(int? productId) {
    if (productId == null) return 0;
    return _quantities[productId.toString()] ?? 0;
  }

  CategoriesProductsModel? productFor(String productId) => _products[productId];

  bool addProduct(CategoriesProductsModel product, {int quantity = 1}) {
    if (product.id == null || !product.canOrder || quantity < 1) return false;
    final id = product.id!.toString();
    _products[id] = product;
    _quantities[id] = (_quantities[id] ?? 0) + quantity;
    notifyListeners();
    return true;
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

  double unitPrice(CategoriesProductsModel product) {
    if (product.discount_price?.isNotEmpty == true) {
      return double.tryParse(product.discount_price!) ?? 0;
    }
    return double.tryParse(product.price ?? '0') ?? 0;
  }

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
      return {
        'id': product.id,
        'productId': product.id,
        'product_id': product.id,
        'vendor_id': product.vendor_id ?? fallbackVendorId,
        'name': product.name,
        'image': product.image_path,
        'price': unitPrice(product),
        'quantity': entry.value,
      };
    }).toList();
  }

  void clear() {
    _quantities.clear();
    _products.clear();
    notifyListeners();
  }
}
