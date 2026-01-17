import 'package:flutter/material.dart';
import '../models/note.dart';
import '../services/local_storage_service.dart';

/// Provider for notes state management
class NotesProvider extends ChangeNotifier {
  final LocalStorageService _storageService;
  
  List<Note> _notes = [];
  Note? _selectedNote;
  String _searchQuery = '';
  NoteColorTag? _colorFilter;
  bool _isLoading = false;

  NotesProvider(this._storageService);

  // Getters
  List<Note> get notes => _getFilteredNotes();
  Note? get selectedNote => _selectedNote;
  String get searchQuery => _searchQuery;
  NoteColorTag? get colorFilter => _colorFilter;
  bool get isLoading => _isLoading;

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
      ..sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
  }

  /// Load notes for a user
  Future<void> loadNotes(String userId) async {
    _isLoading = true;
    notifyListeners();

    _notes = _storageService.getNotesForUser(userId);
    _isLoading = false;
    notifyListeners();
  }

  /// Create a new note
  Future<Note> createNote(String userId) async {
    final newNote = Note.create(userId: userId);
    await _storageService.addNote(newNote);
    _notes.add(newNote);
    _selectedNote = newNote;
    notifyListeners();
    return newNote;
  }

  /// Select a note
  void selectNote(Note? note) {
    _selectedNote = note;
    notifyListeners();
  }

  /// Update a note
  Future<void> updateNote(Note note) async {
    final updatedNote = note.copyWith(updatedAt: DateTime.now());
    await _storageService.updateNote(updatedNote);
    
    final index = _notes.indexWhere((n) => n.id == note.id);
    if (index != -1) {
      _notes[index] = updatedNote;
    }
    
    if (_selectedNote?.id == note.id) {
      _selectedNote = updatedNote;
    }
    
    notifyListeners();
  }

  /// Delete a note
  Future<void> deleteNote(String noteId) async {
    await _storageService.deleteNote(noteId);
    _notes.removeWhere((n) => n.id == noteId);
    
    if (_selectedNote?.id == noteId) {
      _selectedNote = null;
    }
    
    notifyListeners();
  }

  /// Toggle pin status
  Future<void> togglePin(Note note) async {
    final updatedNote = note.copyWith(
      isPinned: !note.isPinned,
      updatedAt: DateTime.now(),
    );
    await updateNote(updatedNote);
  }

  /// Toggle private status (move to/from SAFE)
  Future<void> togglePrivate(Note note) async {
    final updatedNote = note.copyWith(
      isPrivate: !note.isPrivate,
      updatedAt: DateTime.now(),
    );
    await _storageService.updateNote(updatedNote);
    
    final index = _notes.indexWhere((n) => n.id == note.id);
    if (index != -1) {
      _notes[index] = updatedNote;
    }
    
    if (_selectedNote?.id == note.id) {
      _selectedNote = updatedNote;
    }
    
    notifyListeners();
  }

  /// Update note color tag
  Future<void> updateColorTag(Note note, NoteColorTag colorTag) async {
    final updatedNote = note.copyWith(
      colorTag: colorTag,
      updatedAt: DateTime.now(),
    );
    await updateNote(updatedNote);
  }

  /// Set search query
  void setSearchQuery(String query) {
    _searchQuery = query;
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

  // ==================== SAFE PASSWORD OPERATIONS ====================

  /// Check if SAFE password is configured
  bool hasSafePassword(String userId) {
    return _storageService.hasSafePassword(userId);
  }

  /// Set SAFE password
  Future<void> setSafePassword(String userId, String password) async {
    await _storageService.setSafePassword(userId, password);
  }

  /// Verify SAFE password
  bool verifySafePassword(String userId, String password) {
    return _storageService.verifySafePassword(userId, password);
  }

  /// Get current SAFE password (for change password flow)
  String? getSafePassword(String userId) {
    return _storageService.getSafePassword(userId);
  }
}
