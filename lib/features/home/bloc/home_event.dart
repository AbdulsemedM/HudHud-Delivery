part of 'home_bloc.dart';

@immutable
sealed class HomeEvent {}

class GetCategoriesEvent extends HomeEvent {}
