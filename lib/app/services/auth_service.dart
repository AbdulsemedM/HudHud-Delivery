import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../../core/api/api_service.dart';
import '../../core/api/api_constants.dart';
import '../../models/user_model.dart';

class AuthService {
  // Singleton pattern
  static final AuthService _instance = AuthService._internal();
  factory AuthService() => _instance;
  AuthService._internal();
  
  static const _storage = FlutterSecureStorage(
    aOptions: AndroidOptions(
      encryptedSharedPreferences: true,
    ),
    iOptions: IOSOptions(
      accessibility: KeychainAccessibility.first_unlock_this_device,
    ),
  );
  
  // Storage keys
  static const String _tokenKey = 'auth_token';
  static const String _refreshTokenKey = 'refresh_token';
  static const String _userKey = 'user_data';
  static const String _tokenExpiryKey = 'token_expiry';
  static const String _lastLoginKey = 'last_login';
  
  final ApiService _apiService = ApiService.instance;
  
  // In-memory cache for current user
  UserModel? _currentUser;
  String? _currentToken;
  DateTime? _tokenExpiry;
  
  // Getters for current user and authentication state
  UserModel? get currentUser => _currentUser;
  bool get isLoggedIn => _currentUser != null && _currentToken != null;
  bool get hasValidToken => _currentToken != null && !_isTokenExpired();
  
  // Initialize service - load cached data
  Future<void> initialize() async {
    await _loadCachedData();
  }
  
  // Load cached user data and tokens
  Future<void> _loadCachedData() async {
    try {
      _currentToken = await getStoredToken();
      _currentUser = await getStoredUser();
      
      final expiryString = await _storage.read(key: _tokenExpiryKey);
      if (expiryString != null) {
        _tokenExpiry = DateTime.parse(expiryString);
      }
      
      // Check if token is expired and try to refresh
      if (_isTokenExpired() && _currentToken != null) {
        final refreshed = await refreshToken();
        if (!refreshed) {
          await _clearSession();
        }
      }
    } catch (e) {
      // If there's any error loading cached data, clear everything
      await _clearSession();
    }
  }
  
  // Check if token is expired
  bool _isTokenExpired() {
    if (_tokenExpiry == null) return false;
    return DateTime.now().isAfter(_tokenExpiry!);
  }
  
  // Clear current session
  Future<void> _clearSession() async {
    _currentUser = null;
    _currentToken = null;
    _tokenExpiry = null;
    await clearAllData();
  }
  
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
        
        // Validate response structure
        if (data['token'] == null || data['user'] == null) {
          return {
            'success': false,
            'message': 'Invalid server response: missing required data',
          };
        }
        
        // Parse and store user data
        final user = UserModel.fromMap(data);
        await _storeUserSession(
          user: user,
          token: data['token'],
          refreshToken: data['refresh_token'],
          expiresIn: data['expires_in'], // seconds from now
        );
        
        // Store last login timestamp
        await _storage.write(
          key: _lastLoginKey, 
          value: DateTime.now().toIso8601String(),
        );
        
        return {
          'success': true,
          'user': user,
          'message': data['message'] ?? 'Login successful',
        };
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
  
  // Store complete user session data
  Future<void> _storeUserSession({
    required UserModel user,
    required String token,
    String? refreshToken,
    int? expiresIn, // seconds from now
  }) async {
    try {
      // Update in-memory cache
      _currentUser = user;
      _currentToken = token;
      
      // Calculate token expiry (default to 24 hours if not provided)
      final expiryDuration = Duration(seconds: expiresIn ?? 86400);
      _tokenExpiry = DateTime.now().add(expiryDuration);
      
      // Store in secure storage
      await Future.wait([
        _storeToken(token),
        _storeUser(user),
        _storage.write(key: _tokenExpiryKey, value: _tokenExpiry!.toIso8601String()),
        if (refreshToken != null) _storeRefreshToken(refreshToken),
      ]);
    } catch (e) {
      // If storage fails, clear everything to maintain consistency
      await _clearSession();
      rethrow;
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
        
        // Validate response structure
        if (data['token'] == null || data['user'] == null) {
          return {
            'success': false,
            'message': 'Invalid server response: missing required data',
          };
        }
        
        // Parse and store user data
        final user = UserModel.fromMap(data);
        await _storeUserSession(
          user: user,
          token: data['token'],
          refreshToken: data['refresh_token'],
          expiresIn: data['expires_in'],
        );
        
        // Store last login timestamp
        await _storage.write(
          key: _lastLoginKey, 
          value: DateTime.now().toIso8601String(),
        );
        
        return {
          'success': true,
          'user': user,
          'message': data['message'] ?? 'Registration successful',
        };
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
  Future<Map<String, dynamic>> logout() async {
    try {
      // Call logout endpoint if we have a valid token
      if (_currentToken != null) {
        await _apiService.post(ApiConstants.logout);
      }
      
      return {
        'success': true,
        'message': 'Logged out successfully',
      };
    } catch (e) {
      // Continue with local logout even if server call fails
      return {
        'success': true,
        'message': 'Logged out locally',
      };
    } finally {
      // Always clear session data
      await _clearSession();
    }
  }
  
  // Get user profile with automatic token refresh
  Future<UserModel?> getUserProfile({bool forceRefresh = false}) async {
    try {
      // Return cached user if available and not forcing refresh
      if (!forceRefresh && _currentUser != null && hasValidToken) {
        return _currentUser;
      }
      
      // Check token validity and refresh if needed
      if (!hasValidToken) {
        final refreshed = await refreshToken();
        if (!refreshed) {
          await _clearSession();
          return null;
        }
      }
      
      final response = await _apiService.get(ApiConstants.profile);
      
      if (response.statusCode == 200 && response.data != null) {
        final data = response.data as Map<String, dynamic>;
        if (data['user'] != null) {
          final user = UserModel.fromMap(data);
          
          // Update cached user and store
          _currentUser = user;
          await _storeUser(user);
          
          return user;
        }
      }
      
      return null;
    } catch (e) {
      // If unauthorized, clear session
      if (e is ApiException && e.statusCode == 401) {
        await _clearSession();
      }
      return null;
    }
  }
  
  // Update user profile with enhanced validation
  Future<Map<String, dynamic>> updateProfile({
    String? name,
    String? email,
    String? phone,
    String? address,
  }) async {
    try {
      // Check authentication
      if (!isLoggedIn) {
        return {
          'success': false,
          'message': 'User not authenticated',
        };
      }
      
      // Check token validity and refresh if needed
      if (!hasValidToken) {
        final refreshed = await refreshToken();
        if (!refreshed) {
          await _clearSession();
          return {
            'success': false,
            'message': 'Session expired. Please login again.',
          };
        }
      }
      
      // Prepare update data
      final updateData = <String, dynamic>{};
      if (name != null && name.trim().isNotEmpty) updateData['name'] = name.trim();
      if (email != null && email.trim().isNotEmpty) updateData['email'] = email.trim();
      if (phone != null && phone.trim().isNotEmpty) updateData['phone'] = phone.trim();
      if (address != null && address.trim().isNotEmpty) updateData['address'] = address.trim();
      
      if (updateData.isEmpty) {
        return {
          'success': false,
          'message': 'No valid data provided for update',
        };
      }
      
      final response = await _apiService.put(
        ApiConstants.updateProfile,
        data: updateData,
      );
      
      if (response.statusCode == 200 && response.data != null) {
        final responseData = response.data as Map<String, dynamic>;
        
        if (responseData['user'] != null) {
          final user = UserModel.fromMap(responseData);
          
          // Update cached user and store
          _currentUser = user;
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
      // Handle unauthorized access
      if (e.statusCode == 401) {
        await _clearSession();
        return {
          'success': false,
          'message': 'Session expired. Please login again.',
        };
      }
      
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
  
  // Enhanced refresh token with better error handling
  Future<bool> refreshToken() async {
    try {
      final storedRefreshToken = await getStoredRefreshToken();
      if (storedRefreshToken == null) {
        await _clearSession();
        return false;
      }
      
      final response = await _apiService.post(
        ApiConstants.refreshToken,
        data: {'refresh_token': storedRefreshToken},
      );
      
      if (response.statusCode == 200 && response.data != null) {
        final data = response.data as Map<String, dynamic>;
        
        if (data['token'] != null) {
          // Update tokens and expiry
          _currentToken = data['token'];
          
          // Calculate new expiry
          final expiresIn = data['expires_in'] ?? 86400; // default 24 hours
          _tokenExpiry = DateTime.now().add(Duration(seconds: expiresIn));
          
          // Store updated tokens
          await Future.wait([
            _storeToken(data['token']),
            _storage.write(key: _tokenExpiryKey, value: _tokenExpiry!.toIso8601String()),
            if (data['refresh_token'] != null) _storeRefreshToken(data['refresh_token']),
          ]);
          
          return true;
        }
      }
      
      // If refresh fails, clear session
      await _clearSession();
      return false;
    } catch (e) {
      // If refresh fails, clear session
      await _clearSession();
      return false;
    }
  }
  
  // Get last login timestamp
  Future<DateTime?> getLastLoginTime() async {
    try {
      final lastLoginString = await _storage.read(key: _lastLoginKey);
      if (lastLoginString != null) {
        return DateTime.parse(lastLoginString);
      }
      return null;
    } catch (e) {
      return null;
    }
  }
  
  // Check if user session is still valid
  Future<bool> validateSession() async {
    if (!isLoggedIn || !hasValidToken) {
      return false;
    }
    
    // Try to get user profile to validate session
    final user = await getUserProfile();
    return user != null;
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
    await _storage.write(key: _userKey, value: user.toJson());
  }
  
  Future<UserModel?> getStoredUser() async {
    try {
      final userString = await _storage.read(key: _userKey);
      if (userString != null) {
        return UserModel.fromJson(userString);
      }
      return null;
    } catch (e) {
      return null;
    }
  }
  
  Future<void> clearUser() async {
    await _storage.delete(key: _userKey);
  }
  
  // Check if user is authenticated (enhanced)
  Future<bool> isAuthenticated() async {
    // First check in-memory state
    if (isLoggedIn && hasValidToken) {
      return true;
    }
    
    // If not in memory, try to load from storage
    await _loadCachedData();
    
    // Check again after loading
    return isLoggedIn && hasValidToken;
  }
  
  // Get comprehensive user session information
  Future<Map<String, dynamic>> getUserSessionInfo() async {
    final lastLogin = await getLastLoginTime();
    
    return {
      'isLoggedIn': isLoggedIn,
      'hasValidToken': hasValidToken,
      'currentUser': _currentUser?.toMap(),
      'tokenExpiry': _tokenExpiry?.toIso8601String(),
      'lastLogin': lastLogin?.toIso8601String(),
      'isTokenExpired': _isTokenExpired(),
    };
  }
  
  // Update user data in current session
  Future<void> updateCurrentUser(UserModel user) async {
    _currentUser = user;
    await _storeUser(user);
  }
  
  // Store user session data from external sources (e.g., signup)
  Future<void> storeUserSession({
    required UserModel user,
    required String token,
    String? refreshToken,
    int? expiresIn,
  }) async {
    await _storeUserSession(
      user: user,
      token: token,
      refreshToken: refreshToken,
      expiresIn: expiresIn,
    );
  }
  
  // Clear all stored data
  Future<void> clearAllData() async {
    await _storage.deleteAll();
    _currentUser = null;
    _currentToken = null;
    _tokenExpiry = null;
  }
}