import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter/foundation.dart';

import '../../products/data/products_repository.dart';
import '../../products/model/products_query.dart';
import '../data/repository/categories_repository.dart';
import '../model/categories_products_model.dart';
import '../model/category_tree_model.dart';

part 'categories_event.dart';
part 'categories_state.dart';

class CategoriesBloc extends Bloc<CategoriesEvent, CategoriesState> {
  final CategoriesRepository categoriesRepository;
  final ProductsRepository productsRepository;

  CategoriesBloc(this.categoriesRepository, this.productsRepository)
      : super(CategoriesInitial()) {
    on<FetchCategoriesTreeEvent>((event, emit) async {
      emit(FetchCategoriesTreeLoading());
      try {
        final tree = await categoriesRepository.getCategoriesTree();
        emit(FetchCategoriesTreeSuccess(tree));
      } catch (e) {
        emit(FetchCategoriesTreeFailure(e.toString()));
      }
    });
    on<FetchCategoriesListEvent>((event, emit) async {
      emit(FetchCategoriesListLoading());
      try {
        final result =
            await categoriesRepository.getCategories(page: event.page);
        emit(FetchCategoriesListSuccess(result));
      } catch (e) {
        emit(FetchCategoriesListFailure(e.toString()));
      }
    });
    on<FetchCategoriesProductsEvent>((event, emit) async {
      if (!event.loadMore) {
        emit(FetchCategoriesProductsLoading());
      } else {
        emit(FetchCategoriesProductsLoading(isLoadingMore: true));
      }
      try {
        final query = ProductsQuery.forCategory(
          event.categoryId,
          page: event.page,
          search: event.search,
          minPrice: event.minPrice,
          maxPrice: event.maxPrice,
          status: event.status,
        );
        final result = await productsRepository.getProducts(query);

        List<CategoriesProductsModel> merged = result.items;
        if (event.loadMore && state is FetchCategoriesProductsSuccess) {
          final prev = state as FetchCategoriesProductsSuccess;
          merged = [...prev.categoriesProducts, ...result.items];
        }

        emit(FetchCategoriesProductsSuccess(
          categoriesProducts: merged,
          currentPage: result.currentPage,
          lastPage: result.lastPage,
          hasMore: result.hasMore,
          search: event.search,
          minPrice: event.minPrice,
          maxPrice: event.maxPrice,
        ));
      } catch (e) {
        emit(FetchCategoriesProductsFailure(e.toString()));
      }
    });
  }
}
