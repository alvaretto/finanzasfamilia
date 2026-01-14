import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:gotrue/gotrue.dart' as gotrue;

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
  StreamSubscription<gotrue.AuthState>? _authSubscription;

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
    _authSubscription = auth.onAuthStateChange.listen((data) {
      final event = data.event;
      debugPrint('[AUTH] Event: $event, Session: ${data.session != null}');
      switch (event) {
        case AuthChangeEvent.signedIn:
        case AuthChangeEvent.tokenRefreshed:
        case AuthChangeEvent.userUpdated:
          debugPrint('[AUTH] Setting state to authenticated');
          state = AuthStatus.authenticated;
          break;
        case AuthChangeEvent.signedOut:
        // ignore: deprecated_member_use
        case AuthChangeEvent.userDeleted:
          debugPrint('[AUTH] Setting state to unauthenticated');
          state = AuthStatus.unauthenticated;
          break;
        case AuthChangeEvent.initialSession:
          final newState = data.session != null
              ? AuthStatus.authenticated
              : AuthStatus.unauthenticated;
          debugPrint('[AUTH] Initial session, setting state to $newState');
          state = newState;
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
  /// Web Client ID de Google Cloud (client_type: 3 en google-services.json)
  /// Este ID es necesario para obtener el idToken que Supabase requiere
  static const _webClientId =
      '1099277249344-599oavf6hutv3rfcp3rtu3beud57msjm.apps.googleusercontent.com';

  @override
  void build() {
    // No tiene estado propio, solo métodos
  }

  GoTrueClient get _auth => ref.read(supabaseAuthProvider);

  /// Inicia sesión con Google usando Native Sign-In
  ///
  /// IMPORTANTE: Usa el SDK nativo de Google, NO abre navegador externo.
  /// Esto soluciona el problema de:
  /// - Ventanas del navegador que no se cierran
  /// - Deep links que no se procesan correctamente
  /// - Sesiones incompletas que causan pérdida de datos
  Future<AuthResponse> signInWithGoogle() async {
    try {
      debugPrint('[AUTH] Iniciando Native Google Sign-In...');

      // Crear instancia de GoogleSignIn con serverClientId
      // serverClientId es CRÍTICO: permite obtener idToken para Supabase
      final googleSignIn = GoogleSignIn(
        serverClientId: _webClientId,
        scopes: ['email', 'profile'],
      );

      // Intentar sign-in silencioso primero (si ya tiene sesión previa)
      GoogleSignInAccount? googleUser = await googleSignIn.signInSilently();

      // Si no hay sesión previa, mostrar diálogo nativo de Google
      googleUser ??= await googleSignIn.signIn();

      if (googleUser == null) {
        debugPrint('[AUTH] Usuario canceló el sign-in');
        throw const AuthException('Inicio de sesión cancelado');
      }

      debugPrint('[AUTH] Google account: ${googleUser.email}');

      // Obtener tokens de autenticación
      final googleAuth = await googleUser.authentication;
      final idToken = googleAuth.idToken;
      final accessToken = googleAuth.accessToken;

      debugPrint('[AUTH] idToken presente: ${idToken != null}');
      debugPrint('[AUTH] accessToken presente: ${accessToken != null}');

      if (idToken == null) {
        throw const AuthException(
          'No se pudo obtener el token de identidad de Google. '
          'Verifica la configuración de OAuth en Google Cloud Console.',
        );
      }

      // Intercambiar tokens de Google por sesión de Supabase
      debugPrint('[AUTH] Intercambiando tokens con Supabase...');
      final response = await _auth.signInWithIdToken(
        provider: OAuthProvider.google,
        idToken: idToken,
        accessToken: accessToken,
      );

      debugPrint('[AUTH] Supabase session: ${response.session != null}');
      debugPrint('[AUTH] Supabase user: ${response.user?.email}');

      return response;
    } on AuthException {
      rethrow;
    } catch (e) {
      debugPrint('[AUTH] Error en Native Google Sign-In: $e');
      throw AuthException('Error al iniciar sesión con Google: $e');
    }
  }

  /// Cierra sesión de Google (además de Supabase)
  Future<void> _signOutFromGoogle() async {
    try {
      final googleSignIn = GoogleSignIn();
      if (await googleSignIn.isSignedIn()) {
        await googleSignIn.signOut();
        debugPrint('[AUTH] Google Sign-Out completado');
      }
    } catch (e) {
      debugPrint('[AUTH] Error en Google Sign-Out: $e');
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

  /// Cierra la sesión actual (Supabase + Google)
  Future<void> signOut() async {
    try {
      // Cerrar sesión de Google primero
      await _signOutFromGoogle();
      // Luego cerrar sesión de Supabase
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
