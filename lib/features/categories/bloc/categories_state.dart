part of 'categories_bloc.dart';

@immutable
sealed class CategoriesState {}

final class CategoriesInitial extends CategoriesState {}

final class FetchCategoriesTreeLoading extends CategoriesState {}

final class FetchCategoriesTreeSuccess extends CategoriesState {
  final List<CategoryTreeModel> categoriesTree;
  FetchCategoriesTreeSuccess(this.categoriesTree);
}

final class FetchCategoriesTreeFailure extends CategoriesState {
  final String errorMessage;
  FetchCategoriesTreeFailure(this.errorMessage);
}

final class FetchCategoriesProductsLoading extends CategoriesState {}

final class FetchCategoriesProductsSuccess extends CategoriesState {
  final List<CategoriesProductsModel> categoriesProducts;
  FetchCategoriesProductsSuccess(this.categoriesProducts);
}

final class FetchCategoriesProductsFailure extends CategoriesState {
  final String errorMessage;
  FetchCategoriesProductsFailure(this.errorMessage);
}
