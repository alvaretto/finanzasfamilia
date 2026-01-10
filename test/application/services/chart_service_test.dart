import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:finanzas_familiares/application/services/chart_service.dart';
import 'package:finanzas_familiares/data/local/database.dart';
import 'package:finanzas_familiares/data/local/daos/transactions_dao.dart';
import 'package:finanzas_familiares/data/local/daos/categories_dao.dart';

void main() {
  group('ChartService', () {
    late AppDatabase db;
    late ChartService service;
    late TransactionsDao transactionsDao;
    late CategoriesDao categoriesDao;

    setUp(() async {
      db = AppDatabase.forTesting(NativeDatabase.memory());
      transactionsDao = TransactionsDao(db);
      categoriesDao = CategoriesDao(db);
      service = ChartService(
        transactionsDao: transactionsDao,
        categoriesDao: categoriesDao,
      );
    });

    tearDown(() async {
      await db.close();
    });

    test('categoryColors tiene al menos 10 colores', () {
      expect(ChartService.categoryColors.length, greaterThanOrEqualTo(10));
    });

    test('getExpensesByCategory retorna lista vacía sin datos', () async {
      final now = DateTime.now();
      final result = await service.getExpensesByCategory(
        year: now.year,
        month: now.month,
      );
      expect(result, isEmpty);
    });

    test('getMonthlyTrend retorna datos para N meses', () async {
      final result = await service.getMonthlyTrend(months: 6);
      expect(result.length, 6);
    });

    test('getMonthlyTrend cada item tiene mes válido', () async {
      final result = await service.getMonthlyTrend(months: 3);
      expect(result.length, 3);
      for (final item in result) {
        expect(item.month, isNotNull);
        expect(item.income, greaterThanOrEqualTo(0));
        expect(item.expense, greaterThanOrEqualTo(0));
      }
    });

    test('getMonthComparison retorna comparación válida', () async {
      final result = await service.getMonthComparison();
      expect(result.currentIncome, greaterThanOrEqualTo(0));
      expect(result.currentExpense, greaterThanOrEqualTo(0));
      expect(result.previousIncome, greaterThanOrEqualTo(0));
      expect(result.previousExpense, greaterThanOrEqualTo(0));
    });

    test('getTopExpenseCategories respeta límite', () async {
      final now = DateTime.now();
      final result = await service.getTopExpenseCategories(
        year: now.year,
        month: now.month,
        limit: 5,
      );
      expect(result.length, lessThanOrEqualTo(5));
    });
  });

  group('CategoryExpenseData', () {
    test('se crea correctamente', () {
      const data = CategoryExpenseData(
        categoryId: 'cat-1',
        categoryName: 'Alimentación',
        amount: 500000,
        percentage: 45.5,
        color: 0xFF4CAF50,
      );

      expect(data.categoryId, 'cat-1');
      expect(data.categoryName, 'Alimentación');
      expect(data.amount, 500000);
      expect(data.percentage, 45.5);
      expect(data.color, 0xFF4CAF50);
    });
  });

  group('MonthlyTrendData', () {
    test('se crea correctamente', () {
      final data = MonthlyTrendData(
        month: DateTime(2026, 1, 1),
        income: 1000000,
        expense: 800000,
        balance: 200000,
      );

      expect(data.month.year, 2026);
      expect(data.month.month, 1);
      expect(data.income, 1000000);
      expect(data.expense, 800000);
      expect(data.balance, 200000);
    });
  });

  group('PeriodComparison', () {
    test('se crea correctamente', () {
      const comparison = PeriodComparison(
        currentIncome: 1000000,
        previousIncome: 900000,
        incomeChange: 100000,
        incomeChangePercent: 11.1,
        currentExpense: 800000,
        previousExpense: 850000,
        expenseChange: -50000,
        expenseChangePercent: -5.9,
      );

      expect(comparison.currentIncome, 1000000);
      expect(comparison.previousIncome, 900000);
      expect(comparison.incomeChange, 100000);
      expect(comparison.incomeChangePercent, 11.1);
      expect(comparison.currentExpense, 800000);
      expect(comparison.previousExpense, 850000);
      expect(comparison.expenseChange, -50000);
      expect(comparison.expenseChangePercent, -5.9);
    });
  });
}
