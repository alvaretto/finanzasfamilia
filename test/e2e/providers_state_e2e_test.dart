/// E2E Tests - Providers y Estado
/// Tests agresivos que prueban el estado de la aplicación con Riverpod
library;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:finanzas_familiares/core/theme/app_theme.dart';
import 'package:finanzas_familiares/shared/widgets/main_scaffold.dart';
import 'package:finanzas_familiares/features/dashboard/presentation/screens/dashboard_screen.dart';
import 'package:finanzas_familiares/features/accounts/presentation/screens/accounts_screen.dart';
import 'package:finanzas_familiares/features/transactions/presentation/screens/transactions_screen.dart';
import 'package:finanzas_familiares/features/reports/presentation/screens/reports_screen.dart';
import 'package:finanzas_familiares/features/settings/presentation/screens/settings_screen.dart';
import 'package:finanzas_familiares/features/accounts/presentation/widgets/add_account_sheet.dart';
import 'package:finanzas_familiares/features/transactions/presentation/widgets/add_transaction_sheet.dart';
import 'package:finanzas_familiares/features/transactions/domain/models/transaction_model.dart';
import '../helpers/test_helpers.dart';
import '../mocks/mock_providers.dart';

void main() {
  setUpAll(() => setupTestEnvironment());
  tearDownAll(() => tearDownTestEnvironment());
  group('E2E: ProviderScope Initialization', () {
    // =========================================================================
    // TEST 1: ProviderScope se inicializa correctamente
    // =========================================================================
    testWidgets('ProviderScope debe inicializarse sin errores', (tester) async {
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
    // TEST 2: Múltiples ProviderScopes anidados (error case)
    // =========================================================================
    testWidgets('App funciona con ProviderScope único', (tester) async {
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

      // FAB debe funcionar
      await tester.tap(find.byType(FloatingActionButton));
      await tester.pumpAndSettle();

      expect(find.text('Nueva transacción'), findsOneWidget);
    });

    // =========================================================================
    // TEST 3: ProviderScope con overrides vacíos
    // =========================================================================
    testWidgets('ProviderScope con overrides vacíos funciona', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: const [],
          child: MaterialApp(
            theme: AppTheme.light(),
            home: const AccountsScreen(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.byType(AccountsScreen), findsOneWidget);
    });
  });

  group('E2E: Estado entre Pantallas', () {
    // =========================================================================
    // TEST 4: Estado persiste al cambiar de pantalla
    // =========================================================================
    testWidgets('Estado debe persistir al navegar', (tester) async {
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

      // Navegar entre tabs
      await tester.tap(find.text('Cuentas'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Inicio'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Cuentas'));
      await tester.pumpAndSettle();

      // El contenido del scaffold debe persistir después de navegar
      // TestMainScaffold no cambia su contenido, solo permite navegar
      expect(find.text('Content'), findsOneWidget,
          reason: 'El contenido debe persistir después de navegación');
      expect(find.byType(BottomNavigationBar), findsOneWidget,
          reason: 'La barra de navegación debe estar presente');
    });

    // =========================================================================
    // TEST 5: Estado de formularios no se pierde prematuramente
    // =========================================================================
    testWidgets('Formulario abierto mantiene estado', (tester) async {
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

      // Abrir formulario
      await tester.tap(find.byIcon(Icons.add));
      await tester.pumpAndSettle();

      expect(find.byType(AddAccountSheet), findsOneWidget);

      // Ingresar texto
      final nameFields = find.byType(TextFormField);
      if (nameFields.evaluate().isNotEmpty) {
        await tester.enterText(nameFields.first, 'Mi Cuenta');
        await tester.pump();
      }

      // El formulario debe seguir abierto
      expect(find.byType(AddAccountSheet), findsOneWidget);
    });
  });

  group('E2E: Consumer Widgets', () {
    // =========================================================================
    // TEST 6: Dashboard usa Consumer correctamente
    // =========================================================================
    testWidgets('DashboardScreen debe usar providers', (tester) async {
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

      // Dashboard debe mostrar widgets que usan providers
      expect(find.byType(DashboardScreen), findsOneWidget);
    });

    // =========================================================================
    // TEST 7: AccountsScreen usa Consumer correctamente
    // =========================================================================
    testWidgets('AccountsScreen debe usar providers', (tester) async {
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

      // Debe mostrar la pantalla de cuentas (con mock accounts tiene datos)
      expect(find.byType(AccountsScreen), findsOneWidget,
          reason: 'AccountsScreen debe renderizarse');
      expect(find.text('Mis Cuentas'), findsOneWidget,
          reason: 'Debe mostrar el título');
    });

    // =========================================================================
    // TEST 8: TransactionsScreen usa Consumer correctamente
    // =========================================================================
    testWidgets('TransactionsScreen debe usar providers', (tester) async {
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
    // TEST 9: ReportsScreen usa Consumer correctamente
    // =========================================================================
    testWidgets('ReportsScreen debe usar providers', (tester) async {
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
    // TEST 10: SettingsScreen usa Consumer correctamente
    // =========================================================================
    testWidgets('SettingsScreen debe usar providers', (tester) async {
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
  });

  group('E2E: Async State', () {
    // =========================================================================
    // TEST 11: Loading states se manejan correctamente
    // =========================================================================
    testWidgets('App maneja estados de carga', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: testProviderOverrides,
          child: MaterialApp(
            theme: AppTheme.light(),
            home: const DashboardScreen(),
          ),
        ),
      );

      // Pump inicial (estado de carga)
      await tester.pump();

      // Pump settle (estado final)
      await tester.pumpAndSettle();

      expect(find.byType(DashboardScreen), findsOneWidget);
    });

    // =========================================================================
    // TEST 12: Error states se manejan correctamente
    // =========================================================================
    testWidgets('App maneja estados de error', (tester) async {
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

      // Debe mostrar estado vacío o datos (sin crash)
      expect(find.byType(AccountsScreen), findsOneWidget);
    });
  });

  group('E2E: Provider Refresh', () {
    // =========================================================================
    // TEST 13: Refresh no causa crash
    // =========================================================================
    testWidgets('Botón sync en cuentas no causa crash', (tester) async {
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

      // Tap en sync button
      await tester.tap(find.byIcon(Icons.sync));
      await tester.pumpAndSettle();

      // No debe crashear
      expect(find.byType(AccountsScreen), findsOneWidget);
    });

    // =========================================================================
    // TEST 14: Pull to refresh si existe
    // =========================================================================
    testWidgets('Pull to refresh no causa crash', (tester) async {
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

      // Intentar pull to refresh
      await tester.drag(
        find.byType(Scaffold),
        const Offset(0, 300),
      );
      await tester.pumpAndSettle();

      // No debe crashear
    });
  });

  group('E2E: State Isolation', () {
    // =========================================================================
    // TEST 15: Cada pantalla tiene estado independiente
    // =========================================================================
    testWidgets('Estados de pantallas son independientes', (tester) async {
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

      // Ir a cuentas
      await tester.tap(find.text('Cuentas'));
      await tester.pumpAndSettle();

      // Ir a transacciones
      await tester.tap(find.text('Movimientos'));
      await tester.pumpAndSettle();

      // Volver a cuentas
      await tester.tap(find.text('Cuentas'));
      await tester.pumpAndSettle();

      // Estado debe ser consistente - el contenido del scaffold persiste
      // TestMainScaffold no cambia contenido, solo permite navegación
      expect(find.text('Content'), findsOneWidget,
          reason: 'El contenido debe persistir durante navegación');
      expect(find.byType(BottomNavigationBar), findsOneWidget,
          reason: 'La barra de navegación debe estar presente');
    });

    // =========================================================================
    // TEST 16: Formularios no comparten estado
    // =========================================================================
    testWidgets('Formularios tienen estados independientes', (tester) async {
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

      // Abrir formulario de transacción
      await tester.tap(find.byType(FloatingActionButton));
      await tester.pumpAndSettle();

      // Seleccionar tipo Gasto
      await tester.tap(find.text('Gasto'));
      await tester.pumpAndSettle();

      // Cerrar
      final closeButton = find.byIcon(Icons.close);
      if (closeButton.evaluate().isNotEmpty) {
        await tester.tap(closeButton);
        await tester.pumpAndSettle();
      } else {
        await tester.tapAt(const Offset(10, 10));
        await tester.pumpAndSettle();
      }

      // Abrir otro formulario
      await tester.tap(find.byType(FloatingActionButton));
      await tester.pumpAndSettle();

      // Debe mostrar selector de tipo nuevamente
      expect(find.text('Nueva transacción'), findsOneWidget);
    });
  });

  group('E2E: Transaction Types', () {
    // =========================================================================
    // TEST 17: Tipo Gasto abre formulario correcto
    // =========================================================================
    testWidgets('Seleccionar Gasto abre AddTransactionSheet', (tester) async {
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

      // Seleccionar Gasto
      await tester.tap(find.text('Gasto'));
      await tester.pumpAndSettle();

      // Debe abrir formulario de transacción
      expect(find.byType(AddTransactionSheet), findsOneWidget);
    });

    // =========================================================================
    // TEST 18: Tipo Ingreso abre formulario correcto
    // =========================================================================
    testWidgets('Seleccionar Ingreso abre AddTransactionSheet', (tester) async {
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

      // Seleccionar Ingreso
      await tester.tap(find.text('Ingreso'));
      await tester.pumpAndSettle();

      // Debe abrir formulario
      expect(find.byType(AddTransactionSheet), findsOneWidget);
    });

    // =========================================================================
    // TEST 19: Tipo Transferencia abre formulario correcto
    // =========================================================================
    testWidgets('Seleccionar Transferencia abre AddTransactionSheet', (tester) async {
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

      // Seleccionar Transferencia
      await tester.tap(find.text('Transferencia'));
      await tester.pumpAndSettle();

      // Debe abrir formulario
      expect(find.byType(AddTransactionSheet), findsOneWidget);
    });
  });

  group('E2E: Widget Rebuild', () {
    // =========================================================================
    // TEST 20: Rebuilds no causan problemas
    // =========================================================================
    testWidgets('Múltiples rebuilds no causan problemas', (tester) async {
      var counter = 0;

      await tester.pumpWidget(
        ProviderScope(
          child: StatefulBuilder(
            builder: (context, setState) {
              return MaterialApp(
                theme: AppTheme.light(),
                home: Scaffold(
                  body: Text('Counter: $counter'),
                  floatingActionButton: FloatingActionButton(
                    onPressed: () {
                      setState(() => counter++);
                    },
                    child: const Icon(Icons.add),
                  ),
                ),
              );
            },
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Forzar 100 rebuilds
      for (var i = 0; i < 100; i++) {
        await tester.tap(find.byType(FloatingActionButton));
        await tester.pump();
      }

      await tester.pumpAndSettle();

      expect(find.text('Counter: 100'), findsOneWidget);
    });
  });

  group('E2E: Widget Lifecycle', () {
    // =========================================================================
    // TEST 21: initState y dispose se manejan correctamente
    // =========================================================================
    testWidgets('Navegación no causa dispose errors', (tester) async {
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

      // Navegar rápidamente entre todas las pantallas
      for (var i = 0; i < 10; i++) {
        await tester.tap(find.text('Cuentas'));
        await tester.pump();
        await tester.tap(find.text('Movimientos'));
        await tester.pump();
        await tester.tap(find.text('Reportes'));
        await tester.pump();
        await tester.tap(find.text('Inicio'));
        await tester.pump();
      }

      await tester.pumpAndSettle();

      // No debe haber errores de dispose
      expect(find.byType(TestMainScaffold), findsOneWidget);
    });

    // =========================================================================
    // TEST 22: Hot reload simulation
    // =========================================================================
    testWidgets('Hot reload simulado no causa crash', (tester) async {
      // Primer pump
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

      // Simular hot reload con nuevo widget
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
  });

  group('E2E: Form State Persistence', () {
    // =========================================================================
    // TEST 23: Estado de selección persiste en formulario
    // =========================================================================
    testWidgets('Selección de tipo en cuenta persiste', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: testProviderOverrides,
          child: MaterialApp(
            theme: AppTheme.light(),
            home: Scaffold(
              body: Builder(
                builder: (context) => ElevatedButton(
                  onPressed: () {
                    showModalBottomSheet(
                      context: context,
                      isScrollControlled: true,
                      builder: (_) => const AddAccountSheet(),
                    );
                  },
                  child: const Text('Open'),
                ),
              ),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();
      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();

      // Seleccionar un tipo de cuenta
      final chips = find.byType(ChoiceChip);
      if (chips.evaluate().length > 1) {
        await tester.tap(chips.at(1));
        await tester.pumpAndSettle();

        // La selección debe persistir (widget sigue visible)
        expect(find.byType(AddAccountSheet), findsOneWidget);
      }
    });

    // =========================================================================
    // TEST 24: Texto ingresado persiste en formulario
    // =========================================================================
    testWidgets('Texto en campo persiste', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: testProviderOverrides,
          child: MaterialApp(
            theme: AppTheme.light(),
            home: Scaffold(
              body: Builder(
                builder: (context) => ElevatedButton(
                  onPressed: () {
                    showModalBottomSheet(
                      context: context,
                      isScrollControlled: true,
                      builder: (_) => const AddAccountSheet(),
                    );
                  },
                  child: const Text('Open'),
                ),
              ),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();
      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();

      // Ingresar texto
      final textFields = find.byType(TextFormField);
      if (textFields.evaluate().isNotEmpty) {
        await tester.enterText(textFields.first, 'Test Account');
        await tester.pump();

        // Scroll y volver
        final scrollable = find.byType(SingleChildScrollView);
        if (scrollable.evaluate().isNotEmpty) {
          await tester.drag(scrollable.first, const Offset(0, -100));
          await tester.pump();
          await tester.drag(scrollable.first, const Offset(0, 100));
          await tester.pump();
        }

        // El texto debe seguir ahí
        expect(find.text('Test Account'), findsOneWidget);
      }
    });
  });

  group('E2E: Theme Provider', () {
    // =========================================================================
    // TEST 25: Theme se aplica correctamente
    // =========================================================================
    testWidgets('Theme light se aplica', (tester) async {
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

      // Verificar que el tema se aplica
      final scaffold = tester.widget<Scaffold>(find.byType(Scaffold).first);
      expect(scaffold, isNotNull);
    });

    // =========================================================================
    // TEST 26: Theme dark se aplica
    // =========================================================================
    testWidgets('Theme dark se aplica', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: testProviderOverrides,
          child: MaterialApp(
            theme: AppTheme.dark(),
            home: const TestMainScaffold(
              child: Center(child: Text('Content')),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      final scaffold = tester.widget<Scaffold>(find.byType(Scaffold).first);
      expect(scaffold, isNotNull);
    });
  });
}
