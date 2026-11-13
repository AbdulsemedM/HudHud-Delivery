import 'package:flutter/foundation.dart';
import 'package:hudhud_delivery/core/api/api_constants.dart';
import 'package:hudhud_delivery/core/api/api_service.dart';

import 'cancellation_models.dart';

/// Outcome of a cancellation-preview call.
class CancellationPreviewResult {
  final CancellationPreview? preview;

  /// The backend has no preview endpoint yet (404/405) — use the old flow.
  final bool unsupported;
  final String? errorMessage;

  const CancellationPreviewResult({
    this.preview,
    this.unsupported = false,
    this.errorMessage,
  });
}

/// Outcome of paying a fine.
class CancellationFinePayResult {
  final bool ok;
  final String? message;
  final ApiErrorResult? error;

  const CancellationFinePayResult({required this.ok, this.message, this.error});
}

/// `/api/customer/cancellation-*` + per-entity previews.
class CancellationRepository {
  CancellationRepository({ApiService? api}) : _api = api ?? ApiService.instance;

  final ApiService _api;

  String _url(String path, [int? id]) =>
      '${ApiConstants.baseUrl}${id == null ? path : path.replaceFirst('{id}', '$id')}';

  /// Null when unknown (guest, older backend, network) — callers then keep
  /// the old behaviour.
  Future<CancellationStanding?> fetchStanding() async {
    try {
      final r = await _api.get(_url(ApiConstants.customerCancellationStanding));
      return CancellationStanding.fromResponseBody(r.data);
    } on ApiException catch (e) {
      if (e.statusCode == 404 || e.statusCode == 405) {
        return CancellationStanding.disabled;
      }
      return null;
    } catch (e) {
      debugPrint('cancellation standing failed: $e');
      return null;
    }
  }

  Future<CancellationPreviewResult> previewDelivery(int deliveryId) =>
      _preview(_url(ApiConstants.deliveryCancellationPreview, deliveryId));

  Future<CancellationPreviewResult> previewOrder(int orderId) =>
      _preview(_url(ApiConstants.customerOrderCancellationPreview, orderId));

  Future<CancellationPreviewResult> _preview(String url) async {
    try {
      final r = await _api.get(url);
      final preview = CancellationPreview.fromResponseBody(r.data);
      if (preview == null) {
        return const CancellationPreviewResult(unsupported: true);
      }
      return CancellationPreviewResult(preview: preview);
    } on ApiException catch (e) {
      if (e.statusCode == 404 || e.statusCode == 405) {
        // A 404 with a real preview body (e.g. order gone) is still a 404
        // for us: fall back to the old flow, which reports its own error.
        return const CancellationPreviewResult(unsupported: true);
      }
      final parsed = parseApiErrorResult(e.data, statusCode: e.statusCode);
      return CancellationPreviewResult(errorMessage: parsed.displayMessage);
    } catch (e) {
      return CancellationPreviewResult(errorMessage: e.toString());
    }
  }

  /// Pays a fine from the wallet. `insufficient_balance` comes back in
  /// [CancellationFinePayResult.error] so the caller can offer a top-up.
  Future<CancellationFinePayResult> payFine(int fineId) async {
    try {
      final r = await _api.post(
        _url(ApiConstants.customerCancellationFinePay, fineId),
        data: {'payment_method': 'wallet'},
      );
      final body = r.data;
      final message =
          body is Map ? body['message']?.toString().trim() : null;
      return CancellationFinePayResult(ok: true, message: message);
    } on ApiException catch (e) {
      return CancellationFinePayResult(
        ok: false,
        error: parseApiErrorResult(
          e.data,
          statusCode: e.statusCode,
          fallback: e.message,
        ),
      );
    } catch (e) {
      return CancellationFinePayResult(ok: false, message: e.toString());
    }
  }
}
