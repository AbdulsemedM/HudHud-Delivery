part of 'addresses_bloc.dart';

abstract class AddressesEvent extends Equatable {
  const AddressesEvent();

  @override
  List<Object?> get props => [];
}

class LoadAddressesEvent extends AddressesEvent {
  const LoadAddressesEvent();
}

class LoadMoreAddressesEvent extends AddressesEvent {
  const LoadMoreAddressesEvent();
}

class RefreshAddressesEvent extends AddressesEvent {
  const RefreshAddressesEvent();
}

class CreateAddressEvent extends AddressesEvent {
  final AddressPayload payload;
  const CreateAddressEvent(this.payload);

  @override
  List<Object?> get props => [payload];
}

class UpdateAddressEvent extends AddressesEvent {
  final int id;
  final AddressPayload payload;
  const UpdateAddressEvent({required this.id, required this.payload});

  @override
  List<Object?> get props => [id, payload];
}

class DeleteAddressEvent extends AddressesEvent {
  final int id;
  const DeleteAddressEvent(this.id);

  @override
  List<Object?> get props => [id];
}

class BulkDeleteAddressesEvent extends AddressesEvent {
  final List<int> ids;
  final bool force;
  const BulkDeleteAddressesEvent({required this.ids, this.force = false});

  @override
  List<Object?> get props => [ids, force];
}

class SetDefaultAddressEvent extends AddressesEvent {
  final int id;
  const SetDefaultAddressEvent(this.id);

  @override
  List<Object?> get props => [id];
}

class LoadDefaultAddressEvent extends AddressesEvent {
  const LoadDefaultAddressEvent();
}

class EnterSelectionModeEvent extends AddressesEvent {
  const EnterSelectionModeEvent();
}

class ExitSelectionModeEvent extends AddressesEvent {
  const ExitSelectionModeEvent();
}

class ToggleSelectionEvent extends AddressesEvent {
  final int id;
  const ToggleSelectionEvent(this.id);

  @override
  List<Object?> get props => [id];
}

class ClearSelectionEvent extends AddressesEvent {
  const ClearSelectionEvent();
}
