import 'dart:io';

import 'package:device_info_plus/device_info_plus.dart';
import 'package:hudhud_delivery/core/api/api_constants.dart';

import '../../../../core/api/api_service.dart';

class SignupDataProvider {
  ApiService apiService;
  SignupDataProvider({required this.apiService});

  Future<String?> getDeviceId() async {
    DeviceInfoPlugin deviceInfo = DeviceInfoPlugin();

    if (Platform.isAndroid) {
      AndroidDeviceInfo androidInfo = await deviceInfo.androidInfo;
      return androidInfo.id; // Or use androidInfo.androidId (deprecated)
    } else if (Platform.isIOS) {
      IosDeviceInfo iosInfo = await deviceInfo.iosInfo;
      return iosInfo.identifierForVendor; // Unique ID on iOS
    } else {
      return null;
    }
  }

  Future<Map<String, dynamic>> signup(
    String name,
    String email,
    String phone,
    String password,
    String password_confirmation,
  ) async {
    try {
      final body = {
        'name': name,
        'email': email,
        'phone': phone,
        'password': password,
        'password_confirmation': password_confirmation,
        'device_token': await getDeviceId(),
        'type': 'customer',
      };
      final response = await apiService.post(
        '${ApiConstants.baseUrl}auth/register',
        data: body,
      );
      return {
        'statusCode': response.statusCode,
        'data': response.data,
        'errorMessage': null
      };
    } on ApiException catch (apiError) {
      return {
        'statusCode': apiError.statusCode,
        'data': apiError.data,
        'errorMessage': apiError.message,
      };
    } on Exception catch (e) {
      return {
        'statusCode': 500,
        'data': null,
        'errorMessage': 'Unexpected error: ${e.toString()}',
      };
    }
  }
}
