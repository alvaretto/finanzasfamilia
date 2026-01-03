import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart' as supabase;

import '../../data/repositories/auth_repository.dart';

/// Provider del repositorio de autenticacion
final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return AuthRepository();
});

/// Estado de autenticacion
enum AuthStatus {
  initial,
  authenticated,
  unauthenticated,
  loading,
}

/// Estado del provider de auth
class AuthState {
  final AuthStatus status;
  final supabase.User? user;
  final String? errorMessage;

  const AuthState({
    this.status = AuthStatus.initial,
    this.user,
    this.errorMessage,
  });

  AuthState copyWith({
    AuthStatus? status,
    supabase.User? user,
    String? errorMessage,
  }) {
    return AuthState(
      status: status ?? this.status,
      user: user ?? this.user,
      errorMessage: errorMessage,
    );
  }

  bool get isAuthenticated => status == AuthStatus.authenticated;
  bool get isLoading => status == AuthStatus.loading;
}

/// Notifier de autenticacion
class AuthNotifier extends StateNotifier<AuthState> {
  final AuthRepository _repository;
  StreamSubscription<supabase.AuthState>? _authSubscription;

  AuthNotifier(this._repository) : super(const AuthState()) {
    _init();
  }

  void _init() {
    // Verificar sesion actual
    final user = _repository.currentUser;
    if (user != null) {
      state = AuthState(status: AuthStatus.authenticated, user: user);
    } else {
      state = const AuthState(status: AuthStatus.unauthenticated);
    }

    // Escuchar cambios de autenticacion
    _authSubscription = _repository.authStateChanges.listen((authState) {
      final event = authState.event;
      final session = authState.session;

      switch (event) {
        case supabase.AuthChangeEvent.signedIn:
        case supabase.AuthChangeEvent.tokenRefreshed:
        case supabase.AuthChangeEvent.userUpdated:
          state = AuthState(
            status: AuthStatus.authenticated,
            user: session?.user,
          );
          break;
        case supabase.AuthChangeEvent.signedOut:
          state = const AuthState(status: AuthStatus.unauthenticated);
          break;
        case supabase.AuthChangeEvent.passwordRecovery:
          // Usuario esta en proceso de recuperar password
          break;
        default:
          break;
      }
    });
  }

  /// Registrar nuevo usuario
  Future<bool> signUp({
    required String email,
    required String password,
    String? fullName,
  }) async {
    state = state.copyWith(status: AuthStatus.loading, errorMessage: null);

    try {
      final response = await _repository.signUp(
        email: email,
        password: password,
        fullName: fullName,
      );

      if (response.user != null) {
        // Si requiere confirmacion de email
        if (response.session == null) {
          state = state.copyWith(
            status: AuthStatus.unauthenticated,
            errorMessage: 'Revisa tu email para confirmar tu cuenta',
          );
          return true;
        }
        state = AuthState(
          status: AuthStatus.authenticated,
          user: response.user,
        );
        return true;
      }

      state = state.copyWith(
        status: AuthStatus.unauthenticated,
        errorMessage: 'Error al crear cuenta',
      );
      return false;
    } on supabase.AuthException catch (e) {
      state = state.copyWith(
        status: AuthStatus.unauthenticated,
        errorMessage: _parseAuthError(e.message),
      );
      return false;
    } catch (e) {
      state = state.copyWith(
        status: AuthStatus.unauthenticated,
        errorMessage: 'Error inesperado: $e',
      );
      return false;
    }
  }

  /// Iniciar sesion
  Future<bool> signIn({
    required String email,
    required String password,
  }) async {
    state = state.copyWith(status: AuthStatus.loading, errorMessage: null);

    try {
      final response = await _repository.signInWithEmail(
        email: email,
        password: password,
      );

      if (response.user != null) {
        state = AuthState(
          status: AuthStatus.authenticated,
          user: response.user,
        );
        return true;
      }

      state = state.copyWith(
        status: AuthStatus.unauthenticated,
        errorMessage: 'Credenciales invalidas',
      );
      return false;
    } on supabase.AuthException catch (e) {
      state = state.copyWith(
        status: AuthStatus.unauthenticated,
        errorMessage: _parseAuthError(e.message),
      );
      return false;
    } catch (e) {
      state = state.copyWith(
        status: AuthStatus.unauthenticated,
        errorMessage: 'Error de conexion',
      );
      return false;
    }
  }

  /// Iniciar sesion con Google
  Future<bool> signInWithGoogle() async {
    state = state.copyWith(status: AuthStatus.loading, errorMessage: null);

    try {
      final success = await _repository.signInWithGoogle();
      if (!success) {
        state = state.copyWith(
          status: AuthStatus.unauthenticated,
          errorMessage: 'Error al iniciar con Google',
        );
      }
      return success;
    } catch (e) {
      state = state.copyWith(
        status: AuthStatus.unauthenticated,
        errorMessage: 'Error al iniciar con Google',
      );
      return false;
    }
  }

  /// Enviar email para recuperar contrasena
  Future<bool> sendPasswordReset(String email) async {
    state = state.copyWith(status: AuthStatus.loading, errorMessage: null);

    try {
      await _repository.sendPasswordResetEmail(email);
      state = state.copyWith(status: AuthStatus.unauthenticated);
      return true;
    } on supabase.AuthException catch (e) {
      state = state.copyWith(
        status: AuthStatus.unauthenticated,
        errorMessage: _parseAuthError(e.message),
      );
      return false;
    } catch (e) {
      state = state.copyWith(
        status: AuthStatus.unauthenticated,
        errorMessage: 'Error al enviar email',
      );
      return false;
    }
  }

  /// Cerrar sesion
  Future<void> signOut() async {
    await _repository.signOut();
    state = const AuthState(status: AuthStatus.unauthenticated);
  }

  /// Limpiar mensaje de error
  void clearError() {
    state = state.copyWith(errorMessage: null);
  }

  String _parseAuthError(String message) {
    if (message.contains('Invalid login credentials')) {
      return 'Email o contrasena incorrectos';
    }
    if (message.contains('Email not confirmed')) {
      return 'Debes confirmar tu email primero';
    }
    if (message.contains('User already registered')) {
      return 'Este email ya esta registrado';
    }
    if (message.contains('Password should be')) {
      return 'La contrasena debe tener al menos 6 caracteres';
    }
    if (message.contains('rate limit')) {
      return 'Demasiados intentos. Espera un momento';
    }
    return message;
  }

  @override
  void dispose() {
    _authSubscription?.cancel();
    super.dispose();
  }
}

/// Provider principal de autenticacion
final authProvider = StateNotifierProvider<AuthNotifier, AuthState>((ref) {
  final repository = ref.watch(authRepositoryProvider);
  return AuthNotifier(repository);
});

/// Provider para verificar si esta autenticado
final isAuthenticatedProvider = Provider<bool>((ref) {
  return ref.watch(authProvider).isAuthenticated;
});

/// Provider del usuario actual
final currentUserProvider = Provider<supabase.User?>((ref) {
  return ref.watch(authProvider).user;
});
