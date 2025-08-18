import 'package:hudhud_delivery/app/services/auth_service.dart';
import 'package:hudhud_delivery/features/login/data/data_provider/login_data_provider.dart';
import 'package:hudhud_delivery/models/user_model.dart';

class LoginRepository {
  final LoginDataProvider loginDataProvider;
  LoginRepository(this.loginDataProvider);

  Future<UserModel> login(String email, String password) async {
    AuthService authService = AuthService();
    try {
      final response = await loginDataProvider.login(email, password);
      if (response['statusCode'] == 200) {
        final user = UserModel.fromMap(response['data']['user']);

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
        throw Exception(response['message']);
      }
    } catch (e) {
      throw Exception(e.toString());
    }
  }
}
