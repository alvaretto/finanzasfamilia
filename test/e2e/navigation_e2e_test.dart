/// E2E Tests - Navegación completa de la aplicación
/// Tests agresivos que prueban toda la navegación de la app
library;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:finanzas_familiares/core/theme/app_theme.dart';
import 'package:finanzas_familiares/core/router/app_router.dart';
import 'package:finanzas_familiares/shared/widgets/main_scaffold.dart';
import 'package:finanzas_familiares/features/dashboard/presentation/screens/dashboard_screen.dart';
import 'package:finanzas_familiares/features/accounts/presentation/screens/accounts_screen.dart';
import 'package:finanzas_familiares/features/transactions/presentation/screens/transactions_screen.dart';
import 'package:finanzas_familiares/features/reports/presentation/screens/reports_screen.dart';
import 'package:finanzas_familiares/features/settings/presentation/screens/settings_screen.dart';
import 'package:finanzas_familiares/features/auth/presentation/screens/login_screen.dart';
import '../helpers/test_helpers.dart';
import '../mocks/mock_providers.dart';

void main() {
  setUpAll(() async {
    await setupTestEnvironment();
  });
  tearDownAll(() async {
    await tearDownTestEnvironment();
  });
  group('E2E: Bottom Navigation Bar', () {
    // =========================================================================
    // TEST 1: BottomNavigationBar se renderiza correctamente
    // =========================================================================
    testWidgets('BottomNavigationBar debe mostrar todos los items', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: testProviderOverrides,
          child: MaterialApp(
            theme: AppTheme.light(),
            home: const TestMainScaffold(
              child: Center(child: Text('Content')),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Verificar items de navegación
      expect(find.text('Inicio'), findsOneWidget,
          reason: 'Debe mostrar tab Inicio');
      expect(find.text('Cuentas'), findsOneWidget,
          reason: 'Debe mostrar tab Cuentas');
      expect(find.text('Movimientos'), findsOneWidget,
          reason: 'Debe mostrar tab Movimientos');
      expect(find.text('Reportes'), findsOneWidget,
          reason: 'Debe mostrar tab Reportes');
    });

    // =========================================================================
    // TEST 2: Íconos de navegación están presentes
    // =========================================================================
    testWidgets('Íconos de navegación deben estar presentes', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: testProviderOverrides,
          child: MaterialApp(
            theme: AppTheme.light(),
            home: const TestMainScaffold(
              child: Center(child: Text('Content')),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Verificar íconos (TestMainScaffold usa estos íconos)
      expect(find.byIcon(Icons.home), findsOneWidget);
      expect(find.byIcon(Icons.account_balance_wallet), findsOneWidget);
      expect(find.byIcon(Icons.swap_horiz), findsOneWidget);
      expect(find.byIcon(Icons.bar_chart), findsOneWidget);
    });

    // =========================================================================
    // TEST 3: FAB central está presente
    // =========================================================================
    testWidgets('FAB central debe estar presente', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: testProviderOverrides,
          child: MaterialApp(
            theme: AppTheme.light(),
            home: const TestMainScaffold(
              child: Center(child: Text('Content')),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.byType(FloatingActionButton), findsOneWidget,
          reason: 'FAB debe estar presente');
      expect(find.byIcon(Icons.add), findsOneWidget,
          reason: 'FAB debe tener ícono de agregar');
    });

    // =========================================================================
    // TEST 4: Tap en items de navegación funciona
    // =========================================================================
    testWidgets('Taps en items de navegación deben funcionar', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: testProviderOverrides,
          child: MaterialApp(
            theme: AppTheme.light(),
            home: const TestMainScaffold(
              child: Center(child: Text('Content')),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Tap en cada item de navegación
      await tester.tap(find.text('Inicio'));
      await tester.pump();

      await tester.tap(find.text('Cuentas'));
      await tester.pump();

      await tester.tap(find.text('Movimientos'));
      await tester.pump();

      await tester.tap(find.text('Reportes'));
      await tester.pump();

      // No debe lanzar errores
    });

    // =========================================================================
    // TEST 5: Navegación cíclica funciona
    // =========================================================================
    testWidgets('Navegación cíclica debe funcionar sin errores', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: testProviderOverrides,
          child: MaterialApp(
            theme: AppTheme.light(),
            home: const TestMainScaffold(
              child: Center(child: Text('Content')),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Ciclo completo de navegación múltiples veces
      for (var i = 0; i < 3; i++) {
        await tester.tap(find.text('Inicio'));
        await tester.pump();
        await tester.tap(find.text('Cuentas'));
        await tester.pump();
        await tester.tap(find.text('Movimientos'));
        await tester.pump();
        await tester.tap(find.text('Reportes'));
        await tester.pump();
      }

      // No debe lanzar errores
    });
  });

  group('E2E: Pantallas Individuales', () {
    // =========================================================================
    // TEST 6: DashboardScreen se renderiza
    // =========================================================================
    testWidgets('DashboardScreen debe renderizarse', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: testProviderOverrides,
          child: MaterialApp(
            theme: AppTheme.light(),
            home: const DashboardScreen(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.byType(DashboardScreen), findsOneWidget);
    });

    // =========================================================================
    // TEST 7: AccountsScreen se renderiza
    // =========================================================================
    testWidgets('AccountsScreen debe renderizarse', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: testProviderOverrides,
          child: MaterialApp(
            theme: AppTheme.light(),
            home: const AccountsScreen(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.byType(AccountsScreen), findsOneWidget);
      expect(find.text('Mis Cuentas'), findsOneWidget);
    });

    // =========================================================================
    // TEST 8: TransactionsScreen se renderiza
    // =========================================================================
    testWidgets('TransactionsScreen debe renderizarse', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: testProviderOverrides,
          child: MaterialApp(
            theme: AppTheme.light(),
            home: const TransactionsScreen(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.byType(TransactionsScreen), findsOneWidget);
    });

    // =========================================================================
    // TEST 9: ReportsScreen se renderiza
    // =========================================================================
    testWidgets('ReportsScreen debe renderizarse', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: testProviderOverrides,
          child: MaterialApp(
            theme: AppTheme.light(),
            home: const ReportsScreen(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.byType(ReportsScreen), findsOneWidget);
    });

    // =========================================================================
    // TEST 10: SettingsScreen se renderiza
    // =========================================================================
    testWidgets('SettingsScreen debe renderizarse', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: testProviderOverrides,
          child: MaterialApp(
            theme: AppTheme.light(),
            home: const SettingsScreen(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.byType(SettingsScreen), findsOneWidget);
    });

    // =========================================================================
    // TEST 11: LoginScreen se renderiza
    // =========================================================================
    testWidgets('LoginScreen debe renderizarse', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: testProviderOverrides,
          child: MaterialApp(
            theme: AppTheme.light(),
            home: const LoginScreen(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.byType(LoginScreen), findsOneWidget);
    });
  });

  group('E2E: Gestos de Navegación', () {
    // =========================================================================
    // TEST 12: Swipe en páginas con PageView
    // =========================================================================
    testWidgets('Swipe debe funcionar si hay PageView', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: testProviderOverrides,
          child: MaterialApp(
            theme: AppTheme.light(),
            home: const TestMainScaffold(
              child: Center(child: Text('Content')),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Intentar swipe horizontal
      await tester.drag(
        find.byType(TestMainScaffold),
        const Offset(-200, 0),
      );
      await tester.pumpAndSettle();

      // No debe lanzar errores
    });

    // =========================================================================
    // TEST 13: Doble tap no causa problemas
    // =========================================================================
    testWidgets('Doble tap en navegación no causa problemas', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: testProviderOverrides,
          child: MaterialApp(
            theme: AppTheme.light(),
            home: const TestMainScaffold(
              child: Center(child: Text('Content')),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Doble tap en item
      await tester.tap(find.text('Cuentas'));
      await tester.pump(const Duration(milliseconds: 50));
      await tester.tap(find.text('Cuentas'));
      await tester.pumpAndSettle();

      // No debe lanzar errores
    });

    // =========================================================================
    // TEST 14: Taps muy rápidos en diferentes items
    // =========================================================================
    testWidgets('Taps muy rápidos en diferentes items', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: testProviderOverrides,
          child: MaterialApp(
            theme: AppTheme.light(),
            home: const TestMainScaffold(
              child: Center(child: Text('Content')),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Taps muy rápidos
      await tester.tap(find.text('Inicio'));
      await tester.tap(find.text('Cuentas'));
      await tester.tap(find.text('Movimientos'));
      await tester.tap(find.text('Reportes'));
      await tester.tap(find.text('Inicio'));
      await tester.pumpAndSettle();

      // No debe lanzar errores
    });
  });

  group('E2E: Interacción FAB + Navegación', () {
    // =========================================================================
    // TEST 15: FAB funciona en todas las pantallas
    // =========================================================================
    testWidgets('FAB debe funcionar desde cualquier tab', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: testProviderOverrides,
          child: MaterialApp(
            theme: AppTheme.light(),
            home: const TestMainScaffold(
              child: Center(child: Text('Content')),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Probar FAB desde cada tab
      final tabs = ['Inicio', 'Cuentas', 'Movimientos', 'Reportes'];

      for (final tab in tabs) {
        // Navegar al tab
        await tester.tap(find.text(tab));
        await tester.pumpAndSettle();

        // Abrir FAB
        await tester.tap(find.byType(FloatingActionButton));
        await tester.pumpAndSettle();

        expect(find.text('Nueva transacción'), findsOneWidget,
            reason: 'FAB debe funcionar desde tab $tab');

        // Cerrar
        await tester.tapAt(const Offset(10, 100));
        await tester.pumpAndSettle();
      }
    });

    // =========================================================================
    // TEST 16: Abrir FAB, navegar, volver - no causa errores
    // =========================================================================
    testWidgets('Abrir FAB, cambiar tab, no causa errores', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: testProviderOverrides,
          child: MaterialApp(
            theme: AppTheme.light(),
            home: const TestMainScaffold(
              child: Center(child: Text('Content')),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Abrir FAB
      await tester.tap(find.byType(FloatingActionButton));
      await tester.pumpAndSettle();

      expect(find.text('Nueva transacción'), findsOneWidget);

      // Cerrar y cambiar tab
      await tester.tapAt(const Offset(10, 100));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Cuentas'));
      await tester.pumpAndSettle();

      // Volver a abrir FAB
      await tester.tap(find.byType(FloatingActionButton));
      await tester.pumpAndSettle();

      expect(find.text('Nueva transacción'), findsOneWidget);
    });
  });

  group('E2E: AppRoutes Constantes', () {
    // =========================================================================
    // TEST 17: Todas las rutas están definidas
    // =========================================================================
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

    // =========================================================================
    // TEST 18: Rutas no tienen espacios ni caracteres inválidos
    // =========================================================================
    test('Rutas deben ser válidas', () {
      final routes = [
        AppRoutes.splash,
        AppRoutes.onboarding,
        AppRoutes.login,
        AppRoutes.register,
        AppRoutes.forgotPassword,
        AppRoutes.dashboard,
        AppRoutes.accounts,
        AppRoutes.transactions,
        AppRoutes.budgets,
        AppRoutes.goals,
        AppRoutes.reports,
        AppRoutes.settings,
      ];

      for (final route in routes) {
        expect(route.startsWith('/'), isTrue,
            reason: 'Ruta $route debe comenzar con /');
        expect(route.contains(' '), isFalse,
            reason: 'Ruta $route no debe contener espacios');
      }
    });
  });
}
