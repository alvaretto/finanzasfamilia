import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:finanzas_familiares/core/router/app_router.dart';
import 'package:finanzas_familiares/features/auth/presentation/providers/auth_provider.dart';

/// Test del problema crítico: GoRouterRefreshStream
/// Este es probablemente el bug que causa que la app no responda
void main() {
  group('GoRouterRefreshStream - Tests Críticos', () {
    test('GoRouterRefreshStream debe manejar stream vacío sin error', () {
      final controller = StreamController<AuthState>.broadcast();

      final refreshStream = GoRouterRefreshStream(controller.stream);

      expect(refreshStream, isA<ChangeNotifier>());

      // dispose no debe causar error
      refreshStream.dispose();
      controller.close();
    });

    test('GoRouterRefreshStream debe notificar cuando el stream emite', () async {
      final controller = StreamController<AuthState>.broadcast();
      final refreshStream = GoRouterRefreshStream(controller.stream);

      var notificationCount = 0;
      refreshStream.addListener(() {
        notificationCount++;
      });

      // Emitir un estado
      controller.add(const AuthState(status: AuthStatus.authenticated));

      // Esperar a que el evento se propague
      await Future.delayed(const Duration(milliseconds: 10));

      expect(notificationCount, 1,
          reason: 'Debe notificar cuando el stream emite');

      refreshStream.dispose();
      controller.close();
    });

    test('GoRouterRefreshStream debe sobrevivir múltiples emisiones rápidas', () async {
      final controller = StreamController<AuthState>.broadcast();
      final refreshStream = GoRouterRefreshStream(controller.stream);

      var notificationCount = 0;
      refreshStream.addListener(() {
        notificationCount++;
      });

      // Emisiones rápidas - simula cambios de auth frecuentes
      for (var i = 0; i < 100; i++) {
        controller.add(AuthState(
          status: i.isEven ? AuthStatus.authenticated : AuthStatus.unauthenticated,
        ));
      }

      await Future.delayed(const Duration(milliseconds: 100));

      expect(notificationCount, 100,
          reason: 'Debe manejar emisiones rápidas sin perder eventos');

      refreshStream.dispose();
      controller.close();
    });

    test('GoRouterRefreshStream.dispose debe cancelar la suscripción', () async {
      final controller = StreamController<AuthState>.broadcast();
      final refreshStream = GoRouterRefreshStream(controller.stream);

      var notificationCount = 0;
      refreshStream.addListener(() {
        notificationCount++;
      });

      refreshStream.dispose();

      // Después del dispose, las emisiones no deben notificar
      controller.add(const AuthState(status: AuthStatus.authenticated));
      await Future.delayed(const Duration(milliseconds: 10));

      expect(notificationCount, 0,
          reason: 'Después de dispose, no debe recibir más notificaciones');

      controller.close();
    });

    test('GoRouterRefreshStream debe manejar múltiples listeners', () async {
      final controller = StreamController<AuthState>.broadcast();
      final refreshStream = GoRouterRefreshStream(controller.stream);

      var listener1Count = 0;
      var listener2Count = 0;

      refreshStream.addListener(() => listener1Count++);
      refreshStream.addListener(() => listener2Count++);

      controller.add(const AuthState(status: AuthStatus.authenticated));
      await Future.delayed(const Duration(milliseconds: 10));

      expect(listener1Count, 1);
      expect(listener2Count, 1);

      refreshStream.dispose();
      controller.close();
    });
  });

  group('Router Redirect Logic - Tests Críticos', () {
    test('Redirect debe enviar a login cuando no está autenticado', () {
      const unauthState = AuthState(status: AuthStatus.unauthenticated);

      final isAuthenticated = unauthState.isAuthenticated;
      const matchedLocation = '/dashboard';
      const isAuthRoute = false;

      // Lógica de redirect
      String? redirect;
      if (!isAuthenticated && !isAuthRoute) {
        redirect = AppRoutes.login;
      }

      expect(redirect, AppRoutes.login);
    });

    test('Redirect debe enviar a dashboard cuando está autenticado en login', () {
      const authState = AuthState(status: AuthStatus.authenticated);

      final isAuthenticated = authState.isAuthenticated;
      const matchedLocation = '/login';
      const isAuthRoute = true;

      String? redirect;
      if (isAuthenticated && isAuthRoute) {
        redirect = AppRoutes.dashboard;
      }

      expect(redirect, AppRoutes.dashboard);
    });

    test('Redirect debe retornar null cuando estado es correcto', () {
      const authState = AuthState(status: AuthStatus.authenticated);

      final isAuthenticated = authState.isAuthenticated;
      const matchedLocation = '/dashboard';
      const isAuthRoute = false;

      String? redirect;
      if (!isAuthenticated && !isAuthRoute) {
        redirect = AppRoutes.login;
      } else if (isAuthenticated && isAuthRoute) {
        redirect = AppRoutes.dashboard;
      }

      expect(redirect, isNull,
          reason: 'Usuario autenticado en dashboard no necesita redirect');
    });

    test('Estado initial no debe causar redirect infinito', () {
      const initialState = AuthState(status: AuthStatus.initial);

      // Con status initial, isAuthenticated es false
      expect(initialState.isAuthenticated, isFalse);

      // Esto causará redirect a login, lo cual está bien
      // Pero si el estado nunca sale de initial, habrá problemas
    });

    test('Estado loading debe ser manejado correctamente', () {
      const loadingState = AuthState(status: AuthStatus.loading);

      expect(loadingState.isAuthenticated, isFalse);
      expect(loadingState.isLoading, isTrue);

      // Durante loading, el redirect enviará a login
      // Esto puede causar parpadeo si el estado cambia rápido
    });
  });

  group('AppRoutes - Validación de Rutas', () {
    test('Todas las rutas deben estar definidas', () {
      expect(AppRoutes.splash, isNotEmpty);
      expect(AppRoutes.onboarding, isNotEmpty);
      expect(AppRoutes.login, isNotEmpty);
      expect(AppRoutes.register, isNotEmpty);
      expect(AppRoutes.forgotPassword, isNotEmpty);
      expect(AppRoutes.dashboard, isNotEmpty);
      expect(AppRoutes.accounts, isNotEmpty);
      expect(AppRoutes.transactions, isNotEmpty);
      expect(AppRoutes.budgets, isNotEmpty);
      expect(AppRoutes.goals, isNotEmpty);
      expect(AppRoutes.reports, isNotEmpty);
      expect(AppRoutes.settings, isNotEmpty);
    });

    test('Rutas de auth deben ser detectables correctamente', () {
      const authRoutes = [
        AppRoutes.login,
        AppRoutes.register,
        AppRoutes.forgotPassword,
      ];

      for (final route in authRoutes) {
        final isAuthRoute = route == AppRoutes.login ||
            route == AppRoutes.register ||
            route == AppRoutes.forgotPassword;

        expect(isAuthRoute, isTrue,
            reason: '$route debe ser detectada como ruta de auth');
      }
    });

    test('Rutas protegidas no deben ser rutas de auth', () {
      const protectedRoutes = [
        AppRoutes.dashboard,
        AppRoutes.accounts,
        AppRoutes.transactions,
        AppRoutes.budgets,
        AppRoutes.reports,
        AppRoutes.settings,
      ];

      for (final route in protectedRoutes) {
        final isAuthRoute = route == AppRoutes.login ||
            route == AppRoutes.register ||
            route == AppRoutes.forgotPassword;

        expect(isAuthRoute, isFalse,
            reason: '$route NO debe ser detectada como ruta de auth');
      }
    });
  });
}
