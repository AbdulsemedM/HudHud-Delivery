import 'dart:io';

import 'package:dio/dio.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../../core/api/api_service.dart';
import '../../core/api/api_constants.dart';
import '../../core/utils/phone_util.dart';
import '../../models/user_model.dart';
import 'fcm_service.dart';
import 'fcm_topic_service.dart';
import 'guest_browse_service.dart';

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
    // Fire-and-forget: send FCM token and subscribe to topics when restoring session
    if (_currentUser != null && hasValidToken) {
      _sendFcmTokenToBackend();
      FcmTopicService().subscribeForCurrentUser();
    }
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
    await GuestBrowseService().clearGuestBrowseMode();
  }

  /// Get device ID for FCM token registration (Android: id, iOS: identifierForVendor).
  Future<String?> _getDeviceId() async {
    try {
      final deviceInfo = DeviceInfoPlugin();
      if (Platform.isAndroid) {
        final androidInfo = await deviceInfo.androidInfo;
        return androidInfo.id;
      } else if (Platform.isIOS) {
        final iosInfo = await deviceInfo.iosInfo;
        return iosInfo.identifierForVendor;
      }
    } catch (e) {
      if (kDebugMode) debugPrint('AuthService: getDeviceId failed: $e');
    }
    return null;
  }

  /// Send FCM token to backend. Fire-and-forget; never throws.
  Future<void> _sendFcmTokenToBackend() async {
    try {
      final userId = _currentUser?.id;
      if (userId == null) return;

      final fcmToken = await FcmService().getToken();
      if (fcmToken == null || fcmToken.isEmpty) return;

      final deviceId = await _getDeviceId();
      if (deviceId == null || deviceId.isEmpty) return;

      final deviceType =
          Platform.isAndroid ? 'android' : (Platform.isIOS ? 'ios' : 'unknown');
      if (deviceType == 'unknown') return;

      await _apiService.post(
        ApiConstants.fcmToken,
        data: {
          'token': fcmToken,
          'device_type': deviceType,
          'user_id': userId,
          'device_id': deviceId,
        },
      );
    } catch (e) {
      if (kDebugMode) {
        debugPrint('AuthService: sendFcmTokenToBackend failed: $e');
      }
    }
  }

  /// Public entry point for sending FCM token (e.g. from onTokenRefresh).
  Future<void> sendFcmTokenToBackend() => _sendFcmTokenToBackend();

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
        // Extract user object and include permissions from root level if available
        final userData =
            Map<String, dynamic>.from(data['user'] as Map<String, dynamic>);
        if (data['permissions'] != null) {
          userData['permissions'] = data['permissions'];
        }
        final user = UserModel.fromMap(userData);
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
      // Clear any stale session before storing new tokens
      await clearAllData();

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
        _storage.write(
            key: _tokenExpiryKey, value: _tokenExpiry!.toIso8601String()),
        if (refreshToken != null) _storeRefreshToken(refreshToken),
      ]);

      await GuestBrowseService().clearGuestBrowseMode();

      // Fire-and-forget: send FCM token to backend and subscribe to topics
      _sendFcmTokenToBackend();
      FcmTopicService().subscribeForCurrentUser();
    } catch (e) {
      // If storage fails, clear everything to maintain consistency
      await _clearSession();
      rethrow;
    }
  }

  /// Store only the token (and refresh token, expiry) without user data.
  /// Used after login so the profile API can be called with the new token.
  Future<void> storeTokenOnly({
    required String token,
    String? refreshToken,
    int? expiresIn,
  }) async {
    await clearAllData();
    await GuestBrowseService().clearGuestBrowseMode();
    _currentToken = token;
    _tokenExpiry =
        DateTime.now().add(Duration(seconds: expiresIn ?? 86400));
    await Future.wait([
      _storeToken(token),
      _storage.write(
          key: _tokenExpiryKey, value: _tokenExpiry!.toIso8601String()),
      _storage.write(
          key: _lastLoginKey, value: DateTime.now().toIso8601String()),
      if (refreshToken != null) _storeRefreshToken(refreshToken),
    ]);
  }

  /// Fetch profile from GET /api/profile, merge permissions, and store the user.
  /// Call after storeTokenOnly so the request is authenticated.
  /// On 401: clears session and rethrows. On other errors: rethrows.
  Future<UserModel?> fetchProfileAndStore({List<dynamic>? permissions}) async {
    try {
      final response = await _apiService.get(ApiConstants.profile);
      if (response.statusCode != 200 || response.data == null) return null;

      final data = response.data as Map<String, dynamic>;
      // API returns { success: true, data: { ...user } } or { user: { ... } }
      final userMap = (data['data'] ?? data['user'] ?? data) as Map<String, dynamic>;
      if (permissions != null) userMap['permissions'] = permissions;

      final user = UserModel.fromMap(userMap);
      _currentUser = user;
      await _storeUser(user);
      _sendFcmTokenToBackend();
      FcmTopicService().subscribeForCurrentUser();
      return user;
    } on ApiException catch (e) {
      if (e.statusCode == 401) {
        await _clearSession();
      }
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
          'phone': normalizePhoneToBackend(phone),
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

  /// Removes the FCM token from the backend. Fail-open; never throws.
  Future<void> _removeFcmTokenFromBackend() async {
    try {
      final fcmToken = await FcmService().getToken();
      if (fcmToken == null || fcmToken.isEmpty) return;

      final deviceId = await _getDeviceId();
      await _apiService.delete(
        ApiConstants.fcmTokenDelete,
        data: {
          'token': fcmToken,
          if (deviceId != null && deviceId.isNotEmpty) 'device_id': deviceId,
        },
      );
    } catch (e) {
      if (kDebugMode) {
        debugPrint('AuthService: removeFcmTokenFromBackend failed: $e');
      }
    }
  }

  Future<void> _cleanupFcmOnLogout() async {
    await FcmTopicService().unsubscribeAll();
    await _removeFcmTokenFromBackend();
    try {
      await FcmService().deleteToken();
    } catch (e) {
      if (kDebugMode) {
        debugPrint('AuthService: FCM deleteToken failed: $e');
      }
    }
  }

  // Logout user
  Future<Map<String, dynamic>> logout() async {
    try {
      await _cleanupFcmOnLogout();

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
        var userMap = UserModel.userMapFromApiEnvelope(data);
        if (userMap == null &&
            (data['id'] != null ||
                data['email'] != null ||
                data['name'] != null)) {
          userMap = Map<String, dynamic>.from(data);
        }
        if (userMap == null) return null;
        if (userMap['permissions'] == null && _currentUser?.permissions != null) {
          userMap['permissions'] = _currentUser!.permissions;
        }
        final user = UserModel.fromMap(userMap);

        // Update cached user and store
        _currentUser = user;
        await _storeUser(user);

        return user;
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

  // Update user profile — POST /api/update-profile (multipart form-data)
  Future<Map<String, dynamic>> updateProfile({
    String? name,
    String? email,
    String? phone,
    String? address,
    String? avatarPath,
  }) async {
    try {
      if (!isLoggedIn) {
        return {
          'success': false,
          'message': 'User not authenticated',
        };
      }

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

      final previousEmail =
          _currentUser?.email?.trim().toLowerCase();
      final previousPhone = _currentUser?.phone != null
          ? normalizePhoneToBackend(_currentUser!.phone)
          : null;

      final formData = FormData();
      var hasField = false;

      if (name != null && name.trim().isNotEmpty) {
        formData.fields.add(MapEntry('name', name.trim()));
        hasField = true;
      }
      if (email != null && email.trim().isNotEmpty) {
        formData.fields.add(MapEntry('email', email.trim()));
        hasField = true;
      }
      if (phone != null && phone.trim().isNotEmpty) {
        formData.fields.add(
          MapEntry('phone', normalizePhoneToBackend(phone)),
        );
        hasField = true;
      }
      if (address != null && address.trim().isNotEmpty) {
        formData.fields.add(MapEntry('address', address.trim()));
        hasField = true;
      }
      if (avatarPath != null && avatarPath.isNotEmpty) {
        final file = File(avatarPath);
        if (await file.exists()) {
          formData.files.add(
            MapEntry(
              'avatar',
              await MultipartFile.fromFile(
                avatarPath,
                filename: avatarPath.split(Platform.pathSeparator).last,
              ),
            ),
          );
          hasField = true;
        }
      }

      if (!hasField) {
        return {
          'success': false,
          'message': 'No valid data provided for update',
        };
      }

      final response = await _apiService.post(
        ApiConstants.updateProfile,
        data: formData,
      );

      final status = response.statusCode ?? 0;
      if ((status == 200 || status == 201) && response.data != null) {
        final responseData = response.data as Map<String, dynamic>;
        final userMap = UserModel.userMapFromApiEnvelope(responseData);
        if (responseData['success'] == true && userMap != null) {
          if (userMap['permissions'] == null &&
              _currentUser?.permissions != null) {
            userMap['permissions'] = _currentUser!.permissions;
          }
          final user = UserModel.fromMap(userMap);

          final newEmail = user.email?.trim().toLowerCase();
          final newPhone =
              user.phone != null ? normalizePhoneToBackend(user.phone) : null;
          final emailOrPhoneChanged =
              (previousEmail != null &&
                  newEmail != null &&
                  previousEmail != newEmail) ||
              (previousPhone != null &&
                  newPhone != null &&
                  previousPhone != newPhone);

          _currentUser = user;
          await _storeUser(user);

          return {
            'success': true,
            'user': user,
            'message':
                responseData['message']?.toString() ??
                    'Profile updated successfully',
            'emailOrPhoneChanged': emailOrPhoneChanged,
          };
        }
      }

      final responseData = response.data;
      final message = responseData is Map
          ? responseData['message']?.toString()
          : null;
      return {
        'success': false,
        'message': message ?? 'Failed to update profile',
      };
    } on ApiException catch (e) {
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

  // Change password (settings) - POST /api/update-password
  Future<Map<String, dynamic>> changePassword({
    required String currentPassword,
    required String newPassword,
    required String newPasswordConfirmation,
  }) async {
    try {
      if (!isLoggedIn) {
        return {'success': false, 'message': 'User not authenticated'};
      }
      if (!hasValidToken) {
        final refreshed = await refreshToken();
        if (!refreshed) {
          await _clearSession();
          return {
            'success': false,
            'message': 'Session expired. Please login again.'
          };
        }
      }
      final response = await _apiService.post(
        ApiConstants.updatePassword,
        data: {
          'current_password': currentPassword,
          'new_password': newPassword,
          'new_password_confirmation': newPasswordConfirmation,
        },
      );
      if (response.statusCode == 200 && response.data != null) {
        final data = response.data as Map<String, dynamic>;
        final status = data['status'] == true;
        return {
          'success': status,
          'message': data['message'] ??
              (status
                  ? 'Password updated successfully'
                  : 'Failed to update password'),
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

  // Send email verification code
  Future<Map<String, dynamic>> sendEmailVerification() async {
    try {
      if (!isLoggedIn) {
        return {'success': false, 'message': 'User not authenticated'};
      }
      final email = _currentUser?.email;
      if (email == null || email.isEmpty) {
        return {'success': false, 'message': 'No email address on account'};
      }
      if (!hasValidToken) {
        final refreshed = await refreshToken();
        if (!refreshed) {
          await _clearSession();
          return {
            'success': false,
            'message': 'Session expired. Please login again.'
          };
        }
      }
      final response = await _apiService.post(
        ApiConstants.sendEmailVerification,
        data: {'email': email},
      );
      if (response.statusCode == 200 && response.data != null) {
        final data = response.data as Map<String, dynamic>;
        return {
          'success': true,
          'message': data['message'] ?? 'Verification code sent successfully!',
        };
      }
      return {'success': false, 'message': 'Failed to send verification code'};
    } on ApiException catch (e) {
      return {'success': false, 'message': e.message};
    } catch (e) {
      return {
        'success': false,
        'message':
            'An unexpected error occurred while sending verification code',
      };
    }
  }

  // Verify email with code
  Future<Map<String, dynamic>> verifyEmail({
    required String email,
    required String code,
  }) async {
    try {
      if (!isLoggedIn) {
        return {'success': false, 'message': 'User not authenticated'};
      }
      if (!hasValidToken) {
        final refreshed = await refreshToken();
        if (!refreshed) {
          await _clearSession();
          return {
            'success': false,
            'message': 'Session expired. Please login again.'
          };
        }
      }
      final response = await _apiService.post(
        ApiConstants.verifyEmail,
        data: {'email': email, 'code': code},
      );
      if (response.statusCode == 200 && response.data != null) {
        final data = response.data as Map<String, dynamic>;
        // Refresh user profile to get updated email_verified_at
        await getUserProfile(forceRefresh: true);
        return {
          'success': true,
          'message': data['message'] ?? 'Email verified successfully!',
        };
      }
      return {'success': false, 'message': 'Failed to verify email'};
    } on ApiException catch (e) {
      return {'success': false, 'message': e.message};
    } catch (e) {
      return {
        'success': false,
        'message': 'An unexpected error occurred while verifying email',
      };
    }
  }

  // Send phone verification code
  Future<Map<String, dynamic>> sendPhoneVerificationCode(String phone) async {
    try {
      if (!isLoggedIn) {
        return {'success': false, 'message': 'User not authenticated'};
      }
      if (!hasValidToken) {
        final refreshed = await refreshToken();
        if (!refreshed) {
          await _clearSession();
          return {
            'success': false,
            'message': 'Session expired. Please login again.'
          };
        }
      }
      final response = await _apiService.post(
        ApiConstants.sendPhoneVerificationCode,
        data: {'phone': normalizePhoneToBackend(phone)},
      );
      if (response.statusCode == 200 && response.data != null) {
        final data = response.data as Map<String, dynamic>;
        return {
          'success': true,
          'message': data['message'] ?? 'Verification code sent successfully!',
        };
      }
      return {'success': false, 'message': 'Failed to send verification code'};
    } on ApiException catch (e) {
      return {'success': false, 'message': e.message};
    } catch (e) {
      return {
        'success': false,
        'message':
            'An unexpected error occurred while sending verification code',
      };
    }
  }

  // Verify phone with code
  Future<Map<String, dynamic>> verifyPhone({
    required String phone,
    required String code,
  }) async {
    try {
      if (!isLoggedIn) {
        return {'success': false, 'message': 'User not authenticated'};
      }
      if (!hasValidToken) {
        final refreshed = await refreshToken();
        if (!refreshed) {
          await _clearSession();
          return {
            'success': false,
            'message': 'Session expired. Please login again.'
          };
        }
      }
      final response = await _apiService.post(
        ApiConstants.verifyPhone,
        data: {'phone': normalizePhoneToBackend(phone), 'code': code},
      );
      if (response.statusCode == 200 && response.data != null) {
        final data = response.data as Map<String, dynamic>;
        await getUserProfile(forceRefresh: true);
        return {
          'success': true,
          'message': data['message'] ?? 'Phone number verified successfully',
        };
      }
      return {'success': false, 'message': 'Failed to verify phone'};
    } on ApiException catch (e) {
      return {'success': false, 'message': e.message};
    } catch (e) {
      return {
        'success': false,
        'message': 'An unexpected error occurred while verifying phone',
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
            _storage.write(
                key: _tokenExpiryKey, value: _tokenExpiry!.toIso8601String()),
            if (data['refresh_token'] != null)
              _storeRefreshToken(data['refresh_token']),
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

  // Clear session data only (preserves biometric credential storage).
  Future<void> clearAllData() async {
    await Future.wait([
      _storage.delete(key: _tokenKey),
      _storage.delete(key: _refreshTokenKey),
      _storage.delete(key: _userKey),
      _storage.delete(key: _tokenExpiryKey),
      _storage.delete(key: _lastLoginKey),
    ]);
    _currentUser = null;
    _currentToken = null;
    _tokenExpiry = null;
  }
}
