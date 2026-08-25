/// Query params for GET /api/products with enforced search scope.
class ProductsQuery {
  final int page;
  final int perPage;
  final int? vendorId;
  final int? categoryId;
  final String? search;
  final String? minPrice;
  final String? maxPrice;
  final String? sortBy;
  final String? status;

  const ProductsQuery._({
    this.page = 1,
    this.perPage = 15,
    this.vendorId,
    this.categoryId,
    this.search,
    this.minPrice,
    this.maxPrice,
    this.sortBy,
    this.status,
  });

  bool get hasPublicProductFilters =>
      (minPrice != null && minPrice!.trim().isNotEmpty) ||
      (maxPrice != null && maxPrice!.trim().isNotEmpty) ||
      (sortBy != null && sortBy!.trim().isNotEmpty);

  /// Category screen: always scoped by [categoryId].
  factory ProductsQuery.forCategory(
    int categoryId, {
    int page = 1,
    int perPage = 15,
    String? search,
    String? minPrice,
    String? maxPrice,
    String? sortBy,
    String? status = 'active',
  }) {
    return ProductsQuery._(
      categoryId: categoryId,
      page: page,
      perPage: perPage,
      search: search,
      minPrice: minPrice,
      maxPrice: maxPrice,
      sortBy: sortBy,
      status: status,
    );
  }

  /// Vendor / store screen: always scoped by [vendorId].
  factory ProductsQuery.forVendor(
    int vendorId, {
    int page = 1,
    int perPage = 15,
    String? search,
    String? minPrice,
    String? maxPrice,
    String? sortBy,
    String? status = 'active',
  }) {
    return ProductsQuery._(
      vendorId: vendorId,
      page: page,
      perPage: perPage,
      search: search,
      minPrice: minPrice,
      maxPrice: maxPrice,
      sortBy: sortBy,
      status: status,
    );
  }

  /// Home global search: no category_id or vendor_id.
  factory ProductsQuery.global({
    int page = 1,
    int perPage = 15,
    String? search,
    String? minPrice,
    String? maxPrice,
    String? sortBy,
    String? status = 'active',
  }) {
    return ProductsQuery._(
      page: page,
      perPage: perPage,
      search: search,
      minPrice: minPrice,
      maxPrice: maxPrice,
      sortBy: sortBy,
      status: status,
    );
  }

  Map<String, dynamic> toQueryParameters() {
    final params = <String, dynamic>{'page': page};
    if (vendorId != null) params['vendor_id'] = vendorId;
    if (categoryId != null) params['category_id'] = categoryId;
    final q = search?.trim();
    if (q != null && q.isNotEmpty) params['search'] = q;
    if (minPrice != null && minPrice!.trim().isNotEmpty) {
      params['min_price'] = minPrice!.trim();
    }
    if (maxPrice != null && maxPrice!.trim().isNotEmpty) {
      params['max_price'] = maxPrice!.trim();
    }
    if (sortBy != null && sortBy!.trim().isNotEmpty) {
      params['sort_by'] = sortBy!.trim();
    }
    if (status != null && status!.trim().isNotEmpty) {
      params['status'] = status!.trim();
    }
    return params;
  }

  ProductsQuery copyWith({
    int? page,
    int? perPage,
    String? search,
    String? minPrice,
    String? maxPrice,
    String? sortBy,
    String? status,
    bool clearSearch = false,
    bool clearMinPrice = false,
    bool clearMaxPrice = false,
    bool clearSortBy = false,
  }) {
    return ProductsQuery._(
      page: page ?? this.page,
      perPage: perPage ?? this.perPage,
      vendorId: vendorId,
      categoryId: categoryId,
      search: clearSearch ? null : (search ?? this.search),
      minPrice: clearMinPrice ? null : (minPrice ?? this.minPrice),
      maxPrice: clearMaxPrice ? null : (maxPrice ?? this.maxPrice),
      sortBy: clearSortBy ? null : (sortBy ?? this.sortBy),
      status: status ?? this.status,
    );
  }
}
