import 'package:hudhud_delivery/core/api/api_constants.dart';
import 'package:hudhud_delivery/core/api/api_service.dart';

class AddressesDataProvider {
  final ApiService apiService;

  AddressesDataProvider({required this.apiService});

  String _url(String path) => '${ApiConstants.baseUrl}$path';

  Future<Map<String, dynamic>> _wrap(Future<dynamic> Function() call) async {
    try {
      final response = await call();
      return {
        'statusCode': response.statusCode,
        'data': response.data,
        'errorMessage': null,
      };
    } on ApiException catch (e) {
      return {
        'statusCode': e.statusCode ?? 500,
        'data': e.data,
        'errorMessage': e.message,
      };
    } on Exception catch (e) {
      return {'statusCode': 500, 'data': null, 'errorMessage': e.toString()};
    }
  }

  Future<Map<String, dynamic>> createAddress(Map<String, dynamic> body) {
    return _wrap(() => apiService.post(_url(ApiConstants.addresses), data: body));
  }

  Future<Map<String, dynamic>> getAddresses({int page = 1}) {
    return _wrap(
      () => apiService.get(
        _url(ApiConstants.addresses),
        queryParameters: {'page': page},
      ),
    );
  }

  Future<Map<String, dynamic>> getAddressById(int id) {
    return _wrap(
      () => apiService.get(
        _url(ApiConstants.replacePathParams(
          ApiConstants.addressDetails,
          {'id': id},
        )),
      ),
    );
  }

  Future<Map<String, dynamic>> updateAddress(
    int id,
    Map<String, dynamic> body,
  ) {
    return _wrap(
      () => apiService.put(
        _url(ApiConstants.replacePathParams(
          ApiConstants.addressDetails,
          {'id': id},
        )),
        data: body,
      ),
    );
  }

  Future<Map<String, dynamic>> setDefaultAddress(int id) {
    return _wrap(
      () => apiService.post(
        _url(ApiConstants.replacePathParams(
          ApiConstants.addressSetDefault,
          {'id': id},
        )),
      ),
    );
  }

  Future<Map<String, dynamic>> getDefaultAddress() {
    return _wrap(() => apiService.get(_url(ApiConstants.addressesDefault)));
  }

  Future<Map<String, dynamic>> deleteAddress(int id) {
    return _wrap(
      () => apiService.delete(
        _url(ApiConstants.replacePathParams(
          ApiConstants.addressDetails,
          {'id': id},
        )),
      ),
    );
  }

  Future<Map<String, dynamic>> bulkDeleteAddresses({
    required List<int> ids,
    bool force = false,
  }) {
    return _wrap(
      () => apiService.post(
        _url(ApiConstants.addressesBulkDelete),
        data: {'ids': ids, 'force': force},
      ),
    );
  }
}
