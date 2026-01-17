import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_quill/flutter_quill.dart';
import 'package:provider/provider.dart';
import '../models/note.dart';
import '../providers/auth_provider.dart';
import '../providers/notes_provider.dart';
import '../theme/app_theme.dart';
import 'password_dialog.dart';

/// Note detail view with rich text editor
class NoteDetailView extends StatefulWidget {
  final Note note;

  const NoteDetailView({
    super.key,
    required this.note,
  });

  @override
  State<NoteDetailView> createState() => _NoteDetailViewState();
}

class _NoteDetailViewState extends State<NoteDetailView> {
  late TextEditingController _titleController;
  late QuillController _quillController;
  late FocusNode _editorFocusNode;
  bool _hasChanges = false;

  @override
  void initState() {
    super.initState();
    _initControllers();
  }

  void _initControllers() {
    _titleController = TextEditingController(text: widget.note.title);
    _editorFocusNode = FocusNode();
    
    // Parse content JSON
    Document document;
    try {
      final contentJson = jsonDecode(widget.note.contentJson);
      if (contentJson is List && contentJson.isNotEmpty) {
        document = Document.fromJson(contentJson);
      } else {
        document = Document();
      }
    } catch (e) {
      document = Document();
    }
    
    _quillController = QuillController(
      document: document,
      selection: const TextSelection.collapsed(offset: 0),
    );

    // Listen for changes
    _titleController.addListener(_onContentChanged);
    _quillController.addListener(_onContentChanged);
  }

  @override
  void didUpdateWidget(NoteDetailView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.note.id != widget.note.id) {
      _saveNote(); // Save previous note
      _disposeControllers();
      _initControllers();
      setState(() {
        _hasChanges = false;
      });
    }
  }

  void _disposeControllers() {
    _titleController.removeListener(_onContentChanged);
    _quillController.removeListener(_onContentChanged);
    _titleController.dispose();
    _quillController.dispose();
    _editorFocusNode.dispose();
  }

  @override
  void dispose() {
    _saveNote();
    _disposeControllers();
    super.dispose();
  }

  void _onContentChanged() {
    if (!_hasChanges) {
      setState(() {
        _hasChanges = true;
      });
    }
  }

  Future<void> _saveNote() async {
    if (!_hasChanges || !mounted) return;

    final notesProvider = context.read<NotesProvider>();
    final contentJson = jsonEncode(_quillController.document.toDelta().toJson());
    final plainText = _quillController.document.toPlainText();

    final updatedNote = widget.note.copyWith(
      title: _titleController.text,
      contentJson: contentJson,
      plainText: plainText,
      updatedAt: DateTime.now(),
    );

    await notesProvider.updateNote(updatedNote);
    if (mounted) {
      setState(() {
        _hasChanges = false;
      });
    }
  }

  String _formatDateTime(DateTime dateTime) {
    return '${dateTime.day}/${dateTime.month}/${dateTime.year} ${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final notesProvider = context.watch<NotesProvider>();
    final colorTag = widget.note.colorTag;
    
    // Background color based on note's color tag
    final backgroundColor = Color(colorTag.lightColorValue);

    return Container(
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Color(colorTag.colorValue).withValues(alpha: 0.3),
          width: 2,
        ),
        boxShadow: [
          BoxShadow(
            color: Color(colorTag.colorValue).withValues(alpha: 0.1),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        children: [
          // Toolbar
          _buildToolbar(notesProvider),
          Divider(height: 1, color: Color(colorTag.colorValue).withValues(alpha: 0.2)),
          
          // Title input
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
            child: TextField(
              controller: _titleController,
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
                color: AppTheme.textPrimary,
              ),
              decoration: const InputDecoration(
                hintText: 'Tiêu đề ghi chú...',
                border: InputBorder.none,
                fillColor: Colors.transparent,
                filled: false,
                contentPadding: EdgeInsets.zero,
              ),
              maxLines: 1,
            ),
          ),
          
          // Rich text editor
          Expanded(
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 20),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey.shade200),
              ),
              child: QuillEditor.basic(
                controller: _quillController,
                focusNode: _editorFocusNode,
                config: QuillEditorConfig(
                  placeholder: 'Bắt đầu viết ghi chú của bạn...',
                  padding: const EdgeInsets.only(bottom: 20),
                  autoFocus: false,
                  expands: true,
                  customStyles: DefaultStyles(
                    paragraph: DefaultTextBlockStyle(
                      TextStyle(
                        color: AppTheme.textPrimary,
                        fontSize: 16,
                        height: 1.6,
                      ),
                      const HorizontalSpacing(0, 0),
                      const VerticalSpacing(8, 0),
                      const VerticalSpacing(0, 0),
                      null,
                    ),
                  ),
                ),
              ),
            ),
          ),
          
          // Quill toolbar
          Container(
            margin: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppTheme.cardColor,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey.shade300),
            ),
            child: Theme(
              data: Theme.of(context).copyWith(
                iconTheme: IconThemeData(
                  color: AppTheme.textPrimary,
                  size: 20,
                ),
              ),
              child: QuillSimpleToolbar(
                controller: _quillController,
                config: const QuillSimpleToolbarConfig(
                  showBoldButton: true,
                  showItalicButton: true,
                  showUnderLineButton: true,
                  showStrikeThrough: true,
                  showListBullets: true,
                  showListNumbers: true,
                  showListCheck: true,
                  showCodeBlock: false,
                  showQuote: true,
                  showLink: false,
                  showUndo: true,
                  showRedo: true,
                  showFontFamily: false,
                  showFontSize: false,
                  showBackgroundColorButton: false,
                  showColorButton: false,
                  showClearFormat: true,
                  showAlignmentButtons: false,
                  showHeaderStyle: true,
                  showIndent: false,
                  showDividers: true,
                  showSearchButton: false,
                  showSubscript: false,
                  showSuperscript: false,
                  showSmallButton: false,
                  showInlineCode: false,
                  showDirection: false,
                ),
              ),
            ),
          ),
          
          // Footer with timestamp
          _buildFooter(),
        ],
      ),
    );
  }

  Widget _buildToolbar(NotesProvider notesProvider) {
    final note = widget.note;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          // Color tag selector
          _ColorTagButton(
            currentColor: note.colorTag,
            onColorSelected: (color) {
              notesProvider.updateColorTag(note, color);
            },
          ),
          const SizedBox(width: 8),
          
          // Pin button
          IconButton(
            icon: Icon(
              note.isPinned ? Icons.push_pin_rounded : Icons.push_pin_outlined,
              color: note.isPinned ? AppTheme.accentYellow : AppTheme.textSecondary,
            ),
            tooltip: note.isPinned ? 'Bỏ ghim' : 'Ghim ghi chú',
            onPressed: () => notesProvider.togglePin(note),
          ),
          
          // Private button
          IconButton(
            icon: Icon(
              note.isPrivate ? Icons.lock_rounded : Icons.lock_outline,
              color: note.isPrivate ? AppTheme.accentGreen : AppTheme.textSecondary,
            ),
            tooltip: note.isPrivate ? 'Bỏ riêng tư' : 'Chuyển sang SAFE',
            onPressed: () => _togglePrivate(notesProvider),
          ),
          
          const Spacer(),
          
          // Save indicator
          if (_hasChanges)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: AppTheme.accentYellow.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.edit_rounded,
                    size: 14,
                    color: AppTheme.accentYellow,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    'Đang chỉnh sửa',
                    style: TextStyle(
                      color: AppTheme.accentYellow,
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          
          const SizedBox(width: 8),
          
          // Save button
          ElevatedButton.icon(
            onPressed: _hasChanges ? _saveNote : null,
            icon: const Icon(Icons.save_outlined, size: 18),
            label: const Text('Lưu'),
            style: ElevatedButton.styleFrom(
              backgroundColor: _hasChanges ? AppTheme.primaryColor : Colors.grey.shade300,
              foregroundColor: _hasChanges ? Colors.white : AppTheme.textSecondary,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            ),
          ),
          
          const SizedBox(width: 8),
          
          // Delete button
          IconButton(
            icon: const Icon(Icons.delete_outline),
            color: AppTheme.accentRed,
            tooltip: 'Xóa ghi chú',
            onPressed: () => _confirmDelete(notesProvider),
          ),
        ],
      ),
    );
  }

  Widget _buildFooter() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.5),
        borderRadius: const BorderRadius.vertical(
          bottom: Radius.circular(16),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.update_rounded,
            size: 14,
            color: AppTheme.textHint,
          ),
          const SizedBox(width: 6),
          Text(
            'Cập nhật lần cuối: ${_formatDateTime(widget.note.updatedAt)}',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: AppTheme.textHint,
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _togglePrivate(NotesProvider notesProvider) async {
    final note = widget.note;
    final authProvider = context.read<AuthProvider>();
    final userId = authProvider.currentUser?.id ?? '';
    
    if (note.isPrivate) {
      // Remove from SAFE - just toggle off
      await notesProvider.togglePrivate(note);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Đã bỏ chế độ riêng tư'),
            backgroundColor: AppTheme.accentGreen,
          ),
        );
      }
    } else {
      // Check if SAFE password is configured
      if (!notesProvider.hasSafePassword(userId)) {
        // Need to configure SAFE password first
        final password = await PasswordDialog.show(
          context,
          title: 'Cấu hình mật khẩu SAFE',
          subtitle: 'Bạn cần đặt mật khẩu SAFE trước khi sử dụng tính năng này',
          isSetPassword: true,
        );
        
        if (password != null) {
          await notesProvider.setSafePassword(userId, password);
          // Now add to SAFE
          await notesProvider.togglePrivate(note);
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Đã cấu hình SAFE và chuyển ghi chú vào SAFE'),
                backgroundColor: AppTheme.accentGreen,
              ),
            );
          }
        }
      } else {
        // SAFE password already configured, just add to SAFE
        await notesProvider.togglePrivate(note);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Đã chuyển ghi chú vào SAFE'),
              backgroundColor: AppTheme.accentGreen,
            ),
          );
        }
      }
    }
  }

  Future<void> _confirmDelete(NotesProvider notesProvider) async {
    final note = widget.note;
    final authProvider = context.read<AuthProvider>();
    final userId = authProvider.currentUser?.id ?? '';
    
    // If private note, require SAFE password first
    if (note.isPrivate) {
      final password = await PasswordDialog.show(
        context,
        title: 'Xác nhận mật khẩu SAFE',
        subtitle: 'Nhập mật khẩu SAFE để xóa ghi chú riêng tư',
      );
      
      if (password == null) return;
      
      if (!notesProvider.verifySafePassword(userId, password)) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Mật khẩu SAFE không đúng'),
              backgroundColor: AppTheme.accentRed,
            ),
          );
        }
        return;
      }
    }
    
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        title: const Text('Xóa ghi chú?'),
        content: const Text('Bạn có chắc muốn xóa ghi chú này? Hành động này không thể hoàn tác.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Hủy'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.accentRed,
            ),
            child: const Text('Xóa'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      _hasChanges = false; // Prevent save on dispose
      await notesProvider.deleteNote(widget.note.id);
    }
  }
}

/// Color tag button with dropdown
class _ColorTagButton extends StatelessWidget {
  final NoteColorTag currentColor;
  final Function(NoteColorTag) onColorSelected;

  const _ColorTagButton({
    required this.currentColor,
    required this.onColorSelected,
  });

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<NoteColorTag>(
      tooltip: 'Chọn màu tag',
      offset: const Offset(0, 40),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      color: Colors.white,
      initialValue: currentColor,
      onSelected: onColorSelected,
      itemBuilder: (context) => NoteColorTag.values.map((colorTag) {
        final isSelected = colorTag == currentColor;
        return PopupMenuItem<NoteColorTag>(
          value: colorTag,
          child: Row(
            children: [
              Container(
                width: 24,
                height: 24,
                decoration: BoxDecoration(
                  color: Color(colorTag.colorValue),
                  shape: BoxShape.circle,
                  border: colorTag == NoteColorTag.none
                      ? Border.all(color: AppTheme.textHint, width: 2)
                      : null,
                ),
                child: colorTag == NoteColorTag.none
                    ? const Icon(Icons.block, size: 14, color: AppTheme.textHint)
                    : null,
              ),
              const SizedBox(width: 12),
              Text(
                colorTag.name,
                style: TextStyle(
                  color: isSelected ? AppTheme.primaryColor : AppTheme.textPrimary,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                ),
              ),
              if (isSelected) ...[
                const Spacer(),
                Icon(Icons.check, size: 18, color: AppTheme.primaryColor),
              ],
            ],
          ),
        );
      }).toList(),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: Color(currentColor.lightColorValue),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: Color(currentColor.colorValue),
            width: 2,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 16,
              height: 16,
              decoration: BoxDecoration(
                color: Color(currentColor.colorValue),
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 8),
            Text(
              currentColor.name,
              style: TextStyle(
                color: Color(currentColor.colorValue),
                fontWeight: FontWeight.w600,
                fontSize: 13,
              ),
            ),
            const SizedBox(width: 4),
            Icon(
              Icons.arrow_drop_down,
              color: Color(currentColor.colorValue),
              size: 20,
            ),
          ],
        ),
      ),
    );
  }
}
