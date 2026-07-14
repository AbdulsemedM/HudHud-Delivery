import 'package:hudhud_delivery/features/service_types/model/service_type_model.dart';

import '../data_provider/service_types_data_provider.dart';

class ServiceTypesRepository {
  final ServiceTypesDataProvider _dataProvider;

  ServiceTypesRepository({required ServiceTypesDataProvider dataProvider})
      : _dataProvider = dataProvider;

  /// Fetches all service types from /api/service-types.
  /// Handles paginated response and returns list of [ServiceTypeModel].
  Future<List<ServiceTypeModel>> getServiceTypes({
    int page = 1,
    int perPage = 15,
  }) async {
    try {
      final response = await _dataProvider.getServiceTypes(
        page: page,
        perPage: perPage,
      );

      if (response['statusCode'] == 200) {
        final body = response['data'] as Map<String, dynamic>?;
        if (body == null) return [];

        // API wraps in { success, data: { data: [...], current_page, ... } }
        final data = body['data'];
        if (data == null) return [];

        final list = data is List ? data : (data is Map ? data['data'] : null);
        if (list is! List) return [];

        return list
            .map((e) =>
                ServiceTypeModel.fromJson(Map<String, dynamic>.from(e as Map)))
            .toList();
      }

      final errorMessage =
          response['errorMessage'] ?? 'Error fetching service types';
      throw Exception(_cleanErrorMessage(errorMessage));
    } catch (e) {
      throw Exception(_cleanErrorMessage(e.toString()));
    }
  }

  String _cleanErrorMessage(String message) {
    if (message.startsWith('Exception: ')) message = message.substring(11);
    if (message.startsWith('ApiException: ')) message = message.substring(14);
    if (message.startsWith('FormatException: ')) {
      message = message.substring(17);
    }
    return message;
  }
}
