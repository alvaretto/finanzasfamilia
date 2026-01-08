import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class SupabaseClientProvider {
  static SupabaseClient? _client;
  static bool _testMode = false;

  static Future<void> initialize() async {
    if (_testMode) return;

    await Supabase.initialize(
      url: dotenv.env['SUPABASE_URL']!,
      anonKey: dotenv.env['SUPABASE_ANON_KEY']!,
    );
    _client = Supabase.instance.client;
  }

  static SupabaseClient get client {
    if (_testMode) {
      throw StateError('Supabase not available in test mode');
    }
    return _client ?? Supabase.instance.client;
  }

  /// Current authenticated user
  static User? get currentUser => client.auth.currentUser;

  /// Check if user is authenticated
  static bool get isAuthenticated => currentUser != null;

  /// Enable test mode (disables Supabase)
  static void enableTestMode() {
    _testMode = true;
  }

  /// Disable test mode
  static void disableTestMode() {
    _testMode = false;
  }

  static bool get isTestMode => _testMode;
}
