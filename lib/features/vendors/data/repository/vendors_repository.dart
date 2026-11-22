import 'package:hudhud_delivery/features/orders/data/models/vendor_model.dart';

import '../data_provider/vendors_data_provider.dart';

class VendorsRepository {
  final VendorsDataProvider vendorsDataProvider;

  VendorsRepository({
    required this.vendorsDataProvider,
  });

  /// GET /api/public/vendors
  Future<List<VendorModel>> getVendors({
    int page = 1,
    int perPage = 20,
    String? search,
    int? categoryId,
    double? latitude,
    double? longitude,
    String? sector,
  }) async {
    final response = await vendorsDataProvider.getVendors(
      page: page,
      perPage: perPage,
      search: search,
      categoryId: categoryId,
      latitude: latitude,
      longitude: longitude,
      sector: sector,
    );
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

  /// The sector keys that currently have at least one browsable shop.
  ///
  /// Never throws. The chip row is a convenience on the home screen, and a
  /// home screen that fails to build because a decoration could not load is
  /// a worse outcome than a home screen with no chips. An empty list is a
  /// valid, correct answer the UI already knows how to draw.
  Future<List<String>> getAvailableSectors() async {
    try {
      final response = await vendorsDataProvider.getVendorSectors();
      if (response['statusCode'] != 200) return const [];

      final rows = response['data'] is Map<String, dynamic>
          ? (response['data'] as Map<String, dynamic>)['data']
          : null;
      if (rows is! List) return const [];

      return rows
          .map((e) => e is Map ? e['key']?.toString() : null)
          .whereType<String>()
          .where((k) => k.isNotEmpty)
          .toList(growable: false);
    } catch (_) {
      return const [];
    }
  }

  String _clean(String message) {
    if (message.startsWith('Exception: ')) message = message.substring(11);
    if (message.startsWith('ApiException: ')) message = message.substring(14);
    return message;
  }
}
