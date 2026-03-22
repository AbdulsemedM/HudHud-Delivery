part of 'wishlist_bloc.dart';

sealed class WishlistEvent extends Equatable {
  const WishlistEvent();

  @override
  List<Object?> get props => [];
}

class LoadWishlistEvent extends WishlistEvent {
  final int userId;
  const LoadWishlistEvent({required this.userId});

  @override
  List<Object?> get props => [userId];
}

class RefreshWishlistEvent extends WishlistEvent {
  final int userId;
  const RefreshWishlistEvent({required this.userId});

  @override
  List<Object?> get props => [userId];
}

class ToggleWishlistEvent extends WishlistEvent {
  final int userId;
  final CategoriesProductsModel product;
  const ToggleWishlistEvent({required this.userId, required this.product});

  @override
  List<Object?> get props => [userId, product];
}

class RemoveWishlistEvent extends WishlistEvent {
  final int userId;
  final int productId;
  const RemoveWishlistEvent({required this.userId, required this.productId});

  @override
  List<Object?> get props => [userId, productId];
}

