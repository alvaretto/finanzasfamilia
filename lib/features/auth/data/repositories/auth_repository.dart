import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../core/network/supabase_client.dart';

/// Repositorio de autenticacion
/// CRÍTICO: Usa lazy initialization para evitar acceder a Supabase antes de que esté listo
class AuthRepository {
  GoTrueClient? _authClient;

  /// Obtiene el cliente de auth con lazy initialization
  GoTrueClient get _auth {
    try {
      _authClient ??= SupabaseClientProvider.auth;
      return _authClient!;
    } catch (e) {
      debugPrint('Error accessing Supabase auth: $e');
      rethrow;
    }
  }

  /// Verifica si Supabase está disponible
  bool get isAvailable {
    try {
      _auth;
      return true;
    } catch (e) {
      return false;
    }
  }

  /// Usuario actual - retorna null si Supabase no está disponible
  User? get currentUser {
    try {
      return _auth.currentUser;
    } catch (e) {
      debugPrint('Warning: Could not get current user: $e');
      return null;
    }
  }

  /// Sesion actual - retorna null si Supabase no está disponible
  Session? get currentSession {
    try {
      return _auth.currentSession;
    } catch (e) {
      debugPrint('Warning: Could not get current session: $e');
      return null;
    }
  }

  /// Stream de cambios de autenticacion
  /// Retorna un stream vacío si Supabase no está disponible
  Stream<AuthState> get authStateChanges {
    try {
      return _auth.onAuthStateChange;
    } catch (e) {
      debugPrint('Warning: Could not get auth state changes: $e');
      // Retornar un stream vacío para evitar crashes
      return const Stream.empty();
    }
  }

  /// Registrar nuevo usuario
  Future<AuthResponse> signUp({
    required String email,
    required String password,
    String? fullName,
  }) async {
    final response = await _auth.signUp(
      email: email,
      password: password,
      data: fullName != null ? {'full_name': fullName} : null,
    );
    return response;
  }

  /// Iniciar sesion con email y password
  Future<AuthResponse> signInWithEmail({
    required String email,
    required String password,
  }) async {
    final response = await _auth.signInWithPassword(
      email: email,
      password: password,
    );
    return response;
  }

  /// Iniciar sesion con Google (Native Sign-In)
  /// Usa el SDK nativo de Google en lugar de OAuth web para mejor UX
  Future<AuthResponse> signInWithGoogle() async {
    // Web Client ID de Google Cloud Console
    const webClientId =
        '796177647122-cr4kvhd4225204298r198ksdcla8i4q4.apps.googleusercontent.com';

    final googleSignIn = GoogleSignIn(
      serverClientId: webClientId,
    );

    final googleUser = await googleSignIn.signIn();
    if (googleUser == null) {
      throw const AuthException('Google Sign-In cancelado por el usuario');
    }

    final googleAuth = await googleUser.authentication;
    final idToken = googleAuth.idToken;
    final accessToken = googleAuth.accessToken;

    if (idToken == null) {
      throw const AuthException('No se pudo obtener el ID token de Google');
    }

    // Usar el ID token para autenticarse con Supabase
    final response = await _auth.signInWithIdToken(
      provider: OAuthProvider.google,
      idToken: idToken,
      accessToken: accessToken,
    );

    return response;
  }

  /// Iniciar sesion con Apple
  Future<bool> signInWithApple() async {
    final response = await _auth.signInWithOAuth(
      OAuthProvider.apple,
      redirectTo: 'io.supabase.finanzasfamiliares://login-callback/',
    );
    return response;
  }

  /// Enviar email para recuperar contrasena
  Future<void> sendPasswordResetEmail(String email) async {
    await _auth.resetPasswordForEmail(email);
  }

  /// Actualizar contrasena
  Future<UserResponse> updatePassword(String newPassword) async {
    final response = await _auth.updateUser(
      UserAttributes(password: newPassword),
    );
    return response;
  }

  /// Cerrar sesion (incluye Google Sign-In)
  Future<void> signOut() async {
    // Cerrar sesión de Google si estaba autenticado con Google
    try {
      final googleSignIn = GoogleSignIn();
      if (await googleSignIn.isSignedIn()) {
        await googleSignIn.disconnect(); // disconnect() fuerza selector de cuentas la próxima vez
      }
    } catch (e) {
      debugPrint('Warning: Could not sign out from Google: $e');
    }

    // Cerrar sesión de Supabase
    await _auth.signOut();
  }

  /// Verificar si el email ya existe
  Future<bool> checkEmailExists(String email) async {
    // Supabase no tiene un metodo directo, intentamos recuperar password
    // Si el email no existe, dara error
    try {
      await _auth.resetPasswordForEmail(email);
      return true;
    } catch (e) {
      return false;
    }
  }

  /// Reenviar email de confirmacion
  Future<void> resendConfirmationEmail(String email) async {
    await _auth.resend(
      type: OtpType.signup,
      email: email,
    );
  }

  /// Actualizar perfil del usuario
  Future<UserResponse> updateProfile({
    String? fullName,
    String? avatarUrl,
  }) async {
    final data = <String, dynamic>{};
    if (fullName != null) data['full_name'] = fullName;
    if (avatarUrl != null) data['avatar_url'] = avatarUrl;

    final response = await _auth.updateUser(
      UserAttributes(data: data),
    );
    return response;
  }
}
