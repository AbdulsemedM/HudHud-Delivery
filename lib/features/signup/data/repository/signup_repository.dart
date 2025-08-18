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
  ) async {
    AuthService authService = AuthService();
    try {
      final response = await _dataProvider.signup(
        name,
        email,
        phone,
        password,
        confirmPassword,
      );
      if (response['statusCode'] == 200) {
        final user = UserModel.fromJson(response['data']);
        
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
      throw Exception(e);
    }
  }
}
