import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:drift/drift.dart' hide isNotNull, isNull;
import 'package:drift/native.dart';
import 'package:intl/date_symbol_data_local.dart';

import 'package:finanzas_familiares/presentation/screens/budgets_screen.dart';
import 'package:finanzas_familiares/application/providers/database_provider.dart';
import 'package:finanzas_familiares/data/local/database.dart';
import 'package:finanzas_familiares/data/local/daos/daos.dart';
import 'package:finanzas_familiares/data/local/seeders/seeders.dart';

void main() {
  setUpAll(() async {
    await initializeDateFormatting('es_CO', null);
  });

  group('BudgetsScreen', () {
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
          home: BudgetsScreen(),
        ),
      );
    }

    testWidgets('muestra título Presupuestos', (tester) async {
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      expect(find.text('Presupuestos'), findsOneWidget);
    });

    testWidgets('muestra selector de período', (tester) async {
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      final now = DateTime.now();
      final monthNames = [
        '', 'Enero', 'Febrero', 'Marzo', 'Abril', 'Mayo', 'Junio',
        'Julio', 'Agosto', 'Septiembre', 'Octubre', 'Noviembre', 'Diciembre'
      ];

      expect(find.text('${monthNames[now.month]} ${now.year}'), findsOneWidget);
      expect(find.byIcon(Icons.chevron_left), findsOneWidget);
      expect(find.byIcon(Icons.chevron_right), findsOneWidget);
    });

    testWidgets('muestra mensaje vacío sin presupuestos', (tester) async {
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      expect(find.text('No hay presupuestos'), findsOneWidget);
      expect(find.text('Toca + para crear uno'), findsOneWidget);
    });

    testWidgets('cambia período al tocar flechas', (tester) async {
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      final now = DateTime.now();
      final monthNames = [
        '', 'Enero', 'Febrero', 'Marzo', 'Abril', 'Mayo', 'Junio',
        'Julio', 'Agosto', 'Septiembre', 'Octubre', 'Noviembre', 'Diciembre'
      ];

      // Ir al mes anterior
      await tester.tap(find.byIcon(Icons.chevron_left));
      await tester.pumpAndSettle();

      final prevMonth = now.month == 1 ? 12 : now.month - 1;
      final prevYear = now.month == 1 ? now.year - 1 : now.year;

      expect(find.text('${monthNames[prevMonth]} $prevYear'), findsOneWidget);
    });

    testWidgets('muestra presupuesto cuando existe', (tester) async {
      // Crear presupuesto de prueba
      final budgetsDao = BudgetsDao(db);
      final categoriesDao = CategoriesDao(db);
      final categories = await categoriesDao.getAllCategories();
      final expenseCategory = categories.firstWhere(
        (c) => c.type == 'expense' && c.parentId != null,
      );

      final now = DateTime.now();
      await budgetsDao.insertBudget(BudgetsCompanion.insert(
        id: 'budget-test-001',
        categoryId: expenseCategory.id,
        amount: 500000,
        month: now.month,
        year: now.year,
      ));

      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      // Debería mostrar el presupuesto con monto (verificamos que no hay mensaje vacío)
      expect(find.text('No hay presupuestos'), findsNothing);
      // Verificar que hay texto con formato de moneda
      expect(find.textContaining('500'), findsWidgets);
    });

    testWidgets('muestra progreso con transacciones', (tester) async {
      // Crear presupuesto y transacciones
      final budgetsDao = BudgetsDao(db);
      final transactionsDao = TransactionsDao(db);
      final categoriesDao = CategoriesDao(db);
      final categories = await categoriesDao.getAllCategories();
      final expenseCategory = categories.firstWhere(
        (c) => c.type == 'expense' && c.parentId != null,
      );

      final now = DateTime.now();

      await budgetsDao.insertBudget(BudgetsCompanion.insert(
        id: 'budget-test-002',
        categoryId: expenseCategory.id,
        amount: 100000,
        month: now.month,
        year: now.year,
      ));

      await transactionsDao.insertTransaction(TransactionsCompanion.insert(
        id: 'tx-budget-001',
        type: 'expense',
        amount: 50000,
        description: const Value('Gasto presupuesto'),
        categoryId: expenseCategory.id,
        transactionDate: now,
      ));

      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      // Debería mostrar porcentaje (50%)
      expect(find.text('50%'), findsWidgets);
    });
  });

  group('budgetPeriodProvider', () {
    test('valor inicial es mes y año actual', () {
      final container = ProviderContainer();
      final now = DateTime.now();
      final period = container.read(budgetPeriodProvider);

      expect(period.month, equals(now.month));
      expect(period.year, equals(now.year));

      container.dispose();
    });

    test('puede cambiar período', () {
      final container = ProviderContainer();

      container.read(budgetPeriodProvider.notifier).state = (month: 6, year: 2025);
      final period = container.read(budgetPeriodProvider);

      expect(period.month, equals(6));
      expect(period.year, equals(2025));

      container.dispose();
    });
  });
}
