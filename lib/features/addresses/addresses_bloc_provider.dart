import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hudhud_delivery/core/api/api_service.dart';
import 'package:hudhud_delivery/features/addresses/bloc/addresses_bloc.dart';
import 'package:hudhud_delivery/features/addresses/data/addresses_data_provider.dart';
import 'package:hudhud_delivery/features/addresses/data/addresses_repository.dart';

AddressesBloc createAddressesBloc() {
  final repo = AddressesRepository(
    addressesDataProvider: AddressesDataProvider(
      apiService: ApiService.instance,
    ),
  );
  return AddressesBloc(repository: repo);
}

BlocProvider<AddressesBloc> addressesBlocProvider({required Widget child}) {
  return BlocProvider(
    create: (_) => createAddressesBloc()..add(const LoadAddressesEvent()),
    child: child,
  );
}
