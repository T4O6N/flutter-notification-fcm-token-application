import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import '../models/user_model.dart';
import '../models/auth_response.dart';

class AuthProvider with ChangeNotifier {
  final AuthService _authService = AuthService();

  User? _user;
  bool _isLoading = false;
  String? _errorMessage;

  User? get user => _user;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  bool get isLoggedIn => _user != null;

  // Google Sign In
  Future<bool> signInWithGoogle() async {
    _setLoading(true);
    _clearError();

    try {
      final AuthResponse response = await _authService.signInWithGoogle();

      if (response.success && response.data != null) {
        _user = response.data!.user;
        notifyListeners();
        return true;
      } else {
        _setError(response.message);
        return false;
      }
    } catch (e) {
      _setError('An unexpected error occurred');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  // รับข้อมูลผู้ใช้
  Future<void> loadUserProfile() async {
    _setLoading(true);

    try {
      final AuthResponse response = await _authService.getProfile();

      if (response.success && response.data != null) {
        _user = response.data!.user;
      } else {
        _setError(response.message);
      }
    } catch (e) {
      _setError('Failed to load profile');
    } finally {
      _setLoading(false);
    }
  }

  // ออกจากระบบ
  Future<void> signOut() async {
    await _authService.signOut();
    _user = null;
    _clearError();
    notifyListeners();
  }

  // ตรวจสอบสถานะการเข้าสู่ระบบ
  Future<void> checkAuthStatus() async {
    final bool isLoggedIn = await _authService.isLoggedIn();
    if (isLoggedIn) {
      await loadUserProfile();
    }
  }

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
}
