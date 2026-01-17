import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/notes_provider.dart';
import '../../theme/app_theme.dart';
import '../../widgets/note_card.dart';
import '../../widgets/note_detail_view.dart';
import '../../widgets/password_dialog.dart';

/// Private notes screen (SAFE section) with shared password
class PrivateNotesScreen extends StatefulWidget {
  const PrivateNotesScreen({super.key});

  @override
  State<PrivateNotesScreen> createState() => _PrivateNotesScreenState();
}

class _PrivateNotesScreenState extends State<PrivateNotesScreen> {
  bool _isUnlocked = false;

  String get _userId {
    return context.read<AuthProvider>().currentUser?.id ?? '';
  }

  Future<void> _unlock() async {
    final notesProvider = context.read<NotesProvider>();
    
    // Check if SAFE password is configured
    if (!notesProvider.hasSafePassword(_userId)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Chưa có mật khẩu SAFE. Hãy khóa một ghi chú để cấu hình.'),
          backgroundColor: AppTheme.accentYellow,
        ),
      );
      return;
    }

    final password = await PasswordDialog.show(
      context,
      title: 'Nhập mật khẩu SAFE',
      subtitle: 'Nhập mật khẩu để xem ghi chú riêng tư',
    );

    if (password != null && mounted) {
      if (notesProvider.verifySafePassword(_userId, password)) {
        setState(() {
          _isUnlocked = true;
        });
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Mật khẩu không đúng'),
            backgroundColor: AppTheme.accentRed,
          ),
        );
      }
    }
  }

  Future<void> _changePassword() async {
    final notesProvider = context.read<NotesProvider>();
    
    // First, verify old password
    final oldPassword = await PasswordDialog.show(
      context,
      title: 'Xác nhận mật khẩu cũ',
      subtitle: 'Nhập mật khẩu SAFE hiện tại',
    );

    if (oldPassword == null) return;

    if (!notesProvider.verifySafePassword(_userId, oldPassword)) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Mật khẩu cũ không đúng'),
            backgroundColor: AppTheme.accentRed,
          ),
        );
      }
      return;
    }

    // Now set new password
    final newPassword = await PasswordDialog.show(
      context,
      title: 'Đặt mật khẩu mới',
      subtitle: 'Nhập mật khẩu SAFE mới',
      isSetPassword: true,
    );

    if (newPassword != null && mounted) {
      await notesProvider.setSafePassword(_userId, newPassword);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Đã đổi mật khẩu SAFE thành công'),
          backgroundColor: AppTheme.accentGreen,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: AppTheme.backgroundGradient,
        ),
        child: SafeArea(
          child: Column(
            children: [
              // Header
              _buildHeader(),
              
              // Main content
              Expanded(
                child: _isUnlocked
                    ? _buildUnlockedContent()
                    : _buildLockedContent(),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    final notesProvider = context.watch<NotesProvider>();
    final hasSafePassword = notesProvider.hasSafePassword(_userId);
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          // Back button
          IconButton(
            icon: const Icon(Icons.arrow_back_rounded),
            onPressed: () => Navigator.pop(context),
          ),
          const SizedBox(width: 8),
          
          // Icon
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppTheme.accentGreen.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              _isUnlocked ? Icons.lock_open_rounded : Icons.lock_rounded,
              color: AppTheme.accentGreen,
              size: 24,
            ),
          ),
          const SizedBox(width: 12),
          
          // Title
          Text(
            'Ghi chú riêng tư (SAFE)',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          
          const Spacer(),
          
          // Change password button (only when unlocked and has password)
          if (_isUnlocked && hasSafePassword)
            TextButton.icon(
              onPressed: _changePassword,
              icon: const Icon(Icons.key_rounded, size: 18),
              label: const Text('Đổi mật khẩu'),
              style: TextButton.styleFrom(
                foregroundColor: AppTheme.primaryColor,
              ),
            ),
          
          // Lock/Unlock button
          if (_isUnlocked)
            TextButton.icon(
              onPressed: () {
                setState(() {
                  _isUnlocked = false;
                });
                context.read<NotesProvider>().selectNote(null);
              },
              icon: const Icon(Icons.lock_rounded, size: 18),
              label: const Text('Khóa'),
              style: TextButton.styleFrom(
                foregroundColor: AppTheme.accentRed,
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildLockedContent() {
    final notesProvider = context.watch<NotesProvider>();
    final hasSafePassword = notesProvider.hasSafePassword(_userId);
    final privateNotesCount = notesProvider.privateNotes.length;
    
    return Center(
      child: Container(
        constraints: const BoxConstraints(maxWidth: 400),
        padding: const EdgeInsets.all(32),
        margin: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: AppTheme.accentGreen.withValues(alpha: 0.1),
              blurRadius: 30,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: AppTheme.accentGreen.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.lock_rounded,
                size: 64,
                color: AppTheme.accentGreen,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'Khu vực được bảo vệ',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              hasSafePassword
                  ? 'Nhập mật khẩu để xem $privateNotesCount ghi chú riêng tư'
                  : 'Chưa có mật khẩu SAFE. Hãy khóa một ghi chú để bắt đầu.',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: AppTheme.textSecondary,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            if (hasSafePassword)
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton.icon(
                  onPressed: _unlock,
                  icon: const Icon(Icons.lock_open_rounded),
                  label: const Text('Mở khóa'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.accentGreen,
                  ),
                ),
              )
            else
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppTheme.accentYellow.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: AppTheme.accentYellow.withValues(alpha: 0.3),
                  ),
                ),
                child: Row(
                  children: [
                    Icon(Icons.info_outline, color: AppTheme.accentYellow),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Nhấn vào biểu tượng khóa trên một ghi chú để thêm vào SAFE và cấu hình mật khẩu.',
                        style: TextStyle(
                          color: AppTheme.accentYellow,
                          fontSize: 13,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildUnlockedContent() {
    final notesProvider = context.watch<NotesProvider>();
    final privateNotes = notesProvider.privateNotes;
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 768;

    if (privateNotes.isEmpty) {
      return _buildEmptyState();
    }

    if (isMobile) {
      // Mobile layout
      if (notesProvider.selectedNote != null) {
        return Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back),
                    onPressed: () => notesProvider.selectNote(null),
                  ),
                  const Text('Quay lại danh sách'),
                ],
              ),
            ),
            Expanded(
              child: Container(
                margin: const EdgeInsets.all(16),
                child: NoteDetailView(
                  key: ValueKey(notesProvider.selectedNote!.id),
                  note: notesProvider.selectedNote!,
                ),
              ),
            ),
          ],
        );
      }

      return Container(
        margin: const EdgeInsets.all(16),
        decoration: AppTheme.glassDecoration,
        child: _buildNotesList(privateNotes, notesProvider),
      );
    }

    // Desktop layout
    return Row(
      children: [
        // Notes list
        Container(
          width: 340,
          margin: const EdgeInsets.all(16),
          decoration: AppTheme.glassDecoration,
          child: _buildNotesList(privateNotes, notesProvider),
        ),
        
        // Note detail
        Expanded(
          child: Container(
            margin: const EdgeInsets.fromLTRB(0, 16, 16, 16),
            child: notesProvider.selectedNote != null
                ? NoteDetailView(
                    key: ValueKey(notesProvider.selectedNote!.id),
                    note: notesProvider.selectedNote!,
                  )
                : _buildSelectNoteState(),
          ),
        ),
      ],
    );
  }

  Widget _buildNotesList(List privateNotes, NotesProvider notesProvider) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppTheme.accentGreen.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  Icons.security_rounded,
                  color: AppTheme.accentGreen,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Text(
                '${privateNotes.length} ghi chú riêng tư',
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
        Divider(height: 1, color: Colors.grey.shade200),
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: privateNotes.length,
            itemBuilder: (context, index) {
              final note = privateNotes[index];
              return NoteCard(
                note: note,
                isSelected: notesProvider.selectedNote?.id == note.id,
                onTap: () => notesProvider.selectNote(note),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.folder_off_rounded,
            size: 80,
            color: AppTheme.textHint.withValues(alpha: 0.5),
          ),
          const SizedBox(height: 16),
          Text(
            'Không có ghi chú riêng tư',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              color: AppTheme.textHint,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Chuyển ghi chú sang riêng tư từ màn hình chính',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: AppTheme.textHint.withValues(alpha: 0.7),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSelectNoteState() {
    return Container(
      decoration: AppTheme.glassDecoration,
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.touch_app_rounded,
              size: 80,
              color: AppTheme.textHint.withValues(alpha: 0.5),
            ),
            const SizedBox(height: 16),
            Text(
              'Chọn một ghi chú để xem',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: AppTheme.textHint,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
