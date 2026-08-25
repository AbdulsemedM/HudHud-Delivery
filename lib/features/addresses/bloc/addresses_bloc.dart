import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hudhud_delivery/features/addresses/data/addresses_repository.dart';
import 'package:hudhud_delivery/features/addresses/model/address_model.dart';
import 'package:hudhud_delivery/features/addresses/model/address_payload.dart';

part 'addresses_event.dart';
part 'addresses_state.dart';

class AddressesBloc extends Bloc<AddressesEvent, AddressesState> {
  final AddressesRepository repository;

  AddressesBloc({required this.repository}) : super(AddressesInitial()) {
    on<LoadAddressesEvent>(_onLoad);
    on<LoadMoreAddressesEvent>(_onLoadMore);
    on<RefreshAddressesEvent>(_onRefresh);
    on<CreateAddressEvent>(_onCreate);
    on<UpdateAddressEvent>(_onUpdate);
    on<DeleteAddressEvent>(_onDelete);
    on<BulkDeleteAddressesEvent>(_onBulkDelete);
    on<SetDefaultAddressEvent>(_onSetDefault);
    on<LoadDefaultAddressEvent>(_onLoadDefault);
    on<EnterSelectionModeEvent>(_onEnterSelection);
    on<ExitSelectionModeEvent>(_onExitSelection);
    on<ToggleSelectionEvent>(_onToggleSelection);
    on<ClearSelectionEvent>(_onClearSelection);
  }

  Future<void> _onLoad(
    LoadAddressesEvent event,
    Emitter<AddressesState> emit,
  ) async {
    emit(AddressesLoading());
    try {
      final result = await repository.getAddresses(page: 1);
      emit(AddressesLoaded(
        addresses: result.addresses,
        meta: result.meta,
        currentPage: 1,
        hasMore: result.hasMore,
      ));
    } catch (e) {
      emit(AddressesError(e.toString()));
    }
  }

  Future<void> _onLoadMore(
    LoadMoreAddressesEvent event,
    Emitter<AddressesState> emit,
  ) async {
    final current = state;
    if (current is! AddressesLoaded ||
        !current.hasMore ||
        current.isLoadingMore) {
      return;
    }
    emit(current.copyWith(isLoadingMore: true));
    try {
      final nextPage = current.currentPage + 1;
      final result = await repository.getAddresses(page: nextPage);
      emit(current.copyWith(
        addresses: [...current.addresses, ...result.addresses],
        meta: result.meta,
        currentPage: nextPage,
        hasMore: result.hasMore,
        isLoadingMore: false,
      ));
    } catch (e) {
      emit(current.copyWith(isLoadingMore: false));
      emit(AddressesError(e.toString()));
    }
  }

  Future<void> _onRefresh(
    RefreshAddressesEvent event,
    Emitter<AddressesState> emit,
  ) async {
    add(const LoadAddressesEvent());
  }

  Future<void> _onCreate(
    CreateAddressEvent event,
    Emitter<AddressesState> emit,
  ) async {
    final current = state;
    if (current is AddressesLoaded) {
      emit(current.copyWith(isSubmitting: true));
    }
    try {
      await repository.createAddress(event.payload);
      final refreshed = await repository.getAddresses(page: 1);
      emit(AddressesLoaded(
        addresses: refreshed.addresses,
        meta: refreshed.meta,
        currentPage: 1,
        hasMore: refreshed.hasMore,
        isSubmitting: false,
        successMessage: 'created',
      ));
    } catch (e) {
      if (current is AddressesLoaded) {
        emit(current.copyWith(isSubmitting: false));
      }
      emit(AddressesError(e.toString()));
    }
  }

  Future<void> _onUpdate(
    UpdateAddressEvent event,
    Emitter<AddressesState> emit,
  ) async {
    final current = state;
    if (current is AddressesLoaded) {
      emit(current.copyWith(isSubmitting: true));
    }
    try {
      final address =
          await repository.updateAddress(event.id, event.payload);
      if (current is AddressesLoaded) {
        final updated = current.addresses
            .map((a) => a.id == address.id ? address : a)
            .toList();
        emit(current.copyWith(
          addresses: _applyDefaultFlags(updated, address),
          isSubmitting: false,
          successMessage: 'updated',
        ));
      }
    } catch (e) {
      if (current is AddressesLoaded) {
        emit(current.copyWith(isSubmitting: false));
      }
      emit(AddressesError(e.toString()));
    }
  }

  Future<void> _onDelete(
    DeleteAddressEvent event,
    Emitter<AddressesState> emit,
  ) async {
    final current = state;
    try {
      await repository.deleteAddress(event.id);
      if (current is AddressesLoaded) {
        final wasDefault =
            current.addresses.any((a) => a.id == event.id && a.isDefault);
        final updated =
            current.addresses.where((a) => a.id != event.id).toList();
        emit(current.copyWith(
          addresses: updated,
          selectedIds: current.selectedIds.difference({event.id}),
        ));
        if (wasDefault) {
          await repository.getDefaultAddress();
        }
      }
      add(const LoadAddressesEvent());
    } catch (e) {
      emit(AddressesError(e.toString()));
    }
  }

  Future<void> _onBulkDelete(
    BulkDeleteAddressesEvent event,
    Emitter<AddressesState> emit,
  ) async {
    final current = state;
    if (current is AddressesLoaded) {
      emit(current.copyWith(isSubmitting: true));
    }
    try {
      await repository.bulkDeleteAddresses(
        ids: event.ids,
        force: event.force,
      );
      if (current is AddressesLoaded) {
        emit(current.copyWith(
          isSubmitting: false,
          isSelectionMode: false,
          selectedIds: {},
        ));
      }
      await repository.getDefaultAddress();
      add(const LoadAddressesEvent());
    } catch (e) {
      if (current is AddressesLoaded) {
        emit(current.copyWith(isSubmitting: false));
      }
      emit(AddressesError(e.toString()));
    }
  }

  Future<void> _onSetDefault(
    SetDefaultAddressEvent event,
    Emitter<AddressesState> emit,
  ) async {
    final current = state;
    try {
      final address = await repository.setDefaultAddress(event.id);
      if (current is AddressesLoaded) {
        emit(current.copyWith(
          addresses: _applyDefaultFlags(current.addresses, address),
          successMessage: 'default_set',
        ));
      }
    } catch (e) {
      emit(AddressesError(e.toString()));
    }
  }

  Future<void> _onLoadDefault(
    LoadDefaultAddressEvent event,
    Emitter<AddressesState> emit,
  ) async {
    try {
      await repository.getDefaultAddress();
    } catch (_) {
      // No default yet — ignore
    }
  }

  void _onEnterSelection(
    EnterSelectionModeEvent event,
    Emitter<AddressesState> emit,
  ) {
    final current = state;
    if (current is AddressesLoaded) {
      emit(current.copyWith(isSelectionMode: true, selectedIds: {}));
    }
  }

  void _onExitSelection(
    ExitSelectionModeEvent event,
    Emitter<AddressesState> emit,
  ) {
    final current = state;
    if (current is AddressesLoaded) {
      emit(current.copyWith(isSelectionMode: false, selectedIds: {}));
    }
  }

  void _onToggleSelection(
    ToggleSelectionEvent event,
    Emitter<AddressesState> emit,
  ) {
    final current = state;
    if (current is! AddressesLoaded) return;
    final next = Set<int>.from(current.selectedIds);
    if (next.contains(event.id)) {
      next.remove(event.id);
    } else {
      next.add(event.id);
    }
    emit(current.copyWith(selectedIds: next));
  }

  void _onClearSelection(
    ClearSelectionEvent event,
    Emitter<AddressesState> emit,
  ) {
    final current = state;
    if (current is AddressesLoaded) {
      emit(current.copyWith(selectedIds: {}));
    }
  }

  List<AddressModel> _applyDefaultFlags(
    List<AddressModel> list,
    AddressModel changed,
  ) {
    if (!changed.isDefault) return list;
    return list
        .map((a) => a.copyWith(isDefault: a.id == changed.id))
        .toList();
  }
}
