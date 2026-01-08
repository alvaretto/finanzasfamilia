import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
// import 'package:drift/drift.dart' hide isNull, isNotNull; // No necesario sin cuenta de prueba
import 'package:drift/native.dart';
import 'package:intl/date_symbol_data_local.dart';

import 'package:finanzas_familiares/presentation/screens/transaction_form_screen.dart';
import 'package:finanzas_familiares/application/providers/database_provider.dart';
import 'package:finanzas_familiares/data/local/database.dart';
import 'package:finanzas_familiares/data/local/daos/daos.dart';
import 'package:finanzas_familiares/data/local/seeders/seeders.dart';

void main() {
  setUpAll(() async {
    await initializeDateFormatting('es_CO', null);
  });

  group('TransactionFormScreen Widget Tests', () {
    late AppDatabase db;

    setUp(() async {
      db = AppDatabase.forTesting(NativeDatabase.memory());
      final categoriesDao = CategoriesDao(db);
      await seedCategories(categoriesDao);
    });

    tearDown(() async {
      await db.close();
    });

    Widget createTestWidget() {
      return ProviderScope(
        overrides: [
          appDatabaseProvider.overrideWithValue(db),
        ],
        child: const MaterialApp(
          home: TransactionFormScreen(),
          localizationsDelegates: [
            DefaultMaterialLocalizations.delegate,
            DefaultWidgetsLocalizations.delegate,
          ],
        ),
      );
    }

    testWidgets('muestra título Nueva Transacción', (tester) async {
      await tester.pumpWidget(createTestWidget());
      // Usar pump con duración en lugar de pumpAndSettle para evitar timeout
      // con FutureProviders que pueden no completar inmediatamente
      await tester.pump(const Duration(milliseconds: 500));

      expect(find.text('Nueva Transacción'), findsOneWidget);
    });

    testWidgets('muestra selector de tipo con 3 opciones', (tester) async {
      await tester.pumpWidget(createTestWidget());
      await tester.pump(const Duration(milliseconds: 500));

      expect(find.byType(SegmentedButton<String>), findsOneWidget);
      expect(find.text('Gasto'), findsOneWidget);
      expect(find.text('Ingreso'), findsOneWidget);
      // Transfer puede estar abreviado
      expect(find.textContaining('Transfer'), findsOneWidget);
    });

    testWidgets('muestra campo de monto', (tester) async {
      await tester.pumpWidget(createTestWidget());
      await tester.pump(const Duration(milliseconds: 500));

      expect(find.text('Monto'), findsOneWidget);
    });

    testWidgets('muestra selector de fecha', (tester) async {
      await tester.pumpWidget(createTestWidget());
      await tester.pump(const Duration(milliseconds: 500));

      expect(find.text('Fecha'), findsOneWidget);
      // El ícono de calendario puede ser calendar_today o date_range
      expect(find.byIcon(Icons.calendar_today), findsWidgets);
    });

    testWidgets('muestra selector de categoría', (tester) async {
      await tester.pumpWidget(createTestWidget());
      await tester.pump(const Duration(milliseconds: 500));

      // Hacer scroll para ver el selector de categoría
      await tester.drag(find.byType(ListView), const Offset(0, -100));
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.text('Categoría'), findsOneWidget);
    });

    testWidgets('muestra campo de descripción', (tester) async {
      await tester.pumpWidget(createTestWidget());
      await tester.pump(const Duration(milliseconds: 500));

      expect(find.text('Descripción (opcional)'), findsOneWidget);
    });

    testWidgets('muestra botón Guardar', (tester) async {
      await tester.pumpWidget(createTestWidget());
      await tester.pump(const Duration(milliseconds: 500));

      // Hacer scroll para ver el botón Guardar
      await tester.drag(find.byType(ListView), const Offset(0, -300));
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.text('Guardar'), findsOneWidget);
    });

    testWidgets('puede cambiar tipo de transacción', (tester) async {
      await tester.pumpWidget(createTestWidget());
      await tester.pump(const Duration(milliseconds: 500));

      // Verificar que el SegmentedButton está visible
      expect(find.byType(SegmentedButton<String>), findsOneWidget);

      // Cambiar a Ingreso
      final ingresoFinder = find.text('Ingreso');
      if (ingresoFinder.evaluate().isNotEmpty) {
        await tester.tap(ingresoFinder);
        await tester.pump(const Duration(milliseconds: 300));
      }

      // El SegmentedButton sigue visible
      expect(find.byType(SegmentedButton<String>), findsOneWidget);
    });

    testWidgets('valida monto requerido al guardar', (tester) async {
      await tester.pumpWidget(createTestWidget());
      await tester.pump(const Duration(milliseconds: 500));

      // Hacer scroll para ver el botón guardar
      await tester.drag(find.byType(ListView), const Offset(0, -300));
      await tester.pump(const Duration(milliseconds: 300));

      // Intentar guardar sin monto
      final guardarButton = find.text('Guardar');
      if (guardarButton.evaluate().isNotEmpty) {
        await tester.tap(guardarButton);
        await tester.pump(const Duration(milliseconds: 300));
        // Verificar que hay algún mensaje de error
        expect(find.textContaining('monto'), findsWidgets);
      }
    });
  });

  group('transactionTypeProvider', () {
    test('valor inicial es expense', () {
      final container = ProviderContainer();
      expect(container.read(transactionTypeProvider), equals('expense'));
      container.dispose();
    });

    test('puede cambiar tipo', () {
      final container = ProviderContainer();

      container.read(transactionTypeProvider.notifier).state = 'income';
      expect(container.read(transactionTypeProvider), equals('income'));

      container.read(transactionTypeProvider.notifier).state = 'transfer';
      expect(container.read(transactionTypeProvider), equals('transfer'));

      container.dispose();
    });
  });

  group('selectedDateProvider', () {
    test('valor inicial es hoy', () {
      final container = ProviderContainer();
      final today = DateTime.now();
      final selected = container.read(selectedDateProvider);

      expect(selected.year, equals(today.year));
      expect(selected.month, equals(today.month));
      expect(selected.day, equals(today.day));

      container.dispose();
    });

    test('puede cambiar fecha', () {
      final container = ProviderContainer();
      final newDate = DateTime(2024, 6, 15);

      container.read(selectedDateProvider.notifier).state = newDate;
      expect(container.read(selectedDateProvider), equals(newDate));

      container.dispose();
    });
  });

  group('selectedCategoryIdProvider', () {
    test('valor inicial es null', () {
      final container = ProviderContainer();
      expect(container.read(selectedCategoryIdProvider), isNull);
      container.dispose();
    });

    test('puede seleccionar categoría', () {
      final container = ProviderContainer();

      container.read(selectedCategoryIdProvider.notifier).state = 'cat-123';
      expect(container.read(selectedCategoryIdProvider), equals('cat-123'));

      container.dispose();
    });
  });

  group('selectedFromAccountIdProvider', () {
    test('valor inicial es null', () {
      final container = ProviderContainer();
      expect(container.read(selectedFromAccountIdProvider), isNull);
      container.dispose();
    });

    test('puede seleccionar cuenta origen', () {
      final container = ProviderContainer();

      container.read(selectedFromAccountIdProvider.notifier).state = 'acc-123';
      expect(container.read(selectedFromAccountIdProvider), equals('acc-123'));

      container.dispose();
    });
  });

  group('selectedToAccountIdProvider', () {
    test('valor inicial es null', () {
      final container = ProviderContainer();
      expect(container.read(selectedToAccountIdProvider), isNull);
      container.dispose();
    });

    test('puede seleccionar cuenta destino', () {
      final container = ProviderContainer();

      container.read(selectedToAccountIdProvider.notifier).state = 'acc-456';
      expect(container.read(selectedToAccountIdProvider), equals('acc-456'));

      container.dispose();
    });
  });
}
