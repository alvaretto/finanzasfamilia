import 'dart:convert';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:finanzas_familiares/core/storage/secure_local_storage.dart';

void main() {
  // Inicializar binding de Flutter para tests
  TestWidgetsFlutterBinding.ensureInitialized();

  group('SecureLocalStorage', () {
    late SecureLocalStorage storage;

    setUp(() {
      // Configurar mocks iniciales para FlutterSecureStorage
      FlutterSecureStorage.setMockInitialValues({});
      storage = SecureLocalStorage();
    });

    test('hasAccessToken retorna false cuando no hay token', () async {
      final hasToken = await storage.hasAccessToken();
      expect(hasToken, isFalse);
    });

    test('persistSession y retrieveSession funcionan correctamente', () async {
      // Arrange
      final session = {
        'access_token': 'test_access_token_123',
        'refresh_token': 'test_refresh_token_456',
      };
      final sessionString = jsonEncode(session);

      // Act
      await storage.persistSession(sessionString);
      final retrieved = await storage.retrieveSession();

      // Assert
      expect(retrieved, isNotNull);
      if (retrieved != null) {
        final decoded = jsonDecode(retrieved) as Map<String, dynamic>;
        expect(decoded['access_token'], equals('test_access_token_123'));
        expect(decoded['refresh_token'], equals('test_refresh_token_456'));
      }
    });

    test('accessToken retorna el token guardado', () async {
      // Arrange
      final session = {
        'access_token': 'test_token',
        'refresh_token': 'test_refresh',
      };
      await storage.persistSession(jsonEncode(session));

      // Act
      final token = await storage.accessToken();

      // Assert
      expect(token, equals('test_token'));
    });

    test('hasAccessToken retorna true después de persistir sesión', () async {
      // Arrange
      final session = {
        'access_token': 'test_token',
        'refresh_token': 'test_refresh',
      };
      await storage.persistSession(jsonEncode(session));

      // Act
      final hasToken = await storage.hasAccessToken();

      // Assert
      expect(hasToken, isTrue);
    });

    test('removePersistedSession elimina todos los tokens', () async {
      // Arrange
      final session = {
        'access_token': 'test_token',
        'refresh_token': 'test_refresh',
      };
      await storage.persistSession(jsonEncode(session));

      // Act
      await storage.removePersistedSession();
      final retrieved = await storage.retrieveSession();
      final hasToken = await storage.hasAccessToken();

      // Assert
      expect(retrieved, isNull);
      expect(hasToken, isFalse);
    });

    test('persistSession maneja JSON inválido sin lanzar excepción', () async {
      // Act & Assert - no debe lanzar excepción
      await storage.persistSession('invalid json {');

      // Debe completar sin error
      final retrieved = await storage.retrieveSession();
      expect(retrieved, isNull); // No se guardó nada por el error
    });

    test('persistSession maneja sesión sin tokens correctamente', () async {
      // Arrange
      final session = {'other_field': 'value'};
      final sessionString = jsonEncode(session);

      // Act
      await storage.persistSession(sessionString);
      final retrieved = await storage.retrieveSession();

      // Assert
      expect(retrieved, isNull); // Sin tokens, no hay sesión válida
    });
  });
}
