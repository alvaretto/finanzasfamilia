import 'package:flutter_test/flutter_test.dart';

import 'package:finanzas_familiares/domain/entities/dashboard/budget_alert.dart';
import 'package:finanzas_familiares/domain/entities/dashboard/category_expense.dart';
import 'package:finanzas_familiares/domain/entities/dashboard/dashboard_summary.dart';
import 'package:finanzas_familiares/domain/entities/dashboard/expense_group.dart';
import 'package:finanzas_familiares/domain/entities/dashboard/indicator_status.dart';
import 'package:finanzas_familiares/domain/entities/dashboard/month_summary.dart';

void main() {
  group('CategoryExpense', () {
    test('constructor con valores requeridos', () {
      const expense = CategoryExpense(
        categoryId: 'cat-1',
        categoryName: 'Alimentación',
        amount: 350000,
        percentage: 35,
      );

      expect(expense.categoryId, equals('cat-1'));
      expect(expense.categoryName, equals('Alimentación'));
      expect(expense.amount, equals(350000));
      expect(expense.percentage, equals(35));
      expect(expense.icon, isNull);
    });

    test('constructor con icono', () {
      const expense = CategoryExpense(
        categoryId: 'cat-1',
        categoryName: 'Transporte',
        icon: '🚗',
        amount: 200000,
        percentage: 20,
      );

      expect(expense.icon, equals('🚗'));
    });

    test('percentage puede ser 0', () {
      const expense = CategoryExpense(
        categoryId: 'cat-1',
        categoryName: 'Sin gastos',
        amount: 0,
        percentage: 0,
      );

      expect(expense.percentage, equals(0));
    });

    test('percentage puede ser 100', () {
      const expense = CategoryExpense(
        categoryId: 'cat-1',
        categoryName: 'Todo el presupuesto',
        amount: 1000000,
        percentage: 100,
      );

      expect(expense.percentage, equals(100));
    });
  });

  group('ExpenseGroup', () {
    test('constructor con subcategorías vacías', () {
      const group = ExpenseGroup(
        masterCategoryId: 'master-1',
        masterCategoryName: 'Gastos Fijos',
        totalAmount: 0,
        subcategories: [],
      );

      expect(group.subcategories, isEmpty);
      expect(group.totalAmount, equals(0));
    });

    test('constructor con subcategorías', () {
      const group = ExpenseGroup(
        masterCategoryId: 'master-1',
        masterCategoryName: 'Alimentación',
        icon: '🍽️',
        totalAmount: 500000,
        subcategories: [
          CategoryExpense(
            categoryId: 'sub-1',
            categoryName: 'Mercado',
            amount: 300000,
            percentage: 60,
          ),
          CategoryExpense(
            categoryId: 'sub-2',
            categoryName: 'Restaurantes',
            amount: 200000,
            percentage: 40,
          ),
        ],
      );

      expect(group.subcategories, hasLength(2));
      expect(group.totalAmount, equals(500000));
      expect(group.icon, equals('🍽️'));
    });
  });

  group('MonthSummary', () {
    test('constructor básico', () {
      const summary = MonthSummary(
        month: 1,
        year: 2026,
        incomeTotal: 5000000,
        expenseTotal: 3000000,
        netBalance: 2000000,
        expenseGroups: [],
      );

      expect(summary.month, equals(1));
      expect(summary.year, equals(2026));
      expect(summary.incomeTotal, equals(5000000));
      expect(summary.expenseTotal, equals(3000000));
      expect(summary.netBalance, equals(2000000));
    });

    test('netBalance puede ser negativo', () {
      const summary = MonthSummary(
        month: 2,
        year: 2026,
        incomeTotal: 2000000,
        expenseTotal: 3000000,
        netBalance: -1000000,
        expenseGroups: [],
      );

      expect(summary.netBalance, equals(-1000000));
    });

    test('mes válido 1-12', () {
      for (var month = 1; month <= 12; month++) {
        final summary = MonthSummary(
          month: month,
          year: 2026,
          incomeTotal: 0,
          expenseTotal: 0,
          netBalance: 0,
          expenseGroups: const [],
        );
        expect(summary.month, equals(month));
      }
    });
  });

  group('BudgetAlert', () {
    test('isOverBudget es true cuando percentage >= 100', () {
      const alert = BudgetAlert(
        categoryId: 'cat-1',
        categoryName: 'Alimentación',
        budgetAmount: 500000,
        spentAmount: 600000,
        percentage: 120,
        status: IndicatorStatus.danger,
      );

      expect(alert.isOverBudget, isTrue);
      expect(alert.isWarning, isFalse);
    });

    test('isOverBudget es true exactamente en 100%', () {
      const alert = BudgetAlert(
        categoryId: 'cat-1',
        categoryName: 'Test',
        budgetAmount: 500000,
        spentAmount: 500000,
        percentage: 100,
        status: IndicatorStatus.danger,
      );

      expect(alert.isOverBudget, isTrue);
    });

    test('isWarning es true cuando percentage >= 80 y < 100', () {
      const alert = BudgetAlert(
        categoryId: 'cat-1',
        categoryName: 'Transporte',
        budgetAmount: 200000,
        spentAmount: 170000,
        percentage: 85,
        status: IndicatorStatus.warning,
      );

      expect(alert.isWarning, isTrue);
      expect(alert.isOverBudget, isFalse);
    });

    test('isWarning es true exactamente en 80%', () {
      const alert = BudgetAlert(
        categoryId: 'cat-1',
        categoryName: 'Test',
        budgetAmount: 100000,
        spentAmount: 80000,
        percentage: 80,
        status: IndicatorStatus.warning,
      );

      expect(alert.isWarning, isTrue);
    });

    test('isWarning es false cuando percentage < 80', () {
      const alert = BudgetAlert(
        categoryId: 'cat-1',
        categoryName: 'Servicios',
        budgetAmount: 300000,
        spentAmount: 150000,
        percentage: 50,
        status: IndicatorStatus.good,
      );

      expect(alert.isWarning, isFalse);
      expect(alert.isOverBudget, isFalse);
    });

    test('isWarning es false exactamente en 79.9%', () {
      const alert = BudgetAlert(
        categoryId: 'cat-1',
        categoryName: 'Test',
        budgetAmount: 100000,
        spentAmount: 79900,
        percentage: 79.9,
        status: IndicatorStatus.good,
      );

      expect(alert.isWarning, isFalse);
    });
  });

  group('DashboardSummary', () {
    test('constructor con todos los campos', () {
      const summary = DashboardSummary(
        totalIncome: 5000000,
        totalExpenses: 3000000,
        netBalance: 2000000,
        totalAssets: 10000000,
        totalLiabilities: 2000000,
        netWorth: 8000000,
        availableBalance: 1500000,
        expensesByCategory: [
          CategoryExpense(
            categoryId: 'cat-1',
            categoryName: 'Alimentación',
            amount: 500000,
            percentage: 16.7,
          ),
        ],
        budgetAlerts: [
          BudgetAlert(
            categoryId: 'cat-1',
            categoryName: 'Alimentación',
            budgetAmount: 600000,
            spentAmount: 500000,
            percentage: 83.3,
            status: IndicatorStatus.warning,
          ),
        ],
        currentMonth: MonthSummary(
          month: 1,
          year: 2026,
          incomeTotal: 5000000,
          expenseTotal: 3000000,
          netBalance: 2000000,
          expenseGroups: [],
        ),
      );

      expect(summary.totalIncome, equals(5000000));
      expect(summary.totalExpenses, equals(3000000));
      expect(summary.netBalance, equals(2000000));
      expect(summary.totalAssets, equals(10000000));
      expect(summary.totalLiabilities, equals(2000000));
      expect(summary.netWorth, equals(8000000));
      expect(summary.availableBalance, equals(1500000));
      expect(summary.expensesByCategory, hasLength(1));
      expect(summary.budgetAlerts, hasLength(1));
    });

    test('listas vacías son válidas', () {
      const summary = DashboardSummary(
        totalIncome: 0,
        totalExpenses: 0,
        netBalance: 0,
        totalAssets: 0,
        totalLiabilities: 0,
        netWorth: 0,
        availableBalance: 0,
        expensesByCategory: [],
        budgetAlerts: [],
        currentMonth: MonthSummary(
          month: 1,
          year: 2026,
          incomeTotal: 0,
          expenseTotal: 0,
          netBalance: 0,
          expenseGroups: [],
        ),
      );

      expect(summary.expensesByCategory, isEmpty);
      expect(summary.budgetAlerts, isEmpty);
    });

    test('netWorth puede ser negativo', () {
      const summary = DashboardSummary(
        totalIncome: 1000000,
        totalExpenses: 2000000,
        netBalance: -1000000,
        totalAssets: 5000000,
        totalLiabilities: 8000000,
        netWorth: -3000000,
        availableBalance: -500000,
        expensesByCategory: [],
        budgetAlerts: [],
        currentMonth: MonthSummary(
          month: 1,
          year: 2026,
          incomeTotal: 0,
          expenseTotal: 0,
          netBalance: 0,
          expenseGroups: [],
        ),
      );

      expect(summary.netWorth, equals(-3000000));
      expect(summary.availableBalance, equals(-500000));
    });
  });
}
