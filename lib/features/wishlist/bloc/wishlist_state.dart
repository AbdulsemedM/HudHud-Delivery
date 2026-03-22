part of 'wishlist_bloc.dart';

sealed class WishlistState extends Equatable {
  const WishlistState();

  @override
  List<Object?> get props => [];
}

class WishlistInitial extends WishlistState {}

class WishlistLoading extends WishlistState {}

class WishlistLoaded extends WishlistState {
  final List<CategoriesProductsModel> items;
  const WishlistLoaded({required this.items});

  Set<int> get wishlistedProductIds =>
      items.map((p) => p.id).whereType<int>().toSet();

  WishlistLoaded copyWith({List<CategoriesProductsModel>? items}) =>
      WishlistLoaded(items: items ?? this.items);

  @override
  List<Object?> get props => [items];
}

class WishlistError extends WishlistState {
  final String message;
  const WishlistError(this.message);

  @override
  List<Object?> get props => [message];
}

