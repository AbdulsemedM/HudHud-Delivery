import 'package:hudhud_delivery/core/api/api_constants.dart';
import 'package:hudhud_delivery/core/api/api_service.dart';

class HandymanDataProvider {
  final ApiService apiService;

  HandymanDataProvider({required this.apiService});

  /// POST /api/customer/services/requests
  /// Create a new service request
  Future<Map<String, dynamic>> createServiceRequest(
    Map<String, dynamic> body,
  ) async {
    try {
      final response = await apiService.post(
        '${ApiConstants.baseUrl}${ApiConstants.customerServiceRequests}',
        data: body,
      );

      return {
        'statusCode': response.statusCode,
        'data': response.data,
        'errorMessage': null,
      };
    } on ApiException catch (apiException) {
      return {
        'statusCode': apiException.statusCode,
        'data': null,
        'errorMessage': apiException.message,
      };
    } on Exception catch (e) {
      return {'statusCode': 500, 'data': null, 'errorMessage': e.toString()};
    }
  }

  /// GET /api/customer/services/requests
  /// List service requests (paginated)
  Future<Map<String, dynamic>> getServiceRequests({int page = 1}) async {
    try {
      final response = await apiService.get(
        '${ApiConstants.baseUrl}${ApiConstants.customerServiceRequests}',
        queryParameters: {'page': page},
      );

      return {
        'statusCode': response.statusCode,
        'data': response.data,
        'errorMessage': null,
      };
    } on ApiException catch (apiException) {
      return {
        'statusCode': apiException.statusCode,
        'data': null,
        'errorMessage': apiException.message,
      };
    } on Exception catch (e) {
      return {'statusCode': 500, 'data': null, 'errorMessage': e.toString()};
    }
  }

  /// PUT /api/customer/services/requests/{id}
  /// Update a service request
  Future<Map<String, dynamic>> updateServiceRequest(
    int id,
    Map<String, dynamic> body,
  ) async {
    try {
      final url =
          '${ApiConstants.baseUrl}${ApiConstants.customerServiceRequests}/$id';
      final response = await apiService.put(url, data: body);

      return {
        'statusCode': response.statusCode,
        'data': response.data,
        'errorMessage': null,
      };
    } on ApiException catch (apiException) {
      return {
        'statusCode': apiException.statusCode,
        'data': null,
        'errorMessage': apiException.message,
      };
    } on Exception catch (e) {
      return {'statusCode': 500, 'data': null, 'errorMessage': e.toString()};
    }
  }

  /// GET /api/customer/services/requests/{id}/quotes
  /// Get quotes for a service request
  Future<Map<String, dynamic>> getServiceQuotes(
    int requestId, {
    int page = 1,
  }) async {
    try {
      final url = ApiConstants.baseUrl +
          ApiConstants.customerServiceRequestQuotes
              .replaceAll('{id}', requestId.toString());
      final response = await apiService.get(
        url,
        queryParameters: {'page': page},
      );

      return {
        'statusCode': response.statusCode,
        'data': response.data,
        'errorMessage': null,
      };
    } on ApiException catch (apiException) {
      return {
        'statusCode': apiException.statusCode,
        'data': null,
        'errorMessage': apiException.message,
      };
    } on Exception catch (e) {
      return {'statusCode': 500, 'data': null, 'errorMessage': e.toString()};
    }
  }

  /// POST /api/customer/services/requests/{id}/quotes/{quoteId}/accept
  /// Accept a quote
  Future<Map<String, dynamic>> acceptQuote(
    int requestId,
    int quoteId,
  ) async {
    try {
      final url = ApiConstants.baseUrl +
          ApiConstants.customerServiceRequestQuoteAccept
              .replaceAll('{id}', requestId.toString())
              .replaceAll('{quoteId}', quoteId.toString());
      final response = await apiService.post(url);

      return {
        'statusCode': response.statusCode,
        'data': response.data,
        'errorMessage': null,
      };
    } on ApiException catch (apiException) {
      return {
        'statusCode': apiException.statusCode,
        'data': null,
        'errorMessage': apiException.message,
      };
    } on Exception catch (e) {
      return {'statusCode': 500, 'data': null, 'errorMessage': e.toString()};
    }
  }

  /// POST /api/customer/services/requests/{id}/quotes/{quoteId}/reject
  /// Reject a quote
  Future<Map<String, dynamic>> rejectQuote(
    int requestId,
    int quoteId,
  ) async {
    try {
      final url = ApiConstants.baseUrl +
          ApiConstants.customerServiceRequestQuoteReject
              .replaceAll('{id}', requestId.toString())
              .replaceAll('{quoteId}', quoteId.toString());
      final response = await apiService.post(url);

      return {
        'statusCode': response.statusCode,
        'data': response.data,
        'errorMessage': null,
      };
    } on ApiException catch (apiException) {
      return {
        'statusCode': apiException.statusCode,
        'data': null,
        'errorMessage': apiException.message,
      };
    } on Exception catch (e) {
      return {'statusCode': 500, 'data': null, 'errorMessage': e.toString()};
    }
  }

  /// POST /api/customer/services/requests/{id}/cancel
  /// Cancel a service request
  Future<Map<String, dynamic>> cancelServiceRequest(int requestId) async {
    try {
      final url = ApiConstants.baseUrl +
          ApiConstants.customerServiceRequestCancel
              .replaceAll('{id}', requestId.toString());
      final response = await apiService.post(url);

      return {
        'statusCode': response.statusCode,
        'data': response.data,
        'errorMessage': null,
      };
    } on ApiException catch (apiException) {
      return {
        'statusCode': apiException.statusCode,
        'data': null,
        'errorMessage': apiException.message,
      };
    } on Exception catch (e) {
      return {'statusCode': 500, 'data': null, 'errorMessage': e.toString()};
    }
  }

  /// GET /api/customer/services/handymen/{id}
  /// Get handyman details
  Future<Map<String, dynamic>> getHandymanDetails(int handymanId) async {
    try {
      final url = ApiConstants.baseUrl +
          ApiConstants.customerHandymen.replaceAll('{id}', handymanId.toString());
      final response = await apiService.get(url);

      return {
        'statusCode': response.statusCode,
        'data': response.data,
        'errorMessage': null,
      };
    } on ApiException catch (apiException) {
      return {
        'statusCode': apiException.statusCode,
        'data': null,
        'errorMessage': apiException.message,
      };
    } on Exception catch (e) {
      return {'statusCode': 500, 'data': null, 'errorMessage': e.toString()};
    }
  }

  /// POST /api/customer/service-requests/{id}/rate
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
      final url = ApiConstants.baseUrl +
          ApiConstants.customerServiceRequestRate
              .replaceAll('{id}', requestId.toString());

      final body = <String, dynamic>{
        'rating': rating,
        'is_public': isPublic,
      };
      if (comment != null && comment.isNotEmpty) body['comment'] = comment;
      if (providerRating != null) body['provider_rating'] = providerRating;
      if (providerComment != null && providerComment.isNotEmpty) {
        body['provider_comment'] = providerComment;
      }

      final response = await apiService.post(url, data: body);

      return {
        'statusCode': response.statusCode,
        'data': response.data,
        'errorMessage': null,
      };
    } on ApiException catch (apiException) {
      return {
        'statusCode': apiException.statusCode,
        'data': null,
        'errorMessage': apiException.message,
      };
    } on Exception catch (e) {
      return {'statusCode': 500, 'data': null, 'errorMessage': e.toString()};
    }
  }
}
