import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Cliente singleton de Supabase
class SupabaseClientProvider {
  static SupabaseClient? _client;

  /// Inicializa Supabase con las credenciales del .env
  static Future<void> initialize() async {
    await Supabase.initialize(
      url: dotenv.env['SUPABASE_URL'] ?? '',
      anonKey: dotenv.env['SUPABASE_ANON_KEY'] ?? '',
      authOptions: const FlutterAuthClientOptions(
        authFlowType: AuthFlowType.pkce,
      ),
      realtimeClientOptions: const RealtimeClientOptions(
        logLevel: RealtimeLogLevel.info,
      ),
    );
    _client = Supabase.instance.client;
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
