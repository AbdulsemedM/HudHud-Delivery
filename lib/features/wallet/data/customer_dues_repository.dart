import 'package:hudhud_delivery/core/api/api_constants.dart';
import 'package:hudhud_delivery/core/api/api_service.dart';
import 'package:hudhud_delivery/features/courier/parcel_v2/parcel_v2_models.dart';

/// `GET /api/customer/dues` — money the customer still owes HudHud (e.g. a
/// cash parcel's cancellation fee). Shares [ParcelDuesSummary] with the
/// parcel config's `outstanding_dues` block.
class CustomerDuesRepository {
  CustomerDuesRepository({Future<dynamic> Function()? fetch})
      : _fetch = fetch ?? _defaultFetch;

  final Future<dynamic> Function() _fetch;

  static Future<dynamic> _defaultFetch() async {
    final response = await ApiService.instance.get(
      '${ApiConstants.baseUrl}${ApiConstants.customerDues}',
    );
    return response.data;
  }

  /// Open dues, or null when unknown (guest, older backend, network error):
  /// callers then behave as before and the server still answers
  /// OUTSTANDING_DUES if a cash booking is refused.
  Future<ParcelDuesSummary?> fetchSummary() async {
    try {
      return parseSummary(await _fetch());
    } catch (_) {
      return null;
    }
  }

  /// `{success, data: {summary: {count, amounts: [{currency, amount}]}}}`.
  static ParcelDuesSummary? parseSummary(dynamic body) {
    if (body is! Map) return null;
    final data = body['data'];
    if (data is! Map) return null;
    final summary = data['summary'];
    if (summary == null) return const ParcelDuesSummary();
    return ParcelDuesSummary.fromJson(summary);
  }
}
