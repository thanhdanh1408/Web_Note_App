import 'package:flutter/material.dart';
import '../services/supabase_service.dart';

/// ViewModel for profile management (MVVM Architecture)
class ProfileViewModel extends ChangeNotifier {
  final SupabaseService _supabaseService;

  bool _isLoading = false;
  String? _error;
  String _username = '';

  ProfileViewModel(this._supabaseService);

  // Getters
  bool get isLoading => _isLoading;
  String? get error => _error;
  String get username => _username;

  /// Load user profile
  Future<void> loadProfile() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final userId = _supabaseService.currentUser?.id;
      if (userId == null) {
        throw Exception('User not logged in');
      }

      final profile = await _supabaseService.getProfile(userId);
      if (profile != null) {
        _username = profile['username'] as String? ?? '';
      } else {
        // If no profile found, use user metadata
        _username = _supabaseService.currentUser?.userMetadata?['username'] ?? '';
      }

      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _error = 'Không thể tải hồ sơ: ${e.toString()}';
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Update username
  Future<bool> updateUsername(String newUsername) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final userId = _supabaseService.currentUser?.id;
      if (userId == null) {
        throw Exception('User not logged in');
      }

      await _supabaseService.updateProfile(
        userId: userId,
        username: newUsername,
      );

      _username = newUsername;
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _error = 'Không thể cập nhật hồ sơ: ${e.toString()}';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  /// Change password with current password verification
  Future<bool> changePassword(String currentPassword, String newPassword) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      // First, verify current password by attempting to sign in
      final email = _supabaseService.currentUser?.email;
      if (email == null) {
        throw Exception('User email not found');
      }

      // Try to authenticate with current password
      final isValid = await _supabaseService.verifyCurrentPassword(email, currentPassword);
      
      if (!isValid) {
        _error = 'Mật khẩu hiện tại không đúng';
        _isLoading = false;
        notifyListeners();
        return false;
      }

      // If verification successful, update the password
      await _supabaseService.updatePassword(newPassword);

      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _error = 'Không thể đổi mật khẩu: ${e.toString()}';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }
}
