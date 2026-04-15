import 'package:flutter/material.dart';
import '../models/user_model.dart';
import '../app/services/auth_service.dart';
import '../core/api/api_service.dart';

class AuthController extends ChangeNotifier {
  final AuthService _authService = AuthService();
  
  UserModel? _currentUser;
  bool _isLoading = false;
  bool _isLoggedIn = false;
  String? _errorMessage;
  
  // Getters
  UserModel? get currentUser => _currentUser;
  bool get isLoading => _isLoading;
  bool get isLoggedIn => _isLoggedIn;
  String? get errorMessage => _errorMessage;
  bool get hasError => _errorMessage != null;
  
  // Initialize auth controller
  Future<void> init() async {
    await _checkAuthStatus();
  }
  
  // Check if user is already authenticated
  Future<void> _checkAuthStatus() async {
    try {
      _setLoading(true);
      final token = await _authService.getStoredToken();
      
      if (token != null) {
        // Verify token by getting user profile
        final user = await _authService.getUserProfile();
        if (user != null) {
          _currentUser = user;
          _isLoggedIn = true;
        } else {
          // Token is invalid, clear it
          await _authService.clearToken();
          _isLoggedIn = false;
        }
      } else {
        _isLoggedIn = false;
      }
    } catch (e) {
      _isLoggedIn = false;
      _setError('Failed to check authentication status');
    } finally {
      _setLoading(false);
    }
  }
  
  // Login with email and password
  Future<bool> login(String email, String password) async {
    try {
      _setLoading(true);
      _clearError();
      
      final result = await _authService.login(email, password);
      
      if (result['success'] == true) {
        _currentUser = result['user'];
        _isLoggedIn = true;
        return true;
      } else {
        _setError(result['message'] ?? 'Login failed');
        return false;
      }
    } on ApiException catch (e) {
      _setError(e.message);
      return false;
    } catch (e) {
      _setError('An unexpected error occurred during login');
      return false;
    } finally {
      _setLoading(false);
    }
  }
  
  // Register new user
  Future<bool> register({
    required String name,
    required String email,
    required String password,
    required String phone,
    String? address,
  }) async {
    try {
      _setLoading(true);
      _clearError();
      
      final result = await _authService.register(
        name: name,
        email: email,
        password: password,
        phone: phone,
        address: address,
      );
      
      if (result['success'] == true) {
        _currentUser = result['user'];
        _isLoggedIn = true;
        return true;
      } else {
        _setError(result['message'] ?? 'Registration failed');
        return false;
      }
    } on ApiException catch (e) {
      _setError(e.message);
      return false;
    } catch (e) {
      _setError('An unexpected error occurred during registration');
      return false;
    } finally {
      _setLoading(false);
    }
  }
  
  // Logout user
  Future<void> logout() async {
    try {
      _setLoading(true);
      await _authService.logout();
    } catch (e) {
      // Even if logout fails on server, clear local data
      debugPrint('Logout error: $e');
    } finally {
      _currentUser = null;
      _isLoggedIn = false;
      _clearError();
      _setLoading(false);
    }
  }
  
  // Refresh user profile
  Future<bool> refreshUserProfile() async {
    try {
      _setLoading(true);
      _clearError();
      
      final user = await _authService.getUserProfile();
      if (user != null) {
        _currentUser = user;
        return true;
      } else {
        _setError('Failed to refresh user profile');
        return false;
      }
    } on ApiException catch (e) {
      _setError(e.message);
      return false;
    } catch (e) {
      _setError('An unexpected error occurred while refreshing profile');
      return false;
    } finally {
      _setLoading(false);
    }
  }
  
  // Update user profile
  Future<bool> updateProfile({
    String? name,
    String? email,
    String? phone,
    String? address,
  }) async {
    try {
      _setLoading(true);
      _clearError();
      
      final result = await _authService.updateProfile(
        name: name,
        email: email,
        phone: phone,
        address: address,
      );
      
      if (result['success'] == true) {
        _currentUser = result['user'];
        return true;
      } else {
        _setError(result['message'] ?? 'Profile update failed');
        return false;
      }
    } on ApiException catch (e) {
      _setError(e.message);
      return false;
    } catch (e) {
      _setError('An unexpected error occurred while updating profile');
      return false;
    } finally {
      _setLoading(false);
    }
  }
  
  // Change password
  Future<bool> changePassword({
    required String currentPassword,
    required String newPassword,
    required String newPasswordConfirmation,
  }) async {
    try {
      _setLoading(true);
      _clearError();
      
      final result = await _authService.changePassword(
        currentPassword: currentPassword,
        newPassword: newPassword,
        newPasswordConfirmation: newPasswordConfirmation,
      );
      
      if (result['success'] == true) {
        return true;
      } else {
        _setError(result['message'] ?? 'Password change failed');
        return false;
      }
    } on ApiException catch (e) {
      _setError(e.message);
      return false;
    } catch (e) {
      _setError('An unexpected error occurred while changing password');
      return false;
    } finally {
      _setLoading(false);
    }
  }
  
  // Reset password
  Future<bool> resetPassword({
    required String token,
    required String newPassword,
  }) async {
    try {
      _setLoading(true);
      _clearError();
      
      final result = await _authService.resetPassword(
        token: token,
        newPassword: newPassword,
      );
      
      if (result['success'] == true) {
        return true;
      } else {
        _setError(result['message'] ?? 'Password reset failed');
        return false;
      }
    } on ApiException catch (e) {
      _setError(e.message);
      return false;
    } catch (e) {
      _setError('An unexpected error occurred while resetting password');
      return false;
    } finally {
      _setLoading(false);
    }
  }
  
  // Helper methods
  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }
  
  void _setError(String error) {
    _errorMessage = error;
    notifyListeners();
  }
  
  void _clearError() {
    _errorMessage = null;
    notifyListeners();
  }
  
  // Clear error manually
  void clearError() {
    _clearError();
  }
  
  // Check if user has specific role or permission
  bool hasRole(String role) {
    return _currentUser?.permissions?.contains(role) == true;
  }
  
  // Get user display name
  String get userDisplayName {
    return _currentUser?.name ?? 'User';
  }
  
  // Get user email
  String get userEmail {
    return _currentUser?.email ?? '';
  }
  
}