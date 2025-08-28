part of 'home_bloc.dart';

@immutable
sealed class HomeState {}

final class HomeInitial extends HomeState {}

final class GetCategoriesLoadingState extends HomeState {}

final class GetCategoriesSuccessState extends HomeState {
  final List<CategoryModel> categories;
  GetCategoriesSuccessState({required this.categories});
}

final class GetCategoriesErrorState extends HomeState {
  final String errorMessage;
  GetCategoriesErrorState({required this.errorMessage});
}
