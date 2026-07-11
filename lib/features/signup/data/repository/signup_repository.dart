import 'package:hudhud_delivery/app/services/auth_service.dart';

import '../../../../models/user_model.dart';
import '../data_provider/signup_data_provider.dart';

class SignupRepository {
  final SignupDataProvider _dataProvider;

  SignupRepository(this._dataProvider);

  Future<UserModel> signup(
    String name,
    String email,
    String phone,
    String password,
    String confirmPassword,
    {String? referralCode}
  ) async {
    AuthService authService = AuthService();
    try {
      final response = await _dataProvider.signup(
        name,
        email,
        phone,
        password,
        confirmPassword,
        referralCode: referralCode,
      );
      if (response['statusCode'] == 201) {
        // Extract user data from nested 'user' object
        final user = UserModel.fromMap(response['data']['user']);
        
        // Store token and user data using AuthService
        // Extract token from root level of response data
        if (response['data']['token'] != null) {
          await authService.storeUserSession(
            user: user,
            token: response['data']['token'],
            refreshToken: response['data']['refresh_token'],
            expiresIn: response['data']['expires_in'],
          );
        }
        
        return user;
      } else {
        // Get clean error message from data provider
        String errorMessage = response['errorMessage'] ?? 'Signup failed';
        // Clean any prefixes that might exist
        errorMessage = _cleanErrorMessage(errorMessage);
        throw errorMessage; // Throw string directly instead of Exception
      }
    } catch (e) {
      if (e is String) {
        throw e; // Re-throw clean string errors
      }
      // Clean any exception messages
      String errorMessage = _cleanErrorMessage(e.toString());
      throw errorMessage;
    }
  }
  
  String _cleanErrorMessage(String message) {
    // Remove various prefixes that might appear
    if (message.startsWith('Exception: ')) {
      message = message.substring(11);
    }
    if (message.startsWith('ApiException: ')) {
      message = message.substring(14);
    }
    if (message.startsWith('FormatException: ')) {
      message = message.substring(17);
    }
    return message;
  }
}
