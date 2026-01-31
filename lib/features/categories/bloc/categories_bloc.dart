import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter/foundation.dart';

import '../data/repository/categories_repository.dart';
import '../model/categories_products_model.dart';
import '../model/category_tree_model.dart';

part 'categories_event.dart';
part 'categories_state.dart';

class CategoriesBloc extends Bloc<CategoriesEvent, CategoriesState> {
  final CategoriesRepository categoriesRepository;
  CategoriesBloc(this.categoriesRepository) : super(CategoriesInitial()) {
    on<FetchCategoriesTreeEvent>((event, emit) async {
      emit(FetchCategoriesTreeLoading());
      try {
        final tree =
            await categoriesRepository.getCategoriesTree();
        emit(FetchCategoriesTreeSuccess(tree));
      } catch (e) {
        emit(FetchCategoriesTreeFailure(e.toString()));
      }
    });
    on<FetchCategoriesProductsEvent>((event, emit) async {
      emit(FetchCategoriesProductsLoading());
      try {
        final categoriesProducts =
            await categoriesRepository.getCategoriesProducts(
          categoryId: int.parse(event.categoryId),
        );
        emit(FetchCategoriesProductsSuccess(categoriesProducts));
      } catch (e) {
        emit(FetchCategoriesProductsFailure(e.toString()));
      }
    });
  }
}
