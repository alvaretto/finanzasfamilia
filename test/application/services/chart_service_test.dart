import 'package:flutter_test/flutter_test.dart';

import 'package:finanzas_familiares/domain/entities/dashboard/dashboard.dart';
import 'package:finanzas_familiares/domain/services/chart_service.dart';

void main() {
  group('ChartService', () {
    late ChartService service;

    setUp(() {
      service = ChartService();
    });

    test('categoryColors tiene al menos 10 colores', () {
      expect(ChartService.categoryColors.length, greaterThanOrEqualTo(10));
    });

    group('calculateExpensesByCategory', () {
      test('retorna lista vacía sin transacciones', () {
        final result = service.calculateExpensesByCategory(
          transactions: [],
          categories: [],
        );
        expect(result, isEmpty);
      });

      test('agrupa gastos por categoría correctamente', () {
        final now = DateTime.now();
        final transactions = [
          _createTransaction('tx1', 'cat1', 100, 'expense', now),
          _createTransaction('tx2', 'cat1', 150, 'expense', now),
          _createTransaction('tx3', 'cat2', 400, 'expense', now),
        ];
        final categories = [
          _createCategory('cat1', 'Alimentación'),
          _createCategory('cat2', 'Transporte'),
        ];

        final result = service.calculateExpensesByCategory(
          transactions: transactions,
          categories: categories,
        );

        expect(result.length, 2);
        // Ordenado por monto descendente
        expect(result[0].categoryName, 'Transporte');
        expect(result[0].amount, 400);
        expect(result[1].categoryName, 'Alimentación');
        expect(result[1].amount, 250);
      });

      test('calcula porcentajes correctamente', () {
        final now = DateTime.now();
        final transactions = [
          _createTransaction('tx1', 'cat1', 100, 'expense', now),
          _createTransaction('tx2', 'cat2', 100, 'expense', now),
        ];
        final categories = [
          _createCategory('cat1', 'Cat 1'),
          _createCategory('cat2', 'Cat 2'),
        ];

        final result = service.calculateExpensesByCategory(
          transactions: transactions,
          categories: categories,
        );

        expect(result[0].percentage, 50);
        expect(result[1].percentage, 50);
      });

      test('ignora ingresos', () {
        final now = DateTime.now();
        final transactions = [
          _createTransaction('tx1', 'cat1', 100, 'expense', now),
          _createTransaction('tx2', 'cat1', 500, 'income', now),
        ];
        final categories = [_createCategory('cat1', 'Cat 1')];

        final result = service.calculateExpensesByCategory(
          transactions: transactions,
          categories: categories,
        );

        expect(result.length, 1);
        expect(result[0].amount, 100);
      });
    });

    group('calculateMonthlyTrend', () {
      test('retorna datos para cada mes', () {
        final months = [
          DateTime(2026, 1, 1),
          DateTime(2026, 2, 1),
          DateTime(2026, 3, 1),
        ];
        final transactionsByMonth = <List<TransactionSummaryDto>>[[], [], []];

        final result = service.calculateMonthlyTrend(
          transactionsByMonth: transactionsByMonth,
          months: months,
        );

        expect(result.length, 3);
        expect(result[0].month, DateTime(2026, 1, 1));
        expect(result[1].month, DateTime(2026, 2, 1));
        expect(result[2].month, DateTime(2026, 3, 1));
      });

      test('calcula ingresos y gastos por mes', () {
        final now = DateTime.now();
        final months = [DateTime(2026, 1, 1)];
        final transactionsByMonth = [
          [
            _createTransaction('tx1', 'cat1', 1000, 'income', now),
            _createTransaction('tx2', 'cat1', 400, 'expense', now),
          ],
        ];

        final result = service.calculateMonthlyTrend(
          transactionsByMonth: transactionsByMonth,
          months: months,
        );

        expect(result[0].income, 1000);
        expect(result[0].expense, 400);
        expect(result[0].balance, 600);
      });
    });

    group('calculateMonthComparison', () {
      test('calcula diferencias entre meses', () {
        final now = DateTime.now();
        final currentTx = [
          _createTransaction('tx1', 'cat1', 1000, 'income', now),
          _createTransaction('tx2', 'cat1', 600, 'expense', now),
        ];
        final previousTx = [
          _createTransaction('tx3', 'cat1', 800, 'income', now),
          _createTransaction('tx4', 'cat1', 500, 'expense', now),
        ];

        final result = service.calculateMonthComparison(
          currentMonthTransactions: currentTx,
          previousMonthTransactions: previousTx,
        );

        expect(result.currentIncome, 1000);
        expect(result.previousIncome, 800);
        expect(result.incomeChange, 200);
        expect(result.incomeChangePercent, 25);
        expect(result.currentExpense, 600);
        expect(result.previousExpense, 500);
        expect(result.expenseChange, 100);
        expect(result.expenseChangePercent, 20);
      });

      test('maneja mes anterior sin datos', () {
        final now = DateTime.now();
        final currentTx = [
          _createTransaction('tx1', 'cat1', 1000, 'income', now),
        ];

        final result = service.calculateMonthComparison(
          currentMonthTransactions: currentTx,
          previousMonthTransactions: [],
        );

        expect(result.currentIncome, 1000);
        expect(result.previousIncome, 0);
        expect(result.incomeChangePercent, 0); // División por cero manejada
      });
    });

    group('getTopExpenseCategories', () {
      test('respeta límite', () {
        final allExpenses = [
          const CategoryExpenseData(
            categoryId: 'c1',
            categoryName: 'Cat 1',
            amount: 100,
            percentage: 50,
            color: 0xFF000000,
          ),
          const CategoryExpenseData(
            categoryId: 'c2',
            categoryName: 'Cat 2',
            amount: 80,
            percentage: 30,
            color: 0xFF111111,
          ),
          const CategoryExpenseData(
            categoryId: 'c3',
            categoryName: 'Cat 3',
            amount: 40,
            percentage: 20,
            color: 0xFF222222,
          ),
        ];

        final result = service.getTopExpenseCategories(
          allExpenses: allExpenses,
          limit: 2,
        );

        expect(result.length, 2);
        expect(result[0].categoryName, 'Cat 1');
        expect(result[1].categoryName, 'Cat 2');
      });
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

// Helpers para crear datos de test
TransactionSummaryDto _createTransaction(
  String id,
  String categoryId,
  double amount,
  String type,
  DateTime date,
) {
  return TransactionSummaryDto(
    id: id,
    type: type,
    categoryId: categoryId,
    amount: amount,
  );
}

CategoryInfoDto _createCategory(String id, String name) {
  return CategoryInfoDto(
    id: id,
    name: name,
    type: 'expense',
    level: 1,
  );
}
