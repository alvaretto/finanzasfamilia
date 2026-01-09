import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

part 'auth_provider.g.dart';

/// Estado de autenticación de la app
enum AuthStatus {
  /// Verificando estado inicial
  loading,

  /// Usuario autenticado
  authenticated,

  /// Usuario no autenticado
  unauthenticated,
}

/// Provider del cliente Supabase Auth
@Riverpod(keepAlive: true)
GoTrueClient supabaseAuth(Ref ref) {
  return Supabase.instance.client.auth;
}

/// Provider del usuario actual (reactivo)
@Riverpod(keepAlive: true)
User? currentUser(Ref ref) {
  final auth = ref.watch(supabaseAuthProvider);
  return auth.currentUser;
}

/// Provider del estado de autenticación
@Riverpod(keepAlive: true)
class AuthState extends _$AuthState {
  StreamSubscription<AuthState>? _authSubscription;

  @override
  AuthStatus build() {
    final auth = ref.watch(supabaseAuthProvider);

    // Escuchar cambios de autenticación
    _listenToAuthChanges(auth);

    // Estado inicial basado en sesión actual
    if (auth.currentSession != null) {
      return AuthStatus.authenticated;
    }
    return AuthStatus.unauthenticated;
  }

  void _listenToAuthChanges(GoTrueClient auth) {
    _authSubscription?.cancel();
    auth.onAuthStateChange.listen((data) {
      final event = data.event;
      switch (event) {
        case AuthChangeEvent.signedIn:
        case AuthChangeEvent.tokenRefreshed:
        case AuthChangeEvent.userUpdated:
          state = AuthStatus.authenticated;
          break;
        case AuthChangeEvent.signedOut:
        // ignore: deprecated_member_use
        case AuthChangeEvent.userDeleted:
          state = AuthStatus.unauthenticated;
          break;
        case AuthChangeEvent.initialSession:
          state = data.session != null
              ? AuthStatus.authenticated
              : AuthStatus.unauthenticated;
          break;
        case AuthChangeEvent.passwordRecovery:
        case AuthChangeEvent.mfaChallengeVerified:
          // No cambiar estado
          break;
      }
    });
  }
}

/// Servicio de autenticación
@Riverpod(keepAlive: true)
class AuthService extends _$AuthService {
  @override
  void build() {
    // No tiene estado propio, solo métodos
  }

  GoTrueClient get _auth => ref.read(supabaseAuthProvider);

  /// Inicia sesión con Google OAuth
  Future<AuthResponse> signInWithGoogle() async {
    try {
      final response = await _auth.signInWithOAuth(
        OAuthProvider.google,
        redirectTo: 'io.supabase.finanzasfamiliares://login-callback/',
        queryParams: {
          'access_type': 'offline',
          'prompt': 'consent',
        },
      );

      if (!response) {
        throw const AuthException('No se pudo iniciar el flujo de autenticación');
      }

      // El resultado real vendrá por el listener de auth state
      // Retornamos un placeholder mientras se procesa
      return AuthResponse(session: null, user: null);
    } on AuthException {
      rethrow;
    } catch (e) {
      throw AuthException('Error al iniciar sesión: $e');
    }
  }

  /// Inicia sesión con email y contraseña (para desarrollo/testing)
  Future<AuthResponse> signInWithEmail({
    required String email,
    required String password,
  }) async {
    try {
      return await _auth.signInWithPassword(
        email: email,
        password: password,
      );
    } on AuthException {
      rethrow;
    } catch (e) {
      throw AuthException('Error al iniciar sesión: $e');
    }
  }

  /// Registra un nuevo usuario con email
  Future<AuthResponse> signUpWithEmail({
    required String email,
    required String password,
    String? displayName,
  }) async {
    try {
      return await _auth.signUp(
        email: email,
        password: password,
        data: displayName != null ? {'display_name': displayName} : null,
      );
    } on AuthException {
      rethrow;
    } catch (e) {
      throw AuthException('Error al registrar usuario: $e');
    }
  }

  /// Cierra la sesión actual
  Future<void> signOut() async {
    try {
      await _auth.signOut();
    } on AuthException {
      rethrow;
    } catch (e) {
      throw AuthException('Error al cerrar sesión: $e');
    }
  }

  /// Verifica si hay una sesión activa
  bool get isAuthenticated => _auth.currentSession != null;

  /// Obtiene el usuario actual
  User? get currentUser => _auth.currentUser;

  /// Obtiene el token de acceso actual
  String? get accessToken => _auth.currentSession?.accessToken;

  /// Refresca la sesión si está por expirar
  Future<void> refreshSession() async {
    try {
      await _auth.refreshSession();
    } on AuthException {
      rethrow;
    } catch (e) {
      throw AuthException('Error al refrescar sesión: $e');
    }
  }
}

// Nota: isFirstTimeUserProvider está definido en onboarding_provider.dart
