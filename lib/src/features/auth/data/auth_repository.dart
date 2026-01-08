import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/network/supabase_client.dart';

class AuthRepository {
  final GoogleSignIn _googleSignIn = GoogleSignIn(
    scopes: ['email', 'profile'],
  );

  SupabaseClient get _supabase => SupabaseClientProvider.client;

  /// Usuario actual
  User? get currentUser => _supabase.auth.currentUser;

  /// Stream de cambios de autenticación
  Stream<AuthState> get authStateChanges => _supabase.auth.onAuthStateChange;

  /// Está autenticado
  bool get isAuthenticated => currentUser != null;

  /// Sign in con Google
  Future<AuthResponse> signInWithGoogle() async {
    try {
      // 1. Iniciar flujo de Google Sign-In
      final googleUser = await _googleSignIn.signIn();
      if (googleUser == null) {
        throw AuthException('Google Sign-In cancelado');
      }

      // 2. Obtener tokens de autenticación
      final googleAuth = await googleUser.authentication;
      final idToken = googleAuth.idToken;
      final accessToken = googleAuth.accessToken;

      if (idToken == null) {
        throw AuthException('No se pudo obtener el ID token de Google');
      }

      // 3. Autenticar con Supabase usando el token de Google
      final response = await _supabase.auth.signInWithIdToken(
        provider: OAuthProvider.google,
        idToken: idToken,
        accessToken: accessToken,
      );

      if (kDebugMode) {
        print('[Auth] User signed in: ${response.user?.email}');
      }

      return response;
    } on AuthException {
      rethrow;
    } catch (e) {
      throw AuthException('Error en Google Sign-In: $e');
    }
  }

  /// Sign out
  Future<void> signOut() async {
    try {
      await Future.wait([
        _googleSignIn.signOut(),
        _supabase.auth.signOut(),
      ]);

      if (kDebugMode) {
        print('[Auth] User signed out');
      }
    } catch (e) {
      throw AuthException('Error al cerrar sesión: $e');
    }
  }

  /// Obtener token de acceso actual (para PowerSync)
  String? get accessToken => _supabase.auth.currentSession?.accessToken;

  /// Refrescar sesión si está por expirar
  Future<void> refreshSessionIfNeeded() async {
    final session = _supabase.auth.currentSession;
    if (session == null) return;

    // Refrescar si expira en menos de 5 minutos
    final expiresAt = session.expiresAt;
    if (expiresAt != null) {
      final expirationTime = DateTime.fromMillisecondsSinceEpoch(expiresAt * 1000);
      final now = DateTime.now();
      if (expirationTime.difference(now).inMinutes < 5) {
        await _supabase.auth.refreshSession();
        if (kDebugMode) {
          print('[Auth] Session refreshed');
        }
      }
    }
  }
}
