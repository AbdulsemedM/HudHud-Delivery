import 'package:hudhud_delivery/app/services/auth_service.dart';
import 'package:hudhud_delivery/features/login/data/data_provider/login_data_provider.dart';
import 'package:hudhud_delivery/models/user_model.dart';

class LoginRepository {
  final LoginDataProvider loginDataProvider;
  LoginRepository(this.loginDataProvider);

  Future<UserModel> login(String emailOrPhone, String password, String fieldType) async {
    AuthService authService = AuthService();
    try {
      final response = await loginDataProvider.login(emailOrPhone, password, fieldType);
      if (response['statusCode'] == 200) {
        // Extract user object and include permissions from root level if available
        final userData = Map<String, dynamic>.from(response['data']['user'] as Map<String, dynamic>);
        if (response['data']['permissions'] != null) {
          userData['permissions'] = response['data']['permissions'];
        }
        final user = UserModel.fromMap(userData);

        // Store token and user data using AuthService
        // Extract token from response if available
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
        String errorMessage = response['errorMessage'] ?? 'Login failed';
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
