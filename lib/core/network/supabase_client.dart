import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Cliente singleton de Supabase
class SupabaseClientProvider {
  static SupabaseClient? _client;
  static bool _isInitialized = false;

  /// Verifica si Supabase esta inicializado
  static bool get isInitialized => _isInitialized;

  /// Inicializa Supabase con las credenciales del .env
  static Future<void> initialize() async {
    if (_isInitialized) return;

    final url = dotenv.env['SUPABASE_URL'];
    final anonKey = dotenv.env['SUPABASE_ANON_KEY'];

    if (url == null || url.isEmpty || anonKey == null || anonKey.isEmpty) {
      debugPrint('Warning: Supabase credentials not found in .env');
      return;
    }

    await Supabase.initialize(
      url: url,
      anonKey: anonKey,
      debug: kDebugMode,
      authOptions: const FlutterAuthClientOptions(
        authFlowType: AuthFlowType.pkce,
      ),
      realtimeClientOptions: const RealtimeClientOptions(
        logLevel: RealtimeLogLevel.info,
      ),
      storageOptions: const StorageClientOptions(
        retryAttempts: 3,
      ),
    );
    _client = Supabase.instance.client;
    _isInitialized = true;
  }

  /// Obtiene el cliente de Supabase
  static SupabaseClient get client {
    if (_client == null) {
      throw Exception('Supabase not initialized. Call initialize() first.');
    }
    return _client!;
  }

  /// Obtiene el cliente de autenticacion
  static GoTrueClient get auth => client.auth;

  /// Obtiene el cliente de la base de datos
  static SupabaseQueryBuilder table(String name) => client.from(name);

  /// Obtiene el cliente de realtime
  static RealtimeClient get realtime => client.realtime;

  /// Obtiene el cliente de storage
  static SupabaseStorageClient get storage => client.storage;

  /// Usuario actual (puede ser null)
  static User? get currentUser => auth.currentUser;

  /// Sesion actual (puede ser null)
  static Session? get currentSession => auth.currentSession;

  /// Stream de cambios de autenticacion
  static Stream<AuthState> get authStateChanges => auth.onAuthStateChange;

  /// Cierra sesion
  static Future<void> signOut() async {
    await auth.signOut();
  }
}
