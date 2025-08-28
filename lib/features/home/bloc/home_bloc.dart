import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter/foundation.dart';

import '../data/repository/home_repository.dart';
import '../model/category_model.dart';

part 'home_event.dart';
part 'home_state.dart';

class HomeBloc extends Bloc<HomeEvent, HomeState> {
  final HomeRepository homeRepository;
  HomeBloc({required this.homeRepository}) : super(HomeInitial()) {
    on<GetCategoriesEvent>((event, emit) async {
      emit(GetCategoriesLoadingState());
      try {
        final categories = await homeRepository.getCategories();
        emit(GetCategoriesSuccessState(categories: categories));
      } catch (e) {
        emit(GetCategoriesErrorState(errorMessage: e.toString()));
      }
    });
  }
}
