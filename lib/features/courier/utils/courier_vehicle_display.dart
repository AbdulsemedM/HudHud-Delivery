import 'package:flutter/material.dart';
import 'package:hudhud_delivery/l10n/app_localizations.dart';

import 'delivery_estimate.dart';

IconData courierVehicleIcon(String vehicleId) {
  switch (mapCourierVehicleType(vehicleId)) {
    case 'car':
      return Icons.directions_car;
    case 'van':
    case 'pickup':
      return Icons.local_shipping;
    case 'bajaj':
      return Icons.electric_rickshaw;
    case 'bicycle':
      return Icons.pedal_bike;
    default:
      return Icons.two_wheeler;
  }
}

const kCourierMotorbikeMapAsset = 'assets/images/delivery-guy.png';
const kCourierTukMapAsset = 'assets/images/tuk.png';
const kCourierCarMapAsset = 'assets/images/car.png';

/// Map marker asset for anonymous nearby-driver pins by API `vehicle_type`.
String courierVehicleMapAsset(String? vehicleType) {
  switch (mapCourierVehicleType(vehicleType?.trim() ?? '')) {
    case 'bajaj':
      return kCourierTukMapAsset;
    case 'car':
    case 'van':
    case 'pickup':
      return kCourierCarMapAsset;
    default:
      return kCourierMotorbikeMapAsset;
  }
}

String courierVehicleLabel(String vehicleId, AppLocalizations l10n) {
  switch (mapCourierVehicleType(vehicleId)) {
    case 'car':
      return l10n.vehicleCar;
    case 'van':
      return l10n.vehicleVan;
    case 'bajaj':
      return l10n.vehicleBajaj;
    case 'pickup':
      return l10n.vehiclePickup;
    case 'motorbike':
    case 'motorcycle':
      return l10n.vehicleMotorcycle;
    default:
      final id = vehicleId.trim();
      if (id.isEmpty) return id;
      return '${id[0].toUpperCase()}${id.substring(1)}';
  }
}
