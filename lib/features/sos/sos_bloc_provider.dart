import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hudhud_delivery/core/api/api_service.dart';
import 'package:hudhud_delivery/features/sos/bloc/sos_bloc.dart';
import 'package:hudhud_delivery/features/sos/data/sos_data_provider.dart';
import 'package:hudhud_delivery/features/sos/data/sos_repository.dart';

SosRepository createSosRepository() {
  return SosRepository(
    dataProvider: SosDataProvider(apiService: ApiService.instance),
  );
}

SosBloc createSosBloc() {
  return SosBloc(repository: createSosRepository());
}

BlocProvider<SosBloc> sosBlocProvider({required Widget child}) {
  return BlocProvider(
    create: (_) => createSosBloc(),
    child: child,
  );
}
