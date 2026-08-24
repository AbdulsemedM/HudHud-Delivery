import 'package:hudhud_delivery/features/orders/data/models/vendor_model.dart';

import '../data_provider/vendors_data_provider.dart';

class VendorsRepository {
  final VendorsDataProvider vendorsDataProvider;

  VendorsRepository({
    required this.vendorsDataProvider,
  });

  /// GET /api/vendors?page=
  Future<List<VendorModel>> getVendors({int page = 1}) async {
    final response = await vendorsDataProvider.getVendors(page: page);
    if (response['statusCode'] != 200) {
      throw Exception(
        _clean(response['errorMessage']?.toString() ?? 'Error fetching vendors'),
      );
    }
    final data = response['data'];
    if (data == null) return [];
    List<dynamic> list;
    if (data is List) {
      list = data;
    } else if (data is Map<String, dynamic>) {
      final inner = data['data'];
      if (inner is List) {
        list = inner;
      } else if (inner is Map<String, dynamic> && inner['data'] is List) {
        list = inner['data'] as List;
      } else {
        list = [];
      }
    } else {
      list = [];
    }
    return list
        .map((e) =>
            VendorModel.fromVendorListJson(Map<String, dynamic>.from(e as Map)))
        .toList();
  }

  String _clean(String message) {
    if (message.startsWith('Exception: ')) message = message.substring(11);
    if (message.startsWith('ApiException: ')) message = message.substring(14);
    return message;
  }
}
