import 'package:geocoding/geocoding.dart';
import 'custom_location_service.dart';

class GeocodingService {
  static const String _defaultAddress = "Current Location";
  
  /// Get address from latitude and longitude coordinates
  static Future<String> getAddressFromLatLng(double lat, double lng) async {
    try {
      List<Placemark> placemarks = await placemarkFromCoordinates(lat, lng);
      
      if (placemarks.isNotEmpty) {
        Placemark place = placemarks[0];
        
        // Build address string with available components
        List<String> addressParts = [];
        
        if (place.street != null && place.street!.isNotEmpty) {
          addressParts.add(place.street!);
        }
        
        if (place.locality != null && place.locality!.isNotEmpty) {
          addressParts.add(place.locality!);
        }
        
        if (place.administrativeArea != null && place.administrativeArea!.isNotEmpty) {
          addressParts.add(place.administrativeArea!);
        }
        
        if (addressParts.isNotEmpty) {
          return addressParts.join(', ');
        }
      }
      
      return _defaultAddress;
    } catch (e) {
      print('Error getting address from coordinates: $e');
      return _defaultAddress;
    }
  }
  
  /// Get current location address using GPS coordinates
  static Future<String> getCurrentLocationAddress() async {
    try {
      final LocationData? position = await CustomLocationService.getCurrentPosition();
      
      if (position != null) {
        return await getAddressFromLatLng(position.latitude, position.longitude);
      }
      
      return _defaultAddress;
    } catch (e) {
      print('Error getting current location address: $e');
      return _defaultAddress;
    }
  }
  
  /// Get street name only from coordinates
  static Future<String> getStreetNameFromLatLng(double lat, double lng) async {
    try {
      List<Placemark> placemarks = await placemarkFromCoordinates(lat, lng);
      
      if (placemarks.isNotEmpty) {
        Placemark place = placemarks[0];
        
        if (place.street != null && place.street!.isNotEmpty) {
          return place.street!;
        }
        
        // Fallback to locality if street is not available
        if (place.locality != null && place.locality!.isNotEmpty) {
          return place.locality!;
        }
      }
      
      return _defaultAddress;
    } catch (e) {
      print('Error getting street name from coordinates: $e');
      return _defaultAddress;
    }
  }
  
  /// Get current street name using GPS coordinates
  static Future<String> getCurrentStreetName() async {
    try {
      final LocationData? position = await CustomLocationService.getCurrentPosition();
      
      if (position != null) {
        return await getStreetNameFromLatLng(position.latitude, position.longitude);
      }
      
      return _defaultAddress;
    } catch (e) {
      print('Error getting current street name: $e');
      return _defaultAddress;
    }
  }
}