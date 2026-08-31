import 'package:flutter_test/flutter_test.dart';
import 'package:hudhud_delivery/features/courier/utils/courier_vehicle_display.dart';

void main() {
  group('courierVehicleMapAsset', () {
    test('maps motorbike and bicycle to delivery-guy asset', () {
      expect(courierVehicleMapAsset('motorbike'), kCourierMotorbikeMapAsset);
      expect(courierVehicleMapAsset('motorcycle'), kCourierMotorbikeMapAsset);
      expect(courierVehicleMapAsset('bicycle'), kCourierMotorbikeMapAsset);
    });

    test('maps bajaj to tuk asset', () {
      expect(courierVehicleMapAsset('bajaj'), kCourierTukMapAsset);
    });

    test('maps car-like vehicles to car asset', () {
      expect(courierVehicleMapAsset('car'), kCourierCarMapAsset);
      expect(courierVehicleMapAsset('van'), kCourierCarMapAsset);
      expect(courierVehicleMapAsset('pickup'), kCourierCarMapAsset);
    });

    test('falls back to delivery-guy for null and unknown types', () {
      expect(courierVehicleMapAsset(null), kCourierMotorbikeMapAsset);
      expect(courierVehicleMapAsset(''), kCourierMotorbikeMapAsset);
      expect(courierVehicleMapAsset('scooter'), kCourierMotorbikeMapAsset);
    });
  });
}
