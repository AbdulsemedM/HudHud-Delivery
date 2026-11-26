import 'package:hudhud_delivery/core/api/api_constants.dart';
import 'package:hudhud_delivery/core/api/api_service.dart';

class VendorsDataProvider {
  final ApiService apiService;
  VendorsDataProvider({required this.apiService});

  /// GET /api/public/vendors — preferred discovery route (lat/lng optional).
  ///
  /// [sector] is one of the platform's eight vendor sectors: restaurant,
  /// bakery, supermarket, grocery, market, pharmacy, spare_parts, general.
  /// The server resolves it from the vendor's organization record, falling
  /// back to business_type, and narrows BEFORE paginating — so asking for
  /// pharmacies returns pharmacies rather than the pharmacies that happened
  /// to land on page one. An unrecognised value is refused with 422 and
  /// `code: SECTOR_UNRECOGNISED`, so send a key, not a label.
  Future<Map<String, dynamic>> getVendors({
    int page = 1,
    int perPage = 20,
    String? search,
    int? categoryId,
    double? latitude,
    double? longitude,
    String? sector,
  }) async {
    try {
      final query = <String, dynamic>{
        'page': page,
        'per_page': perPage,
      };
      if (search != null && search.trim().isNotEmpty) {
        query['search'] = search.trim();
      }
      if (categoryId != null) query['category_id'] = categoryId;
      if (latitude != null) query['latitude'] = latitude;
      if (longitude != null) query['longitude'] = longitude;
      if (sector != null && sector.trim().isNotEmpty) {
        query['sector'] = sector.trim();
      }

      final response = await apiService.get(
        '${ApiConstants.baseUrl}${ApiConstants.publicVendors}',
        queryParameters: query,
      );
      return {
        'statusCode': response.statusCode,
        'data': response.data,
        'errorMessage': null,
      };
    } on ApiException catch (e) {
      return {
        'statusCode': e.statusCode,
        'data': null,
        'errorMessage': e.message,
      };
    } on Exception catch (e) {
      return {'statusCode': 500, 'data': null, 'errorMessage': e.toString()};
    }
  }

  /// GET /api/public/vendors/sectors — which sectors have a shop in them.
  ///
  /// The chip row used to be nine hardcoded sectors. The platform supports
  /// all eight; the marketplace does not have them all yet, and the app had
  /// no way to tell the difference — so tapping Pharmacy opened an empty
  /// list with nothing to explain it, which reads as a broken app rather
  /// than an empty category.
  ///
  /// The server answers with only the sectors it can actually fill, counted
  /// against the same query that backs the list itself, so a chip and its
  /// result cannot disagree.
  Future<Map<String, dynamic>> getVendorSectors() async {
    try {
      final response = await apiService.get(
        '${ApiConstants.baseUrl}${ApiConstants.publicVendors}/sectors',
      );
      return {
        'statusCode': response.statusCode,
        'data': response.data,
        'errorMessage': null,
      };
    } on ApiException catch (e) {
      return {'statusCode': e.statusCode, 'data': null, 'errorMessage': e.message};
    } on Exception catch (e) {
      return {'statusCode': 500, 'data': null, 'errorMessage': e.toString()};
    }
  }

  /// GET /api/public/vendors/{id}
  Future<Map<String, dynamic>> getVendorById(int vendorId) async {
    try {
      final response = await apiService.get(
        '${ApiConstants.baseUrl}${ApiConstants.publicVendors}/$vendorId',
      );
      return {
        'statusCode': response.statusCode,
        'data': response.data,
        'errorMessage': null,
      };
    } on ApiException catch (e) {
      return {
        'statusCode': e.statusCode,
        'data': null,
        'errorMessage': e.message,
      };
    } on Exception catch (e) {
      return {'statusCode': 500, 'data': null, 'errorMessage': e.toString()};
    }
  }

  /// GET /api/public/vendors/{id}/products
  Future<Map<String, dynamic>> getVendorProducts(
    int vendorId, {
    int page = 1,
    int perPage = 30,
  }) async {
    try {
      final path = ApiConstants.replacePathParams(
        ApiConstants.publicVendorProducts,
        {'id': vendorId},
      );
      final response = await apiService.get(
        '${ApiConstants.baseUrl}$path',
        queryParameters: {
          'page': page,
          'per_page': perPage,
        },
      );
      return {
        'statusCode': response.statusCode,
        'data': response.data,
        'errorMessage': null,
      };
    } on ApiException catch (e) {
      return {
        'statusCode': e.statusCode,
        'data': null,
        'errorMessage': e.message,
      };
    } on Exception catch (e) {
      return {'statusCode': 500, 'data': null, 'errorMessage': e.toString()};
    }
  }
}
