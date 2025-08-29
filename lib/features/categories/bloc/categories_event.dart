part of 'categories_bloc.dart';

@immutable
sealed class CategoriesEvent {}

class FetchCategoriesProductsEvent extends CategoriesEvent {
  final String categoryId;
  FetchCategoriesProductsEvent(this.categoryId);
}