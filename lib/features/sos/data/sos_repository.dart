import 'package:hudhud_delivery/features/sos/data/sos_contacts_local_store.dart';
import 'package:hudhud_delivery/features/sos/data/sos_data_provider.dart';
import 'package:hudhud_delivery/features/sos/model/emergency_contact_model.dart';
import 'package:hudhud_delivery/features/sos/model/sos_history_result.dart';
import 'package:hudhud_delivery/features/sos/model/sos_trigger_request.dart';
import 'package:hudhud_delivery/features/sos/model/sos_trigger_result.dart';

class SosRepository {
  final SosDataProvider dataProvider;
  final SosContactsLocalStore localStore;

  SosRepository({
    required this.dataProvider,
    SosContactsLocalStore? localStore,
  }) : localStore = localStore ?? SosContactsLocalStore();

  Future<List<EmergencyContactModel>> getLocalContacts() {
    return localStore.getContacts();
  }

  Future<SosHistoryResult> getSosHistory({
    String? status,
    int page = 1,
    int perPage = 10,
  }) async {
    final response = await dataProvider.getSosHistory(
      status: status,
      page: page,
      perPage: perPage,
    );
    _ensureSuccess(response, 'Error fetching SOS history');
    return SosHistoryResult.fromResponseData(response['data']);
  }

  Future<SosTriggerResult> triggerSos(SosTriggerRequest request) async {
    final response = await dataProvider.triggerSos(request.toJson());
    _ensureSuccess(response, 'Error triggering SOS alert');
    final root = response['data'];
    if (root is Map) {
      return SosTriggerResult.fromResponse(
        Map<String, dynamic>.from(root),
      );
    }
    throw Exception('Invalid SOS trigger response');
  }

  Future<EmergencyContactModel> addEmergencyContact(
    EmergencyContactModel contact,
  ) async {
    final response = await dataProvider.addEmergencyContact(
      contact.toCreateBody(),
    );
    _ensureSuccess(response, 'Error adding emergency contact');
    final parsed = _parseContact(response['data']);
    await localStore.saveContact(parsed);
    return parsed;
  }

  Future<EmergencyContactModel> updateEmergencyContact(
    EmergencyContactModel contact,
  ) async {
    final response = await dataProvider.updateEmergencyContact(
      contact.id,
      contact.toUpdateBody(),
    );
    _ensureSuccess(response, 'Error updating emergency contact');
    final parsed = _parseContact(response['data']);
    await localStore.saveContact(parsed);
    return parsed;
  }

  Future<void> deleteEmergencyContact(int id) async {
    final response = await dataProvider.deleteEmergencyContact(id);
    _ensureSuccess(response, 'Error deleting emergency contact');
    await localStore.removeContact(id);
  }

  EmergencyContactModel _parseContact(dynamic root) {
    final data = _extractDataMap(root);
    return EmergencyContactModel.fromJson(data);
  }

  Map<String, dynamic> _extractDataMap(dynamic root) {
    if (root is Map<String, dynamic>) {
      if (root['data'] is Map) {
        return Map<String, dynamic>.from(root['data'] as Map);
      }
      return root;
    }
    if (root is Map) {
      final map = Map<String, dynamic>.from(root);
      if (map['data'] is Map) {
        return Map<String, dynamic>.from(map['data'] as Map);
      }
      return map;
    }
    throw Exception('Invalid response');
  }

  bool _isHttpSuccess(Map<String, dynamic> response) {
    final code = response['statusCode'] as int?;
    return code != null && code >= 200 && code < 300;
  }

  void _ensureSuccess(Map<String, dynamic> response, String fallback) {
    if (_isHttpSuccess(response)) {
      final data = response['data'];
      if (data is Map && data['success'] == false) {
        throw Exception(
          _clean(data['message']?.toString() ?? fallback),
        );
      }
      return;
    }
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
