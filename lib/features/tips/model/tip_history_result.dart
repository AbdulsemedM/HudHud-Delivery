import 'tip_history_item_model.dart';

class TipHistoryStats {
  final int totalTipsGiven;
  final num totalAmountTipped;
  final num averageTip;

  const TipHistoryStats({
    this.totalTipsGiven = 0,
    this.totalAmountTipped = 0,
    this.averageTip = 0,
  });

  factory TipHistoryStats.fromJson(Map<String, dynamic>? json) {
    if (json == null) return const TipHistoryStats();
    return TipHistoryStats(
      totalTipsGiven: _parseInt(json['total_tips_given']) ?? 0,
      totalAmountTipped: _parseNum(json['total_amount_tipped']),
      averageTip: _parseNum(json['average_tip']),
    );
  }

  static int? _parseInt(dynamic v) {
    if (v == null) return null;
    if (v is int) return v;
    return int.tryParse(v.toString());
  }

  static num _parseNum(dynamic v) {
    if (v == null) return 0;
    if (v is num) return v;
    return num.tryParse(v.toString()) ?? 0;
  }
}

class TipHistoryResult {
  final List<TipHistoryItemModel> items;
  final int currentPage;
  final int lastPage;
  final int total;
  final TipHistoryStats stats;

  const TipHistoryResult({
    required this.items,
    this.currentPage = 1,
    this.lastPage = 1,
    this.total = 0,
    this.stats = const TipHistoryStats(),
  });

  bool get hasMore => currentPage < lastPage;

  factory TipHistoryResult.fromResponseData(dynamic root) {
    if (root is! Map) {
      return const TipHistoryResult(items: []);
    }
    final map = Map<String, dynamic>.from(root);
    final stats = TipHistoryStats.fromJson(
      map['stats'] is Map
          ? Map<String, dynamic>.from(map['stats'] as Map)
          : null,
    );

    final inner = map['data'];
    final pageMap = inner is Map ? Map<String, dynamic>.from(inner) : map;

    final listRaw = pageMap['data'];
    final items = <TipHistoryItemModel>[];
    if (listRaw is List) {
      for (final item in listRaw) {
        if (item is Map) {
          items.add(
            TipHistoryItemModel.fromJson(Map<String, dynamic>.from(item)),
          );
        }
      }
    }

    return TipHistoryResult(
      items: items,
      currentPage: _asInt(pageMap['current_page']) ?? 1,
      lastPage: _asInt(pageMap['last_page']) ?? 1,
      total: _asInt(pageMap['total']) ?? items.length,
      stats: stats,
    );
  }

  static int? _asInt(dynamic value) {
    if (value == null) return null;
    if (value is int) return value;
    return int.tryParse(value.toString());
  }
}
