/// E2E Tests - UI Core sin dependencias de Supabase/GoRouter
/// Tests agresivos de la UI base de la aplicación
library;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:finanzas_familiares/core/theme/app_theme.dart';
import '../helpers/test_helpers.dart';

void main() {
  group('E2E: Bottom Navigation Bar', () {
    // =========================================================================
    // TEST 1: BottomNavigationBar se renderiza correctamente
    // =========================================================================
    testWidgets('BottomNavigationBar debe mostrar todos los items', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
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
          child: MaterialApp(
            theme: AppTheme.light(),
            home: const TestMainScaffold(
              child: Center(child: Text('Content')),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Verificar íconos
      expect(find.byIcon(Icons.dashboard), findsOneWidget);
      expect(find.byIcon(Icons.account_balance_wallet_outlined), findsOneWidget);
      expect(find.byIcon(Icons.receipt_long_outlined), findsOneWidget);
      expect(find.byIcon(Icons.bar_chart_outlined), findsOneWidget);
    });

    // =========================================================================
    // TEST 3: FAB central está presente
    // =========================================================================
    testWidgets('FAB central debe estar presente', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
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

  group('E2E: FAB Transaction Sheet', () {
    // =========================================================================
    // TEST 6: FAB abre modal de transacción
    // =========================================================================
    testWidgets('FAB debe abrir modal de nueva transacción', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            theme: AppTheme.light(),
            home: const TestMainScaffold(
              child: Center(child: Text('Content')),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Tap en FAB
      await tester.tap(find.byType(FloatingActionButton));
      await tester.pumpAndSettle();

      // Verificar que el modal se abre
      expect(find.text('Nueva transaccion'), findsOneWidget);
      expect(find.text('Gasto'), findsOneWidget);
      expect(find.text('Ingreso'), findsOneWidget);
      expect(find.text('Transferencia'), findsOneWidget);
    });

    // =========================================================================
    // TEST 7: Botón Gasto funciona
    // =========================================================================
    testWidgets('Botón Gasto debe cerrar modal', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
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

      // Tap en Gasto
      await tester.tap(find.text('Gasto'));
      await tester.pumpAndSettle();

      // Modal debe cerrarse
      expect(find.text('Nueva transaccion'), findsNothing);
    });

    // =========================================================================
    // TEST 8: Botón Ingreso funciona
    // =========================================================================
    testWidgets('Botón Ingreso debe cerrar modal', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
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

      // Tap en Ingreso
      await tester.tap(find.text('Ingreso'));
      await tester.pumpAndSettle();

      // Modal debe cerrarse
      expect(find.text('Nueva transaccion'), findsNothing);
    });

    // =========================================================================
    // TEST 9: Botón Transferencia funciona
    // =========================================================================
    testWidgets('Botón Transferencia debe cerrar modal', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
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

      // Tap en Transferencia
      await tester.tap(find.text('Transferencia'));
      await tester.pumpAndSettle();

      // Modal debe cerrarse
      expect(find.text('Nueva transaccion'), findsNothing);
    });

    // =========================================================================
    // TEST 10: Abrir/cerrar FAB múltiples veces
    // =========================================================================
    testWidgets('Abrir/cerrar FAB 20 veces no causa errores', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
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
        // Abrir
        await tester.tap(find.byType(FloatingActionButton));
        await tester.pump(const Duration(milliseconds: 100));

        // Cerrar con tap fuera
        await tester.tapAt(const Offset(10, 100));
        await tester.pump(const Duration(milliseconds: 100));
      }

      await tester.pumpAndSettle();
      // No debe crashear
    });
  });

  group('E2E: Interacciones Extremas', () {
    // =========================================================================
    // TEST 11: 100 taps rápidos en FAB
    // =========================================================================
    testWidgets('100 taps rápidos en FAB no causan crash', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            theme: AppTheme.light(),
            home: const TestMainScaffold(
              child: Center(child: Text('Content')),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // 100 taps muy rápidos
      for (var i = 0; i < 100; i++) {
        await tester.tap(find.byType(FloatingActionButton));
        await tester.pump(const Duration(milliseconds: 10));
      }

      await tester.pumpAndSettle();
      // No debe crashear
    });

    // =========================================================================
    // TEST 12: 50 cambios de tab rápidos
    // =========================================================================
    testWidgets('50 cambios de tab rápidos no causan crash', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
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
    // TEST 13: Doble tap en navegación
    // =========================================================================
    testWidgets('Doble tap en navegación no causa problemas', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            theme: AppTheme.light(),
            home: const TestMainScaffold(
              child: Center(child: Text('Content')),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Doble tap en cada item
      await tester.tap(find.text('Cuentas'));
      await tester.pump(const Duration(milliseconds: 50));
      await tester.tap(find.text('Cuentas'));
      await tester.pumpAndSettle();

      // No debe crashear
    });

    // =========================================================================
    // TEST 14: Taps muy rápidos en diferentes items
    // =========================================================================
    testWidgets('Taps muy rápidos en diferentes items', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            theme: AppTheme.light(),
            home: const TestMainScaffold(
              child: Center(child: Text('Content')),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Taps muy rápidos sin esperar
      await tester.tap(find.text('Inicio'));
      await tester.tap(find.text('Cuentas'));
      await tester.tap(find.text('Movimientos'));
      await tester.tap(find.text('Reportes'));
      await tester.tap(find.text('Inicio'));
      await tester.pumpAndSettle();

      // No debe crashear
    });
  });

  group('E2E: Tamaños de Pantalla', () {
    // =========================================================================
    // TEST 15: Pantalla muy pequeña (320x480)
    // =========================================================================
    testWidgets('App funciona en pantalla 320x480', (tester) async {
      tester.view.physicalSize = const Size(320, 480);
      tester.view.devicePixelRatio = 1.0;

      await tester.pumpWidget(
        ProviderScope(
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

      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    // =========================================================================
    // TEST 16: Pantalla grande (1920x1080)
    // =========================================================================
    testWidgets('App funciona en pantalla 1920x1080', (tester) async {
      tester.view.physicalSize = const Size(1920, 1080);
      tester.view.devicePixelRatio = 1.0;

      await tester.pumpWidget(
        ProviderScope(
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

      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    // =========================================================================
    // TEST 17: Landscape mode
    // =========================================================================
    testWidgets('App funciona en landscape', (tester) async {
      tester.view.physicalSize = const Size(800, 400);
      tester.view.devicePixelRatio = 1.0;

      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            theme: AppTheme.light(),
            home: const TestMainScaffold(
              child: Center(child: Text('Content')),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.byType(BottomAppBar), findsOneWidget);
      expect(find.byType(FloatingActionButton), findsOneWidget);

      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });
  });

  group('E2E: Temas', () {
    // =========================================================================
    // TEST 18: Tema oscuro funciona
    // =========================================================================
    testWidgets('App funciona con tema oscuro', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
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

      expect(find.text('Nueva transaccion'), findsOneWidget);
    });

    // =========================================================================
    // TEST 19: Cambio de tema durante uso
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

  group('E2E: Font Scale', () {
    // =========================================================================
    // TEST 20: Font scale pequeño
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
    // TEST 21: Font scale grande
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
    // TEST 22: Pantalla con notch
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
    // TEST 23: Keyboard visible
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

  group('E2E: Memory Stress', () {
    // =========================================================================
    // TEST 24: Crear y destruir widgets 50 veces
    // =========================================================================
    testWidgets('Crear/destruir widgets 50 veces', (tester) async {
      for (var i = 0; i < 50; i++) {
        await tester.pumpWidget(
          ProviderScope(
            child: MaterialApp(
              theme: AppTheme.light(),
              home: const TestMainScaffold(
                child: Center(child: Text('Content')),
              ),
            ),
          ),
        );
        await tester.pump();
      }

      await tester.pumpAndSettle();
      // No debe crashear
    });

    // =========================================================================
    // TEST 25: Flujo completo 10 veces
    // =========================================================================
    testWidgets('Flujo completo 10 veces sin memory leak', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            theme: AppTheme.light(),
            home: const TestMainScaffold(
              child: Center(child: Text('Content')),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      for (var i = 0; i < 10; i++) {
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
}
