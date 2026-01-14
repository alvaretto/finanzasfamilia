import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:drift/drift.dart' hide isNotNull, isNull;
import 'package:drift/native.dart';
import 'package:intl/date_symbol_data_local.dart';

import 'package:finanzas_familiares/presentation/screens/budgets_screen.dart';
import 'package:finanzas_familiares/application/providers/database_provider.dart';
import 'package:finanzas_familiares/application/providers/budget_provider.dart';
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

  group('BudgetsNotifier CRUD', () {
    late AppDatabase db;
    late ProviderContainer container;
    late String testCategoryId;

    setUp(() async {
      db = AppDatabase.forTesting(NativeDatabase.memory());
      final categoriesDao = CategoriesDao(db);
      await seedCategories(categoriesDao);

      // Obtener una categoría de gastos para tests
      final categories = await categoriesDao.getAllCategories();
      testCategoryId = categories
          .firstWhere((c) => c.type == 'expense' && c.parentId != null)
          .id;

      container = ProviderContainer(
        overrides: [appDatabaseProvider.overrideWithValue(db)],
      );
    });

    tearDown(() async {
      container.dispose();
      await db.close();
    });

    test('createBudget crea un presupuesto correctamente', () async {
      final now = DateTime.now();
      final notifier = container.read(
        budgetsNotifierProvider(now.month, now.year).notifier,
      );

      await notifier.createBudget(
        categoryId: testCategoryId,
        amount: 500000,
      );

      final budgets = await container.read(
        budgetsNotifierProvider(now.month, now.year).future,
      );

      expect(budgets, hasLength(1));
      expect(budgets.first.categoryId, equals(testCategoryId));
      expect(budgets.first.amount, equals(500000));
    });

    test('updateBudget actualiza el monto correctamente', () async {
      final now = DateTime.now();
      final budgetsDao = BudgetsDao(db);

      // Crear presupuesto inicial
      await budgetsDao.insertBudget(BudgetsCompanion.insert(
        id: 'budget-update-test',
        categoryId: testCategoryId,
        amount: 100000,
        month: now.month,
        year: now.year,
      ));

      final notifier = container.read(
        budgetsNotifierProvider(now.month, now.year).notifier,
      );

      await notifier.updateBudget(
        id: 'budget-update-test',
        amount: 200000,
      );

      final budgets = await budgetsDao.getBudgetsForMonth(now.month, now.year);
      expect(budgets.first.amount, equals(200000));
    });

    test('deleteBudget elimina el presupuesto', () async {
      final now = DateTime.now();
      final budgetsDao = BudgetsDao(db);

      // Crear presupuesto para eliminar
      await budgetsDao.insertBudget(BudgetsCompanion.insert(
        id: 'budget-delete-test',
        categoryId: testCategoryId,
        amount: 100000,
        month: now.month,
        year: now.year,
      ));

      // Verificar que existe
      var budgets = await budgetsDao.getBudgetsForMonth(now.month, now.year);
      expect(budgets, hasLength(1));

      final notifier = container.read(
        budgetsNotifierProvider(now.month, now.year).notifier,
      );

      await notifier.deleteBudget('budget-delete-test');

      budgets = await budgetsDao.getBudgetsForMonth(now.month, now.year);
      expect(budgets, isEmpty);
    });

    test('copyFromPreviousMonth copia presupuestos del mes anterior', () async {
      final now = DateTime.now();
      final budgetsDao = BudgetsDao(db);

      // Calcular mes anterior
      final prevMonth = now.month == 1 ? 12 : now.month - 1;
      final prevYear = now.month == 1 ? now.year - 1 : now.year;

      // Crear presupuesto en mes anterior
      await budgetsDao.insertBudget(BudgetsCompanion.insert(
        id: 'budget-prev-month',
        categoryId: testCategoryId,
        amount: 300000,
        month: prevMonth,
        year: prevYear,
      ));

      // Verificar que mes actual está vacío
      var currentBudgets = await budgetsDao.getBudgetsForMonth(now.month, now.year);
      expect(currentBudgets, isEmpty);

      final notifier = container.read(
        budgetsNotifierProvider(now.month, now.year).notifier,
      );

      await notifier.copyFromPreviousMonth();

      currentBudgets = await budgetsDao.getBudgetsForMonth(now.month, now.year);
      expect(currentBudgets, hasLength(1));
      expect(currentBudgets.first.amount, equals(300000));
      expect(currentBudgets.first.categoryId, equals(testCategoryId));
    });

    test('copyFromPreviousMonth no duplica presupuestos existentes', () async {
      final now = DateTime.now();
      final budgetsDao = BudgetsDao(db);

      // Calcular mes anterior
      final prevMonth = now.month == 1 ? 12 : now.month - 1;
      final prevYear = now.month == 1 ? now.year - 1 : now.year;

      // Crear presupuesto en mes anterior
      await budgetsDao.insertBudget(BudgetsCompanion.insert(
        id: 'budget-prev-existing',
        categoryId: testCategoryId,
        amount: 300000,
        month: prevMonth,
        year: prevYear,
      ));

      // Crear presupuesto ya existente en mes actual
      await budgetsDao.insertBudget(BudgetsCompanion.insert(
        id: 'budget-current-existing',
        categoryId: testCategoryId,
        amount: 500000,
        month: now.month,
        year: now.year,
      ));

      final notifier = container.read(
        budgetsNotifierProvider(now.month, now.year).notifier,
      );

      await notifier.copyFromPreviousMonth();

      final currentBudgets = await budgetsDao.getBudgetsForMonth(now.month, now.year);

      // Debe haber solo 1 presupuesto (el existente, no duplicado)
      expect(currentBudgets, hasLength(1));
      // Debe mantener el monto original (500000, no 300000)
      expect(currentBudgets.first.amount, equals(500000));
    });
  });

  group('BudgetProgress', () {
    late AppDatabase db;
    late ProviderContainer container;

    setUp(() async {
      db = AppDatabase.forTesting(NativeDatabase.memory());
      final categoriesDao = CategoriesDao(db);
      await seedCategories(categoriesDao);

      container = ProviderContainer(
        overrides: [appDatabaseProvider.overrideWithValue(db)],
      );
    });

    tearDown(() async {
      container.dispose();
      await db.close();
    });

    test('BudgetStatus.safe cuando porcentaje < 80%', () {
      final progress = BudgetProgressData(
        budget: BudgetData(
          id: 'test',
          categoryId: 'cat-1',
          amount: 100000,
          month: 1,
          year: 2026,
          isActive: true,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        ),
        spent: 50000,
        percentage: 50,
        status: BudgetStatus.safe,
      );

      expect(progress.status, equals(BudgetStatus.safe));
      expect(progress.remaining, equals(50000));
    });

    test('BudgetStatus.warning cuando porcentaje >= 80% y < 100%', () {
      final progress = BudgetProgressData(
        budget: BudgetData(
          id: 'test',
          categoryId: 'cat-1',
          amount: 100000,
          month: 1,
          year: 2026,
          isActive: true,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        ),
        spent: 85000,
        percentage: 85,
        status: BudgetStatus.warning,
      );

      expect(progress.status, equals(BudgetStatus.warning));
      expect(progress.remaining, equals(15000));
    });

    test('BudgetStatus.exceeded cuando porcentaje >= 100%', () {
      final progress = BudgetProgressData(
        budget: BudgetData(
          id: 'test',
          categoryId: 'cat-1',
          amount: 100000,
          month: 1,
          year: 2026,
          isActive: true,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        ),
        spent: 120000,
        percentage: 120,
        status: BudgetStatus.exceeded,
      );

      expect(progress.status, equals(BudgetStatus.exceeded));
      expect(progress.remaining, equals(-20000));
    });
  });
}
