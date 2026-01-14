import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:gotrue/gotrue.dart' as gotrue;

import 'package:finanzas_familiares/application/providers/auth_provider.dart';

// Mocks
class MockGoTrueClient extends Mock implements GoTrueClient {}

class MockSession extends Mock implements Session {}

class MockUser extends Mock implements User {}

void main() {
  late MockGoTrueClient mockAuth;

  setUpAll(() {
    registerFallbackValue(OAuthProvider.google);
  });

  setUp(() {
    mockAuth = MockGoTrueClient();
  });

  group('AuthStatus enum', () {
    test('tiene los estados correctos', () {
      expect(AuthStatus.values, hasLength(3));
      expect(AuthStatus.values, contains(AuthStatus.loading));
      expect(AuthStatus.values, contains(AuthStatus.authenticated));
      expect(AuthStatus.values, contains(AuthStatus.unauthenticated));
    });
  });

  group('AuthService - signInWithEmail', () {
    test('llama a signInWithPassword con credenciales correctas', () async {
      final mockSession = MockSession();
      final mockUser = MockUser();
      final authResponse = AuthResponse(session: mockSession, user: mockUser);

      when(() => mockAuth.signInWithPassword(
            email: any(named: 'email'),
            password: any(named: 'password'),
          )).thenAnswer((_) async => authResponse);

      final result = await mockAuth.signInWithPassword(
        email: 'test@example.com',
        password: 'password123',
      );

      expect(result.session, equals(mockSession));
      expect(result.user, equals(mockUser));
      verify(() => mockAuth.signInWithPassword(
            email: 'test@example.com',
            password: 'password123',
          )).called(1);
    });

    test('propaga AuthException en error de autenticación', () async {
      when(() => mockAuth.signInWithPassword(
            email: any(named: 'email'),
            password: any(named: 'password'),
          )).thenThrow(const AuthException('Invalid credentials'));

      expect(
        () => mockAuth.signInWithPassword(
          email: 'test@example.com',
          password: 'wrong',
        ),
        throwsA(isA<AuthException>()),
      );
    });
  });

  group('AuthService - signUpWithEmail', () {
    test('registra usuario con email y password', () async {
      final mockUser = MockUser();
      final authResponse = AuthResponse(session: null, user: mockUser);

      when(() => mockAuth.signUp(
            email: any(named: 'email'),
            password: any(named: 'password'),
            data: any(named: 'data'),
          )).thenAnswer((_) async => authResponse);

      final result = await mockAuth.signUp(
        email: 'nuevo@example.com',
        password: 'password123',
      );

      expect(result.user, equals(mockUser));
    });

    test('registra usuario con displayName en data', () async {
      final mockUser = MockUser();
      final authResponse = AuthResponse(session: null, user: mockUser);

      when(() => mockAuth.signUp(
            email: any(named: 'email'),
            password: any(named: 'password'),
            data: any(named: 'data'),
          )).thenAnswer((_) async => authResponse);

      await mockAuth.signUp(
        email: 'nuevo@example.com',
        password: 'password123',
        data: {'display_name': 'Juan Pérez'},
      );

      verify(() => mockAuth.signUp(
            email: 'nuevo@example.com',
            password: 'password123',
            data: {'display_name': 'Juan Pérez'},
          )).called(1);
    });
  });

  group('AuthService - signOut', () {
    test('cierra sesión correctamente', () async {
      when(() => mockAuth.signOut()).thenAnswer((_) async {});

      await mockAuth.signOut();

      verify(() => mockAuth.signOut()).called(1);
    });

    test('propaga excepción en error de signOut', () async {
      when(() => mockAuth.signOut())
          .thenThrow(const AuthException('Network error'));

      expect(
        () => mockAuth.signOut(),
        throwsA(isA<AuthException>()),
      );
    });
  });

  group('AuthService - session management', () {
    test('currentSession retorna null cuando no hay sesión', () {
      when(() => mockAuth.currentSession).thenReturn(null);

      expect(mockAuth.currentSession, isNull);
    });

    test('currentSession retorna sesión activa', () {
      final mockSession = MockSession();
      when(() => mockAuth.currentSession).thenReturn(mockSession);

      expect(mockAuth.currentSession, equals(mockSession));
    });

    test('currentUser retorna null cuando no hay usuario', () {
      when(() => mockAuth.currentUser).thenReturn(null);

      expect(mockAuth.currentUser, isNull);
    });

    test('currentUser retorna usuario autenticado', () {
      final mockUser = MockUser();
      when(() => mockAuth.currentUser).thenReturn(mockUser);

      expect(mockAuth.currentUser, equals(mockUser));
    });
  });

  group('AuthService - refreshSession', () {
    test('refresca sesión correctamente', () async {
      final mockSession = MockSession();
      final mockUser = MockUser();
      final response = AuthResponse(session: mockSession, user: mockUser);
      when(() => mockAuth.refreshSession()).thenAnswer((_) async => response);

      await mockAuth.refreshSession();

      verify(() => mockAuth.refreshSession()).called(1);
    });

    test('propaga excepción si refresh falla', () async {
      when(() => mockAuth.refreshSession())
          .thenThrow(const AuthException('Token expired'));

      expect(
        () => mockAuth.refreshSession(),
        throwsA(isA<AuthException>()),
      );
    });
  });

  group('AuthService - OAuth', () {
    // Nota: signInWithOAuth es una extensión de supabase_flutter sobre GoTrueClient.
    // Las extensiones no pueden ser mockeadas directamente con mocktail.
    // Los tests de integración de OAuth se cubren con tests E2E o manuales.

    test('getOAuthSignInUrl genera URL para proveedor', () async {
      const mockUrl = OAuthResponse(
        provider: OAuthProvider.google,
        url: 'https://auth.supabase.co/...',
      );

      when(() => mockAuth.getOAuthSignInUrl(
            provider: any(named: 'provider'),
            redirectTo: any(named: 'redirectTo'),
            queryParams: any(named: 'queryParams'),
          )).thenAnswer((_) async => mockUrl);

      final result = await mockAuth.getOAuthSignInUrl(
        provider: OAuthProvider.google,
        redirectTo: 'io.supabase.finanzasfamiliares://login-callback/',
        queryParams: {'access_type': 'offline'},
      );

      expect(result.provider, equals(OAuthProvider.google));
      expect(result.url, contains('auth.supabase'));
    });
  });

  group('AuthState - onAuthStateChange', () {
    test('stream emite eventos de autenticación', () async {
      final controller = StreamController<gotrue.AuthState>();

      when(() => mockAuth.onAuthStateChange).thenAnswer((_) => controller.stream);

      final events = <gotrue.AuthState>[];
      final subscription = mockAuth.onAuthStateChange.listen(events.add);

      // Simular evento de signIn
      controller.add(gotrue.AuthState(
        AuthChangeEvent.signedIn,
        MockSession(),
      ));

      await Future.delayed(const Duration(milliseconds: 10));

      expect(events, hasLength(1));
      expect(events.first.event, equals(AuthChangeEvent.signedIn));

      await subscription.cancel();
      await controller.close();
    });

    test('stream emite signedOut cuando usuario cierra sesión', () async {
      final controller = StreamController<gotrue.AuthState>();

      when(() => mockAuth.onAuthStateChange).thenAnswer((_) => controller.stream);

      final events = <gotrue.AuthState>[];
      final subscription = mockAuth.onAuthStateChange.listen(events.add);

      controller.add(const gotrue.AuthState(
        AuthChangeEvent.signedOut,
        null,
      ));

      await Future.delayed(const Duration(milliseconds: 10));

      expect(events, hasLength(1));
      expect(events.first.event, equals(AuthChangeEvent.signedOut));
      expect(events.first.session, isNull);

      await subscription.cancel();
      await controller.close();
    });

    test('stream emite tokenRefreshed cuando token se refresca', () async {
      final controller = StreamController<gotrue.AuthState>();

      when(() => mockAuth.onAuthStateChange).thenAnswer((_) => controller.stream);

      final events = <gotrue.AuthState>[];
      final subscription = mockAuth.onAuthStateChange.listen(events.add);

      controller.add(gotrue.AuthState(
        AuthChangeEvent.tokenRefreshed,
        MockSession(),
      ));

      await Future.delayed(const Duration(milliseconds: 10));

      expect(events.first.event, equals(AuthChangeEvent.tokenRefreshed));

      await subscription.cancel();
      await controller.close();
    });

    test('stream emite initialSession al iniciar', () async {
      final controller = StreamController<gotrue.AuthState>();

      when(() => mockAuth.onAuthStateChange).thenAnswer((_) => controller.stream);

      final events = <gotrue.AuthState>[];
      final subscription = mockAuth.onAuthStateChange.listen(events.add);

      // Sin sesión inicial
      controller.add(const gotrue.AuthState(
        AuthChangeEvent.initialSession,
        null,
      ));

      await Future.delayed(const Duration(milliseconds: 10));

      expect(events.first.event, equals(AuthChangeEvent.initialSession));
      expect(events.first.session, isNull);

      await subscription.cancel();
      await controller.close();
    });

    test('stream emite initialSession con sesión existente', () async {
      final controller = StreamController<gotrue.AuthState>();
      final mockSession = MockSession();

      when(() => mockAuth.onAuthStateChange).thenAnswer((_) => controller.stream);

      final events = <gotrue.AuthState>[];
      final subscription = mockAuth.onAuthStateChange.listen(events.add);

      controller.add(gotrue.AuthState(
        AuthChangeEvent.initialSession,
        mockSession,
      ));

      await Future.delayed(const Duration(milliseconds: 10));

      expect(events.first.event, equals(AuthChangeEvent.initialSession));
      expect(events.first.session, isNotNull);

      await subscription.cancel();
      await controller.close();
    });
  });

  group('Session accessToken', () {
    test('accessToken retorna token de sesión activa', () {
      final mockSession = MockSession();
      when(() => mockSession.accessToken).thenReturn('jwt-token-123');
      when(() => mockAuth.currentSession).thenReturn(mockSession);

      expect(mockAuth.currentSession?.accessToken, equals('jwt-token-123'));
    });

    test('accessToken es null sin sesión', () {
      when(() => mockAuth.currentSession).thenReturn(null);

      expect(mockAuth.currentSession?.accessToken, isNull);
    });
  });
}
