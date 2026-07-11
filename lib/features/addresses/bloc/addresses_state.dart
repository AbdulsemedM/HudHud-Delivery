part of 'addresses_bloc.dart';

abstract class AddressesState extends Equatable {
  const AddressesState();

  @override
  List<Object?> get props => [];
}

class AddressesInitial extends AddressesState {}

class AddressesLoading extends AddressesState {}

class AddressesLoaded extends AddressesState {
  final List<AddressModel> addresses;
  final AddressesListMeta meta;
  final int currentPage;
  final bool hasMore;
  final bool isLoadingMore;
  final Set<int> selectedIds;
  final bool isSelectionMode;
  final bool isSubmitting;
  final String? successMessage;

  const AddressesLoaded({
    required this.addresses,
    required this.meta,
    required this.currentPage,
    required this.hasMore,
    this.isLoadingMore = false,
    this.selectedIds = const {},
    this.isSelectionMode = false,
    this.isSubmitting = false,
    this.successMessage,
  });

  AddressesLoaded copyWith({
    List<AddressModel>? addresses,
    AddressesListMeta? meta,
    int? currentPage,
    bool? hasMore,
    bool? isLoadingMore,
    Set<int>? selectedIds,
    bool? isSelectionMode,
    bool? isSubmitting,
    String? successMessage,
    bool clearSuccessMessage = false,
  }) {
    return AddressesLoaded(
      addresses: addresses ?? this.addresses,
      meta: meta ?? this.meta,
      currentPage: currentPage ?? this.currentPage,
      hasMore: hasMore ?? this.hasMore,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
      selectedIds: selectedIds ?? this.selectedIds,
      isSelectionMode: isSelectionMode ?? this.isSelectionMode,
      isSubmitting: isSubmitting ?? this.isSubmitting,
      successMessage: clearSuccessMessage
          ? null
          : (successMessage ?? this.successMessage),
    );
  }

  @override
  List<Object?> get props => [
        addresses,
        meta,
        currentPage,
        hasMore,
        isLoadingMore,
        selectedIds,
        isSelectionMode,
        isSubmitting,
        successMessage,
      ];
}

class AddressesError extends AddressesState {
  final String message;
  const AddressesError(this.message);

  @override
  List<Object?> get props => [message];
}

class AddressActionSuccess extends AddressesState {
  final String message;
  final AddressModel? address;
  const AddressActionSuccess({required this.message, this.address});

  @override
  List<Object?> get props => [message, address];
}
