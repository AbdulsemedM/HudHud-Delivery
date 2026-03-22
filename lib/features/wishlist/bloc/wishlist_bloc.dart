import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:hudhud_delivery/features/categories/model/categories_products_model.dart';
import 'package:hudhud_delivery/features/wishlist/data/wishlist_repository.dart';

part 'wishlist_event.dart';
part 'wishlist_state.dart';

class WishlistBloc extends Bloc<WishlistEvent, WishlistState> {
  WishlistBloc({WishlistRepository? repository})
      : _repository = repository ?? WishlistRepository(),
        super(WishlistInitial()) {
    on<LoadWishlistEvent>(_onLoad);
    on<ToggleWishlistEvent>(_onToggle);
    on<RemoveWishlistEvent>(_onRemove);
    on<RefreshWishlistEvent>(_onRefresh);
  }

  final WishlistRepository _repository;

  Future<void> _onLoad(
    LoadWishlistEvent event,
    Emitter<WishlistState> emit,
  ) async {
    emit(WishlistLoading());
    try {
      final items = await _repository.getWishlist(userId: event.userId);
      emit(WishlistLoaded(items: items));
    } catch (e) {
      emit(WishlistError(e.toString()));
    }
  }

  Future<void> _onRefresh(
    RefreshWishlistEvent event,
    Emitter<WishlistState> emit,
  ) async {
    add(LoadWishlistEvent(userId: event.userId));
  }

  Future<void> _onToggle(
    ToggleWishlistEvent event,
    Emitter<WishlistState> emit,
  ) async {
    final current = state;
    if (current is! WishlistLoaded) {
      // If not loaded yet, toggle then load.
      await _repository.toggleWishlist(userId: event.userId, product: event.product);
      add(LoadWishlistEvent(userId: event.userId));
      return;
    }

    final productId = event.product.id;
    if (productId == null) return;

    final wasWishlisted = current.wishlistedProductIds.contains(productId);
    final optimisticItems = wasWishlisted
        ? current.items.where((p) => p.id != productId).toList(growable: false)
        : <CategoriesProductsModel>[event.product, ...current.items]
            .fold<List<CategoriesProductsModel>>([], (acc, p) {
            // Deduplicate by id (newest first)
            final id = p.id;
            if (id == null) return acc;
            if (acc.any((x) => x.id == id)) return acc;
            acc.add(p);
            return acc;
          }).toList(growable: false);

    emit(current.copyWith(items: optimisticItems));

    try {
      await _repository.toggleWishlist(userId: event.userId, product: event.product);
      // Re-sync to ensure DB order/timestamps are reflected.
      final synced = await _repository.getWishlist(userId: event.userId);
      emit(current.copyWith(items: synced));
    } catch (e) {
      // Roll back by reloading from DB.
      try {
        final rollback = await _repository.getWishlist(userId: event.userId);
        emit(current.copyWith(items: rollback));
      } catch (_) {
        emit(WishlistError(e.toString()));
      }
    }
  }

  Future<void> _onRemove(
    RemoveWishlistEvent event,
    Emitter<WishlistState> emit,
  ) async {
    final current = state;
    if (current is WishlistLoaded) {
      emit(current.copyWith(
        items: current.items.where((p) => p.id != event.productId).toList(growable: false),
      ));
    }
    try {
      await _repository.remove(userId: event.userId, productId: event.productId);
    } catch (e) {
      emit(WishlistError(e.toString()));
    }
  }
}

