import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hudhud_delivery/features/categories/model/categories_products_model.dart';
import 'package:hudhud_delivery/features/wishlist/data/wishlist_repository.dart';
import 'package:hudhud_delivery/features/wishlist/model/wishlist_item_model.dart';
import 'package:hudhud_delivery/features/wishlist/model/wishlist_list_result.dart';
import 'package:hudhud_delivery/features/wishlist/model/wishlist_query.dart';
import 'package:hudhud_delivery/features/wishlist/model/wishlist_share_result.dart';
import 'package:hudhud_delivery/features/wishlist/model/wishlist_vendor_group_model.dart';

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
    on<UpdateWishlistNotesEvent>(_onUpdateNotes);
    on<BulkRemoveWishlistEvent>(_onBulkRemove);
    on<ShareWishlistEvent>(_onShare);
    on<CheckPriceDropsEvent>(_onCheckPriceDrops);
  }

  final WishlistRepository _repository;

  Future<void> _onLoad(
    LoadWishlistEvent event,
    Emitter<WishlistState> emit,
  ) async {
    emit(WishlistLoading());
    try {
      await _repository.migrateIfNeeded(event.userId);
      final result = await _repository.getWishlist(
        query: event.query ?? const WishlistQuery(),
      );
      emit(WishlistLoaded(
        items: result.items,
        vendorGroups: result.vendorGroups,
        currentPage: result.currentPage,
        lastPage: result.lastPage,
        total: result.total,
      ));
    } catch (e) {
      emit(WishlistError(e.toString()));
    }
  }

  Future<void> _onRefresh(
    RefreshWishlistEvent event,
    Emitter<WishlistState> emit,
  ) async {
    add(LoadWishlistEvent(userId: event.userId, query: event.query));
  }

  Future<void> _onToggle(
    ToggleWishlistEvent event,
    Emitter<WishlistState> emit,
  ) async {
    final productId = event.product.id;
    if (productId == null) return;

    final current = state;
    WishlistLoaded? loaded;
    if (current is WishlistLoaded) {
      loaded = current;
    }

    WishlistItemModel? existingItem;
    if (loaded != null) {
      for (final item in loaded.items) {
        if (item.productId == productId) {
          existingItem = item;
          break;
        }
      }
    }
    existingItem ??= _repository.findCachedByProductId(productId);
    final wasWishlisted = existingItem != null;

    if (loaded != null) {
      final optimistic = wasWishlisted
          ? loaded.items.where((i) => i.productId != productId).toList()
          : [
              WishlistItemModel(
                id: -productId,
                userId: event.userId,
                productId: productId,
                product: event.product,
              ),
              ...loaded.items,
            ];
      emit(loaded.copyWith(items: optimistic));
    }

    try {
      await _repository.toggleProduct(
        productId: productId,
        product: event.product,
        notes: event.notes,
        wishlistId: existingItem?.id,
      );
      final result = await _repository.getWishlist();
      if (loaded != null) {
        emit(loaded.copyWith(
          items: result.items,
          vendorGroups: result.vendorGroups,
          currentPage: result.currentPage,
          lastPage: result.lastPage,
          total: result.total,
        ));
      } else {
        emit(WishlistLoaded(items: result.items));
      }
    } catch (e) {
      if (loaded != null) {
        try {
          final result = await _repository.getWishlist();
          emit(loaded.copyWith(items: result.items));
        } catch (_) {
          emit(WishlistError(e.toString()));
        }
      } else {
        emit(WishlistError(e.toString()));
      }
    }
  }

  Future<void> _onRemove(
    RemoveWishlistEvent event,
    Emitter<WishlistState> emit,
  ) async {
    final current = state;
    final previous =
        current is WishlistLoaded ? List<WishlistItemModel>.from(current.items) : null;

    if (current is WishlistLoaded) {
      emit(current.copyWith(
        items: current.items
            .where((i) => i.id != event.wishlistId && i.productId != event.productId)
            .toList(growable: false),
      ));
    }

    try {
      if (event.wishlistId > 0) {
        await _repository.removeByWishlistId(event.wishlistId);
      } else {
        await _repository.bulkRemoveByProductIds([event.productId]);
      }
    } catch (e) {
      if (previous != null && current is WishlistLoaded) {
        emit(current.copyWith(items: previous));
      } else {
        emit(WishlistError(e.toString()));
      }
    }
  }

  Future<void> _onUpdateNotes(
    UpdateWishlistNotesEvent event,
    Emitter<WishlistState> emit,
  ) async {
    final current = state;
    if (current is! WishlistLoaded) return;
    try {
      final updated =
          await _repository.updateNotes(event.wishlistId, event.notes);
      emit(current.copyWith(
        items: current.items
            .map((i) => i.id == event.wishlistId ? updated : i)
            .toList(growable: false),
      ));
    } catch (e) {
      emit(WishlistError(e.toString()));
    }
  }

  Future<void> _onBulkRemove(
    BulkRemoveWishlistEvent event,
    Emitter<WishlistState> emit,
  ) async {
    final current = state;
    if (current is! WishlistLoaded) return;
    final previous = List<WishlistItemModel>.from(current.items);
    emit(current.copyWith(
      items: current.items
          .where((i) => !event.productIds.contains(i.productId))
          .toList(growable: false),
    ));
    try {
      await _repository.bulkRemoveByProductIds(event.productIds);
    } catch (e) {
      emit(current.copyWith(items: previous));
      emit(WishlistError(e.toString()));
    }
  }

  Future<void> _onShare(
    ShareWishlistEvent event,
    Emitter<WishlistState> emit,
  ) async {
    final current = state;
    try {
      final result = await _repository.shareWishlist(
        email: event.email,
        permission: event.permission,
        expiresInDays: event.expiresInDays,
      );
      if (current is WishlistLoaded) {
        emit(current.copyWith(lastShareResult: result));
      } else {
        emit(WishlistShareSuccess(result));
      }
    } catch (e) {
      emit(WishlistError(e.toString()));
    }
  }

  Future<void> _onCheckPriceDrops(
    CheckPriceDropsEvent event,
    Emitter<WishlistState> emit,
  ) async {
    final current = state;
    try {
      final result = await _repository.getPriceDrops();
      if (current is WishlistLoaded) {
        emit(current.copyWith(
          priceDropsResult: result,
          items: result.items.isNotEmpty ? result.items : current.items,
        ));
      } else {
        emit(WishlistPriceDropsChecked(result));
      }
    } catch (e) {
      emit(WishlistError(e.toString()));
    }
  }
}
