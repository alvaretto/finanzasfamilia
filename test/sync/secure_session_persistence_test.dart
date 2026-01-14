/// Tests de persistencia de sesión post-desinstalación
///
/// Verifican que SecureLocalStorage mantiene los tokens de autenticación
/// incluso cuando la app es desinstalada y reinstalada.
///
/// CRÍTICO: SharedPreferences se borra en desinstalación.
/// SecureLocalStorage usa Android Keystore / iOS Keychain que persisten.
library;

import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:finanzas_familiares/core/storage/secure_local_storage.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('SecureSessionPersistence - Persistencia de Sesión', () {
    late SecureLocalStorage storage;
    late Map<String, String> mockStorage;

    setUp(() {
      mockStorage = {};
      FlutterSecureStorage.setMockInitialValues(mockStorage);
      storage = SecureLocalStorage();
    });

    group('Fase 1: Ciclo Básico de Sesión', () {
      test('Sesión se persiste correctamente', () async {
        // Arrange
        final session = {
          'access_token': 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.test',
          'refresh_token': 'refresh_token_abc123',
          'expires_at': DateTime.now()
              .add(const Duration(hours: 1))
              .millisecondsSinceEpoch,
          'user': {
            'id': '550e8400-e29b-41d4-a716-446655440000',
            'email': 'test@example.com',
          }
        };

        // Act
        await storage.persistSession(jsonEncode(session));

        // Assert
        final hasToken = await storage.hasAccessToken();
        expect(hasToken, isTrue, reason: 'Debe reportar que tiene token');

        final accessToken = await storage.accessToken();
        expect(accessToken, equals(session['access_token']),
            reason: 'Access token debe ser recuperable');
      });

      test('Sesión se recupera después de "reinstalación" simulada', () async {
        // Arrange - primera "instalación"
        final originalSession = {
          'access_token': 'original_access_token_xyz',
          'refresh_token': 'original_refresh_token_123',
          'expires_at': DateTime.now()
              .add(const Duration(hours: 1))
              .millisecondsSinceEpoch,
        };

        await storage.persistSession(jsonEncode(originalSession));

        // Guardar estado del "Keystore" simulado
        final keystoreState = Map<String, String>.from(mockStorage);

        // Simular "reinstalación" - nueva instancia pero mismo Keystore
        FlutterSecureStorage.setMockInitialValues(keystoreState);
        final newStorage = SecureLocalStorage();

        // Assert
        final hasToken = await newStorage.hasAccessToken();
        expect(hasToken, isTrue,
            reason: 'Token debe persistir después de reinstalación');

        final recovered = await newStorage.retrieveSession();
        expect(recovered, isNotNull,
            reason: 'Sesión debe ser recuperable');

        final decoded = jsonDecode(recovered!) as Map<String, dynamic>;
        expect(decoded['access_token'], equals('original_access_token_xyz'),
            reason: 'Access token debe ser idéntico');
        expect(decoded['refresh_token'], equals('original_refresh_token_123'),
            reason: 'Refresh token debe ser idéntico');
      });

      test('removePersistedSession limpia completamente', () async {
        // Arrange
        final session = {
          'access_token': 'token_to_remove',
          'refresh_token': 'refresh_to_remove',
        };
        await storage.persistSession(jsonEncode(session));

        // Verificar que existe
        expect(await storage.hasAccessToken(), isTrue);

        // Act
        await storage.removePersistedSession();

        // Assert
        expect(await storage.hasAccessToken(), isFalse,
            reason: 'No debe haber token después de eliminar');
        expect(await storage.retrieveSession(), isNull,
            reason: 'Sesión debe ser null después de eliminar');
      });
    });

    group('Fase 2: Escenarios de Tokens', () {
      test('Sesión sin access_token no se considera válida', () async {
        final session = {
          'refresh_token': 'only_refresh',
          'expires_at': DateTime.now()
              .add(const Duration(hours: 1))
              .millisecondsSinceEpoch,
        };

        await storage.persistSession(jsonEncode(session));

        // Access token específico debe ser null
        final accessToken = await storage.accessToken();
        expect(accessToken, isNull,
            reason: 'Sin access_token explícito, debe ser null');
      });

      test('Sesión con solo access_token es suficiente para hasAccessToken', () async {
        final session = {
          'access_token': 'minimal_token',
        };

        await storage.persistSession(jsonEncode(session));

        final hasToken = await storage.hasAccessToken();
        expect(hasToken, isTrue,
            reason: 'Con access_token, hasAccessToken debe ser true');
      });

      test('Token expirado todavía se recupera (la validación es en otro lugar)', () async {
        // SecureLocalStorage solo almacena, no valida expiración
        final expiredSession = {
          'access_token': 'expired_token',
          'refresh_token': 'can_refresh',
          'expires_at': DateTime.now()
              .subtract(const Duration(hours: 1))
              .millisecondsSinceEpoch,
        };

        await storage.persistSession(jsonEncode(expiredSession));

        final hasToken = await storage.hasAccessToken();
        expect(hasToken, isTrue,
            reason: 'Token expirado sigue siendo un token almacenado');

        final session = await storage.retrieveSession();
        expect(session, isNotNull,
            reason: 'Sesión expirada debe ser recuperable para refresh');
      });
    });

    group('Fase 3: Robustez ante Datos Corruptos', () {
      test('JSON inválido no causa crash', () async {
        // Act & Assert - no debe lanzar excepción
        await storage.persistSession('not valid json {{{');

        final hasToken = await storage.hasAccessToken();
        expect(hasToken, isFalse,
            reason: 'JSON inválido no debe resultar en token válido');
      });

      test('Sesión vacía es manejada correctamente', () async {
        await storage.persistSession(jsonEncode({}));

        final hasToken = await storage.hasAccessToken();
        expect(hasToken, isFalse,
            reason: 'Sesión vacía no debe tener token');

        final session = await storage.retrieveSession();
        expect(session, isNull,
            reason: 'Sesión vacía debe ser null');
      });

      test('Valores null en sesión son manejados', () async {
        final session = {
          'access_token': null,
          'refresh_token': 'valid_refresh',
        };

        await storage.persistSession(jsonEncode(session));

        final hasToken = await storage.hasAccessToken();
        expect(hasToken, isFalse,
            reason: 'access_token null no cuenta como token válido');
      });

      test('Strings vacíos no cuentan como tokens válidos', () async {
        final session = {
          'access_token': '',
          'refresh_token': '',
        };

        await storage.persistSession(jsonEncode(session));

        final accessToken = await storage.accessToken();
        // El comportamiento depende de implementación, pero debe ser consistente
        expect(accessToken == null || accessToken.isEmpty, isTrue,
            reason: 'Token vacío debe ser null o string vacío');
      });
    });

    group('Fase 4: Múltiples Sesiones Consecutivas', () {
      test('Nueva sesión sobrescribe la anterior completamente', () async {
        // Primera sesión
        final session1 = {
          'access_token': 'first_token',
          'refresh_token': 'first_refresh',
          'user': {'id': 'user1'},
        };
        await storage.persistSession(jsonEncode(session1));

        // Segunda sesión (diferente usuario)
        final session2 = {
          'access_token': 'second_token',
          'refresh_token': 'second_refresh',
          'user': {'id': 'user2'},
        };
        await storage.persistSession(jsonEncode(session2));

        // Assert - solo debe existir la segunda
        final accessToken = await storage.accessToken();
        expect(accessToken, equals('second_token'),
            reason: 'Debe tener el token de la segunda sesión');

        final retrieved = await storage.retrieveSession();
        final decoded = jsonDecode(retrieved!) as Map<String, dynamic>;
        expect(decoded['refresh_token'], equals('second_refresh'),
            reason: 'Refresh token debe ser el de la segunda sesión');
      });

      test('Logout y nuevo login funcionan correctamente', () async {
        // Login inicial
        await storage.persistSession(jsonEncode({
          'access_token': 'initial_token',
          'refresh_token': 'initial_refresh',
        }));

        // Logout
        await storage.removePersistedSession();
        expect(await storage.hasAccessToken(), isFalse);

        // Nuevo login
        await storage.persistSession(jsonEncode({
          'access_token': 'new_token',
          'refresh_token': 'new_refresh',
        }));

        expect(await storage.hasAccessToken(), isTrue);
        expect(await storage.accessToken(), equals('new_token'));
      });
    });

    group('Fase 5: Simulación de Escenarios Reales', () {
      test('Flujo OAuth completo: login → uso → reinstall → uso', () async {
        // === PASO 1: Login OAuth ===
        final oauthResponse = {
          'access_token': 'ya29.a0AfH6SMBx...', // Token estilo Google
          'refresh_token': '1//0eXxXxXxX...',
          'expires_at': DateTime.now()
              .add(const Duration(hours: 1))
              .millisecondsSinceEpoch,
          'token_type': 'Bearer',
          'provider_token': 'google_provider_token',
          'user': {
            'id': '550e8400-e29b-41d4-a716-446655440000',
            'email': 'usuario@gmail.com',
            'app_metadata': {'provider': 'google'},
          }
        };
        await storage.persistSession(jsonEncode(oauthResponse));

        // === PASO 2: Verificar sesión activa ===
        expect(await storage.hasAccessToken(), isTrue);

        // === PASO 3: Simular uso de la app (tiempo pasa) ===
        // El token original sigue siendo válido

        // === PASO 4: Usuario desinstala y reinstala ===
        // Simulamos que el Keystore persiste
        final keystoreBackup = Map<String, String>.from(mockStorage);
        FlutterSecureStorage.setMockInitialValues(keystoreBackup);
        final reinstalledStorage = SecureLocalStorage();

        // === PASO 5: Verificar recuperación post-reinstall ===
        expect(await reinstalledStorage.hasAccessToken(), isTrue,
            reason: 'Token debe persistir tras reinstalación');

        final recovered = await reinstalledStorage.retrieveSession();
        expect(recovered, isNotNull,
            reason: 'Sesión completa debe ser recuperable');

        final decoded = jsonDecode(recovered!) as Map<String, dynamic>;
        // SecureLocalStorage solo persiste access_token y refresh_token
        // Los datos del user se recuperan del JWT al hacer refresh
        expect(decoded['access_token'], equals('ya29.a0AfH6SMBx...'),
            reason: 'Access token debe persistir');
        expect(decoded['refresh_token'], equals('1//0eXxXxXxX...'),
            reason: 'Refresh token debe persistir');
      });

      test('Refresh token permite re-autenticación tras expiración', () async {
        // Token expirado pero con refresh_token válido
        final expiredSession = {
          'access_token': 'expired_access_token',
          'refresh_token': 'valid_refresh_for_renewal',
          'expires_at': DateTime.now()
              .subtract(const Duration(minutes: 30))
              .millisecondsSinceEpoch,
        };
        await storage.persistSession(jsonEncode(expiredSession));

        // Recuperar sesión para usar refresh_token
        final session = await storage.retrieveSession();
        final decoded = jsonDecode(session!) as Map<String, dynamic>;

        // Simular refresh exitoso (en producción, Supabase hace esto)
        final newAccessToken = 'new_access_after_refresh';
        decoded['access_token'] = newAccessToken;
        decoded['expires_at'] = DateTime.now()
            .add(const Duration(hours: 1))
            .millisecondsSinceEpoch;

        await storage.persistSession(jsonEncode(decoded));

        // Verificar nuevo token
        final refreshedToken = await storage.accessToken();
        expect(refreshedToken, equals(newAccessToken),
            reason: 'Nuevo token debe estar disponible tras refresh');
      });
    });
  });
}
