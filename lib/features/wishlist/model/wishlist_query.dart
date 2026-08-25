class WishlistQuery {
  final int page;
  final int perPage;
  final String sortBy;
  final String sortOrder;
  final int? vendorId;
  final int? categoryId;

  const WishlistQuery({
    this.page = 1,
    this.perPage = 20,
    this.sortBy = 'created_at',
    this.sortOrder = 'desc',
    this.vendorId,
    this.categoryId,
  });

  Map<String, dynamic> toParams() {
    final params = <String, dynamic>{
      'page': page,
      'per_page': perPage,
      'sort_by': sortBy,
      'sort_order': sortOrder,
    };
    if (vendorId != null) params['vendor_id'] = vendorId;
    if (categoryId != null) params['category_id'] = categoryId;
    return params;
  }

  WishlistQuery copyWith({
    int? page,
    int? perPage,
    String? sortBy,
    String? sortOrder,
    int? vendorId,
    int? categoryId,
    bool clearVendorId = false,
    bool clearCategoryId = false,
  }) {
    return WishlistQuery(
      page: page ?? this.page,
      perPage: perPage ?? this.perPage,
      sortBy: sortBy ?? this.sortBy,
      sortOrder: sortOrder ?? this.sortOrder,
      vendorId: clearVendorId ? null : (vendorId ?? this.vendorId),
      categoryId: clearCategoryId ? null : (categoryId ?? this.categoryId),
    );
  }
}
