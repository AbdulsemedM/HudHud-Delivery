import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hudhud_delivery/features/tips/bloc/tips_bloc.dart';

BlocProvider<TipsBloc> tipsBlocProvider({required Widget child}) {
  return BlocProvider(
    create: (_) => TipsBloc(),
    child: child,
  );
}
