/// The calling endpoints, which until now nothing in this app called.
///
/// Every route below has existed and been tested on the server since before
/// this file did. Grepping this app for `/calls/` returned nothing — the same
/// shape as the vendor wallet, found the same way.
library;

import 'package:hudhud_delivery/core/api/api_constants.dart';
import 'package:hudhud_delivery/core/api/api_service.dart';

import 'call_transport.dart';

/// An ICE server list, with the one fact that decides whether a call will
/// work in the field.
class IceConfig {
  const IceConfig({required this.servers, required this.turnAvailable});

  /// Passed to the peer connection untouched.
  final List<Map<String, dynamic>> servers;

  /// False means STUN only. A direct path between two phones works on wifi
  /// and fails between two phones on Ethiopian mobile data, where both sit
  /// behind carrier NAT — so this is the difference between "calling works"
  /// and "calling works in the office". The UI warns instead of dialling
  /// into silence.
  final bool turnAvailable;

  static const unavailable = IceConfig(servers: [], turnAvailable: false);
}

class CallApi implements CallSignalSource {
  CallApi({ApiService? api}) : _api = api ?? ApiService.instance;

  final ApiService _api;

  String _url(String path) => '${ApiConstants.baseUrl}$path';

  /// Start a call. The server decides whether it is allowed — the two must
  /// share a job that is still running — so a refusal here is expected and
  /// its code is worth showing.
  Future<String?> initiate(int calleeId) async {
    final r = await _api.post<Map<String, dynamic>>(
      _url('/calls/initiate'),
      data: {'callee_id': calleeId},
    );
    final uid = (r.data?['data'] as Map?)?['call_uid'];
    return uid is String ? uid : null;
  }

  Future<void> accept(String uid) async =>
      _api.post<dynamic>(_url('/calls/$uid/accept'));

  Future<void> reject(String uid, {String reason = 'declined'}) async =>
      _api.post<dynamic>(_url('/calls/$uid/reject'), data: {'reason': reason});

  Future<void> end(String uid, {String reason = 'hangup'}) async =>
      _api.post<dynamic>(_url('/calls/$uid/end'), data: {'reason': reason});

  /// type is offer | answer | ice. The server never parses the payload.
  Future<void> signal(String uid, String type, Object data) async =>
      _api.post<dynamic>(
        _url('/calls/$uid/signal'),
        data: {'type': type, 'data': data},
      );

  @override
  Future<DrainResult> drain(String callUid, int after) async {
    final r = await _api.get<Map<String, dynamic>>(
      _url('/calls/$callUid/signals'),
      queryParameters: {'after': after},
    );
    final data = r.data?['data'];
    if (data is! Map) return DrainResult(signals: const [], cursor: after);

    final raw = data['signals'];
    final signals = <CallSignalMessage>[];
    if (raw is List) {
      for (final item in raw) {
        final parsed = CallSignalMessage.fromJson(item);
        if (parsed != null) signals.add(parsed);
      }
    }

    final cursor = data['cursor'];
    final status = data['status'];

    return DrainResult(
      signals: signals,
      // Never fall back to 0: a cursor that resets redelivers the whole
      // call, `ended` included.
      cursor: cursor is int ? cursor : after,
      status: status is String ? status : null,
    );
  }

  Future<IceConfig> iceServers() async {
    try {
      final r = await _api.get<Map<String, dynamic>>(_url('/calls/ice-servers'));
      final body = r.data;
      final list = body?['data'];
      if (list is! List) return IceConfig.unavailable;

      return IceConfig(
        servers: list
            .whereType<Map>()
            .map((e) => Map<String, dynamic>.from(e))
            .toList(growable: false),
        turnAvailable: body?['turn_available'] == true,
      );
    } catch (_) {
      // Without a server list a peer connection cannot be built at all, so
      // the caller treats this as "calling unavailable" rather than trying
      // and failing silently.
      return IceConfig.unavailable;
    }
  }
}
