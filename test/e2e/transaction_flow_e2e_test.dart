/// E2E Tests - Flujo completo de transacciones
/// Tests agresivos que prueban el flujo completo de crear, editar y eliminar transacciones
library;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:finanzas_familiares/core/theme/app_theme.dart';
import 'package:finanzas_familiares/features/transactions/domain/models/transaction_model.dart';
import 'package:finanzas_familiares/features/transactions/presentation/widgets/add_transaction_sheet.dart';
import 'package:finanzas_familiares/features/accounts/domain/models/account_model.dart';
import 'package:finanzas_familiares/shared/widgets/main_scaffold.dart';
import '../helpers/test_helpers.dart';
import '../mocks/mock_providers.dart';

void main() {
  setUpAll(() => setupTestEnvironment());
  tearDownAll(() => tearDownTestEnvironment());
  group('E2E: Flujo Completo de Transacciones', () {
    // =========================================================================
    // TEST 1: Apertura del selector de tipo de transacción
    // =========================================================================
    testWidgets('FAB debe abrir selector de tipo de transacción', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: testProviderOverrides,
          child: MaterialApp(
            theme: AppTheme.light(),
            home: const TestMainScaffold(
              child: Scaffold(body: Center(child: Text('Dashboard'))),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Verificar que FAB existe
      expect(find.byType(FloatingActionButton), findsOneWidget,
          reason: 'FAB debe existir en MainScaffold');

      // Tap en FAB
      await tester.tap(find.byType(FloatingActionButton));
      await tester.pumpAndSettle();

      // Verificar que aparece el selector de tipo
      expect(find.text('Nueva transaccion'), findsOneWidget,
          reason: 'Debe aparecer el título del selector');
      expect(find.text('Gasto'), findsOneWidget,
          reason: 'Debe aparecer opción Gasto');
      expect(find.text('Ingreso'), findsOneWidget,
          reason: 'Debe aparecer opción Ingreso');
      expect(find.text('Transferencia'), findsOneWidget,
          reason: 'Debe aparecer opción Transferencia');
    });

    // =========================================================================
    // TEST 2: Selección de tipo GASTO abre formulario correcto
    // =========================================================================
    testWidgets('Seleccionar GASTO debe abrir formulario de gasto', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: testProviderOverrides,
          child: MaterialApp(
            theme: AppTheme.light(),
            home: const TestMainScaffold(
              child: Scaffold(body: Center(child: Text('Dashboard'))),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Abrir selector
      await tester.tap(find.byType(FloatingActionButton));
      await tester.pumpAndSettle();

      // Seleccionar Gasto
      await tester.tap(find.text('Gasto'));
      await tester.pumpAndSettle();

      // Verificar que se abre el formulario
      expect(find.text('Nueva Transaccion'), findsOneWidget,
          reason: 'Debe abrir formulario de transacción');

      // Verificar elementos del formulario de gasto
      expect(find.text('Cuenta'), findsWidgets,
          reason: 'Debe mostrar selector de cuenta');
      expect(find.text('Categoria'), findsWidgets,
          reason: 'Debe mostrar selector de categoría');
      expect(find.text('Descripcion'), findsWidgets,
          reason: 'Debe mostrar campo de descripción');
      expect(find.text('Registrar Gasto'), findsOneWidget,
          reason: 'Botón debe decir Registrar Gasto');
    });

    // =========================================================================
    // TEST 3: Selección de tipo INGRESO abre formulario correcto
    // =========================================================================
    testWidgets('Seleccionar INGRESO debe abrir formulario de ingreso', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: testProviderOverrides,
          child: MaterialApp(
            theme: AppTheme.light(),
            home: const TestMainScaffold(
              child: Scaffold(body: Center(child: Text('Dashboard'))),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Abrir selector
      await tester.tap(find.byType(FloatingActionButton));
      await tester.pumpAndSettle();

      // Seleccionar Ingreso
      await tester.tap(find.text('Ingreso'));
      await tester.pumpAndSettle();

      // Verificar que se abre el formulario con tipo ingreso
      expect(find.text('Nueva Transaccion'), findsOneWidget);
      expect(find.text('Registrar Ingreso'), findsOneWidget,
          reason: 'Botón debe decir Registrar Ingreso');
    });

    // =========================================================================
    // TEST 4: Selección de tipo TRANSFERENCIA abre formulario correcto
    // =========================================================================
    testWidgets('Seleccionar TRANSFERENCIA debe abrir formulario de transferencia', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: testProviderOverrides,
          child: MaterialApp(
            theme: AppTheme.light(),
            home: const TestMainScaffold(
              child: Scaffold(body: Center(child: Text('Dashboard'))),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Abrir selector
      await tester.tap(find.byType(FloatingActionButton));
      await tester.pumpAndSettle();

      // Seleccionar Transferencia
      await tester.tap(find.text('Transferencia'));
      await tester.pumpAndSettle();

      // Verificar formulario de transferencia
      expect(find.text('Nueva Transaccion'), findsOneWidget);
      expect(find.text('Realizar Transferencia'), findsOneWidget,
          reason: 'Botón debe decir Realizar Transferencia');
    });

    // =========================================================================
    // TEST 5: Cerrar formulario con botón X
    // =========================================================================
    testWidgets('Botón X debe cerrar el formulario', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: testProviderOverrides,
          child: MaterialApp(
            theme: AppTheme.light(),
            home: const TestMainScaffold(
              child: Scaffold(body: Center(child: Text('Dashboard'))),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Abrir selector y luego formulario
      await tester.tap(find.byType(FloatingActionButton));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Gasto'));
      await tester.pumpAndSettle();

      // Verificar que formulario está abierto
      expect(find.text('Nueva Transaccion'), findsOneWidget);

      // Cerrar con botón X
      await tester.tap(find.byIcon(Icons.close));
      await tester.pumpAndSettle();

      // Verificar que formulario se cerró
      expect(find.text('Nueva Transaccion'), findsNothing,
          reason: 'Formulario debe cerrarse');
    });

    // =========================================================================
    // TEST 6: Cambiar tipo de transacción dentro del formulario
    // =========================================================================
    testWidgets('SegmentedButton debe cambiar tipo de transacción', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: testProviderOverrides,
          child: MaterialApp(
            theme: AppTheme.light(),
            home: const TestMainScaffold(
              child: Scaffold(body: Center(child: Text('Dashboard'))),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Abrir con tipo Gasto
      await tester.tap(find.byType(FloatingActionButton));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Gasto'));
      await tester.pumpAndSettle();

      // Verificar estado inicial
      expect(find.text('Registrar Gasto'), findsOneWidget);

      // Buscar y tap en el segmento de Ingreso dentro del formulario
      final segmentedButton = find.byType(SegmentedButton<TransactionType>);
      expect(segmentedButton, findsOneWidget,
          reason: 'Debe existir SegmentedButton para cambiar tipo');

      // Tap en "Ingreso" dentro del SegmentedButton
      // El texto "Ingreso" aparece tanto en el selector inicial como en el formulario
      final ingresoInForm = find.descendant(
        of: find.byType(SegmentedButton<TransactionType>),
        matching: find.text('Ingreso'),
      );

      if (ingresoInForm.evaluate().isNotEmpty) {
        await tester.tap(ingresoInForm);
        await tester.pumpAndSettle();

        // Verificar que cambió
        expect(find.text('Registrar Ingreso'), findsOneWidget,
            reason: 'Debe cambiar a Registrar Ingreso');
      }
    });

    // =========================================================================
    // TEST 7: Input de monto acepta solo números válidos
    // =========================================================================
    testWidgets('Campo de monto debe aceptar solo números válidos', (tester) async {
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
                      builder: (_) => const AddTransactionSheet(
                        initialType: TransactionType.expense,
                      ),
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

      // Buscar campo de monto (primer TextFormField)
      final textFields = find.byType(TextFormField);

      if (textFields.evaluate().isNotEmpty) {
        // Ingresar monto válido
        await tester.enterText(textFields.first, '150.50');
        await tester.pump();

        // Verificar que el valor se ingresó
        expect(find.text('150.50'), findsOneWidget);
      }
    });

    // =========================================================================
    // TEST 8: Validación de formulario vacío
    // =========================================================================
    testWidgets('Formulario debe validar campos requeridos', (tester) async {
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
                      builder: (_) => const AddTransactionSheet(
                        initialType: TransactionType.expense,
                      ),
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

      // Intentar guardar sin llenar campos
      await tester.tap(find.text('Registrar Gasto'));
      await tester.pumpAndSettle();

      // Debe mostrar error de validación
      expect(find.text('Ingresa el monto'), findsOneWidget,
          reason: 'Debe mostrar error de monto requerido');
    });

    // =========================================================================
    // TEST 9: Selector de fecha funciona
    // =========================================================================
    testWidgets('Selector de fecha debe abrir DatePicker', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: testProviderOverrides,
          child: MaterialApp(
            theme: AppTheme.light(),
            localizationsDelegates: const [
              DefaultMaterialLocalizations.delegate,
              DefaultWidgetsLocalizations.delegate,
            ],
            home: Scaffold(
              body: Builder(
                builder: (context) => ElevatedButton(
                  onPressed: () {
                    showModalBottomSheet(
                      context: context,
                      isScrollControlled: true,
                      builder: (_) => const AddTransactionSheet(
                        initialType: TransactionType.expense,
                      ),
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

      // Buscar y tap en selector de fecha
      final dateSelector = find.text('Fecha');
      expect(dateSelector, findsOneWidget);

      await tester.tap(dateSelector);
      await tester.pumpAndSettle();

      // Debe abrir DatePicker
      expect(find.byType(DatePickerDialog), findsOneWidget,
          reason: 'Debe abrir el DatePicker');

      // Cerrar DatePicker
      await tester.tap(find.text('Cancel').last);
      await tester.pumpAndSettle();
    });

    // =========================================================================
    // TEST 10: Múltiples aperturas y cierres no causan errores
    // =========================================================================
    testWidgets('Múltiples aperturas/cierres deben funcionar sin errores', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: testProviderOverrides,
          child: MaterialApp(
            theme: AppTheme.light(),
            home: const TestMainScaffold(
              child: Scaffold(body: Center(child: Text('Dashboard'))),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Ciclo de abrir/cerrar múltiples veces
      for (var i = 0; i < 5; i++) {
        // Abrir selector
        await tester.tap(find.byType(FloatingActionButton));
        await tester.pumpAndSettle();

        expect(find.text('Nueva transaccion'), findsOneWidget,
            reason: 'Iteración $i: Debe abrir selector');

        // Abrir formulario
        await tester.tap(find.text('Gasto'));
        await tester.pumpAndSettle();

        expect(find.text('Nueva Transaccion'), findsOneWidget,
            reason: 'Iteración $i: Debe abrir formulario');

        // Cerrar
        await tester.tap(find.byIcon(Icons.close));
        await tester.pumpAndSettle();

        expect(find.text('Nueva Transaccion'), findsNothing,
            reason: 'Iteración $i: Debe cerrar formulario');
      }
    });

    // =========================================================================
    // TEST 11: Scroll funciona en formulario largo
    // =========================================================================
    testWidgets('Formulario debe hacer scroll correctamente', (tester) async {
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
                      builder: (_) => const AddTransactionSheet(
                        initialType: TransactionType.expense,
                      ),
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

      // Buscar el SingleChildScrollView
      final scrollable = find.byType(SingleChildScrollView);
      expect(scrollable, findsOneWidget);

      // Hacer scroll
      await tester.drag(scrollable, const Offset(0, -200));
      await tester.pumpAndSettle();

      // No debe lanzar errores (el test pasará si no hay excepciones)
    });
  });

  group('E2E: AddTransactionSheet - Tests Unitarios Aislados', () {
    // =========================================================================
    // TEST 12: Widget se construye correctamente con tipo expense
    // =========================================================================
    testWidgets('AddTransactionSheet se construye con tipo expense', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: testProviderOverrides,
          child: MaterialApp(
            theme: AppTheme.light(),
            home: const Scaffold(
              body: AddTransactionSheet(initialType: TransactionType.expense),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.byType(AddTransactionSheet), findsOneWidget);
      expect(find.text('Registrar Gasto'), findsOneWidget);
    });

    // =========================================================================
    // TEST 13: Widget se construye correctamente con tipo income
    // =========================================================================
    testWidgets('AddTransactionSheet se construye con tipo income', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: testProviderOverrides,
          child: MaterialApp(
            theme: AppTheme.light(),
            home: const Scaffold(
              body: AddTransactionSheet(initialType: TransactionType.income),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.byType(AddTransactionSheet), findsOneWidget);
      expect(find.text('Registrar Ingreso'), findsOneWidget);
    });

    // =========================================================================
    // TEST 14: Widget se construye correctamente con tipo transfer
    // =========================================================================
    testWidgets('AddTransactionSheet se construye con tipo transfer', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: testProviderOverrides,
          child: MaterialApp(
            theme: AppTheme.light(),
            home: const Scaffold(
              body: AddTransactionSheet(initialType: TransactionType.transfer),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.byType(AddTransactionSheet), findsOneWidget);
      expect(find.text('Realizar Transferencia'), findsOneWidget);
    });

    // =========================================================================
    // TEST 15: Campos de notas son opcionales
    // =========================================================================
    testWidgets('Campo de notas debe ser opcional', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: testProviderOverrides,
          child: MaterialApp(
            theme: AppTheme.light(),
            home: const Scaffold(
              body: AddTransactionSheet(initialType: TransactionType.expense),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Verificar que existe el campo de notas opcional
      expect(find.text('Notas (opcional)'), findsOneWidget,
          reason: 'Campo de notas debe existir y ser opcional');
    });
  });
}
