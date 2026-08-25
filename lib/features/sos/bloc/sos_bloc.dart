import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hudhud_delivery/features/sos/data/sos_repository.dart';
import 'package:hudhud_delivery/features/sos/model/emergency_contact_model.dart';
import 'package:hudhud_delivery/features/sos/model/sos_alert_model.dart';
import 'package:hudhud_delivery/features/sos/model/sos_trigger_request.dart';
import 'package:hudhud_delivery/features/sos/model/sos_trigger_result.dart';

part 'sos_event.dart';
part 'sos_state.dart';

class SosBloc extends Bloc<SosEvent, SosState> {
  final SosRepository repository;

  SosBloc({required this.repository}) : super(const SosInitial()) {
    on<LoadLocalContactsEvent>(_onLoadContacts);
    on<LoadSosHistoryEvent>(_onLoadHistory);
    on<LoadMoreSosHistoryEvent>(_onLoadMoreHistory);
    on<AddEmergencyContactEvent>(_onAddContact);
    on<UpdateEmergencyContactEvent>(_onUpdateContact);
    on<DeleteEmergencyContactEvent>(_onDeleteContact);
    on<TriggerSosEvent>(_onTrigger);
  }

  Future<void> _onLoadContacts(
    LoadLocalContactsEvent event,
    Emitter<SosState> emit,
  ) async {
    try {
      final contacts = await repository.getLocalContacts();
      final current = state;
      if (current is SosLoaded) {
        emit(current.copyWith(contacts: contacts));
      } else {
        emit(SosLoaded(contacts: contacts));
      }
    } catch (e) {
      emit(SosError(e.toString()));
    }
  }

  Future<void> _onLoadHistory(
    LoadSosHistoryEvent event,
    Emitter<SosState> emit,
  ) async {
    emit(const SosLoading());
    try {
      final contacts = await repository.getLocalContacts();
      final result = await repository.getSosHistory(
        status: event.statusFilter,
        page: 1,
      );
      emit(
        SosLoaded(
          contacts: contacts,
          history: result.items,
          statusFilter: event.statusFilter,
          currentPage: result.currentPage,
          hasMoreHistory: result.hasMore,
        ),
      );
    } catch (e) {
      emit(SosError(e.toString()));
    }
  }

  Future<void> _onLoadMoreHistory(
    LoadMoreSosHistoryEvent event,
    Emitter<SosState> emit,
  ) async {
    final current = state;
    if (current is! SosLoaded ||
        !current.hasMoreHistory ||
        current.isLoadingMore) {
      return;
    }
    emit(current.copyWith(isLoadingMore: true));
    try {
      final nextPage = current.currentPage + 1;
      final result = await repository.getSosHistory(
        status: current.statusFilter,
        page: nextPage,
      );
      emit(
        current.copyWith(
          history: [...current.history, ...result.items],
          currentPage: result.currentPage,
          hasMoreHistory: result.hasMore,
          isLoadingMore: false,
        ),
      );
    } catch (e) {
      emit(current.copyWith(isLoadingMore: false));
      emit(SosError(e.toString()));
    }
  }

  Future<void> _onAddContact(
    AddEmergencyContactEvent event,
    Emitter<SosState> emit,
  ) async {
    final current = state;
    if (current is SosLoaded) {
      emit(current.copyWith(isSubmitting: true, clearSuccess: true));
    }
    try {
      await repository.addEmergencyContact(event.contact);
      final contacts = await repository.getLocalContacts();
      if (current is SosLoaded) {
        emit(
          current.copyWith(
            contacts: contacts,
            isSubmitting: false,
            successMessage: 'contact_added',
          ),
        );
      } else {
        emit(SosLoaded(contacts: contacts, successMessage: 'contact_added'));
      }
    } catch (e) {
      if (current is SosLoaded) {
        emit(current.copyWith(isSubmitting: false));
      }
      emit(SosError(e.toString()));
    }
  }

  Future<void> _onUpdateContact(
    UpdateEmergencyContactEvent event,
    Emitter<SosState> emit,
  ) async {
    final current = state;
    if (current is SosLoaded) {
      emit(current.copyWith(isSubmitting: true, clearSuccess: true));
    }
    try {
      await repository.updateEmergencyContact(event.contact);
      final contacts = await repository.getLocalContacts();
      if (current is SosLoaded) {
        emit(
          current.copyWith(
            contacts: contacts,
            isSubmitting: false,
            successMessage: 'contact_updated',
          ),
        );
      } else {
        emit(SosLoaded(contacts: contacts, successMessage: 'contact_updated'));
      }
    } catch (e) {
      if (current is SosLoaded) {
        emit(current.copyWith(isSubmitting: false));
      }
      emit(SosError(e.toString()));
    }
  }

  Future<void> _onDeleteContact(
    DeleteEmergencyContactEvent event,
    Emitter<SosState> emit,
  ) async {
    final current = state;
    if (current is SosLoaded) {
      emit(current.copyWith(isSubmitting: true, clearSuccess: true));
    }
    try {
      await repository.deleteEmergencyContact(event.contactId);
      final contacts = await repository.getLocalContacts();
      if (current is SosLoaded) {
        emit(
          current.copyWith(
            contacts: contacts,
            isSubmitting: false,
            successMessage: 'contact_deleted',
          ),
        );
      } else {
        emit(SosLoaded(contacts: contacts, successMessage: 'contact_deleted'));
      }
    } catch (e) {
      if (current is SosLoaded) {
        emit(current.copyWith(isSubmitting: false));
      }
      emit(SosError(e.toString()));
    }
  }

  Future<void> _onTrigger(
    TriggerSosEvent event,
    Emitter<SosState> emit,
  ) async {
    final current = state;
    if (current is SosLoaded) {
      emit(current.copyWith(isSubmitting: true, clearSuccess: true));
    } else {
      emit(const SosLoading());
    }
    try {
      final result = await repository.triggerSos(event.request);
      if (current is SosLoaded) {
        emit(
          current.copyWith(
            isSubmitting: false,
            lastTriggerResult: result,
            successMessage: 'sos_triggered',
          ),
        );
      } else {
        emit(
          SosLoaded(
            lastTriggerResult: result,
            successMessage: 'sos_triggered',
          ),
        );
      }
    } catch (e) {
      if (current is SosLoaded) {
        emit(current.copyWith(isSubmitting: false));
      }
      emit(SosError(e.toString()));
    }
  }
}
