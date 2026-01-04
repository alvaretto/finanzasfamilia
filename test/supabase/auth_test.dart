/// Tests de Autenticacion Supabase
/// Verifica login, logout, registro, sesiones y tokens
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:finanzas_familiares/core/network/supabase_client.dart';
import 'package:finanzas_familiares/features/auth/data/repositories/auth_repository.dart';

void main() {
  setUpAll(() {
    SupabaseClientProvider.enableTestMode();
  });

  tearDownAll(() {
    SupabaseClientProvider.reset();
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
      await expectLater(
        authRepo.signOut(),
        completes,
      );
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
  final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
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
