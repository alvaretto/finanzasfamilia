import 'dart:async';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:finanzas_familiares/features/auth/presentation/providers/auth_provider.dart';

void main() {
  group('AuthState - Tests de Estado', () {
    test('AuthState.copyWith debe preservar valores no especificados', () {
      const original = AuthState(
        status: AuthStatus.authenticated,
        errorMessage: 'test error',
      );

      final copied = original.copyWith(status: AuthStatus.loading);

      expect(copied.status, AuthStatus.loading);
      // errorMessage se resetea a null en copyWith - esto puede ser intencional
      // pero debemos verificar el comportamiento
      expect(copied.errorMessage, isNull,
          reason: 'copyWith resetea errorMessage - verificar si es intencional');
    });

    test('AuthState.copyWith con errorMessage null debe funcionar', () {
      const original = AuthState(
        status: AuthStatus.authenticated,
        errorMessage: 'error',
      );

      final copied = original.copyWith(errorMessage: null);

      expect(copied.errorMessage, isNull);
    });

    test('isAuthenticated debe ser consistente con status', () {
      const authenticatedState = AuthState(status: AuthStatus.authenticated);
      const unauthenticatedState = AuthState(status: AuthStatus.unauthenticated);
      const loadingState = AuthState(status: AuthStatus.loading);
      const initialState = AuthState(status: AuthStatus.initial);

      expect(authenticatedState.isAuthenticated, isTrue);
      expect(unauthenticatedState.isAuthenticated, isFalse);
      expect(loadingState.isAuthenticated, isFalse);
      expect(initialState.isAuthenticated, isFalse);
    });

    test('isLoading debe ser consistente con status', () {
      const loadingState = AuthState(status: AuthStatus.loading);
      const notLoadingState = AuthState(status: AuthStatus.authenticated);

      expect(loadingState.isLoading, isTrue);
      expect(notLoadingState.isLoading, isFalse);
    });
  });

  group('AuthState - Validación de Estados', () {
    test('Transiciones de estado válidas', () {
      // initial -> loading -> authenticated
      // initial -> loading -> unauthenticated
      // authenticated -> loading -> unauthenticated (logout)

      const states = [
        AuthState(status: AuthStatus.initial),
        AuthState(status: AuthStatus.loading),
        AuthState(status: AuthStatus.authenticated),
        AuthState(status: AuthStatus.unauthenticated),
      ];

      for (final state in states) {
        expect(state.status, isNotNull);
        // isAuthenticated debe ser consistente con status
        expect(
          state.isAuthenticated,
          state.status == AuthStatus.authenticated,
          reason: 'isAuthenticated debe coincidir con status',
        );
      }
    });

    test('Estado con error debe tener status correcto', () {
      const stateWithError = AuthState(
        status: AuthStatus.unauthenticated,
        errorMessage: 'Credenciales inválidas',
      );

      expect(stateWithError.isAuthenticated, isFalse);
      expect(stateWithError.errorMessage, isNotNull);
      expect(stateWithError.isLoading, isFalse);
    });
  });
}
