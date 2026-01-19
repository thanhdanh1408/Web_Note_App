import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../viewmodels/auth_viewmodel_supabase.dart';
import '../../viewmodels/notes_viewmodel_supabase.dart';
import '../../theme/app_theme.dart';
import '../../widgets/note_card.dart';
import '../../widgets/note_detail_view.dart';
import '../../widgets/search_filter_bar.dart';
import '../private/private_notes_screen.dart';
import '../profile/profile_screen.dart';

/// Main home screen with split layout
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  @override
  void initState() {
    super.initState();
    // Use addPostFrameCallback to avoid calling setState during build
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadNotes();
    });
  }

  Future<void> _loadNotes() async {
    if (!mounted) return;
    
    final authViewModel = context.read<AuthViewModelSupabase>();
    print('HomeScreen - User logged in: ${authViewModel.isLoggedIn}');
    print('HomeScreen - User ID: ${authViewModel.userId}');
    
    final notesViewModel = context.read<NotesViewModelSupabase>();
    await notesViewModel.loadNotes();
  }

  @override
  Widget build(BuildContext context) {
    final authViewModel = context.watch<AuthViewModelSupabase>();
    final notesViewModel = context.watch<NotesViewModelSupabase>();
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 768;

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: AppTheme.backgroundGradient,
        ),
        child: SafeArea(
          child: Column(
            children: [
              // Header
              _buildHeader(authViewModel),
              
              // Main content
              Expanded(
                child: isMobile
                    ? _buildMobileLayout(notesViewModel, authViewModel)
                    : _buildDesktopLayout(notesViewModel, authViewModel),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(AuthViewModelSupabase authViewModel) {
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
          // Logo
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              gradient: AppTheme.primaryGradient,
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(
              Icons.note_alt_rounded,
              color: Colors.white,
              size: 24,
            ),
          ),
          const SizedBox(width: 12),
          
          // App name
          Text(
            'NotesApp',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
              color: AppTheme.textPrimary,
            ),
          ),
          
          const Spacer(),
          
          // User profile button
          Tooltip(
            message: 'Hồ sơ người dùng',
            child: IconButton(
              icon: CircleAvatar(
                radius: 16,
                backgroundColor: AppTheme.primaryColor,
                child: Text(
                  authViewModel.username.isNotEmpty 
                      ? authViewModel.username[0].toUpperCase() 
                      : '?',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const ProfileScreen(),
                  ),
                );
              },
            ),
          ),
          const SizedBox(width: 8),
          
          // User greeting
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: AppTheme.cardColor,
              borderRadius: BorderRadius.circular(30),
            ),
            child: Row(
              children: [
                Text(
                  'Xin chào, ${authViewModel.username}',
                  style: TextStyle(
                    color: AppTheme.textPrimary,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          
          // SAFE button
          Tooltip(
            message: 'Ghi chú riêng tư',
            child: ElevatedButton.icon(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const PrivateNotesScreen(),
                  ),
                );
              },
              icon: const Icon(Icons.lock_rounded, size: 18),
              label: const Text('SAFE'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.accentGreen,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              ),
            ),
          ),
          const SizedBox(width: 8),
          
          // Logout button
          Tooltip(
            message: 'Đăng xuất',
            child: IconButton(
              icon: const Icon(Icons.logout_rounded),
              color: AppTheme.accentRed,
              onPressed: () => _confirmLogout(authViewModel),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDesktopLayout(NotesViewModelSupabase notesViewModel, AuthViewModelSupabase authViewModel) {
    return Row(
      children: [
        // Sidebar - Notes list
        Container(
          width: 360,
          margin: const EdgeInsets.all(16),
          decoration: AppTheme.glassDecoration,
          child: _buildSidebar(notesViewModel, authViewModel),
        ),
        
        // Main content - Note detail
        Expanded(
          child: Container(
            margin: const EdgeInsets.fromLTRB(0, 16, 16, 16),
            child: notesViewModel.selectedNote != null
                ? NoteDetailView(
                    key: ValueKey(notesViewModel.selectedNote!.id),
                    note: notesViewModel.selectedNote!,
                  )
                : _buildEmptyState(),
          ),
        ),
      ],
    );
  }

  Widget _buildMobileLayout(NotesViewModelSupabase notesViewModel, AuthViewModelSupabase authViewModel) {
    // On mobile, show either the list or the detail
    if (notesViewModel.selectedNote != null) {
      return Column(
        children: [
          // Back button
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.arrow_back),
                  onPressed: () => notesViewModel.selectNote(null),
                ),
                const Text('Quay lại danh sách'),
              ],
            ),
          ),
          Expanded(
            child: Container(
              margin: const EdgeInsets.all(16),
              child: NoteDetailView(
                key: ValueKey(notesViewModel.selectedNote!.id),
                note: notesViewModel.selectedNote!,
              ),
            ),
          ),
        ],
      );
    }

    return Container(
      margin: const EdgeInsets.all(16),
      decoration: AppTheme.glassDecoration,
      child: _buildSidebar(notesViewModel, authViewModel),
    );
  }

  Widget _buildSidebar(NotesViewModelSupabase notesViewModel, AuthViewModelSupabase authViewModel) {
    return Column(
      children: [
        // Search and filter
        Padding(
          padding: const EdgeInsets.all(16),
          child: SearchFilterBar(
            searchQuery: notesViewModel.searchQuery,
            selectedColor: notesViewModel.colorFilter,
            onSearchChanged: notesViewModel.setSearchQuery,
            onColorSelected: notesViewModel.setColorFilter,
          ),
        ),
        
        // Add note button
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () async {
                final note = await notesViewModel.createNote();
                if (note == null && notesViewModel.error != null) {
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(notesViewModel.error!),
                        backgroundColor: Colors.red,
                      ),
                    );
                  }
                }
              },
              icon: const Icon(Icons.add_rounded),
              label: const Text('Tạo ghi chú mới'),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
            ),
          ),
        ),
        
        const SizedBox(height: 12),
        Divider(height: 1, color: Colors.grey.shade200),
        
        // Notes list
        Expanded(
          child: notesViewModel.isLoading
              ? const Center(child: CircularProgressIndicator())
              : notesViewModel.notes.isEmpty
                  ? _buildEmptyListState()
                  : ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: notesViewModel.notes.length,
                      itemBuilder: (context, index) {
                        final note = notesViewModel.notes[index];
                        return NoteCard(
                          note: note,
                          isSelected: notesViewModel.selectedNote?.id == note.id,
                          onTap: () => notesViewModel.selectNote(note),
                        );
                      },
                    ),
        ),
      ],
    );
  }

  Widget _buildEmptyState() {
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
            const SizedBox(height: 8),
            Text(
              'Hoặc tạo ghi chú mới từ sidebar bên trái',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: AppTheme.textHint.withValues(alpha: 0.7),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyListState() {
    final notesViewModel = context.read<NotesViewModelSupabase>();
    final hasFilters = notesViewModel.searchQuery.isNotEmpty || 
                       notesViewModel.colorFilter != null;
    
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            hasFilters ? Icons.search_off_rounded : Icons.note_add_rounded,
            size: 64,
            color: AppTheme.textHint.withValues(alpha: 0.5),
          ),
          const SizedBox(height: 16),
          Text(
            hasFilters 
                ? 'Không tìm thấy ghi chú' 
                : 'Chưa có ghi chú nào',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              color: AppTheme.textHint,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            hasFilters
                ? 'Thử thay đổi bộ lọc'
                : 'Hãy tạo ghi chú đầu tiên!',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: AppTheme.textHint.withValues(alpha: 0.7),
            ),
          ),
          if (hasFilters) ...[
            const SizedBox(height: 16),
            TextButton.icon(
              onPressed: () => notesViewModel.clearFilters(),
              icon: const Icon(Icons.clear_all),
              label: const Text('Xóa bộ lọc'),
            ),
          ],
        ],
      ),
    );
  }

  Future<void> _confirmLogout(AuthViewModelSupabase authViewModel) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        title: const Text('Đăng xuất?'),
        content: const Text('Bạn có chắc muốn đăng xuất khỏi ứng dụng?'),
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
            child: const Text('Đăng xuất'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await authViewModel.logout();
    }
  }
}
