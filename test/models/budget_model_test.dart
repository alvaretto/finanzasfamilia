import 'package:flutter_test/flutter_test.dart';
import 'package:finanzas_familiares/features/budgets/domain/models/budget_model.dart';

void main() {
  group('BudgetModel', () {
    test('create() genera presupuesto con valores correctos', () {
      final budget = BudgetModel.create(
        userId: 'user-123',
        categoryId: 'cat-1',
        amount: 5000.0,
        period: BudgetPeriod.monthly,
      );

      expect(budget.userId, 'user-123');
      expect(budget.categoryId, 'cat-1');
      expect(budget.amount, 5000.0);
      expect(budget.period, BudgetPeriod.monthly);
      expect(budget.spent, 0.0);
      expect(budget.isSynced, false);
    });

    test('percentSpent calcula correctamente', () {
      final budget = BudgetModel(
        id: 'budget-1',
        userId: 'user-123',
        categoryId: 'cat-1',
        amount: 1000.0,
        period: BudgetPeriod.monthly,
        startDate: DateTime(2026, 1, 1),
        spent: 750.0,
      );

      expect(budget.percentSpent, 75.0);
    });

    test('percentSpent es 0 cuando amount es 0', () {
      final budget = BudgetModel(
        id: 'budget-1',
        userId: 'user-123',
        categoryId: 'cat-1',
        amount: 0.0,
        period: BudgetPeriod.monthly,
        startDate: DateTime(2026, 1, 1),
        spent: 100.0,
      );

      expect(budget.percentSpent, 0.0);
    });

    test('remaining calcula correctamente', () {
      final budget = BudgetModel(
        id: 'budget-1',
        userId: 'user-123',
        categoryId: 'cat-1',
        amount: 1000.0,
        period: BudgetPeriod.monthly,
        startDate: DateTime(2026, 1, 1),
        spent: 600.0,
      );

      expect(budget.remaining, 400.0);
    });

    test('isOverBudget detecta presupuesto excedido', () {
      final overBudget = BudgetModel(
        id: 'budget-1',
        userId: 'user-123',
        categoryId: 'cat-1',
        amount: 1000.0,
        period: BudgetPeriod.monthly,
        startDate: DateTime(2026, 1, 1),
        spent: 1200.0,
      );

      final underBudget = BudgetModel(
        id: 'budget-2',
        userId: 'user-123',
        categoryId: 'cat-2',
        amount: 1000.0,
        period: BudgetPeriod.monthly,
        startDate: DateTime(2026, 1, 1),
        spent: 800.0,
      );

      expect(overBudget.isOverBudget, true);
      expect(underBudget.isOverBudget, false);
    });

    test('isNearLimit detecta presupuesto cerca del limite', () {
      final nearLimit = BudgetModel(
        id: 'budget-1',
        userId: 'user-123',
        categoryId: 'cat-1',
        amount: 1000.0,
        period: BudgetPeriod.monthly,
        startDate: DateTime(2026, 1, 1),
        spent: 850.0,
      );

      final farFromLimit = BudgetModel(
        id: 'budget-2',
        userId: 'user-123',
        categoryId: 'cat-2',
        amount: 1000.0,
        period: BudgetPeriod.monthly,
        startDate: DateTime(2026, 1, 1),
        spent: 500.0,
      );

      expect(nearLimit.isNearLimit, true);
      expect(farFromLimit.isNearLimit, false);
    });
  });

  group('BudgetPeriod', () {
    test('displayName devuelve nombre correcto', () {
      expect(BudgetPeriod.weekly.displayName, 'Semanal');
      expect(BudgetPeriod.monthly.displayName, 'Mensual');
      expect(BudgetPeriod.yearly.displayName, 'Anual');
    });

    test('shortName devuelve abreviatura correcta', () {
      expect(BudgetPeriod.weekly.shortName, 'sem');
      expect(BudgetPeriod.monthly.shortName, 'mes');
      expect(BudgetPeriod.yearly.shortName, 'año');
    });
  });
}
