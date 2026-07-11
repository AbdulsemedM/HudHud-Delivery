part of 'service_types_bloc.dart';

@immutable
sealed class ServiceTypesEvent {}

class FetchServiceTypesEvent extends ServiceTypesEvent {
  final int page;
  final int perPage;

  FetchServiceTypesEvent({this.page = 1, this.perPage = 15});
}
