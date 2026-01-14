import 'dart:convert';
import 'dart:developer' as developer;

import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Implementación de LocalStorage que persiste sesiones de Supabase
/// usando flutter_secure_storage para sobrevivir desinstalaciones
///
/// CRÍTICO: SharedPreferences SE BORRA al desinstalar.
/// FlutterSecureStorage persiste en Android Keystore/iOS Keychain.
class SecureLocalStorage extends LocalStorage {
  final FlutterSecureStorage _storage;

  static const String _accessTokenKey = 'supabase_access_token';
  static const String _refreshTokenKey = 'supabase_refresh_token';

  SecureLocalStorage()
      : _storage = const FlutterSecureStorage(
          aOptions: AndroidOptions(
            encryptedSharedPreferences: true,
          ),
          iOptions: IOSOptions(
            accessibility: KeychainAccessibility.first_unlock,
          ),
        );

  @override
  Future<void> initialize() async {
    // No requiere inicialización
  }

  @override
  Future<String?> accessToken() async {
    return await _storage.read(key: _accessTokenKey);
  }

  @override
  Future<bool> hasAccessToken() async {
    final token = await accessToken();
    return token != null && token.isNotEmpty;
  }

  @override
  Future<void> persistSession(String persistSessionString) async {
    try {
      final decoded = jsonDecode(persistSessionString) as Map<String, dynamic>;
      final accessToken = decoded['access_token'] as String?;
      final refreshToken = decoded['refresh_token'] as String?;

      if (accessToken != null) {
        await _storage.write(key: _accessTokenKey, value: accessToken);
      }

      if (refreshToken != null) {
        await _storage.write(key: _refreshTokenKey, value: refreshToken);
      }
    } catch (e) {
      // Log error pero no lanzar excepción para evitar romper el flujo
      developer.log('Error persistiendo sesión: $e', name: 'SecureLocalStorage');
    }
  }

  @override
  Future<void> removePersistedSession() async {
    await _storage.delete(key: _accessTokenKey);
    await _storage.delete(key: _refreshTokenKey);
  }

  Future<String?> retrieveSession() async {
    try {
      final accessToken = await _storage.read(key: _accessTokenKey);
      final refreshToken = await _storage.read(key: _refreshTokenKey);

      if (accessToken == null || refreshToken == null) {
        return null;
      }

      // Reconstruir la sesión en formato esperado por Supabase
      final session = {
        'access_token': accessToken,
        'refresh_token': refreshToken,
      };

      return jsonEncode(session);
    } catch (e) {
      developer.log('Error recuperando sesión: $e', name: 'SecureLocalStorage');
      return null;
    }
  }
}
