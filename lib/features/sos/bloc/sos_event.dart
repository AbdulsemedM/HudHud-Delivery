part of 'sos_bloc.dart';

abstract class SosEvent {
  const SosEvent();
}

class LoadLocalContactsEvent extends SosEvent {
  const LoadLocalContactsEvent();
}

class LoadSosHistoryEvent extends SosEvent {
  final String? statusFilter;

  const LoadSosHistoryEvent({this.statusFilter});
}

class LoadMoreSosHistoryEvent extends SosEvent {
  const LoadMoreSosHistoryEvent();
}

class AddEmergencyContactEvent extends SosEvent {
  final EmergencyContactModel contact;

  const AddEmergencyContactEvent(this.contact);
}

class UpdateEmergencyContactEvent extends SosEvent {
  final EmergencyContactModel contact;

  const UpdateEmergencyContactEvent(this.contact);
}

class DeleteEmergencyContactEvent extends SosEvent {
  final int contactId;

  const DeleteEmergencyContactEvent(this.contactId);
}

class TriggerSosEvent extends SosEvent {
  final SosTriggerRequest request;

  const TriggerSosEvent(this.request);
}
