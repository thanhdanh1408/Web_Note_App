import 'package:flutter/material.dart';
import '../models/user.dart';
import '../services/local_storage_service.dart';

/// Provider for authentication state
class AuthProvider extends ChangeNotifier {
  final LocalStorageService _storageService;
  
  AppUser? _currentUser;
  bool _isLoading = false;
  String? _error;

  AuthProvider(this._storageService) {
    _loadCurrentUser();
  }

  // Getters
  AppUser? get currentUser => _currentUser;
  bool get isLoggedIn => _currentUser != null;
  bool get isLoading => _isLoading;
  String? get error => _error;
  String get username => _currentUser?.username ?? '';

  /// Load current user from storage
  void _loadCurrentUser() {
    _currentUser = _storageService.getCurrentUser();
    notifyListeners();
  }

  /// Register a new user
  Future<bool> register(String username, String password) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      // Check if username already exists
      final existingUser = _storageService.getUserByUsername(username);
      if (existingUser != null) {
        _error = 'Tên đăng nhập đã tồn tại';
        _isLoading = false;
        notifyListeners();
        return false;
      }

      // Create new user
      final newUser = AppUser(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        username: username,
        passwordHash: AppUser.hashPassword(password),
        createdAt: DateTime.now(),
      );

      await _storageService.addUser(newUser);
      await _storageService.saveCurrentUser(newUser);
      _currentUser = newUser;
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _error = 'Đã xảy ra lỗi: $e';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  /// Login with username and password
  Future<bool> login(String username, String password) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final user = _storageService.getUserByUsername(username);
      if (user == null) {
        _error = 'Tên đăng nhập không tồn tại';
        _isLoading = false;
        notifyListeners();
        return false;
      }

      if (!user.verifyPassword(password)) {
        _error = 'Mật khẩu không đúng';
        _isLoading = false;
        notifyListeners();
        return false;
      }

      await _storageService.saveCurrentUser(user);
      _currentUser = user;
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _error = 'Đã xảy ra lỗi: $e';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  /// Logout
  Future<void> logout() async {
    await _storageService.saveCurrentUser(null);
    _currentUser = null;
    notifyListeners();
  }

  /// Clear error
  void clearError() {
    _error = null;
    notifyListeners();
  }
}
