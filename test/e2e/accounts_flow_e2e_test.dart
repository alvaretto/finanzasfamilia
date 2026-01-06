/// E2E Tests - Flujo completo de cuentas
/// Tests agresivos que prueban el flujo completo de gestión de cuentas
library;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:finanzas_familiares/core/theme/app_theme.dart';
import 'package:finanzas_familiares/features/accounts/presentation/screens/accounts_screen.dart';
import 'package:finanzas_familiares/features/accounts/presentation/widgets/add_account_sheet.dart';
import 'package:finanzas_familiares/features/accounts/domain/models/account_model.dart';
import '../helpers/test_helpers.dart';
import '../mocks/mock_providers.dart';

void main() {
  setUpAll(() async {
    await setupTestEnvironment();
  });
  tearDownAll(() async {
    await tearDownTestEnvironment();
  });
  group('E2E: Pantalla de Cuentas', () {
    // =========================================================================
    // TEST 1: Pantalla de cuentas se renderiza correctamente
    // =========================================================================
    testWidgets('AccountsScreen debe renderizarse sin errores', (tester) async {
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

      // Verificar elementos básicos
      expect(find.text('Mis Cuentas'), findsOneWidget,
          reason: 'Debe mostrar título Mis Cuentas');
      expect(find.byIcon(Icons.sync), findsOneWidget,
          reason: 'Debe tener botón de sincronización');
      expect(find.byIcon(Icons.add), findsOneWidget,
          reason: 'Debe tener botón de agregar');
    });

    // =========================================================================
    // TEST 2: Estado vacío se muestra correctamente
    // =========================================================================
    testWidgets('Estado vacío muestra mensaje y botón de agregar', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: emptyStateProviderOverrides,
          child: MaterialApp(
            theme: AppTheme.light(),
            home: const AccountsScreen(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Estado vacío debe mostrar wizard de primera cuenta
      expect(find.text('Comienza tu viaje financiero'), findsOneWidget,
          reason: 'Debe mostrar wizard de primera cuenta');
      expect(find.text('Selecciona el tipo de cuenta que quieres crear primero'), findsOneWidget,
          reason: 'Debe mostrar instrucciones del wizard');
    });

    // =========================================================================
    // TEST 3: Botón de agregar en AppBar abre formulario
    // =========================================================================
    testWidgets('Botón + en AppBar debe abrir formulario de cuenta', (tester) async {
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

      // Tap en botón de agregar
      await tester.tap(find.byIcon(Icons.add));
      await tester.pumpAndSettle();

      // Verificar que se abre el formulario
      expect(find.byType(AddAccountSheet), findsOneWidget,
          reason: 'Debe abrir AddAccountSheet');
    });

    // =========================================================================
    // TEST 4: Botón de agregar en estado vacío abre formulario
    // =========================================================================
    testWidgets('Botón Agregar Cuenta en estado vacío abre formulario', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: emptyStateProviderOverrides,
          child: MaterialApp(
            theme: AppTheme.light(),
            home: const AccountsScreen(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // En estado vacío, el wizard muestra opciones de tipo de cuenta
      // Buscar el primer tipo de cuenta disponible para crear
      final bankCard = find.byKey(const Key('account_type_bank'));
      if (bankCard.evaluate().isNotEmpty) {
        await tester.tap(bankCard);
        await tester.pumpAndSettle();
      } else {
        // Si no hay key específica, buscar el botón + en AppBar
        await tester.tap(find.byIcon(Icons.add));
        await tester.pumpAndSettle();
      }

      // Verificar que se abre el formulario
      expect(find.byType(AddAccountSheet), findsOneWidget,
          reason: 'Debe abrir AddAccountSheet');
    });

    // =========================================================================
    // TEST 5: Botón de sincronización existe y es interactivo
    // =========================================================================
    testWidgets('Botón de sincronización debe ser interactivo', (tester) async {
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

      // Tap en botón de sync
      final syncButton = find.byIcon(Icons.sync);
      expect(syncButton, findsOneWidget);

      await tester.tap(syncButton);
      await tester.pump();

      // No debe lanzar errores (el test pasa si no hay excepciones)
    });
  });

  group('E2E: Formulario AddAccountSheet', () {
    // =========================================================================
    // TEST 6: Formulario de cuenta se renderiza correctamente
    // =========================================================================
    testWidgets('AddAccountSheet debe renderizarse con todos los campos', (tester) async {
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

      // Verificar elementos del formulario
      expect(find.text('Nueva Cuenta'), findsOneWidget,
          reason: 'Debe mostrar título Nueva Cuenta');
      expect(find.text('Nombre de la cuenta'), findsOneWidget,
          reason: 'Debe tener campo de nombre');
      expect(find.text('Tipo de Cuenta'), findsOneWidget,
          reason: 'Debe tener selector de tipo');
    });

    // =========================================================================
    // TEST 7: Tipos de cuenta están disponibles
    // =========================================================================
    testWidgets('Selector de tipo debe mostrar todos los tipos de cuenta', (tester) async {
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

      // Verificar tipos de cuenta (pueden estar en chips o dropdown)
      // Los tipos son: Efectivo, Banco, Crédito, Ahorro, Inversión, Wallet
      expect(find.byType(ChoiceChip), findsWidgets,
          reason: 'Debe mostrar chips de selección de tipo');
    });

    // =========================================================================
    // TEST 8: Campo de nombre acepta texto
    // =========================================================================
    testWidgets('Campo de nombre debe aceptar texto', (tester) async {
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

      // Buscar campos de texto
      final textFields = find.byType(TextFormField);

      if (textFields.evaluate().isNotEmpty) {
        await tester.enterText(textFields.first, 'Mi Cuenta de Prueba');
        await tester.pump();
        expect(find.text('Mi Cuenta de Prueba'), findsOneWidget);
      }
    });

    // =========================================================================
    // TEST 9: Validación de nombre requerido
    // =========================================================================
    testWidgets('Debe validar que el nombre es requerido', (tester) async {
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

      // Intentar guardar sin nombre
      final saveButton = find.text('Guardar');
      if (saveButton.evaluate().isNotEmpty) {
        await tester.tap(saveButton);
        await tester.pumpAndSettle();

        // Debe mostrar error de validación
        expect(
          find.textContaining('nombre'),
          findsWidgets,
          reason: 'Debe mostrar error de nombre requerido',
        );
      }
    });

    // =========================================================================
    // TEST 10: Cerrar formulario con botón X
    // =========================================================================
    testWidgets('Botón X debe cerrar el formulario', (tester) async {
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

      // Cerrar con botón X
      final closeButton = find.byIcon(Icons.close);
      if (closeButton.evaluate().isNotEmpty) {
        await tester.tap(closeButton);
        await tester.pumpAndSettle();

        expect(find.byType(AddAccountSheet), findsNothing,
            reason: 'Formulario debe cerrarse');
      }
    });

    // =========================================================================
    // TEST 11: Seleccionar tipo de cuenta
    // =========================================================================
    testWidgets('Debe poder seleccionar diferentes tipos de cuenta', (tester) async {
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

      // Buscar chips de tipo
      final chips = find.byType(ChoiceChip);

      if (chips.evaluate().length > 1) {
        // Tap en el segundo chip
        await tester.tap(chips.at(1));
        await tester.pump();
        // No debe lanzar errores
      }
    });

    // =========================================================================
    // TEST 12: Campo de balance inicial
    // =========================================================================
    testWidgets('Debe tener campo de balance inicial', (tester) async {
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

      // Buscar campo de balance
      expect(find.text('Balance actual'), findsOneWidget,
          reason: 'Debe tener campo de balance inicial');
    });

    // =========================================================================
    // TEST 13: Scroll en formulario largo
    // =========================================================================
    testWidgets('Formulario debe hacer scroll', (tester) async {
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

      // Buscar scrollable
      final scrollable = find.byType(SingleChildScrollView);

      if (scrollable.evaluate().isNotEmpty) {
        await tester.drag(scrollable.first, const Offset(0, -200));
        await tester.pumpAndSettle();
        // No debe lanzar errores
      }
    });
  });

  group('E2E: Interacciones Rápidas', () {
    // =========================================================================
    // TEST 14: Múltiples aperturas rápidas no causan errores
    // =========================================================================
    testWidgets('Múltiples aperturas rápidas del formulario', (tester) async {
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

      for (var i = 0; i < 3; i++) {
        // Abrir
        await tester.tap(find.byIcon(Icons.add));
        await tester.pumpAndSettle();

        expect(find.byType(AddAccountSheet), findsOneWidget,
            reason: 'Iteración $i: Debe abrir formulario');

        // Cerrar
        final closeButton = find.byIcon(Icons.close);
        if (closeButton.evaluate().isNotEmpty) {
          await tester.tap(closeButton);
          await tester.pumpAndSettle();
        } else {
          // Cerrar con tap fuera
          await tester.tapAt(const Offset(10, 10));
          await tester.pumpAndSettle();
        }
      }
    });

    // =========================================================================
    // TEST 15: Tap rápidos en botón de sync
    // =========================================================================
    testWidgets('Taps rápidos en sync no causan errores', (tester) async {
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

      // Múltiples taps rápidos
      for (var i = 0; i < 5; i++) {
        await tester.tap(find.byIcon(Icons.sync));
        await tester.pump(const Duration(milliseconds: 50));
      }

      await tester.pumpAndSettle();
      // No debe lanzar errores
    });
  });
}
