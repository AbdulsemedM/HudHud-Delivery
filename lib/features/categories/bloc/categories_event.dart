part of 'categories_bloc.dart';

@immutable
sealed class CategoriesEvent {}

class FetchCategoriesTreeEvent extends CategoriesEvent {}

class FetchCategoriesListEvent extends CategoriesEvent {
  final int page;
  FetchCategoriesListEvent({this.page = 1});
}

class FetchCategoriesProductsEvent extends CategoriesEvent {
  final String categoryId;
  FetchCategoriesProductsEvent(this.categoryId);
}