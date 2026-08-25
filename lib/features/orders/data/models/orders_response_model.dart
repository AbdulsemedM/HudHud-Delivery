import 'package:equatable/equatable.dart';
import 'order_model.dart';

class OrdersResponseModel extends Equatable {
  final bool success;
  final String message;
  final List<OrderModel> data;
  final PaginationModel pagination;

  const OrdersResponseModel({
    required this.success,
    required this.message,
    required this.data,
    required this.pagination,
  });

  factory OrdersResponseModel.fromJson(Map<String, dynamic> json) {
    // API: { success, data: { data: [], total, current_page, ... } } or flat page object
    final payload = _unwrapOrdersPayload(json);
    final cp = _parseInt(payload['current_page'], fallback: 1);
    final pp = _parseInt(payload['per_page'], fallback: 10);
    final tot = _parseInt(payload['total'], fallback: 0);
    final paginationJson = payload['pagination'] as Map<String, dynamic>? ??
        {
          'current_page': cp,
          'total_pages': payload['total_pages'] ?? cp,
          'last_page': payload['total_pages'] ?? cp,
          'per_page': pp,
          'total': tot,
          'from': payload['from'],
          'to': payload['to'],
        };
    return OrdersResponseModel(
      success: payload['success'] == true || json['success'] == true,
      message: (payload['message'] ?? json['message'] ?? '').toString(),
      data: _parseOrdersList(payload['data']),
      pagination: PaginationModel.fromJson(paginationJson),
    );
  }

  static Map<String, dynamic> _unwrapOrdersPayload(Map<String, dynamic> json) {
    final inner = json['data'];
    if (inner is Map<String, dynamic> &&
        (inner['data'] is List || inner.containsKey('total'))) {
      return inner;
    }
    return json;
  }

  static List<OrderModel> _parseOrdersList(dynamic raw) {
    if (raw is! List) return [];
    return raw
        .map((orderJson) =>
            OrderModel.fromJson(orderJson as Map<String, dynamic>))
        .toList();
  }

  static int _parseInt(dynamic value, {required int fallback}) {
    if (value is int) return value;
    return int.tryParse(value?.toString() ?? '') ?? fallback;
  }

  Map<String, dynamic> toJson() {
    return {
      'success': success,
      'message': message,
      'data': data.map((order) => order.toJson()).toList(),
      'pagination': pagination.toJson(),
    };
  }

  @override
  List<Object?> get props => [success, message, data, pagination];
}

class PaginationModel extends Equatable {
  final int currentPage;
  final int lastPage;
  final int perPage;
  final int total;
  final int from;
  final int to;
  final String? nextPageUrl;
  final String? prevPageUrl;

  const PaginationModel({
    required this.currentPage,
    required this.lastPage,
    required this.perPage,
    required this.total,
    required this.from,
    required this.to,
    this.nextPageUrl,
    this.prevPageUrl,
  });

  factory PaginationModel.fromJson(Map<String, dynamic> json) {
    final currentPage = (json['current_page'] ?? 1) is int
        ? (json['current_page'] ?? 1) as int
        : int.tryParse((json['current_page'] ?? 1).toString()) ?? 1;
    final perPage = (json['per_page'] ?? 10) is int
        ? (json['per_page'] ?? 10) as int
        : int.tryParse((json['per_page'] ?? 10).toString()) ?? 10;
    final total = (json['total'] ?? 0) is int
        ? (json['total'] ?? 0) as int
        : int.tryParse((json['total'] ?? 0).toString()) ?? 0;
    final lastPage = (json['last_page'] ?? json['total_pages'] ?? 1) is int
        ? (json['last_page'] ?? json['total_pages'] ?? 1) as int
        : int.tryParse((json['last_page'] ?? json['total_pages'] ?? 1).toString()) ?? 1;
    final from = _parseBound(json['from'], currentPage, perPage, total, isFrom: true);
    final to = _parseBound(json['to'], currentPage, perPage, total, isFrom: false);
    return PaginationModel(
      currentPage: currentPage,
      lastPage: lastPage,
      perPage: perPage,
      total: total,
      from: from,
      to: to,
      nextPageUrl: json['next_page_url']?.toString(),
      prevPageUrl: json['prev_page_url']?.toString(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'current_page': currentPage,
      'last_page': lastPage,
      'per_page': perPage,
      'total': total,
      'from': from,
      'to': to,
      'next_page_url': nextPageUrl,
      'prev_page_url': prevPageUrl,
    };
  }

  bool get hasNextPage => nextPageUrl != null;
  bool get hasPrevPage => prevPageUrl != null;

  static int _parseBound(
    dynamic value,
    int currentPage,
    int perPage,
    int total, {
    required bool isFrom,
  }) {
    if (value != null) {
      return value is int ? value : int.tryParse(value.toString()) ?? 0;
    }
    if (total <= 0) return 0;
    if (isFrom) {
      return ((currentPage - 1) * perPage + 1).clamp(1, total);
    }
    return (currentPage * perPage).clamp(0, total);
  }

  @override
  List<Object?> get props => [
        currentPage,
        lastPage,
        perPage,
        total,
        from,
        to,
        nextPageUrl,
        prevPageUrl,
      ];
}