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
        final data = response['data'] as Map<String, dynamic>?;
        if (data == null || data['token'] == null || data['user'] == null) {
          throw 'Invalid server response: missing required data';
        }

        final token = data['token'] as String;
        final permissions = data['permissions'] as List<dynamic>?;
        final loginUser = UserModel.fromMap(
          Map<String, dynamic>.from(data['user'] as Map<String, dynamic>)
            ..['permissions'] = permissions ?? [],
        );

        // Store token first so profile API can be called with it
        await authService.storeTokenOnly(
          token: token,
          refreshToken: data['refresh_token']?.toString(),
          expiresIn: data['expires_in'] is int ? data['expires_in'] as int : null,
        );

        // Fetch full profile from /api/profile and store (with permissions from login)
        try {
          final profileUser = await authService.fetchProfileAndStore(
            permissions: permissions,
          );
          return profileUser ?? loginUser;
        } catch (_) {
          // Profile fetch failed (network, 500, etc.); fall back to login user
          await authService.storeUserSession(
            user: loginUser,
            token: token,
            refreshToken: data['refresh_token']?.toString(),
            expiresIn: data['expires_in'] is int ? data['expires_in'] as int : null,
          );
          return loginUser;
        }
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
