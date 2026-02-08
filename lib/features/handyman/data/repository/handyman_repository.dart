import '../data_provider/handyman_data_provider.dart';
import '../models/handyman_model.dart';
import '../models/service_quote_model.dart';
import '../models/service_request_model.dart';

class HandymanRepository {
  final HandymanDataProvider dataProvider;

  HandymanRepository({required this.dataProvider});

  static String _cleanErrorMessage(String message) {
    if (message.startsWith('ApiException: ')) {
      return message.substring(14);
    }
    return message;
  }

  /// Create a new service request
  Future<Map<String, dynamic>> createServiceRequest(
    Map<String, dynamic> body,
  ) async {
    try {
      final response = await dataProvider.createServiceRequest(body);

      if (response['statusCode'] == 200 || response['statusCode'] == 201) {
        final data = response['data'] as Map<String, dynamic>?;
        final serviceRequestRaw = data?['service_request'];
        ServiceRequestModel? serviceRequest;
        if (serviceRequestRaw is Map<String, dynamic>) {
          serviceRequest = ServiceRequestModel.fromJson(serviceRequestRaw);
        }

        return {
          'success': true,
          'serviceRequest': serviceRequest,
          'data': serviceRequestRaw,
          'message': data?['message'] as String? ?? 'Service request created successfully',
        };
      } else {
        final errorMessage = _cleanErrorMessage(
          response['errorMessage'] as String? ?? 'Error creating service request',
        );
        return {
          'success': false,
          'serviceRequest': null,
          'data': null,
          'message': errorMessage,
        };
      }
    } catch (e) {
      final errorMessage = _cleanErrorMessage(e.toString());
      return {
        'success': false,
        'serviceRequest': null,
        'data': null,
        'message': errorMessage,
      };
    }
  }

  /// Get list of service requests (paginated)
  Future<Map<String, dynamic>> getServiceRequests({int page = 1}) async {
    try {
      final response = await dataProvider.getServiceRequests(page: page);

      if (response['statusCode'] == 200) {
        final rawData = response['data'] as Map<String, dynamic>?;
        final list = rawData?['data'] as List<dynamic>? ?? [];
        final requests = list
            .whereType<Map<String, dynamic>>()
            .map((e) => ServiceRequestModel.fromJson(e))
            .toList();

        return {
          'success': true,
          'requests': requests,
          'currentPage': rawData?['current_page'] as int? ?? 1,
          'lastPage': rawData?['last_page'] as int? ?? 1,
          'total': rawData?['total'] as int? ?? 0,
          'message': null,
        };
      } else {
        final errorMessage = _cleanErrorMessage(
          response['errorMessage'] as String? ?? 'Error fetching service requests',
        );
        return {
          'success': false,
          'requests': <ServiceRequestModel>[],
          'currentPage': 1,
          'lastPage': 1,
          'total': 0,
          'message': errorMessage,
        };
      }
    } catch (e) {
      final errorMessage = _cleanErrorMessage(e.toString());
      return {
        'success': false,
        'requests': <ServiceRequestModel>[],
        'currentPage': 1,
        'lastPage': 1,
        'total': 0,
        'message': errorMessage,
      };
    }
  }

  /// Update a service request
  Future<Map<String, dynamic>> updateServiceRequest(
    int id,
    Map<String, dynamic> body,
  ) async {
    try {
      final response = await dataProvider.updateServiceRequest(id, body);

      if (response['statusCode'] == 200 || response['statusCode'] == 201) {
        final data = response['data'] as Map<String, dynamic>?;
        final serviceRequestRaw = data?['service_request'] ?? data;
        ServiceRequestModel? serviceRequest;
        if (serviceRequestRaw is Map<String, dynamic>) {
          serviceRequest = ServiceRequestModel.fromJson(serviceRequestRaw);
        }

        return {
          'success': true,
          'serviceRequest': serviceRequest,
          'message': data?['message'] as String? ?? 'Service request updated',
        };
      } else {
        final errorMessage = _cleanErrorMessage(
          response['errorMessage'] as String? ?? 'Error updating service request',
        );
        return {
          'success': false,
          'serviceRequest': null,
          'message': errorMessage,
        };
      }
    } catch (e) {
      final errorMessage = _cleanErrorMessage(e.toString());
      return {
        'success': false,
        'serviceRequest': null,
        'message': errorMessage,
      };
    }
  }

  /// Get quotes for a service request
  Future<Map<String, dynamic>> getServiceQuotes(
    int requestId, {
    int page = 1,
  }) async {
    try {
      final response = await dataProvider.getServiceQuotes(
        requestId,
        page: page,
      );

      if (response['statusCode'] == 200) {
        final rawData = response['data'] as Map<String, dynamic>?;
        final quotesRaw = rawData?['quotes'];
        List<ServiceQuoteModel> quotes = [];
        ServiceRequestModel? serviceRequest;

        if (quotesRaw is Map<String, dynamic>) {
          final dataList = quotesRaw['data'] as List<dynamic>? ?? [];
          quotes = dataList
              .whereType<Map<String, dynamic>>()
              .map((e) => ServiceQuoteModel.fromJson(e))
              .toList();
        }

        final serviceRequestRaw = rawData?['service_request'];
        if (serviceRequestRaw is Map<String, dynamic>) {
          serviceRequest = ServiceRequestModel.fromJson(serviceRequestRaw);
        }

        return {
          'success': true,
          'quotes': quotes,
          'serviceRequest': serviceRequest,
          'currentPage': quotesRaw is Map ? (quotesRaw['current_page'] as int?) ?? 1 : 1,
          'lastPage': quotesRaw is Map ? (quotesRaw['last_page'] as int?) ?? 1 : 1,
          'total': quotesRaw is Map ? (quotesRaw['total'] as int?) ?? 0 : 0,
          'message': null,
        };
      } else {
        final errorMessage = _cleanErrorMessage(
          response['errorMessage'] as String? ?? 'Error fetching quotes',
        );
        return {
          'success': false,
          'quotes': <ServiceQuoteModel>[],
          'serviceRequest': null,
          'message': errorMessage,
        };
      }
    } catch (e) {
      final errorMessage = _cleanErrorMessage(e.toString());
      return {
        'success': false,
        'quotes': <ServiceQuoteModel>[],
        'serviceRequest': null,
        'message': errorMessage,
      };
    }
  }

  /// Accept a quote
  Future<Map<String, dynamic>> acceptQuote(
    int requestId,
    int quoteId,
  ) async {
    try {
      final response = await dataProvider.acceptQuote(requestId, quoteId);

      if (response['statusCode'] == 200 || response['statusCode'] == 201) {
        final data = response['data'] as Map<String, dynamic>?;
        return {
          'success': true,
          'message': data?['message'] as String? ?? 'Quote accepted',
        };
      } else {
        final errorMessage = _cleanErrorMessage(
          response['errorMessage'] as String? ?? 'Error accepting quote',
        );
        return {'success': false, 'message': errorMessage};
      }
    } catch (e) {
      final errorMessage = _cleanErrorMessage(e.toString());
      return {'success': false, 'message': errorMessage};
    }
  }

  /// Reject a quote
  Future<Map<String, dynamic>> rejectQuote(
    int requestId,
    int quoteId,
  ) async {
    try {
      final response = await dataProvider.rejectQuote(requestId, quoteId);

      if (response['statusCode'] == 200 || response['statusCode'] == 201) {
        final data = response['data'] as Map<String, dynamic>?;
        return {
          'success': true,
          'message': data?['message'] as String? ?? 'Quote rejected',
        };
      } else {
        final errorMessage = _cleanErrorMessage(
          response['errorMessage'] as String? ?? 'Error rejecting quote',
        );
        return {'success': false, 'message': errorMessage};
      }
    } catch (e) {
      final errorMessage = _cleanErrorMessage(e.toString());
      return {'success': false, 'message': errorMessage};
    }
  }

  /// Cancel a service request
  Future<Map<String, dynamic>> cancelServiceRequest(int requestId) async {
    try {
      final response = await dataProvider.cancelServiceRequest(requestId);

      if (response['statusCode'] == 200 || response['statusCode'] == 201) {
        final data = response['data'] as Map<String, dynamic>?;
        return {
          'success': true,
          'message': data?['message'] as String? ?? 'Request cancelled',
        };
      } else {
        final errorMessage = _cleanErrorMessage(
          response['errorMessage'] as String? ?? 'Error cancelling request',
        );
        return {'success': false, 'message': errorMessage};
      }
    } catch (e) {
      final errorMessage = _cleanErrorMessage(e.toString());
      return {'success': false, 'message': errorMessage};
    }
  }

  /// Get handyman details
  Future<Map<String, dynamic>> getHandymanDetails(int handymanId) async {
    try {
      final response = await dataProvider.getHandymanDetails(handymanId);

      if (response['statusCode'] == 200) {
        final data = response['data'] as Map<String, dynamic>?;
        final handymanRaw = data?['handyman'];
        HandymanModel? handyman;
        if (handymanRaw is Map<String, dynamic>) {
          handyman = HandymanModel.fromJson(handymanRaw);
        }

        return {
          'success': true,
          'handyman': handyman,
          'stats': data?['stats'],
          'message': null,
        };
      } else {
        final errorMessage = _cleanErrorMessage(
          response['errorMessage'] as String? ?? 'Error fetching handyman',
        );
        return {
          'success': false,
          'handyman': null,
          'stats': null,
          'message': errorMessage,
        };
      }
    } catch (e) {
      final errorMessage = _cleanErrorMessage(e.toString());
      return {
        'success': false,
        'handyman': null,
        'stats': null,
        'message': errorMessage,
      };
    }
  }

  /// Rate a completed service
  Future<Map<String, dynamic>> rateServiceRequest(
    int requestId, {
    required int rating,
    String? comment,
    int? providerRating,
    String? providerComment,
    bool isPublic = true,
  }) async {
    try {
      final response = await dataProvider.rateServiceRequest(
        requestId,
        rating: rating,
        comment: comment,
        providerRating: providerRating,
        providerComment: providerComment,
        isPublic: isPublic,
      );

      if (response['statusCode'] == 200 || response['statusCode'] == 201) {
        final data = response['data'] as Map<String, dynamic>?;
        return {
          'success': true,
          'message': data?['message'] as String? ?? 'Service rated successfully',
        };
      } else {
        final errorMessage = _cleanErrorMessage(
          response['errorMessage'] as String? ?? 'Error rating service',
        );
        return {'success': false, 'message': errorMessage};
      }
    } catch (e) {
      final errorMessage = _cleanErrorMessage(e.toString());
      return {'success': false, 'message': errorMessage};
    }
  }
}
