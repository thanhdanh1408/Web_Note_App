import 'package:supabase_flutter/supabase_flutter.dart';

class SupabaseConfig {
  // Supabase credentials - Replace with your actual values from .env
  static const String supabaseUrl = 'https://ttewhmtraletjujjogsk.supabase.co';
  static const String supabaseAnonKey = 'sb_publishable_QqU8Gcd9p3aPCh-1GpK54w_d2KQUT8Z';

  static Future<void> initialize() async {
    await Supabase.initialize(
      url: supabaseUrl,
      anonKey: supabaseAnonKey,
      authOptions: const FlutterAuthClientOptions(
        authFlowType: AuthFlowType.pkce,
      ),
      realtimeClientOptions: const RealtimeClientOptions(
        logLevel: RealtimeLogLevel.info,
      ),
      storageOptions: const StorageClientOptions(
        retryAttempts: 10,
      ),
    );
  }
}

/// Shortcut to access Supabase client
final supabase = Supabase.instance.client;
