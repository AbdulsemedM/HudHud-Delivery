part of 'wishlist_bloc.dart';

sealed class WishlistState extends Equatable {
  const WishlistState();

  @override
  List<Object?> get props => [];
}

class WishlistInitial extends WishlistState {}

class WishlistLoading extends WishlistState {}

class WishlistLoaded extends WishlistState {
  final List<WishlistItemModel> items;
  final List<WishlistVendorGroupModel> vendorGroups;
  final int currentPage;
  final int lastPage;
  final int? total;
  final WishlistShareResult? lastShareResult;
  final WishlistPriceDropsResult? priceDropsResult;

  const WishlistLoaded({
    required this.items,
    this.vendorGroups = const [],
    this.currentPage = 1,
    this.lastPage = 1,
    this.total,
    this.lastShareResult,
    this.priceDropsResult,
  });

  Set<int> get wishlistedProductIds =>
      items.map((i) => i.productId).toSet();

  int? wishlistIdForProduct(int productId) {
    for (final item in items) {
      if (item.productId == productId) return item.id;
    }
    return null;
  }

  WishlistLoaded copyWith({
    List<WishlistItemModel>? items,
    List<WishlistVendorGroupModel>? vendorGroups,
    int? currentPage,
    int? lastPage,
    int? total,
    WishlistShareResult? lastShareResult,
    WishlistPriceDropsResult? priceDropsResult,
    bool clearShare = false,
    bool clearPriceDrops = false,
  }) {
    return WishlistLoaded(
      items: items ?? this.items,
      vendorGroups: vendorGroups ?? this.vendorGroups,
      currentPage: currentPage ?? this.currentPage,
      lastPage: lastPage ?? this.lastPage,
      total: total ?? this.total,
      lastShareResult:
          clearShare ? null : (lastShareResult ?? this.lastShareResult),
      priceDropsResult: clearPriceDrops
          ? null
          : (priceDropsResult ?? this.priceDropsResult),
    );
  }

  @override
  List<Object?> get props =>
      [items, vendorGroups, currentPage, lastPage, total, lastShareResult, priceDropsResult];
}

class WishlistShareSuccess extends WishlistState {
  final WishlistShareResult result;
  const WishlistShareSuccess(this.result);

  @override
  List<Object?> get props => [result];
}

class WishlistPriceDropsChecked extends WishlistState {
  final WishlistPriceDropsResult result;
  const WishlistPriceDropsChecked(this.result);

  @override
  List<Object?> get props => [result];
}

class WishlistError extends WishlistState {
  final String message;
  const WishlistError(this.message);

  @override
  List<Object?> get props => [message];
}
