part of 'sos_bloc.dart';

abstract class SosState {
  const SosState();
}

class SosInitial extends SosState {
  const SosInitial();
}

class SosLoading extends SosState {
  const SosLoading();
}

class SosLoaded extends SosState {
  final List<EmergencyContactModel> contacts;
  final List<SosAlertModel> history;
  final String? statusFilter;
  final int currentPage;
  final bool hasMoreHistory;
  final bool isLoadingMore;
  final bool isSubmitting;
  final String? successMessage;
  final SosTriggerResult? lastTriggerResult;

  const SosLoaded({
    this.contacts = const [],
    this.history = const [],
    this.statusFilter,
    this.currentPage = 1,
    this.hasMoreHistory = false,
    this.isLoadingMore = false,
    this.isSubmitting = false,
    this.successMessage,
    this.lastTriggerResult,
  });

  SosLoaded copyWith({
    List<EmergencyContactModel>? contacts,
    List<SosAlertModel>? history,
    String? statusFilter,
    int? currentPage,
    bool? hasMoreHistory,
    bool? isLoadingMore,
    bool? isSubmitting,
    String? successMessage,
    SosTriggerResult? lastTriggerResult,
    bool clearSuccess = false,
    bool clearTrigger = false,
  }) {
    return SosLoaded(
      contacts: contacts ?? this.contacts,
      history: history ?? this.history,
      statusFilter: statusFilter ?? this.statusFilter,
      currentPage: currentPage ?? this.currentPage,
      hasMoreHistory: hasMoreHistory ?? this.hasMoreHistory,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
      isSubmitting: isSubmitting ?? this.isSubmitting,
      successMessage:
          clearSuccess ? null : (successMessage ?? this.successMessage),
      lastTriggerResult: clearTrigger
          ? null
          : (lastTriggerResult ?? this.lastTriggerResult),
    );
  }
}

class SosError extends SosState {
  final String message;

  const SosError(this.message);
}
