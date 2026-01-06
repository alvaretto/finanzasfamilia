import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Cliente singleton de Supabase
class SupabaseClientProvider {
  static SupabaseClient? _client;
  static bool _isInitialized = false;
  static bool _isTestMode = false;

  /// Verifica si estamos en modo de pruebas
  static bool get isTestMode => _isTestMode;

  /// Verifica si Supabase esta inicializado
  static bool get isInitialized => _isInitialized || _isTestMode;

  /// Activa modo de pruebas (no requiere Supabase real)
  @visibleForTesting
  static void enableTestMode() {
    _isTestMode = true;
  }

  /// Desactiva modo de pruebas
  @visibleForTesting
  static void disableTestMode() {
    _isTestMode = false;
  }

  /// Resetea el estado (para tests)
  @visibleForTesting
  static void reset() {
    _client = null;
    _isInitialized = false;
    _isTestMode = false;
  }

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
        detectSessionInUri: true,
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
    if (_isTestMode) {
      throw Exception('Test mode: Use mock providers instead of real Supabase client.');
    }
    if (_client == null) {
      throw Exception('Supabase not initialized. Call initialize() first.');
    }
    return _client!;
  }

  /// Obtiene el cliente de Supabase (null-safe para tests)
  static SupabaseClient? get clientOrNull {
    if (_isTestMode) return null;
    return _client;
  }

  /// Obtiene el cliente de autenticacion (null-safe)
  static GoTrueClient? get authOrNull {
    if (_isTestMode || _client == null) return null;
    return _client!.auth;
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
  static User? get currentUser {
    if (_isTestMode || _client == null) return null;
    try {
      return _client!.auth.currentUser;
    } catch (_) {
      return null;
    }
  }

  /// Sesion actual (puede ser null)
  static Session? get currentSession {
    if (_isTestMode || _client == null) return null;
    try {
      return _client!.auth.currentSession;
    } catch (_) {
      return null;
    }
  }

  /// Stream de cambios de autenticacion
  static Stream<AuthState> get authStateChanges {
    if (_isTestMode || _client == null) {
      // Retornar stream vacio para tests
      return const Stream.empty();
    }
    return _client!.auth.onAuthStateChange;
  }

  /// Cierra sesion
  static Future<void> signOut() async {
    if (_isTestMode || _client == null) return;
    await _client!.auth.signOut();
  }
}
