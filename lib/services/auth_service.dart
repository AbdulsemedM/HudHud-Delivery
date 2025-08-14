import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../core/api/api_service.dart';
import '../core/api/api_constants.dart';
import '../models/user_model.dart';

class AuthService {
  static const _storage = FlutterSecureStorage(
    aOptions: AndroidOptions(
      encryptedSharedPreferences: true,
    ),
    iOptions: IOSOptions(
      accessibility: KeychainAccessibility.first_unlock_this_device,
    ),
  );
  
  static const String _tokenKey = 'auth_token';
  static const String _refreshTokenKey = 'refresh_token';
  static const String _userKey = 'user_data';
  
  final ApiService _apiService = ApiService.instance;
  
  // Login with email and password
  Future<Map<String, dynamic>> login(String email, String password) async {
    try {
      final response = await _apiService.post(
        ApiConstants.login,
        data: {
          'email': email,
          'password': password,
        },
      );
      
      if (response.statusCode == 200 && response.data != null) {
        final data = response.data as Map<String, dynamic>;
        
        // Store tokens
        if (data['token'] != null) {
          await _storeToken(data['token']);
        }
        if (data['refresh_token'] != null) {
          await _storeRefreshToken(data['refresh_token']);
        }
        
        // Store user data
        if (data['user'] != null) {
          final user = UserModel.fromJson(data['user']);
          await _storeUser(user);
          
          return {
            'success': true,
            'user': user,
            'message': data['message'] ?? 'Login successful',
          };
        }
      }
      
      return {
        'success': false,
        'message': 'Invalid response from server',
      };
    } on ApiException catch (e) {
      return {
        'success': false,
        'message': e.message,
      };
    } catch (e) {
      return {
        'success': false,
        'message': 'An unexpected error occurred during login',
      };
    }
  }
  
  // Register new user
  Future<Map<String, dynamic>> register({
    required String name,
    required String email,
    required String password,
    required String phone,
    String? address,
  }) async {
    try {
      final response = await _apiService.post(
        ApiConstants.register,
        data: {
          'name': name,
          'email': email,
          'password': password,
          'phone': phone,
          if (address != null) 'address': address,
        },
      );
      
      if (response.statusCode == 201 && response.data != null) {
        final data = response.data as Map<String, dynamic>;
        
        // Store tokens
        if (data['token'] != null) {
          await _storeToken(data['token']);
        }
        if (data['refresh_token'] != null) {
          await _storeRefreshToken(data['refresh_token']);
        }
        
        // Store user data
        if (data['user'] != null) {
          final user = UserModel.fromJson(data['user']);
          await _storeUser(user);
          
          return {
            'success': true,
            'user': user,
            'message': data['message'] ?? 'Registration successful',
          };
        }
      }
      
      return {
        'success': false,
        'message': 'Invalid response from server',
      };
    } on ApiException catch (e) {
      return {
        'success': false,
        'message': e.message,
      };
    } catch (e) {
      return {
        'success': false,
        'message': 'An unexpected error occurred during registration',
      };
    }
  }
  
  // Logout user
  Future<void> logout() async {
    try {
      // Call logout endpoint
      await _apiService.post(ApiConstants.logout);
    } catch (e) {
      // Continue with local logout even if server call fails
    } finally {
      // Clear all stored data
      await clearToken();
      await clearRefreshToken();
      await clearUser();
    }
  }
  
  // Get user profile
  Future<UserModel?> getUserProfile() async {
    try {
      final response = await _apiService.get(ApiConstants.profile);
      
      if (response.statusCode == 200 && response.data != null) {
        final data = response.data as Map<String, dynamic>;
        if (data['user'] != null) {
          final user = UserModel.fromJson(data['user']);
          await _storeUser(user);
          return user;
        }
      }
      
      return null;
    } catch (e) {
      return null;
    }
  }
  
  // Update user profile
  Future<Map<String, dynamic>> updateProfile({
    String? name,
    String? email,
    String? phone,
    String? address,
  }) async {
    try {
      final data = <String, dynamic>{};
      if (name != null) data['name'] = name;
      if (email != null) data['email'] = email;
      if (phone != null) data['phone'] = phone;
      if (address != null) data['address'] = address;
      
      final response = await _apiService.put(
        ApiConstants.updateProfile,
        data: data,
      );
      
      if (response.statusCode == 200 && response.data != null) {
        final responseData = response.data as Map<String, dynamic>;
        
        if (responseData['user'] != null) {
          final user = UserModel.fromJson(responseData['user']);
          await _storeUser(user);
          
          return {
            'success': true,
            'user': user,
            'message': responseData['message'] ?? 'Profile updated successfully',
          };
        }
      }
      
      return {
        'success': false,
        'message': 'Failed to update profile',
      };
    } on ApiException catch (e) {
      return {
        'success': false,
        'message': e.message,
      };
    } catch (e) {
      return {
        'success': false,
        'message': 'An unexpected error occurred while updating profile',
      };
    }
  }
  
  // Change password
  Future<Map<String, dynamic>> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    try {
      final response = await _apiService.put(
        ApiConstants.changePassword,
        data: {
          'current_password': currentPassword,
          'new_password': newPassword,
        },
      );
      
      if (response.statusCode == 200) {
        final data = response.data as Map<String, dynamic>;
        return {
          'success': true,
          'message': data['message'] ?? 'Password changed successfully',
        };
      }
      
      return {
        'success': false,
        'message': 'Failed to change password',
      };
    } on ApiException catch (e) {
      return {
        'success': false,
        'message': e.message,
      };
    } catch (e) {
      return {
        'success': false,
        'message': 'An unexpected error occurred while changing password',
      };
    }
  }
  
  // Forgot password
  Future<Map<String, dynamic>> forgotPassword(String email) async {
    try {
      final response = await _apiService.post(
        ApiConstants.forgotPassword,
        data: {'email': email},
      );
      
      if (response.statusCode == 200) {
        final data = response.data as Map<String, dynamic>;
        return {
          'success': true,
          'message': data['message'] ?? 'Reset email sent successfully',
        };
      }
      
      return {
        'success': false,
        'message': 'Failed to send reset email',
      };
    } on ApiException catch (e) {
      return {
        'success': false,
        'message': e.message,
      };
    } catch (e) {
      return {
        'success': false,
        'message': 'An unexpected error occurred while sending reset email',
      };
    }
  }
  
  // Reset password
  Future<Map<String, dynamic>> resetPassword({
    required String token,
    required String newPassword,
  }) async {
    try {
      final response = await _apiService.post(
        ApiConstants.resetPassword,
        data: {
          'token': token,
          'password': newPassword,
        },
      );
      
      if (response.statusCode == 200) {
        final data = response.data as Map<String, dynamic>;
        return {
          'success': true,
          'message': data['message'] ?? 'Password reset successfully',
        };
      }
      
      return {
        'success': false,
        'message': 'Failed to reset password',
      };
    } on ApiException catch (e) {
      return {
        'success': false,
        'message': e.message,
      };
    } catch (e) {
      return {
        'success': false,
        'message': 'An unexpected error occurred while resetting password',
      };
    }
  }
  
  // Refresh token
  Future<bool> refreshToken() async {
    try {
      final refreshToken = await getStoredRefreshToken();
      if (refreshToken == null) return false;
      
      final response = await _apiService.post(
        ApiConstants.refreshToken,
        data: {'refresh_token': refreshToken},
      );
      
      if (response.statusCode == 200 && response.data != null) {
        final data = response.data as Map<String, dynamic>;
        
        if (data['token'] != null) {
          await _storeToken(data['token']);
          return true;
        }
      }
      
      return false;
    } catch (e) {
      return false;
    }
  }
  
  // Token management
  Future<void> _storeToken(String token) async {
    await _storage.write(key: _tokenKey, value: token);
  }
  
  Future<String?> getStoredToken() async {
    return await _storage.read(key: _tokenKey);
  }
  
  Future<void> clearToken() async {
    await _storage.delete(key: _tokenKey);
  }
  
  // Refresh token management
  Future<void> _storeRefreshToken(String refreshToken) async {
    await _storage.write(key: _refreshTokenKey, value: refreshToken);
  }
  
  Future<String?> getStoredRefreshToken() async {
    return await _storage.read(key: _refreshTokenKey);
  }
  
  Future<void> clearRefreshToken() async {
    await _storage.delete(key: _refreshTokenKey);
  }
  
  // User data management
  Future<void> _storeUser(UserModel user) async {
    await _storage.write(key: _userKey, value: user.toJson().toString());
  }
  
  Future<UserModel?> getStoredUser() async {
    try {
      final userString = await _storage.read(key: _userKey);
      if (userString != null) {
        // Note: In a real app, you'd want to properly serialize/deserialize JSON
        // This is a simplified version
        return UserModel.fromJson(userString as Map<String, dynamic>);
      }
      return null;
    } catch (e) {
      return null;
    }
  }
  
  Future<void> clearUser() async {
    await _storage.delete(key: _userKey);
  }
  
  // Check if user is authenticated
  Future<bool> isAuthenticated() async {
    final token = await getStoredToken();
    return token != null;
  }
  
  // Clear all stored data
  Future<void> clearAllData() async {
    await _storage.deleteAll();
  }
}