import 'package:hudhud_delivery/app/services/saved_location_service.dart';
import 'package:hudhud_delivery/features/addresses/data/addresses_data_provider.dart';
import 'package:hudhud_delivery/features/addresses/model/address_model.dart';
import 'package:hudhud_delivery/features/addresses/model/address_payload.dart';
import 'package:hudhud_delivery/features/addresses/model/addresses_list_result.dart';

class AddressesRepository {
  final AddressesDataProvider addressesDataProvider;

  AddressesRepository({required this.addressesDataProvider});

  Future<AddressesListResult> getAddresses({int page = 1}) async {
    final response = await addressesDataProvider.getAddresses(page: page);
    _ensureSuccess(response, 'Error fetching addresses');
    return AddressesListResult.fromResponseData(response['data'], page: page);
  }

  Future<AddressModel> getAddressById(int id) async {
    final response = await addressesDataProvider.getAddressById(id);
    _ensureSuccess(response, 'Error fetching address');
    return _parseSingleAddress(response['data']);
  }

  Future<AddressModel> createAddress(AddressPayload payload) async {
    final response = await addressesDataProvider.createAddress(
      payload.toJson(forCreate: true),
    );
    _ensureSuccess(response, 'Error creating address');
    final address = _parseSingleAddress(response['data']);
    if (address.isDefault) {
      await syncDefaultToLocal(address);
    }
    return address;
  }

  Future<AddressModel> updateAddress(int id, AddressPayload payload) async {
    final response = await addressesDataProvider.updateAddress(
      id,
      payload.toJson(),
    );
    _ensureSuccess(response, 'Error updating address');
    final address = _parseSingleAddress(response['data']);
    if (address.isDefault) {
      await syncDefaultToLocal(address);
    }
    return address;
  }

  Future<AddressModel> setDefaultAddress(int id) async {
    final response = await addressesDataProvider.setDefaultAddress(id);
    _ensureSuccess(response, 'Error setting default address');
    final address = _parseSingleAddress(response['data']);
    await syncDefaultToLocal(address);
    return address;
  }

  Future<AddressModel?> getDefaultAddress() async {
    final response = await addressesDataProvider.getDefaultAddress();
    if (response['statusCode'] == 404) return null;
    _ensureSuccess(response, 'Error fetching default address');
    final data = response['data'];
    if (data == null) return null;
    final inner = data is Map && data['data'] != null ? data['data'] : data;
    if (inner == null) return null;
    final address = AddressModel.fromJson(
      Map<String, dynamic>.from(inner as Map),
    );
    await syncDefaultToLocal(address);
    return address;
  }

  Future<void> deleteAddress(int id) async {
    final response = await addressesDataProvider.deleteAddress(id);
    _ensureSuccess(response, 'Error deleting address');
  }

  Future<void> bulkDeleteAddresses({
    required List<int> ids,
    bool force = false,
  }) async {
    final response = await addressesDataProvider.bulkDeleteAddresses(
      ids: ids,
      force: force,
    );
    _ensureSuccess(response, 'Error deleting addresses');
  }

  static Future<void> syncDefaultToLocal(AddressModel? address) async {
    if (address == null) return;
    await SavedLocationService.syncFromAddress(
      address: address.displayText,
      latitude: address.latitude,
      longitude: address.longitude,
    );
  }

  AddressModel _parseSingleAddress(dynamic data) {
    if (data is Map<String, dynamic>) {
      final inner = data['data'];
      if (inner is Map) {
        return AddressModel.fromJson(Map<String, dynamic>.from(inner));
      }
      return AddressModel.fromJson(data);
    }
    throw Exception('Invalid address response');
  }

  void _ensureSuccess(Map<String, dynamic> response, String fallback) {
    final code = response['statusCode'] as int?;
    if (code != null && code >= 200 && code < 300) return;
    throw Exception(_clean(response['errorMessage']?.toString() ?? fallback));
  }

  String _clean(String message) {
    if (message.startsWith('Exception: ')) {
      message = message.substring(11);
    }
    if (message.startsWith('ApiException: ')) {
      message = message.substring(14);
    }
    return message;
  }
}
