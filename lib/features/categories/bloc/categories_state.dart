part of 'categories_bloc.dart';

@immutable
sealed class CategoriesState {}

final class CategoriesInitial extends CategoriesState {}

final class FetchCategoriesProductsLoading extends CategoriesState {}

final class FetchCategoriesProductsSuccess extends CategoriesState {
  final List<CategoriesProductsModel> categoriesProducts;
  FetchCategoriesProductsSuccess(this.categoriesProducts);
}

final class FetchCategoriesProductsFailure extends CategoriesState {
  final String errorMessage;
  FetchCategoriesProductsFailure(this.errorMessage);
}
