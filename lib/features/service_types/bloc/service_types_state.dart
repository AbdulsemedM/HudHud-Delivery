part of 'service_types_bloc.dart';

@immutable
sealed class ServiceTypesState {}

final class ServiceTypesInitial extends ServiceTypesState {}

final class ServiceTypesLoading extends ServiceTypesState {}

final class ServiceTypesSuccess extends ServiceTypesState {
  final List<ServiceTypeModel> serviceTypes;

  ServiceTypesSuccess(this.serviceTypes);
}

final class ServiceTypesFailure extends ServiceTypesState {
  final String errorMessage;

  ServiceTypesFailure(this.errorMessage);
}
