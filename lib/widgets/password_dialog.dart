import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

/// Password dialog for private notes
class PasswordDialog extends StatefulWidget {
  final String title;
  final String? subtitle;
  final bool isSetPassword;

  const PasswordDialog({
    super.key,
    required this.title,
    this.subtitle,
    this.isSetPassword = false,
  });

  /// Show the dialog and return the password if submitted
  static Future<String?> show(
    BuildContext context, {
    required String title,
    String? subtitle,
    bool isSetPassword = false,
  }) async {
    return showDialog<String?>(
      context: context,
      barrierDismissible: false,
      builder: (context) => PasswordDialog(
        title: title,
        subtitle: subtitle,
        isSetPassword: isSetPassword,
      ),
    );
  }

  @override
  State<PasswordDialog> createState() => _PasswordDialogState();
}

class _PasswordDialogState extends State<PasswordDialog> {
  final _passwordController = TextEditingController();
  final _confirmController = TextEditingController();
  bool _obscurePassword = true;
  bool _obscureConfirm = true;
  String? _error;

  @override
  void dispose() {
    _passwordController.dispose();
    _confirmController.dispose();
    super.dispose();
  }

  void _submit() {
    final password = _passwordController.text;
    
    if (password.isEmpty) {
      setState(() {
        _error = 'Vui lòng nhập mật khẩu';
      });
      return;
    }

    if (widget.isSetPassword) {
      if (password.length < 4) {
        setState(() {
          _error = 'Mật khẩu phải có ít nhất 4 ký tự';
        });
        return;
      }
      if (_confirmController.text != password) {
        setState(() {
          _error = 'Mật khẩu không khớp';
        });
        return;
      }
    }

    Navigator.pop(context, password);
  }

  InputDecoration _buildInputDecoration(String label, bool obscure, VoidCallback onToggle) {
    return InputDecoration(
      labelText: label,
      labelStyle: TextStyle(color: AppTheme.textSecondary),
      prefixIcon: Icon(Icons.lock_outline, color: AppTheme.textSecondary),
      suffixIcon: IconButton(
        icon: Icon(
          obscure ? Icons.visibility_off_outlined : Icons.visibility_outlined,
          color: AppTheme.textSecondary,
        ),
        onPressed: onToggle,
      ),
      filled: true,
      fillColor: Colors.grey.shade100,
      hintStyle: TextStyle(color: AppTheme.textHint),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: Colors.grey.shade300),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: Colors.grey.shade300),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: AppTheme.primaryColor, width: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ),
      child: Container(
        constraints: const BoxConstraints(maxWidth: 360),
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Lock icon
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppTheme.primaryColor.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                widget.isSetPassword ? Icons.lock_outline : Icons.lock_open_outlined,
                size: 32,
                color: AppTheme.primaryColor,
              ),
            ),
            const SizedBox(height: 16),
            
            // Title
            Text(
              widget.title,
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: AppTheme.textPrimary,
              ),
              textAlign: TextAlign.center,
            ),
            if (widget.subtitle != null) ...[
              const SizedBox(height: 8),
              Text(
                widget.subtitle!,
                style: TextStyle(
                  fontSize: 14,
                  color: AppTheme.textSecondary,
                ),
                textAlign: TextAlign.center,
              ),
            ],
            const SizedBox(height: 24),

            // Error message
            if (_error != null)
              Container(
                margin: const EdgeInsets.only(bottom: 16),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppTheme.accentRed.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: AppTheme.accentRed.withValues(alpha: 0.3),
                  ),
                ),
                child: Row(
                  children: [
                    Icon(Icons.error_outline, color: AppTheme.accentRed, size: 20),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        _error!,
                        style: TextStyle(
                          color: AppTheme.accentRed,
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

            // Password field
            TextField(
              controller: _passwordController,
              obscureText: _obscurePassword,
              autofocus: true,
              style: TextStyle(color: AppTheme.textPrimary, fontSize: 16),
              cursorColor: AppTheme.primaryColor,
              decoration: _buildInputDecoration('Mật khẩu', _obscurePassword, () {
                setState(() {
                  _obscurePassword = !_obscurePassword;
                });
              }),
              onChanged: (_) {
                if (_error != null) {
                  setState(() {
                    _error = null;
                  });
                }
              },
              onSubmitted: widget.isSetPassword ? null : (_) => _submit(),
            ),

            // Confirm password field (only when setting)
            if (widget.isSetPassword) ...[
              const SizedBox(height: 16),
              TextField(
                controller: _confirmController,
                obscureText: _obscureConfirm,
                style: TextStyle(color: AppTheme.textPrimary, fontSize: 16),
                cursorColor: AppTheme.primaryColor,
                decoration: _buildInputDecoration('Xác nhận mật khẩu', _obscureConfirm, () {
                  setState(() {
                    _obscureConfirm = !_obscureConfirm;
                  });
                }),
                onSubmitted: (_) => _submit(),
              ),
            ],
            const SizedBox(height: 24),

            // Buttons
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.pop(context),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppTheme.textSecondary,
                      side: BorderSide(color: Colors.grey.shade300),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: Text('Hủy', style: TextStyle(color: AppTheme.textSecondary)),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: _submit,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.primaryColor,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text('Xác nhận'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
