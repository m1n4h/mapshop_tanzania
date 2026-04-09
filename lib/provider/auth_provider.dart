import 'package:flutter/material.dart';
import '../services/auth_service.dart';

class AuthProvider extends ChangeNotifier {
  bool _isLoading = false;
  String? _errorMessage;
  Map<String, dynamic>? _user;

  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  Map<String, dynamic>? get user => _user;

  // Register
  Future<bool> register({
    required String email,
    required String username,
    required String phoneNumber,
    required String password,
    required String userType,
  }) async {
    _setLoading(true);
    _clearError();

    final result = await AuthService.register(
      email: email,
      username: username,
      phoneNumber: phoneNumber,
      password: password,
      userType: userType,
    );

    _setLoading(false);

    if (result['success']) {
      _user = result['user'];
      return true;
    } else {
      _errorMessage = result['message'];
      notifyListeners();
      return false;
    }
  }

  // Login
  Future<bool> login({
    required String email,
    required String password,
  }) async {
    _setLoading(true);
    _clearError();

    final result = await AuthService.login(
      email: email,
      password: password,
    );

    _setLoading(false);

    if (result['success']) {
      _user = result['user'];
      return true;
    } else {
      _errorMessage = result['message'];
      notifyListeners();
      return false;
    }
  }

  // Send OTP
  Future<bool> sendOTP({
    required String email,
    String? phoneNumber,
  }) async {
    _setLoading(true);
    _clearError();

    final result = await AuthService.sendOTP(
      email: email,
      phoneNumber: phoneNumber,
    );

    _setLoading(false);

    if (result['success']) {
      return true;
    } else {
      _errorMessage = result['message'];
      notifyListeners();
      return false;
    }
  }

  // Verify OTP
  Future<bool> verifyOTP({
    required String email,
    required String otpCode,
  }) async {
    _setLoading(true);
    _clearError();

    final result = await AuthService.verifyOTP(
      email: email,
      otpCode: otpCode,
    );

    _setLoading(false);

    if (result['success']) {
      _user = result['user'];
      return true;
    } else {
      _errorMessage = result['message'];
      notifyListeners();
      return false;
    }
  }

  // Google Sign In
  Future<bool> signInWithGoogle() async {
    _setLoading(true);
    _clearError();

    final result = await AuthService.signInWithGoogle();

    _setLoading(false);

    if (result['success']) {
      _user = result['user'];
      return true;
    } else {
      _errorMessage = result['message'];
      notifyListeners();
      return false;
    }
  }

  // Apple Sign In
  Future<bool> signInWithApple() async {
    _setLoading(true);
    _clearError();

    final result = await AuthService.signInWithApple();

    _setLoading(false);

    if (result['success']) {
      _user = result['user'];
      return true;
    } else {
      _errorMessage = result['message'];
      notifyListeners();
      return false;
    }
  }

  // Logout
  Future<void> logout() async {
    await AuthService.logout();
    _user = null;
    notifyListeners();
  }

  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  void _clearError() {
    _errorMessage = null;
  }
}