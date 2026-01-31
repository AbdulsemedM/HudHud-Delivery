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
    // API returns: data[], total, current_page, total_pages, per_page (flat)
    final cp = (json['current_page'] ?? 1) is int ? (json['current_page'] ?? 1) as int : int.tryParse((json['current_page'] ?? 1).toString()) ?? 1;
    final pp = (json['per_page'] ?? 10) is int ? (json['per_page'] ?? 10) as int : int.tryParse((json['per_page'] ?? 10).toString()) ?? 10;
    final tot = (json['total'] ?? 0) is int ? (json['total'] ?? 0) as int : int.tryParse((json['total'] ?? 0).toString()) ?? 0;
    final paginationJson = json['pagination'] as Map<String, dynamic>? ??
        {
          'current_page': cp,
          'total_pages': json['total_pages'] ?? cp,
          'last_page': json['total_pages'] ?? cp,
          'per_page': pp,
          'total': tot,
          'from': ((cp - 1) * pp + 1).clamp(1, tot),
          'to': (cp * pp).clamp(0, tot),
        };
    return OrdersResponseModel(
      success: true,
      message: json['message'] ?? '',
      data: (json['data'] as List<dynamic>? ?? [])
          .map((orderJson) => OrderModel.fromJson(orderJson as Map<String, dynamic>))
          .toList(),
      pagination: PaginationModel.fromJson(paginationJson),
    );
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
    final from = json['from'] ?? ((currentPage - 1) * perPage + 1).clamp(1, total);
    final to = json['to'] ?? (currentPage * perPage).clamp(0, total);
    return PaginationModel(
      currentPage: currentPage,
      lastPage: lastPage,
      perPage: perPage,
      total: total,
      from: from is int ? from : int.tryParse(from.toString()) ?? 0,
      to: to is int ? to : int.tryParse(to.toString()) ?? 0,
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