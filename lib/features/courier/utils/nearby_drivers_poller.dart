import 'dart:async';

import 'package:hudhud_delivery/features/courier/data/models/nearby_drivers_result.dart';
import 'package:hudhud_delivery/features/courier/data/repository/courier_repository.dart';

/// Polls anonymous nearby-driver markers until disposed or a 422 stops retries.
class NearbyDriversPoller {
  NearbyDriversPoller({
    required this.repository,
    required this.onUpdate,
  });

  final CourierRepository repository;
  final void Function() onUpdate;

  Timer? _timer;
  NearbyDriversResult result = const NearbyDriversResult();
  bool stoppedForInvalidCoordinates = false;

  double? _latitude;
  double? _longitude;
  String? _vehicleType;
  int? _radius;
  int _refreshAfterSeconds = 15;

  int get refreshAfterSeconds => _refreshAfterSeconds;

  void setTarget({
    required double latitude,
    required double longitude,
    required String vehicleType,
    int? radius,
  }) {
    final same = _latitude == latitude &&
        _longitude == longitude &&
        _vehicleType == vehicleType &&
        _radius == radius;
    _latitude = latitude;
    _longitude = longitude;
    _vehicleType = vehicleType;
    _radius = radius;
    if (stoppedForInvalidCoordinates) return;
    if (!same || _timer == null) {
      _restartTimer(fetchNow: true);
    }
  }

  void dispose() {
    _timer?.cancel();
    _timer = null;
  }

  void _restartTimer({required bool fetchNow}) {
    _timer?.cancel();
    if (fetchNow) {
      unawaited(_fetch());
    }
    _timer = Timer.periodic(
      Duration(seconds: _refreshAfterSeconds),
      (_) => _fetch(),
    );
  }

  Future<void> _fetch() async {
    final lat = _latitude;
    final lng = _longitude;
    final vehicle = _vehicleType;
    if (lat == null || lng == null || vehicle == null) return;

    final response = await repository.getNearbyDrivers(
      latitude: lat,
      longitude: lng,
      radius: _radius,
      vehicleType: vehicle,
    );

    if (response['retryable'] == false) {
      stoppedForInvalidCoordinates = true;
      _timer?.cancel();
      _timer = null;
      return;
    }

    if (response['success'] != true) return;

    final nearby = response['nearby'];
    if (nearby is! NearbyDriversResult) return;

    result = nearby;
    final nextRefresh =
        nearby.refreshAfterSeconds < 1 ? 15 : nearby.refreshAfterSeconds;
    final intervalChanged = nextRefresh != _refreshAfterSeconds;
    _refreshAfterSeconds = nextRefresh;
    onUpdate();

    if (intervalChanged && !stoppedForInvalidCoordinates) {
      _restartTimer(fetchNow: false);
    }
  }
}
