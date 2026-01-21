import 'package:flutter/material.dart';
import '../services/supabase_service.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// ViewModel for authentication with Supabase (MVVM Architecture)
class AuthViewModelSupabase extends ChangeNotifier {
  final SupabaseService _supabaseService;
  
  User? _currentUser;
  bool _isLoading = false;
  String? _error;

  AuthViewModelSupabase(this._supabaseService) {
    _loadCurrentUser();
    _listenToAuthChanges();
  }

  // Getters
  User? get currentUser => _currentUser;
  bool get isLoggedIn => _currentUser != null;
  bool get isLoading => _isLoading;
  String? get error => _error;
  String get username => _currentUser?.userMetadata?['username'] ?? _currentUser?.email ?? '';
  String get userId => _currentUser?.id ?? '';

  /// Load current user from Supabase
  void _loadCurrentUser() {
    _currentUser = _supabaseService.currentUser;
    notifyListeners();
  }

  /// Public method to reload current user (useful after profile update)
  void loadCurrentUser() {
    _loadCurrentUser();
  }

  /// Listen to auth state changes
  void _listenToAuthChanges() {
    _supabaseService.authStateChanges.listen((AuthState data) {
      _currentUser = data.session?.user;
      notifyListeners();
    });
  }

  /// Register a new user
  Future<bool> register(String email, String password, String username) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final response = await _supabaseService.signUp(
        email: email,
        password: password,
        username: username,
      );

      print('Register response: ${response.user?.id}');
      print('Session: ${response.session?.accessToken}');

      if (response.user != null) {
        // Sign out after registration - user needs to login manually
        await _supabaseService.signOut();
        _currentUser = null;
        _isLoading = false;
        notifyListeners();
        return true;
      } else {
        _error = 'Đăng ký thất bại';
        _isLoading = false;
        notifyListeners();
        return false;
      }
    } on AuthException catch (e) {
      print('Register AuthException: ${e.message}');
      if (e.message.contains('invalid')) {
        _error = 'Email không hợp lệ. Vui lòng sử dụng email thật.';
      } else if (e.message.contains('already registered')) {
        _error = 'Email này đã được đăng ký.';
      } else {
        _error = 'Đã xảy ra lỗi: ${e.message}';
      }
      _isLoading = false;
      notifyListeners();
      return false;
    } catch (e) {
      print('Register error: $e');
      _error = 'Đã xảy ra lỗi: ${e.toString()}';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  /// Login with email and password
  Future<bool> login(String email, String password) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      print('Attempting login with email: $email');
      
      final response = await _supabaseService.signIn(
        email: email,
        password: password,
      );

      print('Login response: ${response.user?.id}');
      print('Session: ${response.session?.accessToken}');

      if (response.user != null) {
        _currentUser = response.user;
        _isLoading = false;
        notifyListeners();
        return true;
      } else {
        _error = 'Đăng nhập thất bại';
        _isLoading = false;
        notifyListeners();
        return false;
      }
    } on AuthException catch (e) {
      print('Login AuthException: ${e.message}');
      if (e.message.contains('Invalid login credentials')) {
        _error = 'Email hoặc mật khẩu không đúng';
      } else if (e.message.contains('Email not confirmed')) {
        _error = 'Vui lòng xác nhận email trước khi đăng nhập';
      } else {
        _error = 'Đã xảy ra lỗi: ${e.message}';
      }
      _isLoading = false;
      notifyListeners();
      return false;
    } catch (e) {
      print('Login error: $e');
      _error = 'Đã xảy ra lỗi: ${e.toString()}';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  /// Logout
  Future<void> logout() async {
    _isLoading = true;
    notifyListeners();

    try {
      await _supabaseService.signOut();
      _currentUser = null;
      _error = null;
    } catch (e) {
      _error = 'Đăng xuất thất bại: ${e.toString()}';
    }

    _isLoading = false;
    notifyListeners();
  }

  /// Clear error
  void clearError() {
    _error = null;
    notifyListeners();
  }

  /// Check if user has safe password configured
  Future<bool> hasSafePassword() async {
    return await _supabaseService.hasSafePassword();
  }

  /// Set safe password
  Future<bool> setSafePassword(String password) async {
    try {
      await _supabaseService.setSafePassword(password);
      return true;
    } catch (e) {
      _error = 'Không thể đặt mật khẩu SAFE: ${e.toString()}';
      notifyListeners();
      return false;
    }
  }

  /// Verify safe password
  Future<bool> verifySafePassword(String password) async {
    return await _supabaseService.verifySafePassword(password);
  }

  @override
  void dispose() {
    super.dispose();
  }
}
