import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter/foundation.dart';

part 'restaurants_event.dart';
part 'restaurants_state.dart';

class RestaurantsBloc extends Bloc<RestaurantsEvent, RestaurantsState> {
  RestaurantsBloc() : super(RestaurantsInitial()) {
    on<RestaurantsEvent>((event, emit) {
      // TODO: implement event handler
    });
  }
}
