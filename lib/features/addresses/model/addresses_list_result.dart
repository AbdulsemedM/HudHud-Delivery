import 'address_model.dart';

class AddressesListResult {
  final List<AddressModel> addresses;
  final AddressesListMeta meta;
  final int currentPage;

  const AddressesListResult({
    required this.addresses,
    required this.meta,
    required this.currentPage,
  });

  bool get hasMore => addresses.length < meta.total;

  factory AddressesListResult.fromResponseData(
    dynamic data, {
    int page = 1,
  }) {
    List<dynamic> list = [];
    Map<String, dynamic>? metaMap;

    if (data is List) {
      list = data;
    } else if (data is Map<String, dynamic>) {
      final inner = data['data'];
      if (inner is List) {
        list = inner;
      } else if (data['data'] is Map && (data['data'] as Map)['data'] is List) {
        list = (data['data'] as Map)['data'] as List;
      }
      metaMap = data['meta'] is Map
          ? Map<String, dynamic>.from(data['meta'] as Map)
          : null;
    }

    final addresses = list
        .map((e) => AddressModel.fromJson(Map<String, dynamic>.from(e as Map)))
        .toList();

    return AddressesListResult(
      addresses: addresses,
      meta: AddressesListMeta.fromJson(metaMap),
      currentPage: page,
    );
  }
}
