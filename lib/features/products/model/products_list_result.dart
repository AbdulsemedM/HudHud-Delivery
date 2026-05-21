import '../../categories/model/categories_products_model.dart';

class ProductsListResult {
  final List<CategoriesProductsModel> items;
  final int currentPage;
  final int lastPage;
  final int? total;

  const ProductsListResult({
    required this.items,
    required this.currentPage,
    required this.lastPage,
    this.total,
  });

  bool get hasMore => currentPage < lastPage;

  /// Parses Laravel pagination from API response body.
  static ProductsListResult fromResponseData(dynamic data) {
    if (data == null) {
      return const ProductsListResult(
        items: [],
        currentPage: 1,
        lastPage: 1,
      );
    }

    Map<String, dynamic>? pageMap;
    if (data is Map<String, dynamic>) {
      if (data['data'] is List) {
        pageMap = data;
      } else if (data['data'] is Map<String, dynamic>) {
        pageMap = data['data'] as Map<String, dynamic>;
      } else {
        pageMap = data;
      }
    }

    if (pageMap == null) {
      return const ProductsListResult(
        items: [],
        currentPage: 1,
        lastPage: 1,
      );
    }

    final rawList = pageMap['data'];
    final list = rawList is List ? rawList : <dynamic>[];

    final items = list
        .whereType<Map>()
        .map((e) => CategoriesProductsModel.fromMap(
              Map<String, dynamic>.from(e),
            ))
        .toList();

    final currentPage = _parseInt(pageMap['current_page'], fallback: 1);
    final lastPage = _parseInt(pageMap['last_page'], fallback: 1);
    final total = pageMap['total'] != null
        ? _parseInt(pageMap['total'], fallback: items.length)
        : null;

    return ProductsListResult(
      items: items,
      currentPage: currentPage,
      lastPage: lastPage,
      total: total,
    );
  }

  static int _parseInt(dynamic v, {required int fallback}) {
    if (v == null) return fallback;
    if (v is int) return v;
    return int.tryParse(v.toString()) ?? fallback;
  }
}
