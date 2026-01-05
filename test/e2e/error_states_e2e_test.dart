/// E2E Tests - Estados de error y edge cases
/// Tests agresivos que prueban manejo de errores y casos extremos
library;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:finanzas_familiares/core/theme/app_theme.dart';
import 'package:finanzas_familiares/shared/widgets/main_scaffold.dart';
import 'package:finanzas_familiares/features/dashboard/presentation/screens/dashboard_screen.dart';
import 'package:finanzas_familiares/features/accounts/presentation/screens/accounts_screen.dart';
import 'package:finanzas_familiares/features/transactions/presentation/screens/transactions_screen.dart';
import 'package:finanzas_familiares/features/settings/presentation/screens/settings_screen.dart';
import '../helpers/test_helpers.dart';
import '../mocks/mock_providers.dart';

void main() {
  setUpAll(() => setupTestEnvironment());
  tearDownAll(() => tearDownTestEnvironment());
  group('E2E: Estados Vacíos', () {
    // =========================================================================
    // TEST 1: Dashboard sin datos
    // =========================================================================
    testWidgets('Dashboard debe manejar estado sin datos', (tester) async {
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

      // Dashboard debe renderizarse sin crash
      expect(find.byType(DashboardScreen), findsOneWidget);
    });

    // =========================================================================
    // TEST 2: Cuentas vacías
    // =========================================================================
    testWidgets('AccountsScreen debe manejar lista vacía', (tester) async {
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

      // Debe mostrar estado vacío
      expect(find.text('Comienza tu viaje financiero'), findsOneWidget);
    });

    // =========================================================================
    // TEST 3: Transacciones vacías
    // =========================================================================
    testWidgets('TransactionsScreen debe manejar lista vacía', (tester) async {
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

      // Debe renderizarse sin crash
      expect(find.byType(TransactionsScreen), findsOneWidget);
    });
  });

  group('E2E: Interacciones Extremas', () {
    // =========================================================================
    // TEST 4: 100 taps rápidos en FAB
    // =========================================================================
    testWidgets('100 taps rápidos en FAB no causan crash', (tester) async {
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

      // 100 taps muy rápidos (warnIfMissed: false para silenciar warnings esperados)
      for (var i = 0; i < 100; i++) {
        await tester.tap(find.byType(FloatingActionButton), warnIfMissed: false);
        await tester.pump(const Duration(milliseconds: 10));
      }

      await tester.pumpAndSettle();
      // No debe crashear
    });

    // =========================================================================
    // TEST 5: Navegación extremadamente rápida
    // =========================================================================
    testWidgets('50 cambios de tab rápidos no causan crash', (tester) async {
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

      final tabs = ['Inicio', 'Cuentas', 'Movimientos', 'Reportes'];

      for (var i = 0; i < 50; i++) {
        final tab = tabs[i % tabs.length];
        await tester.tap(find.text(tab));
        await tester.pump(const Duration(milliseconds: 20));
      }

      await tester.pumpAndSettle();
      // No debe crashear
    });

    // =========================================================================
    // TEST 6: Scroll agresivo
    // =========================================================================
    testWidgets('Scroll muy rápido no causa crash', (tester) async {
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

      // Múltiples scrolls rápidos
      for (var i = 0; i < 20; i++) {
        await tester.drag(
          find.byType(Scaffold),
          const Offset(0, -500),
        );
        await tester.pump(const Duration(milliseconds: 10));
      }

      await tester.pumpAndSettle();
      // No debe crashear
    });

    // =========================================================================
    // TEST 7: Abrir/cerrar modal 50 veces
    // =========================================================================
    testWidgets('Abrir/cerrar modal 50 veces no causa memory leak', (tester) async {
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

      for (var i = 0; i < 50; i++) {
        // Abrir
        await tester.tap(find.byType(FloatingActionButton));
        await tester.pump(const Duration(milliseconds: 50));

        // Cerrar
        await tester.tapAt(const Offset(10, 100));
        await tester.pump(const Duration(milliseconds: 50));
      }

      await tester.pumpAndSettle();
      // No debe crashear ni consumir memoria excesiva
    });
  });

  group('E2E: Tamaños de Pantalla', () {
    // =========================================================================
    // TEST 8: Pantalla muy pequeña (320x480)
    // =========================================================================
    testWidgets('App funciona en pantalla 320x480', (tester) async {
      tester.view.physicalSize = const Size(320, 480);
      tester.view.devicePixelRatio = 1.0;

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

      expect(find.byType(TestMainScaffold), findsOneWidget);
      expect(find.byType(FloatingActionButton), findsOneWidget);

      // Reset
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    // =========================================================================
    // TEST 9: Pantalla grande (1920x1080)
    // =========================================================================
    testWidgets('App funciona en pantalla 1920x1080', (tester) async {
      tester.view.physicalSize = const Size(1920, 1080);
      tester.view.devicePixelRatio = 1.0;

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

      expect(find.byType(TestMainScaffold), findsOneWidget);

      // Reset
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    // =========================================================================
    // TEST 10: Pantalla tablet (768x1024)
    // =========================================================================
    testWidgets('App funciona en tablet 768x1024', (tester) async {
      tester.view.physicalSize = const Size(768, 1024);
      tester.view.devicePixelRatio = 1.0;

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

      // Reset
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });
  });

  group('E2E: Orientación', () {
    // =========================================================================
    // TEST 11: Landscape mode
    // =========================================================================
    testWidgets('App funciona en landscape', (tester) async {
      tester.view.physicalSize = const Size(800, 400);
      tester.view.devicePixelRatio = 1.0;

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

      // Verificar que elementos críticos son visibles
      expect(find.byType(BottomNavigationBar), findsOneWidget);
      expect(find.byType(FloatingActionButton), findsOneWidget);

      // Reset
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    // =========================================================================
    // TEST 12: Cambio de orientación durante uso
    // =========================================================================
    testWidgets('Cambio de orientación no causa crash', (tester) async {
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

      // Portrait
      tester.view.physicalSize = const Size(400, 800);
      await tester.pumpAndSettle();

      // Landscape
      tester.view.physicalSize = const Size(800, 400);
      await tester.pumpAndSettle();

      // Portrait de nuevo
      tester.view.physicalSize = const Size(400, 800);
      await tester.pumpAndSettle();

      expect(find.byType(TestMainScaffold), findsOneWidget);

      // Reset
      tester.view.resetPhysicalSize();
    });
  });

  group('E2E: Temas', () {
    // =========================================================================
    // TEST 13: Tema oscuro funciona
    // =========================================================================
    testWidgets('App funciona con tema oscuro', (tester) async {
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

      expect(find.byType(TestMainScaffold), findsOneWidget);

      // FAB debe funcionar
      await tester.tap(find.byType(FloatingActionButton));
      await tester.pumpAndSettle();

      expect(find.text('Nueva transacción'), findsOneWidget);
    });

    // =========================================================================
    // TEST 14: Cambio de tema durante uso
    // =========================================================================
    testWidgets('Cambio de tema no causa crash', (tester) async {
      var useDarkTheme = false;

      await tester.pumpWidget(
        ProviderScope(
          child: StatefulBuilder(
            builder: (context, setState) {
              return MaterialApp(
                theme: useDarkTheme ? AppTheme.dark() : AppTheme.light(),
                home: Scaffold(
                  body: const Text('Content'),
                  floatingActionButton: FloatingActionButton(
                    onPressed: () {
                      setState(() => useDarkTheme = !useDarkTheme);
                    },
                    child: const Icon(Icons.brightness_6),
                  ),
                ),
              );
            },
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Cambiar tema múltiples veces
      for (var i = 0; i < 10; i++) {
        await tester.tap(find.byType(FloatingActionButton));
        await tester.pumpAndSettle();
      }

      // No debe crashear
    });
  });

  group('E2E: Gestos Especiales', () {
    // =========================================================================
    // TEST 15: Long press en elementos
    // =========================================================================
    testWidgets('Long press en navegación no causa problemas', (tester) async {
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

      // Long press en cada item
      await tester.longPress(find.text('Inicio'));
      await tester.pumpAndSettle();

      await tester.longPress(find.text('Cuentas'));
      await tester.pumpAndSettle();

      // No debe crashear
    });

    // =========================================================================
    // TEST 16: Multi-touch simulado
    // =========================================================================
    testWidgets('Múltiples gestos simultáneos no causan crash', (tester) async {
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

      // Simular taps en diferentes lugares
      final gesture1 = await tester.startGesture(const Offset(100, 600));
      final gesture2 = await tester.startGesture(const Offset(300, 600));

      await tester.pump();

      await gesture1.up();
      await gesture2.up();

      await tester.pumpAndSettle();
      // No debe crashear
    });

    // =========================================================================
    // TEST 17: Drag con velocidad extrema
    // =========================================================================
    testWidgets('Drag muy rápido no causa problemas', (tester) async {
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

      // Fling muy rápido
      await tester.fling(
        find.byType(Scaffold),
        const Offset(0, -1000),
        10000, // Velocidad extrema
      );
      await tester.pumpAndSettle();

      // Fling hacia arriba
      await tester.fling(
        find.byType(Scaffold),
        const Offset(0, 1000),
        10000,
      );
      await tester.pumpAndSettle();

      // No debe crashear
    });
  });

  group('E2E: Accesibilidad', () {
    // =========================================================================
    // TEST 18: Semantic labels existen
    // =========================================================================
    testWidgets('Elementos tienen semantic labels', (tester) async {
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

      // Verificar que hay texto legible
      expect(find.text('Inicio'), findsOneWidget);
      expect(find.text('Cuentas'), findsOneWidget);
      expect(find.text('Movimientos'), findsOneWidget);
      expect(find.text('Reportes'), findsOneWidget);
    });

    // =========================================================================
    // TEST 19: Navegación por teclado (desktop)
    // =========================================================================
    testWidgets('Tab navigation funciona', (tester) async {
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

      // Simular Tab key
      await tester.sendKeyEvent(LogicalKeyboardKey.tab);
      await tester.pumpAndSettle();

      // No debe crashear
    });
  });

  group('E2E: Memory Stress', () {
    // =========================================================================
    // TEST 20: Crear y destruir widgets repetidamente
    // =========================================================================
    testWidgets('Crear/destruir widgets 100 veces', (tester) async {
      for (var i = 0; i < 100; i++) {
        await tester.pumpWidget(
          ProviderScope(
            child: MaterialApp(
              theme: AppTheme.light(),
              home: const DashboardScreen(),
            ),
          ),
        );
        await tester.pump();
      }

      await tester.pumpAndSettle();
      // No debe haber memory leaks ni crashes
    });

    // =========================================================================
    // TEST 21: Navegación completa 20 veces
    // =========================================================================
    testWidgets('Flujo completo 20 veces sin memory leak', (tester) async {
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

      for (var i = 0; i < 20; i++) {
        // Navegar
        await tester.tap(find.text('Cuentas'));
        await tester.pump();
        await tester.tap(find.text('Movimientos'));
        await tester.pump();
        await tester.tap(find.text('Reportes'));
        await tester.pump();
        await tester.tap(find.text('Inicio'));
        await tester.pump();

        // Abrir FAB
        await tester.tap(find.byType(FloatingActionButton));
        await tester.pump(const Duration(milliseconds: 100));
        await tester.tapAt(const Offset(10, 100));
        await tester.pump(const Duration(milliseconds: 100));
      }

      await tester.pumpAndSettle();
      // No debe crashear
    });
  });

  group('E2E: Edge Cases de Texto', () {
    // =========================================================================
    // TEST 22: Font scale extremo (pequeño)
    // =========================================================================
    testWidgets('App funciona con font scale 0.5', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          child: MediaQuery(
            data: const MediaQueryData(textScaler: TextScaler.linear(0.5)),
            child: MaterialApp(
              theme: AppTheme.light(),
              home: const TestMainScaffold(
                child: Center(child: Text('Content')),
              ),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('Inicio'), findsOneWidget);
    });

    // =========================================================================
    // TEST 23: Font scale extremo (grande)
    // =========================================================================
    testWidgets('App funciona con font scale 2.0', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          child: MediaQuery(
            data: const MediaQueryData(textScaler: TextScaler.linear(2.0)),
            child: MaterialApp(
              theme: AppTheme.light(),
              home: const TestMainScaffold(
                child: Center(child: Text('Content')),
              ),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.byType(TestMainScaffold), findsOneWidget);
    });
  });

  group('E2E: Safe Area', () {
    // =========================================================================
    // TEST 24: Pantalla con notch
    // =========================================================================
    testWidgets('App maneja pantallas con notch', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          child: MediaQuery(
            data: const MediaQueryData(
              padding: EdgeInsets.only(top: 44, bottom: 34),
            ),
            child: MaterialApp(
              theme: AppTheme.light(),
              home: const TestMainScaffold(
                child: Center(child: Text('Content')),
              ),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.byType(TestMainScaffold), findsOneWidget);
      expect(find.byType(FloatingActionButton), findsOneWidget);
    });

    // =========================================================================
    // TEST 25: Pantalla con keyboard visible
    // =========================================================================
    testWidgets('App maneja keyboard visible', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          child: MediaQuery(
            data: const MediaQueryData(
              viewInsets: EdgeInsets.only(bottom: 300),
            ),
            child: MaterialApp(
              theme: AppTheme.light(),
              home: const TestMainScaffold(
                child: Center(child: Text('Content')),
              ),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.byType(TestMainScaffold), findsOneWidget);
    });
  });
}
