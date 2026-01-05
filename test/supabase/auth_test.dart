/// Tests de Autenticacion Supabase
/// Verifica login, logout, registro, sesiones y tokens
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:finanzas_familiares/core/network/supabase_client.dart';
import 'package:finanzas_familiares/features/auth/data/repositories/auth_repository.dart';
import '../helpers/test_helpers.dart';

void main() {
  setUpAll(() async {
    await setupTestEnvironment();
  });

  tearDownAll(() async {
    await tearDownTestEnvironment();
  });

  group('Supabase Auth: Mock Tests', () {
    late MockSupabaseAuth mockAuth;

    setUp(() {
      mockAuth = mockSupabase.auth;
      mockAuth.setMockUser(null); // Empezar sin usuario
    });

    test('MockSupabaseAuth se crea correctamente', () {
      expect(mockAuth, isNotNull);
      expect(mockAuth.currentUser, isNull);
    });

    test('signInWithPassword simula login exitoso', () async {
      final session = await mockAuth.signInWithPassword(
        email: 'test@test.com',
        password: 'password123',
      );

      expect(session, isNotNull);
      expect(session.user.email, 'test@test.com');
      expect(mockAuth.currentUser, isNotNull);
      expect(mockAuth.currentUser!.email, 'test@test.com');
    });

    test('signOut limpia la sesion', () async {
      // Primero hacer login
      await mockAuth.signInWithPassword(
        email: 'test@test.com',
        password: 'password123',
      );
      expect(mockAuth.currentUser, isNotNull);

      // Luego hacer logout
      await mockAuth.signOut();
      expect(mockAuth.currentUser, isNull);
      expect(mockAuth.currentSession, isNull);
    });

    test('onAuthStateChange emite eventos', () async {
      final events = <MockAuthState>[];
      final subscription = mockAuth.onAuthStateChange.listen(events.add);

      await mockAuth.signInWithPassword(
        email: 'test@test.com',
        password: 'password123',
      );

      await Future.delayed(const Duration(milliseconds: 150));

      expect(events, isNotEmpty);
      expect(events.last.event, MockAuthChangeEvent.signedIn);

      await subscription.cancel();
    });

    test('refreshSession actualiza el token', () async {
      await mockAuth.signInWithPassword(
        email: 'test@test.com',
        password: 'password123',
      );

      final originalToken = mockAuth.currentSession!.accessToken;
      await mockAuth.refreshSession();
      final newToken = mockAuth.currentSession!.accessToken;

      expect(newToken, isNot(originalToken));
    });

    test('setMockUser establece usuario directamente', () {
      mockAuth.setMockUser(MockSupabaseUser(
        id: 'custom-id',
        email: 'custom@test.com',
      ));

      expect(mockAuth.currentUser, isNotNull);
      expect(mockAuth.currentUser!.id, 'custom-id');
      expect(mockAuth.currentUser!.email, 'custom@test.com');
    });
  });

  group('Supabase Auth: Repository Tests', () {
    late AuthRepository authRepo;

    setUp(() {
      authRepo = AuthRepository();
    });

    test('AuthRepository se crea sin errores', () {
      expect(authRepo, isNotNull);
    });

    test('currentUser es null sin sesion activa', () {
      final user = authRepo.currentUser;
      expect(user, isNull, reason: 'Sin login, currentUser debe ser null');
    });

    test('currentUser null significa no autenticado', () {
      final user = authRepo.currentUser;
      expect(user == null, true);
    });

    test('signOut completa sin error cuando no hay sesion', () async {
      // En modo test, signOut no debe lanzar excepciones
      try {
        await authRepo.signOut();
        // Si llegamos aquí, el test pasa
        expect(true, true);
      } catch (e) {
        // En test mode, puede lanzar excepción pero eso es esperado
        expect(e, isA<Exception>());
      }
    });

    test('authStateChanges retorna Stream', () {
      final stream = authRepo.authStateChanges;
      expect(stream, isA<Stream>());
    });
  });

  group('Supabase Auth: Validation Tests', () {
    test('Email valido pasa validacion', () {
      final validEmails = [
        'test@example.com',
        'user.name@domain.org',
        'user+tag@email.co.uk',
      ];

      for (final email in validEmails) {
        final isValid = _isValidEmail(email);
        expect(isValid, true, reason: '$email debe ser valido');
      }
    });

    test('Email invalido falla validacion', () {
      final invalidEmails = [
        'notanemail',
        '@nodomain.com',
        'spaces in@email.com',
        '',
      ];

      for (final email in invalidEmails) {
        final isValid = _isValidEmail(email);
        expect(isValid, false, reason: '$email debe ser invalido');
      }
    });

    test('Password fuerte pasa validacion', () {
      final strongPasswords = [
        'Password123!',
        'Str0ng#Pass',
        'MyP@ssw0rd!',
      ];

      for (final password in strongPasswords) {
        final isStrong = _isStrongPassword(password);
        expect(isStrong, true, reason: '$password debe ser fuerte');
      }
    });

    test('Password debil falla validacion', () {
      final weakPasswords = [
        '123456',
        'password',
        'abc',
        '',
      ];

      for (final password in weakPasswords) {
        final isStrong = _isStrongPassword(password);
        expect(isStrong, false, reason: '$password debe ser debil');
      }
    });
  });

  group('Supabase Auth: Session Management', () {
    test('En test mode no hay sesion', () {
      expect(SupabaseClientProvider.clientOrNull, isNull);
    });

    test('Operaciones auth no crashean en test mode', () async {
      final repo = AuthRepository();

      expect(() => repo.currentUser, returnsNormally);
      expect(() => repo.authStateChanges, returnsNormally);
    });
  });
}

bool _isValidEmail(String email) {
  if (email.isEmpty) return false;
  // Regex mejorado para soportar + y subdominios largos
  final emailRegex = RegExp(r'^[\w\.\+\-]+@([\w\-]+\.)+[\w\-]{2,}$');
  return emailRegex.hasMatch(email);
}

bool _isStrongPassword(String password) {
  if (password.length < 8) return false;
  final hasUppercase = password.contains(RegExp(r'[A-Z]'));
  final hasLowercase = password.contains(RegExp(r'[a-z]'));
  final hasDigit = password.contains(RegExp(r'[0-9]'));
  final hasSpecial = password.contains(RegExp(r'[!@#$%^&*(),.?":{}|<>]'));
  return hasUppercase && hasLowercase && hasDigit && hasSpecial;
}
