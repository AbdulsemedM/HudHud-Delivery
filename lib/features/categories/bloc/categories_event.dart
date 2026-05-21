part of 'categories_bloc.dart';

@immutable
sealed class CategoriesEvent {}

class FetchCategoriesTreeEvent extends CategoriesEvent {}

class FetchCategoriesListEvent extends CategoriesEvent {
  final int page;
  FetchCategoriesListEvent({this.page = 1});
}

class FetchCategoriesProductsEvent extends CategoriesEvent {
  final int categoryId;
  final String? search;
  final String? minPrice;
  final String? maxPrice;
  final String? status;
  final int page;
  final bool loadMore;

  FetchCategoriesProductsEvent({
    required this.categoryId,
    this.search,
    this.minPrice,
    this.maxPrice,
    this.status = 'active',
    this.page = 1,
    this.loadMore = false,
  });
}
