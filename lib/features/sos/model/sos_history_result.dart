import 'package:hudhud_delivery/features/sos/model/sos_alert_model.dart';

class SosHistoryResult {
  final List<SosAlertModel> items;
  final int currentPage;
  final int lastPage;
  final int total;

  const SosHistoryResult({
    required this.items,
    this.currentPage = 1,
    this.lastPage = 1,
    this.total = 0,
  });

  bool get hasMore => currentPage < lastPage;

  factory SosHistoryResult.fromResponseData(dynamic root) {
    if (root is! Map) {
      return const SosHistoryResult(items: []);
    }
    final map = Map<String, dynamic>.from(root);
    final inner = map['data'];
    final pageMap = inner is Map ? Map<String, dynamic>.from(inner) : map;

    final listRaw = pageMap['data'];
    final items = <SosAlertModel>[];
    if (listRaw is List) {
      for (final item in listRaw) {
        if (item is Map<String, dynamic>) {
          items.add(SosAlertModel.fromJson(item));
        } else if (item is Map) {
          items.add(SosAlertModel.fromJson(Map<String, dynamic>.from(item)));
        }
      }
    }

    return SosHistoryResult(
      items: items,
      currentPage: _asInt(pageMap['current_page']) ?? 1,
      lastPage: _asInt(pageMap['last_page']) ?? 1,
      total: _asInt(pageMap['total']) ?? items.length,
    );
  }

  static int? _asInt(dynamic value) {
    if (value == null) return null;
    if (value is int) return value;
    return int.tryParse(value.toString());
  }
}
