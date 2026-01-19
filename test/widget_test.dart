import 'package:flutter_test/flutter_test.dart';

import 'package:flutter_note_app/services/supabase_service.dart';
import 'package:flutter_note_app/viewmodels/auth_viewmodel_supabase.dart';
import 'package:flutter_note_app/viewmodels/notes_viewmodel_supabase.dart';

void main() {
  group('Supabase MVVM Architecture Tests', () {
    late SupabaseService supabaseService;

    setUp(() async {
      supabaseService = SupabaseService();
    });

    test('AuthViewModelSupabase initializes correctly', () {
      final authViewModel = AuthViewModelSupabase(supabaseService);
      
      expect(authViewModel.isLoggedIn, false);
      expect(authViewModel.currentUser, isNull);
      expect(authViewModel.isLoading, false);
      expect(authViewModel.error, isNull);
    });

    test('NotesViewModelSupabase initializes correctly', () {
      final notesViewModel = NotesViewModelSupabase(supabaseService);
      
      expect(notesViewModel.notes, isEmpty);
      expect(notesViewModel.selectedNote, isNull);
      expect(notesViewModel.isLoading, false);
      expect(notesViewModel.searchQuery, '');
      expect(notesViewModel.colorFilter, isNull);
    });

    // Note: Full integration tests would require Supabase test environment
    test('ViewModels can be created', () {
      final authViewModel = AuthViewModelSupabase(supabaseService);
      final notesViewModel = NotesViewModelSupabase(supabaseService);
      
      expect(authViewModel, isNotNull);
      expect(notesViewModel, isNotNull);
    });
  });
}
