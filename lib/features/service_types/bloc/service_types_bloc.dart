import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../data/repository/service_types_repository.dart';
import '../model/service_type_model.dart';

part 'service_types_event.dart';
part 'service_types_state.dart';

class ServiceTypesBloc extends Bloc<ServiceTypesEvent, ServiceTypesState> {
  final ServiceTypesRepository repository;

  ServiceTypesBloc(this.repository) : super(ServiceTypesInitial()) {
    on<FetchServiceTypesEvent>((event, emit) async {
      emit(ServiceTypesLoading());
      try {
        final serviceTypes = await repository.getServiceTypes(
          page: event.page,
          perPage: event.perPage,
        );
        emit(ServiceTypesSuccess(serviceTypes));
      } catch (e) {
        emit(ServiceTypesFailure(e.toString()));
      }
    });
  }
}
