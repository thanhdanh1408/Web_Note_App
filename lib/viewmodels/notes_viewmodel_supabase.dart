import 'package:flutter/material.dart';
import '../models/note.dart';
import '../services/supabase_service.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// ViewModel for notes with Supabase (MVVM Architecture)
class NotesViewModelSupabase extends ChangeNotifier {
  final SupabaseService _supabaseService;
  
  List<Note> _notes = [];
  Note? _selectedNote;
  String _searchQuery = '';
  NoteColorTag? _colorFilter;
  bool _isLoading = false;
  String? _error;
  RealtimeChannel? _notesSubscription;

  NotesViewModelSupabase(this._supabaseService);

  // Getters
  List<Note> get notes => _getFilteredNotes();
  Note? get selectedNote => _selectedNote;
  String get searchQuery => _searchQuery;
  NoteColorTag? get colorFilter => _colorFilter;
  bool get isLoading => _isLoading;
  String? get error => _error;

  /// Get filtered and sorted notes
  List<Note> _getFilteredNotes() {
    List<Note> result = List.from(_notes);
    
    // Filter out private notes (they go to SAFE section)
    result = result.where((note) => !note.isPrivate).toList();

    // Apply search filter
    if (_searchQuery.isNotEmpty) {
      final query = _searchQuery.toLowerCase();
      result = result.where((note) {
        return note.title.toLowerCase().contains(query) ||
            note.plainText.toLowerCase().contains(query);
      }).toList();
    }

    // Apply color filter
    if (_colorFilter != null && _colorFilter != NoteColorTag.none) {
      result = result.where((note) => note.colorTag == _colorFilter).toList();
    }

    // Sort: pinned first, then by updated date
    result.sort((a, b) {
      if (a.isPinned && !b.isPinned) return -1;
      if (!a.isPinned && b.isPinned) return 1;
      return b.updatedAt.compareTo(a.updatedAt);
    });

    return result;
  }

  /// Get private notes
  List<Note> get privateNotes {
    return _notes.where((note) => note.isPrivate).toList()
      ..sort((a, b) {
        if (a.isPinned && !b.isPinned) return -1;
        if (!a.isPinned && b.isPinned) return 1;
        return b.updatedAt.compareTo(a.updatedAt);
      });
  }

  /// Load notes from Supabase
  Future<void> loadNotes() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _notes = await _supabaseService.getNotes(includePrivate: true);
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _error = 'Không thể tải ghi chú: ${e.toString()}';
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Load private notes only
  Future<void> loadPrivateNotes() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final privateNotesList = await _supabaseService.getPrivateNotes();
      // Update private notes in the main list
      _notes.removeWhere((note) => note.isPrivate);
      _notes.addAll(privateNotesList);
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _error = 'Không thể tải ghi chú riêng tư: ${e.toString()}';
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Create a new note
  Future<Note?> createNote() async {
    _error = null;
    
    try {
      // Check if user is logged in
      final user = _supabaseService.currentUser;
      print('CreateNote - currentUser: ${user?.id}');
      
      if (user == null) {
        _error = 'Vui lòng đăng nhập để tạo ghi chú';
        notifyListeners();
        return null;
      }
      
      final newNote = Note.create(
        userId: user.id,
      );
      
      print('Creating note with userId: ${user.id}');
      final createdNote = await _supabaseService.createNote(newNote);
      print('Note created: ${createdNote.id}');
      
      _notes.add(createdNote);
      _selectedNote = createdNote;
      notifyListeners();
      return createdNote;
    } catch (e) {
      print('CreateNote error: $e');
      _error = 'Không thể tạo ghi chú: ${e.toString()}';
      notifyListeners();
      return null;
    }
  }

  /// Select a note
  void selectNote(Note? note) {
    _selectedNote = note;
    notifyListeners();
  }

  /// Update a note
  Future<bool> updateNote(Note note) async {
    _error = null;
    
    try {
      final updatedNote = await _supabaseService.updateNote(note);
      
      final index = _notes.indexWhere((n) => n.id == note.id);
      if (index != -1) {
        _notes[index] = updatedNote;
      }
      
      if (_selectedNote?.id == note.id) {
        _selectedNote = updatedNote;
      }
      
      notifyListeners();
      return true;
    } catch (e) {
      _error = 'Không thể cập nhật ghi chú: ${e.toString()}';
      notifyListeners();
      return false;
    }
  }

  /// Delete a note
  Future<bool> deleteNote(String noteId) async {
    _error = null;
    
    try {
      await _supabaseService.deleteNote(noteId);
      _notes.removeWhere((n) => n.id == noteId);
      
      if (_selectedNote?.id == noteId) {
        _selectedNote = null;
      }
      
      notifyListeners();
      return true;
    } catch (e) {
      _error = 'Không thể xóa ghi chú: ${e.toString()}';
      notifyListeners();
      return false;
    }
  }

  /// Toggle pin status
  Future<void> togglePin(Note note) async {
    final updated = note.copyWith(
      isPinned: !note.isPinned,
      updatedAt: DateTime.now(),
    );
    await updateNote(updated);
  }

  /// Toggle private status
  Future<void> togglePrivate(Note note) async {
    final updated = note.copyWith(
      isPrivate: !note.isPrivate,
      updatedAt: DateTime.now(),
    );
    await updateNote(updated);
  }

  /// Update color tag
  Future<void> updateColorTag(Note note, NoteColorTag colorTag) async {
    final updated = note.copyWith(
      colorTag: colorTag,
      updatedAt: DateTime.now(),
    );
    await updateNote(updated);
  }

  /// Set search query
  void setSearchQuery(String query) {
    _searchQuery = query;
    notifyListeners();
  }

  /// Clear search
  void clearSearch() {
    _searchQuery = '';
    notifyListeners();
  }

  /// Set color filter
  void setColorFilter(NoteColorTag? colorTag) {
    _colorFilter = colorTag;
    notifyListeners();
  }

  /// Clear all filters
  void clearFilters() {
    _searchQuery = '';
    _colorFilter = null;
    notifyListeners();
  }

  /// Search notes using Supabase function
  Future<void> searchNotesInSupabase(String query) async {
    if (query.isEmpty) {
      await loadNotes();
      return;
    }

    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final results = await _supabaseService.searchNotes(query);
      _notes = results;
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _error = 'Không thể tìm kiếm: ${e.toString()}';
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Filter notes by color using Supabase function
  Future<void> filterByColorInSupabase(NoteColorTag colorTag) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final results = await _supabaseService.filterNotesByColor(colorTag);
      _notes = results;
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _error = 'Không thể lọc: ${e.toString()}';
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Subscribe to realtime updates
  void subscribeToRealtimeUpdates() {
    try {
      _notesSubscription = _supabaseService.subscribeToNotes(
        onData: (updatedNotes) {
          _notes = updatedNotes;
          notifyListeners();
        },
      );
    } catch (e) {
      debugPrint('Failed to subscribe to realtime updates: $e');
    }
  }

  /// Unsubscribe from realtime updates
  void unsubscribeFromRealtimeUpdates() {
    _notesSubscription?.unsubscribe();
    _notesSubscription = null;
  }

  /// Clear error
  void clearError() {
    _error = null;
    notifyListeners();
  }

  @override
  void dispose() {
    unsubscribeFromRealtimeUpdates();
    super.dispose();
  }
}
