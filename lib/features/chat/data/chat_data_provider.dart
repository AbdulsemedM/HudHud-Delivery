import 'dart:io';

import 'package:dio/dio.dart';
import 'package:hudhud_delivery/core/api/api_constants.dart';
import 'package:hudhud_delivery/core/api/api_service.dart';
import 'package:hudhud_delivery/features/chat/model/send_chat_message_request.dart';

class ChatDataProvider {
  final ApiService apiService;

  ChatDataProvider({required this.apiService});

  String _url(String path) => '${ApiConstants.baseUrl}$path';

  Future<Map<String, dynamic>> _wrap(Future<dynamic> Function() call) async {
    try {
      final response = await call();
      return {
        'statusCode': response.statusCode,
        'data': response.data,
        'errorMessage': null,
      };
    } on ApiException catch (e) {
      return {
        'statusCode': e.statusCode ?? 500,
        'data': e.data,
        'errorMessage': e.message,
      };
    } on Exception catch (e) {
      return {'statusCode': 500, 'data': null, 'errorMessage': e.toString()};
    }
  }

  bool _apiSuccess(Map<String, dynamic> response) {
    final code = response['statusCode'] as int?;
    if (code == null || code < 200 || code >= 300) return false;
    final data = response['data'];
    if (data is Map && data['success'] == false) return false;
    return true;
  }

  Future<Map<String, dynamic>> getConversations() {
    return _wrap(() => apiService.get(_url(ApiConstants.chatConversations)));
  }

  Future<Map<String, dynamic>> getConversation(int id) {
    return _wrap(
      () => apiService.get(
        _url(
          ApiConstants.replacePathParams(
            ApiConstants.chatConversationDetails,
            {'id': id},
          ),
        ),
      ),
    );
  }

  Future<Map<String, dynamic>> getUnreadCount() {
    return _wrap(() => apiService.get(_url(ApiConstants.chatUnreadCount)));
  }

  Future<Map<String, dynamic>> getOrderConversation(int orderId) {
    return _wrap(
      () => apiService.get(
        _url(
          ApiConstants.replacePathParams(
            ApiConstants.chatOrder,
            {'orderId': orderId},
          ),
        ),
      ),
    );
  }

  Future<Map<String, dynamic>> createOrderConversation(int orderId) {
    return _wrap(
      () => apiService.post(
        _url(
          ApiConstants.replacePathParams(
            ApiConstants.chatOrder,
            {'orderId': orderId},
          ),
        ),
      ),
    );
  }

  Future<Map<String, dynamic>> createRideConversation(int rideId) {
    return _wrap(
      () => apiService.post(
        _url(
          ApiConstants.replacePathParams(
            ApiConstants.chatRide,
            {'rideId': rideId},
          ),
        ),
      ),
    );
  }

  Future<Map<String, dynamic>> createSupportConversation({
    required String subject,
  }) {
    return _wrap(
      () => apiService.post(
        _url(ApiConstants.chatSupport),
        data: {'subject': subject},
      ),
    );
  }

  Future<Map<String, dynamic>> markConversationRead(int id) {
    return _wrap(
      () => apiService.post(
        _url(
          ApiConstants.replacePathParams(
            ApiConstants.chatConversationRead,
            {'id': id},
          ),
        ),
      ),
    );
  }

  Future<Map<String, dynamic>> sendMessage(
    int conversationId,
    SendChatMessageRequest request,
  ) {
    if (!request.hasAttachments) {
      return _wrap(
        () => apiService.post(
          _url(
            ApiConstants.replacePathParams(
              ApiConstants.chatConversationMessages,
              {'id': conversationId},
            ),
          ),
          data: request.toJsonBody(),
        ),
      );
    }

    return _wrap(() async {
      final formData = FormData();
      formData.fields.add(MapEntry('message', request.message));
      formData.fields.add(MapEntry('type', request.apiType));
      if (request.metadata != null) {
        for (final entry in request.metadata!.entries) {
          formData.fields.add(
            MapEntry('metadata[${entry.key}]', entry.value.toString()),
          );
        }
      }
      for (final file in request.attachmentFiles) {
        final path = file.path;
        formData.files.add(
          MapEntry(
            'attachments[]',
            await MultipartFile.fromFile(
              path,
              filename: path.split(Platform.pathSeparator).last,
            ),
          ),
        );
      }
      return apiService.post(
        _url(
          ApiConstants.replacePathParams(
            ApiConstants.chatConversationMessages,
            {'id': conversationId},
          ),
        ),
        data: formData,
        options: Options(contentType: 'multipart/form-data'),
      );
    });
  }

  Future<Map<String, dynamic>> editMessage(int messageId, String text) {
    return _wrap(
      () => apiService.put(
        _url(
          ApiConstants.replacePathParams(
            ApiConstants.chatMessage,
            {'id': messageId},
          ),
        ),
        data: {'message': text},
      ),
    );
  }

  Future<Map<String, dynamic>> deleteMessage(int messageId) {
    return _wrap(
      () => apiService.delete(
        _url(
          ApiConstants.replacePathParams(
            ApiConstants.chatMessage,
            {'id': messageId},
          ),
        ),
      ),
    );
  }

  Future<Map<String, dynamic>> getPackageDeliveryConversation(
    int deliveryId,
  ) {
    return _wrap(
      () => apiService.get(
        _url(
          ApiConstants.replacePathParams(
            ApiConstants.packageDeliveryConversation,
            {'deliveryId': deliveryId},
          ),
        ),
      ),
    );
  }

  Future<Map<String, dynamic>> markPackageDeliveryRead(int deliveryId) {
    return _wrap(
      () => apiService.post(
        _url(
          ApiConstants.replacePathParams(
            ApiConstants.packageDeliveryRead,
            {'deliveryId': deliveryId},
          ),
        ),
      ),
    );
  }

  Future<Map<String, dynamic>> sendPackageDeliveryMessage(
    int deliveryId,
    SendChatMessageRequest request,
  ) {
    return _wrap(
      () => apiService.post(
        _url(
          ApiConstants.replacePathParams(
            ApiConstants.packageDeliveryMessage,
            {'deliveryId': deliveryId},
          ),
        ),
        data: request.toJsonBody(),
      ),
    );
  }

  bool isSuccess(Map<String, dynamic> response) => _apiSuccess(response);
}
