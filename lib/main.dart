import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_quill/flutter_quill.dart';
import 'package:provider/provider.dart';

import 'config/supabase_config.dart';
import 'viewmodels/auth_viewmodel_supabase.dart';
import 'viewmodels/notes_viewmodel_supabase.dart';
import 'screens/auth/login_screen.dart';
import 'screens/home/home_screen.dart';
import 'services/supabase_service.dart';
import 'theme/app_theme.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize Supabase
  await SupabaseConfig.initialize();
  
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    // Create Supabase service instance
    final supabaseService = SupabaseService();
    
    return MultiProvider(
      providers: [
        // Supabase service
        Provider<SupabaseService>.value(value: supabaseService),
        
        // Auth ViewModel
        ChangeNotifierProvider(
          create: (_) => AuthViewModelSupabase(supabaseService),
        ),
        
        // Notes ViewModel
        ChangeNotifierProvider(
          create: (_) => NotesViewModelSupabase(supabaseService),
        ),
      ],
      child: MaterialApp(
        title: 'Notes App',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.darkTheme,
        // Add localizations for flutter_quill
        localizationsDelegates: const [
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
          FlutterQuillLocalizations.delegate,
        ],
        supportedLocales: const [
          Locale('vi', 'VN'),
          Locale('en', 'US'),
        ],
        locale: const Locale('vi', 'VN'),
        home: const AuthWrapper(),
      ),
    );
  }
}

/// Wrapper to handle authentication state
class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    final authViewModel = context.watch<AuthViewModelSupabase>();
    
    // Show appropriate screen based on auth state
    if (authViewModel.isLoggedIn) {
      return const HomeScreen();
    } else {
      return const LoginScreen();
    }
  }
}
