import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/user.dart';
import '../models/note.dart';

/// Service for local storage operations
class LocalStorageService {
  static const String _usersKey = 'users';
  static const String _notesKey = 'notes';
  static const String _currentUserKey = 'currentUser';
  static const String _safePasswordKey = 'safePassword'; // Shared SAFE password per user

  late SharedPreferences _prefs;

  /// Initialize the service
  Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
  }

  // ==================== USER OPERATIONS ====================

  /// Get all registered users
  List<AppUser> getUsers() {
    final String? usersJson = _prefs.getString(_usersKey);
    if (usersJson == null) return [];

    final List<dynamic> usersList = jsonDecode(usersJson);
    return usersList.map((json) => AppUser.fromJson(json)).toList();
  }

  /// Save users to local storage
  Future<void> saveUsers(List<AppUser> users) async {
    final String usersJson = jsonEncode(users.map((u) => u.toJson()).toList());
    await _prefs.setString(_usersKey, usersJson);
  }

  /// Add a new user
  Future<void> addUser(AppUser user) async {
    final users = getUsers();
    users.add(user);
    await saveUsers(users);
  }

  /// Get user by username
  AppUser? getUserByUsername(String username) {
    final users = getUsers();
    try {
      return users.firstWhere((u) => u.username == username);
    } catch (e) {
      return null;
    }
  }

  /// Save current logged in user
  Future<void> saveCurrentUser(AppUser? user) async {
    if (user == null) {
      await _prefs.remove(_currentUserKey);
    } else {
      await _prefs.setString(_currentUserKey, jsonEncode(user.toJson()));
    }
  }

  /// Get current logged in user
  AppUser? getCurrentUser() {
    final String? userJson = _prefs.getString(_currentUserKey);
    if (userJson == null) return null;
    return AppUser.fromJson(jsonDecode(userJson));
  }

  // ==================== SAFE PASSWORD OPERATIONS ====================

  /// Get SAFE password for a user
  String? getSafePassword(String userId) {
    final key = '${_safePasswordKey}_$userId';
    return _prefs.getString(key);
  }

  /// Set SAFE password for a user
  Future<void> setSafePassword(String userId, String password) async {
    final key = '${_safePasswordKey}_$userId';
    await _prefs.setString(key, password);
  }

  /// Check if SAFE password is configured for a user
  bool hasSafePassword(String userId) {
    return getSafePassword(userId) != null;
  }

  /// Verify SAFE password
  bool verifySafePassword(String userId, String password) {
    final storedPassword = getSafePassword(userId);
    return storedPassword == password;
  }

  // ==================== NOTES OPERATIONS ====================

  /// Get all notes
  List<Note> getAllNotes() {
    final String? notesJson = _prefs.getString(_notesKey);
    if (notesJson == null) return [];

    final List<dynamic> notesList = jsonDecode(notesJson);
    return notesList.map((json) => Note.fromJson(json)).toList();
  }

  /// Get notes for a specific user
  List<Note> getNotesForUser(String userId, {bool includePrivate = true}) {
    final allNotes = getAllNotes();
    return allNotes.where((note) {
      if (note.userId != userId) return false;
      if (!includePrivate && note.isPrivate) return false;
      return true;
    }).toList();
  }

  /// Save all notes
  Future<void> saveAllNotes(List<Note> notes) async {
    final String notesJson = jsonEncode(notes.map((n) => n.toJson()).toList());
    await _prefs.setString(_notesKey, notesJson);
  }

  /// Add a new note
  Future<void> addNote(Note note) async {
    final notes = getAllNotes();
    notes.add(note);
    await saveAllNotes(notes);
  }

  /// Update a note
  Future<void> updateNote(Note updatedNote) async {
    final notes = getAllNotes();
    final index = notes.indexWhere((n) => n.id == updatedNote.id);
    if (index != -1) {
      notes[index] = updatedNote;
      await saveAllNotes(notes);
    }
  }

  /// Delete a note
  Future<void> deleteNote(String noteId) async {
    final notes = getAllNotes();
    notes.removeWhere((n) => n.id == noteId);
    await saveAllNotes(notes);
  }

  /// Get a single note by ID
  Note? getNoteById(String noteId) {
    final notes = getAllNotes();
    try {
      return notes.firstWhere((n) => n.id == noteId);
    } catch (e) {
      return null;
    }
  }

  /// Search notes by title or content
  List<Note> searchNotes(String userId, String query) {
    final userNotes = getNotesForUser(userId, includePrivate: false);
    final lowerQuery = query.toLowerCase();
    return userNotes.where((note) {
      return note.title.toLowerCase().contains(lowerQuery) ||
          note.plainText.toLowerCase().contains(lowerQuery);
    }).toList();
  }

  /// Filter notes by color tag
  List<Note> filterNotesByColor(String userId, NoteColorTag colorTag) {
    final userNotes = getNotesForUser(userId, includePrivate: false);
    if (colorTag == NoteColorTag.none) return userNotes;
    return userNotes.where((note) => note.colorTag == colorTag).toList();
  }

  /// Get private notes for user
  List<Note> getPrivateNotes(String userId) {
    final allNotes = getAllNotes();
    return allNotes.where((note) => 
      note.userId == userId && note.isPrivate
    ).toList();
  }

  /// Clear all data (for testing)
  Future<void> clearAll() async {
    await _prefs.clear();
  }
}
