import 'package:dio/dio.dart';
import 'package:hudhud_delivery/core/api/api_constants.dart';
import 'package:hudhud_delivery/core/api/api_service.dart';

import 'parcel_v2_models.dart';

/// Outcome of a parcel v2 call. Never throws to the UI.
class ParcelResult<T> {
  final T? value;
  final int? statusCode;
  final String? code;
  final String? message;
  final Map<String, dynamic>? body;

  const ParcelResult({
    this.value,
    this.statusCode,
    this.code,
    this.message,
    this.body,
  });

  bool get ok => value != null;

  ParcelErrorKind get errorKind => parcelErrorKind(code, message: message);
}

/// Phase 10 `/api/parcels/*` client.
class ParcelV2Repository {
  final ApiService _api;

  ParcelV2Repository({ApiService? apiService})
      : _api = apiService ?? ApiService.instance;

  String _url(String path) => '${ApiConstants.baseUrl}$path';

  String _withId(String path, int id) => path.replaceFirst('{id}', '$id');

  Future<ParcelResult<Map<String, dynamic>>> _call(
    Future<Response<dynamic>> Function() request,
  ) async {
    try {
      final response = await request();
      final data = response.data;
      final body = data is Map ? Map<String, dynamic>.from(data) : null;
      return ParcelResult(
        value: body ?? <String, dynamic>{},
        statusCode: response.statusCode,
        body: body,
      );
    } on ApiException catch (e) {
      final raw = e.data;
      final data = raw is Map ? Map<String, dynamic>.from(raw) : null;
      // The body's own code first: ApiException.code is only a fallback
      // (older builds folded unknown 422 codes into validation_error).
      final bodyCode = data?['code']?.toString();
      final code =
          bodyCode != null && bodyCode.isNotEmpty ? bodyCode : e.code;
      final message = (data?['message'] is String &&
              (data!['message'] as String).trim().isNotEmpty)
          ? (data['message'] as String).trim()
          : e.message;
      return ParcelResult(
        statusCode: e.statusCode,
        code: code,
        message: message,
        body: data,
      );
    } catch (e) {
      return ParcelResult(message: e.toString());
    }
  }

  /// Never fails: an older backend or a network error means "v2 disabled".
  Future<ParcelV2Config> fetchConfig({String? market}) async {
    final r = await _call(
      () => _api.get(
        _url(ApiConstants.parcelsConfig),
        queryParameters:
            market == null || market.isEmpty ? null : {'market': market},
      ),
    );
    if (!r.ok) return ParcelV2Config.disabled;
    return ParcelV2Config.fromResponseBody(r.value);
  }

  Future<ParcelResult<ParcelQuote>> quote(ParcelBookingDraft draft) async {
    final r = await _call(
      () => _api.post(
        _url(ApiConstants.parcelsQuote),
        data: draft.quoteBody(),
      ),
    );
    final quote = r.ok ? ParcelQuote.fromResponseBody(r.value) : null;
    return ParcelResult(
      value: quote,
      statusCode: r.statusCode,
      code: r.code ?? (r.ok && quote == null ? 'BAD_RESPONSE' : null),
      message: r.message,
      body: r.body,
    );
  }

  Future<ParcelResult<ParcelV2Parcel>> book(
    ParcelBookingDraft draft,
    String quoteId,
  ) async {
    final r = await _call(
      () => _api.post(
        _url(ApiConstants.parcels),
        data: draft.bookBody(quoteId),
      ),
    );
    final parcel = r.ok ? ParcelV2Parcel.fromResponseBody(r.value) : null;
    return ParcelResult(
      value: parcel,
      statusCode: r.statusCode,
      code: r.code ?? (r.ok && parcel == null ? 'BAD_RESPONSE' : null),
      message: r.message,
      body: r.body ?? r.value,
    );
  }

  Future<ParcelResult<ParcelV2Parcel>> show(int id) async {
    final r = await _call(
      () => _api.get(_url(_withId(ApiConstants.parcelDetail, id))),
    );
    return ParcelResult(
      value: r.ok ? ParcelV2Parcel.fromResponseBody(r.value) : null,
      statusCode: r.statusCode,
      code: r.code,
      message: r.message,
    );
  }

  Future<ParcelResult<ParcelCancellationPreview>> cancellationPreview(
    int id,
  ) async {
    final r = await _call(
      () => _api.get(_url(_withId(ApiConstants.parcelCancellation, id))),
    );
    return ParcelResult(
      value: r.ok
          ? ParcelCancellationPreview.fromJson(r.value?['data'])
          : null,
      statusCode: r.statusCode,
      code: r.code,
      message: r.message,
    );
  }

  /// [acceptFee] must be at least the fee shown; otherwise the server asks
  /// again (`PARCEL_CANCELLATION_FEE_CONFIRMATION_REQUIRED`).
  Future<ParcelResult<Map<String, dynamic>>> cancel(
    int id, {
    required String reason,
    double? acceptFee,
  }) {
    return _call(
      () => _api.post(
        _url(_withId(ApiConstants.parcelCancel, id)),
        data: {
          'reason': reason,
          if (acceptFee != null) 'accept_fee': acceptFee,
        },
      ),
    );
  }
}
