part of 'wishlist_bloc.dart';

sealed class WishlistEvent extends Equatable {
  const WishlistEvent();

  @override
  List<Object?> get props => [];
}

class LoadWishlistEvent extends WishlistEvent {
  final int userId;
  final WishlistQuery? query;
  const LoadWishlistEvent({required this.userId, this.query});

  @override
  List<Object?> get props => [userId, query];
}

class RefreshWishlistEvent extends WishlistEvent {
  final int userId;
  final WishlistQuery? query;
  const RefreshWishlistEvent({required this.userId, this.query});

  @override
  List<Object?> get props => [userId, query];
}

class ToggleWishlistEvent extends WishlistEvent {
  final int userId;
  final CategoriesProductsModel product;
  final String? notes;
  const ToggleWishlistEvent({
    required this.userId,
    required this.product,
    this.notes,
  });

  @override
  List<Object?> get props => [userId, product, notes];
}

class RemoveWishlistEvent extends WishlistEvent {
  final int userId;
  final int wishlistId;
  final int productId;
  const RemoveWishlistEvent({
    required this.userId,
    required this.wishlistId,
    required this.productId,
  });

  @override
  List<Object?> get props => [userId, wishlistId, productId];
}

class UpdateWishlistNotesEvent extends WishlistEvent {
  final int wishlistId;
  final String notes;
  const UpdateWishlistNotesEvent({
    required this.wishlistId,
    required this.notes,
  });

  @override
  List<Object?> get props => [wishlistId, notes];
}

class BulkRemoveWishlistEvent extends WishlistEvent {
  final List<int> productIds;
  const BulkRemoveWishlistEvent({required this.productIds});

  @override
  List<Object?> get props => [productIds];
}

class ShareWishlistEvent extends WishlistEvent {
  final String email;
  final String permission;
  final int expiresInDays;
  const ShareWishlistEvent({
    required this.email,
    this.permission = 'view',
    this.expiresInDays = 7,
  });

  @override
  List<Object?> get props => [email, permission, expiresInDays];
}

class CheckPriceDropsEvent extends WishlistEvent {
  const CheckPriceDropsEvent();
}
