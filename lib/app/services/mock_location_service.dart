import 'package:latlong2/latlong.dart';
import 'package:hudhud_delivery/app/services/nominatim_service.dart';

/// A mock location service that provides predefined location data
/// Used as a fallback when the Nominatim API is unavailable
class MockLocationService {
  /// Returns a list of predefined locations that match the search query
  static List<PlaceResult> getMockLocations(String query) {
    // Convert query to lowercase for case-insensitive matching
    final lowercaseQuery = query.toLowerCase();
    
    // Filter the predefined locations based on the query
    return _mockLocations
        .where((location) => 
            location.displayName.toLowerCase().contains(lowercaseQuery) ||
            (location.city?.toLowerCase().contains(lowercaseQuery) ?? false) ||
            (location.street?.toLowerCase().contains(lowercaseQuery) ?? false))
        .toList();
  }
  
  /// Predefined list of locations
  static final List<PlaceResult> _mockLocations = [
    PlaceResult(
      displayName: 'Addis Ababa, Ethiopia',
      coordinates: LatLng(9.0222, 38.7468),
      street: null,
      city: 'Addis Ababa',
      state: null,
      country: 'Ethiopia',
      postcode: null,
    ),
    PlaceResult(
      displayName: 'Piassa, Addis Ababa, Ethiopia',
      coordinates: LatLng(9.0379, 38.7508),
      street: 'Piassa',
      city: 'Addis Ababa',
      state: null,
      country: 'Ethiopia',
      postcode: null,
    ),
    PlaceResult(
      displayName: 'Bole, Addis Ababa, Ethiopia',
      coordinates: LatLng(8.9806, 38.7878),
      street: 'Bole Road',
      city: 'Addis Ababa',
      state: null,
      country: 'Ethiopia',
      postcode: null,
    ),
    PlaceResult(
      displayName: 'Merkato, Addis Ababa, Ethiopia',
      coordinates: LatLng(9.0384, 38.7470),
      street: 'Merkato',
      city: 'Addis Ababa',
      state: null,
      country: 'Ethiopia',
      postcode: null,
    ),
    PlaceResult(
      displayName: 'Meskel Square, Addis Ababa, Ethiopia',
      coordinates: LatLng(9.0105, 38.7612),
      street: 'Meskel Square',
      city: 'Addis Ababa',
      state: null,
      country: 'Ethiopia',
      postcode: null,
    ),
    // Add more locations as needed
    PlaceResult(
      displayName: 'Nairobi, Kenya',
      coordinates: LatLng(-1.2921, 36.8219),
      street: null,
      city: 'Nairobi',
      state: null,
      country: 'Kenya',
      postcode: null,
    ),
    PlaceResult(
      displayName: 'Cairo, Egypt',
      coordinates: LatLng(30.0444, 31.2357),
      street: null,
      city: 'Cairo',
      state: null,
      country: 'Egypt',
      postcode: null,
    ),
    PlaceResult(
      displayName: 'Lagos, Nigeria',
      coordinates: LatLng(6.5244, 3.3792),
      street: null,
      city: 'Lagos',
      state: null,
      country: 'Nigeria',
      postcode: null,
    ),
  ];
}