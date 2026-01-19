import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/note.dart';
import '../models/user.dart';

/// Service for Supabase operations
class SupabaseService {
  final SupabaseClient _client = Supabase.instance.client;

  // ==================== AUTH OPERATIONS ====================

  /// Get current user
  User? get currentUser => _client.auth.currentUser;

  /// Check if user is logged in
  bool get isLoggedIn => currentUser != null;

  /// Sign up with email and password
  Future<AuthResponse> signUp({
    required String email,
    required String password,
    required String username,
  }) async {
    return await _client.auth.signUp(
      email: email,
      password: password,
      data: {'username': username},
    );
  }

  /// Sign in with email and password
  Future<AuthResponse> signIn({
    required String email,
    required String password,
  }) async {
    return await _client.auth.signInWithPassword(
      email: email,
      password: password,
    );
  }

  /// Sign out
  Future<void> signOut() async {
    await _client.auth.signOut();
  }

  /// Get auth state changes stream
  Stream<AuthState> get authStateChanges => _client.auth.onAuthStateChange;

  /// Update user password
  Future<void> updatePassword(String newPassword) async {
    await _client.auth.updateUser(
      UserAttributes(password: newPassword),
    );
  }

  /// Verify current password by attempting to sign in
  Future<bool> verifyCurrentPassword(String email, String password) async {
    try {
      // Store the current session
      final currentSession = _client.auth.currentSession;
      
      // Try to sign in with the provided credentials
      final response = await _client.auth.signInWithPassword(
        email: email,
        password: password,
      );
      
      // If sign in successful, the password is correct
      // Note: This will create a new session, but we're already logged in
      return response.user != null;
    } catch (e) {
      // If sign in fails, password is incorrect
      return false;
    }
  }

  // ==================== PROFILE OPERATIONS ====================

  /// Get user profile
  Future<Map<String, dynamic>?> getProfile(String userId) async {
    final response = await _client
        .from('profiles')
        .select()
        .eq('id', userId)
        .single();
    return response;
  }

  /// Update user profile
  Future<void> updateProfile({
    required String userId,
    required String username,
  }) async {
    await _client.from('profiles').update({
      'username': username,
      'updated_at': DateTime.now().toIso8601String(),
    }).eq('id', userId);
  }

  // ==================== NOTES OPERATIONS ====================

  /// Get all notes for current user
  Future<List<Note>> getNotes({bool includePrivate = true}) async {
    final userId = currentUser?.id;
    if (userId == null) throw Exception('User not logged in');

    PostgrestFilterBuilder query = _client
        .from('notes')
        .select()
        .eq('user_id', userId);

    if (!includePrivate) {
      query = query.eq('is_private', false);
    }

    final List<dynamic> data = await query
        .order('is_pinned', ascending: false)
        .order('updated_at', ascending: false);
    
    return data.map((json) => _noteFromSupabaseJson(json)).toList();
  }

  /// Get private notes
  Future<List<Note>> getPrivateNotes() async {
    final userId = currentUser?.id;
    if (userId == null) throw Exception('User not logged in');

    final List<dynamic> data = await _client
        .rpc('get_private_notes', params: {'user_id_param': userId});

    return data.map((json) => _noteFromSupabaseJson(json)).toList();
  }

  /// Get a single note by ID
  Future<Note?> getNoteById(String noteId) async {
    try {
      final data = await _client
          .from('notes')
          .select()
          .eq('id', noteId)
          .single();
      return _noteFromSupabaseJson(data);
    } catch (e) {
      return null;
    }
  }

  /// Create a new note
  Future<Note> createNote(Note note) async {
    final data = await _client.from('notes').insert({
      'user_id': currentUser!.id,
      'title': note.title,
      'content_json': note.contentJson,
      'plain_text': note.plainText,
      'color_tag': note.colorTag.dbValue,
      'is_pinned': note.isPinned,
      'is_private': note.isPrivate,
    }).select().single();

    return _noteFromSupabaseJson(data);
  }

  /// Update an existing note
  Future<Note> updateNote(Note note) async {
    final data = await _client.from('notes').update({
      'title': note.title,
      'content_json': note.contentJson,
      'plain_text': note.plainText,
      'color_tag': note.colorTag.dbValue,
      'is_pinned': note.isPinned,
      'is_private': note.isPrivate,
      'updated_at': DateTime.now().toIso8601String(),
    }).eq('id', note.id).select().single();

    return _noteFromSupabaseJson(data);
  }

  /// Delete a note
  Future<void> deleteNote(String noteId) async {
    await _client.from('notes').delete().eq('id', noteId);
  }

  /// Search notes
  Future<List<Note>> searchNotes(String query) async {
    final userId = currentUser?.id;
    if (userId == null) throw Exception('User not logged in');

    final List<dynamic> data = await _client.rpc(
      'search_notes',
      params: {
        'search_query': query,
        'user_id_param': userId,
      },
    );

    return data.map((json) => _noteFromSupabaseJson(json)).toList();
  }

  /// Filter notes by color tag
  Future<List<Note>> filterNotesByColor(NoteColorTag colorTag) async {
    final userId = currentUser?.id;
    if (userId == null) throw Exception('User not logged in');

    final List<dynamic> data = await _client.rpc(
      'get_notes_by_color',
      params: {
        'color_tag_param': colorTag.dbValue,
        'user_id_param': userId,
      },
    );

    return data.map((json) => _noteFromSupabaseJson(json)).toList();
  }

  // ==================== SAFE PASSWORD OPERATIONS ====================

  /// Check if user has a safe password
  Future<bool> hasSafePassword() async {
    final userId = currentUser?.id;
    if (userId == null) return false;

    try {
      await _client
          .from('safe_passwords')
          .select('user_id')
          .eq('user_id', userId)
          .single();
      return true;
    } catch (e) {
      return false;
    }
  }

  /// Set safe password
  Future<void> setSafePassword(String password) async {
    final userId = currentUser?.id;
    if (userId == null) throw Exception('User not logged in');

    final passwordHash = AppUser.hashPassword(password);

    await _client.from('safe_passwords').upsert({
      'user_id': userId,
      'password_hash': passwordHash,
      'updated_at': DateTime.now().toIso8601String(),
    });
  }

  /// Verify safe password
  Future<bool> verifySafePassword(String password) async {
    final userId = currentUser?.id;
    if (userId == null) return false;

    try {
      final data = await _client
          .from('safe_passwords')
          .select('password_hash')
          .eq('user_id', userId)
          .single();

      final storedHash = data['password_hash'] as String;
      final inputHash = AppUser.hashPassword(password);

      return storedHash == inputHash;
    } catch (e) {
      return false;
    }
  }

  /// Delete safe password
  Future<void> deleteSafePassword() async {
    final userId = currentUser?.id;
    if (userId == null) throw Exception('User not logged in');

    await _client.from('safe_passwords').delete().eq('user_id', userId);
  }

  // ==================== REALTIME SUBSCRIPTIONS ====================

  /// Subscribe to notes changes
  RealtimeChannel subscribeToNotes({
    required void Function(List<Note>) onData,
  }) {
    final userId = currentUser?.id;
    if (userId == null) throw Exception('User not logged in');

    return _client
        .channel('notes_$userId')
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'notes',
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'user_id',
            value: userId,
          ),
          callback: (payload) async {
            // Reload all notes when changes occur
            final notes = await getNotes();
            onData(notes);
          },
        )
        .subscribe();
  }

  // ==================== HELPER METHODS ====================

  /// Convert Supabase JSON to Note model
  Note _noteFromSupabaseJson(Map<String, dynamic> json) {
    return Note(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      title: json['title'] as String? ?? '',
      contentJson: json['content_json'] as String? ?? '[]',
      plainText: json['plain_text'] as String? ?? '',
      colorTag: _parseColorTag(json['color_tag'] as String?),
      isPinned: json['is_pinned'] as bool? ?? false,
      isPrivate: json['is_private'] as bool? ?? false,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
    );
  }

  /// Parse color tag from string
  NoteColorTag _parseColorTag(String? colorTag) {
    if (colorTag == null) return NoteColorTag.none;
    
    switch (colorTag) {
      case 'red':
        return NoteColorTag.red;
      case 'orange':
        return NoteColorTag.orange;
      case 'yellow':
        return NoteColorTag.yellow;
      case 'green':
        return NoteColorTag.green;
      case 'blue':
        return NoteColorTag.blue;
      case 'purple':
        return NoteColorTag.purple;
      case 'pink':
        return NoteColorTag.pink;
      default:
        return NoteColorTag.none;
    }
  }
}
