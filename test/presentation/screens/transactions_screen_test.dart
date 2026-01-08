import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:drift/drift.dart' hide isNotNull, isNull;
import 'package:drift/native.dart';
import 'package:intl/date_symbol_data_local.dart';

import 'package:finanzas_familiares/presentation/screens/transactions_screen.dart';
import 'package:finanzas_familiares/application/providers/database_provider.dart';
import 'package:finanzas_familiares/data/local/database.dart';
import 'package:finanzas_familiares/data/local/daos/daos.dart';
import 'package:finanzas_familiares/data/local/seeders/seeders.dart';

void main() {
  setUpAll(() async {
    await initializeDateFormatting('es_CO', null);
  });

  group('TransactionsScreen', () {
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
          home: TransactionsScreen(),
        ),
      );
    }

    testWidgets('muestra título Movimientos', (tester) async {
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      expect(find.text('Movimientos'), findsOneWidget);
    });

    testWidgets('muestra filtros de tipo', (tester) async {
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      expect(find.text('Todos'), findsOneWidget);
      expect(find.text('Gastos'), findsOneWidget);
      expect(find.text('Ingresos'), findsOneWidget);
      expect(find.text('Transferencias'), findsOneWidget);
    });

    testWidgets('muestra mensaje vacío sin transacciones', (tester) async {
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      expect(find.text('No hay movimientos'), findsOneWidget);
      expect(find.text('Toca + para agregar uno'), findsOneWidget);
    });

    testWidgets('muestra transacciones cuando existen', (tester) async {
      // Agregar transacción de prueba
      final transactionsDao = TransactionsDao(db);
      final categoriesDao = CategoriesDao(db);
      final categories = await categoriesDao.getAllCategories();
      final expenseCategory = categories.firstWhere(
        (c) => c.type == 'expense' && c.parentId != null,
      );

      await transactionsDao.insertTransaction(TransactionsCompanion.insert(
        id: 'tx-test-001',
        type: 'expense',
        amount: 50000,
        description: const Value('Café'),
        categoryId: expenseCategory.id,
        transactionDate: DateTime.now(),
      ));

      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      // Debería mostrar la transacción
      expect(find.text('Café'), findsOneWidget);
      // Verificar que hay texto con formato de moneda
      expect(find.textContaining('50'), findsWidgets);
    });

    testWidgets('filtra por tipo al seleccionar chip', (tester) async {
      // Agregar transacciones de diferentes tipos
      final transactionsDao = TransactionsDao(db);
      final categoriesDao = CategoriesDao(db);
      final categories = await categoriesDao.getAllCategories();
      final expenseCategory = categories.firstWhere(
        (c) => c.type == 'expense' && c.parentId != null,
      );
      final incomeCategory = categories.firstWhere(
        (c) => c.type == 'income' && c.parentId != null,
      );

      await transactionsDao.insertTransaction(TransactionsCompanion.insert(
        id: 'tx-expense-001',
        type: 'expense',
        amount: 30000,
        description: const Value('Gasto test'),
        categoryId: expenseCategory.id,
        transactionDate: DateTime.now(),
      ));

      await transactionsDao.insertTransaction(TransactionsCompanion.insert(
        id: 'tx-income-001',
        type: 'income',
        amount: 100000,
        description: const Value('Ingreso test'),
        categoryId: incomeCategory.id,
        transactionDate: DateTime.now(),
      ));

      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      // Ambas transacciones visibles inicialmente
      expect(find.text('Gasto test'), findsOneWidget);
      expect(find.text('Ingreso test'), findsOneWidget);

      // Filtrar solo gastos
      await tester.tap(find.text('Gastos'));
      await tester.pumpAndSettle();

      expect(find.text('Gasto test'), findsOneWidget);
      expect(find.text('Ingreso test'), findsNothing);

      // Filtrar solo ingresos
      await tester.tap(find.text('Ingresos'));
      await tester.pumpAndSettle();

      expect(find.text('Gasto test'), findsNothing);
      expect(find.text('Ingreso test'), findsOneWidget);
    });
  });

  group('transactionTypeFilterProvider', () {
    test('valor inicial es null', () {
      final container = ProviderContainer();
      expect(container.read(transactionTypeFilterProvider), isNull);
      container.dispose();
    });

    test('puede filtrar por tipo', () {
      final container = ProviderContainer();

      container.read(transactionTypeFilterProvider.notifier).state = 'expense';
      expect(container.read(transactionTypeFilterProvider), equals('expense'));

      container.read(transactionTypeFilterProvider.notifier).state = 'income';
      expect(container.read(transactionTypeFilterProvider), equals('income'));

      container.read(transactionTypeFilterProvider.notifier).state = null;
      expect(container.read(transactionTypeFilterProvider), isNull);

      container.dispose();
    });
  });

  group('selectedPeriodProvider', () {
    test('valor inicial es mes actual', () {
      final container = ProviderContainer();
      final now = DateTime.now();
      final period = container.read(selectedPeriodProvider);

      expect(period.start.month, equals(now.month));
      expect(period.start.year, equals(now.year));
      expect(period.end.month, equals(now.month));

      container.dispose();
    });
  });
}
