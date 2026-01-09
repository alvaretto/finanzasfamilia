import 'package:flutter_test/flutter_test.dart';
import 'package:finanzas_familiares/domain/entities/entities.dart';

/// Tests para las entidades de dominio Freezed
void main() {
  group('Category Entity', () {
    test('crea categoría con valores requeridos', () {
      final now = DateTime.now();
      final category = Category(
        id: 'cat-001',
        name: 'Activos',
        type: CategoryType.asset,
        createdAt: now,
        updatedAt: now,
      );

      expect(category.id, equals('cat-001'));
      expect(category.name, equals('Activos'));
      expect(category.type, equals(CategoryType.asset));
      expect(category.level, equals(0));
      expect(category.isActive, isTrue);
      expect(category.isSystem, isFalse);
    });

    test('isRoot es true cuando level es 0', () {
      final category = Category(
        id: 'root',
        name: 'Raíz',
        type: CategoryType.asset,
        level: 0,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      expect(category.isRoot, isTrue);
    });

    test('hasParent es true cuando parentId no es null', () {
      final category = Category(
        id: 'sub',
        name: 'Subcategoría',
        type: CategoryType.expense,
        parentId: 'parent-id',
        level: 1,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      expect(category.hasParent, isTrue);
    });

    test('typeName retorna nombre en español', () {
      final asset = Category(
        id: '1',
        name: 'A',
        type: CategoryType.asset,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
      final liability = Category(
        id: '2',
        name: 'L',
        type: CategoryType.liability,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
      final income = Category(
        id: '3',
        name: 'I',
        type: CategoryType.income,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
      final expense = Category(
        id: '4',
        name: 'E',
        type: CategoryType.expense,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      expect(asset.typeName, equals('Lo que Tengo'));
      expect(liability.typeName, equals('Lo que Debo'));
      expect(income.typeName, equals('Lo que Entra'));
      expect(expense.typeName, equals('Lo que Sale'));
    });

    test('copyWith crea copia modificada', () {
      final original = Category(
        id: 'cat-001',
        name: 'Original',
        type: CategoryType.asset,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      final modified = original.copyWith(name: 'Modificado');

      expect(modified.id, equals(original.id));
      expect(modified.name, equals('Modificado'));
      expect(modified.type, equals(original.type));
    });
  });

  group('Account Entity', () {
    test('crea cuenta con valores por defecto', () {
      final account = Account(
        id: 'acc-001',
        name: 'Cuenta de Ahorros',
        categoryId: 'cat-bank',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      expect(account.balance, equals(0.0));
      expect(account.isActive, isTrue);
    });

    test('hasPositiveBalance es true con saldo positivo', () {
      final account = Account(
        id: 'acc-001',
        name: 'Ahorros',
        categoryId: 'cat-bank',
        balance: 1500000,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      expect(account.hasPositiveBalance, isTrue);
      expect(account.hasNegativeBalance, isFalse);
    });

    test('hasNegativeBalance es true con deuda', () {
      final account = Account(
        id: 'acc-001',
        name: 'Tarjeta',
        categoryId: 'cat-cc',
        balance: -500000,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      expect(account.hasNegativeBalance, isTrue);
      expect(account.hasPositiveBalance, isFalse);
    });

    test('formattedBalance muestra signo correcto', () {
      final positive = Account(
        id: '1',
        name: 'A',
        categoryId: 'c',
        balance: 1000000,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
      final negative = Account(
        id: '2',
        name: 'B',
        categoryId: 'c',
        balance: -500000,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      expect(positive.formattedBalance, equals('\$1000000'));
      expect(negative.formattedBalance, equals('-\$500000'));
    });
  });

  group('Transaction Entity', () {
    test('crea transacción de ingreso', () {
      final tx = Transaction(
        id: 'tx-001',
        accountId: 'acc-001',
        categoryId: 'cat-salary',
        type: TransactionType.income,
        amount: 5000000,
        date: DateTime.now(),
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      expect(tx.isIncome, isTrue);
      expect(tx.isExpense, isFalse);
      expect(tx.isTransfer, isFalse);
    });

    test('signedAmount es positivo para ingresos', () {
      final income = Transaction(
        id: 'tx-001',
        accountId: 'acc-001',
        categoryId: 'cat-salary',
        type: TransactionType.income,
        amount: 5000000,
        date: DateTime.now(),
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      expect(income.signedAmount, equals(5000000));
    });

    test('signedAmount es negativo para gastos', () {
      final expense = Transaction(
        id: 'tx-002',
        accountId: 'acc-001',
        categoryId: 'cat-food',
        type: TransactionType.expense,
        amount: 150000,
        date: DateTime.now(),
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      expect(expense.signedAmount, equals(-150000));
    });

    test('typeName retorna nombre en español', () {
      final income = Transaction(
        id: '1',
        accountId: 'a',
        categoryId: 'c',
        type: TransactionType.income,
        amount: 100,
        date: DateTime.now(),
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
      final expense = Transaction(
        id: '2',
        accountId: 'a',
        categoryId: 'c',
        type: TransactionType.expense,
        amount: 100,
        date: DateTime.now(),
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
      final transfer = Transaction(
        id: '3',
        accountId: 'a',
        categoryId: 'c',
        type: TransactionType.transfer,
        amount: 100,
        date: DateTime.now(),
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      expect(income.typeName, equals('Ingreso'));
      expect(expense.typeName, equals('Gasto'));
      expect(transfer.typeName, equals('Transferencia'));
    });
  });

  group('Budget Entity', () {
    test('crea presupuesto mensual', () {
      final budget = Budget(
        id: 'bud-001',
        categoryId: 'cat-food',
        amount: 800000,
        month: 1,
        year: 2026,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      expect(budget.amount, equals(800000));
      expect(budget.month, equals(1));
      expect(budget.year, equals(2026));
    });

    test('percentageUsed calcula correctamente', () {
      final budget = Budget(
        id: 'bud-001',
        categoryId: 'cat-food',
        amount: 1000000,
        month: 1,
        year: 2026,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      expect(budget.percentageUsed(500000), equals(50.0));
      expect(budget.percentageUsed(800000), equals(80.0));
      expect(budget.percentageUsed(1200000), equals(120.0));
    });

    test('status retorna semáforo correcto', () {
      final budget = Budget(
        id: 'bud-001',
        categoryId: 'cat-food',
        amount: 1000000,
        month: 1,
        year: 2026,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      expect(budget.status(500000), equals(BudgetStatus.safe));
      expect(budget.status(850000), equals(BudgetStatus.warning));
      expect(budget.status(1100000), equals(BudgetStatus.exceeded));
    });

    test('isExceeded detecta presupuesto excedido', () {
      final budget = Budget(
        id: 'bud-001',
        categoryId: 'cat-food',
        amount: 1000000,
        month: 1,
        year: 2026,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      expect(budget.isExceeded(900000), isFalse);
      expect(budget.isExceeded(1000000), isTrue);
      expect(budget.isExceeded(1100000), isTrue);
    });

    test('periodName formatea mes y año', () {
      final budget = Budget(
        id: 'bud-001',
        categoryId: 'cat-food',
        amount: 800000,
        month: 3,
        year: 2026,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      expect(budget.periodName, equals('Marzo 2026'));
    });
  });

  group('NetWorthSummary Entity', () {
    test('calcula patrimonio neto', () {
      final summary = NetWorthSummary(
        totalAssets: 50000000,
        totalLiabilities: 20000000,
        calculatedAt: DateTime.now(),
      );

      expect(summary.netWorth, equals(30000000));
      expect(summary.isPositive, isTrue);
    });

    test('detecta patrimonio negativo', () {
      final summary = NetWorthSummary(
        totalAssets: 10000000,
        totalLiabilities: 25000000,
        calculatedAt: DateTime.now(),
      );

      expect(summary.netWorth, equals(-15000000));
      expect(summary.isNegative, isTrue);
    });

    test('calcula ratio de deuda', () {
      final summary = NetWorthSummary(
        totalAssets: 100000000,
        totalLiabilities: 40000000,
        calculatedAt: DateTime.now(),
      );

      expect(summary.debtRatio, equals(0.4));
    });
  });

  group('MonthlyFlowSummary Entity', () {
    test('calcula balance neto', () {
      const summary = MonthlyFlowSummary(
        month: 1,
        year: 2026,
        totalIncome: 8000000,
        totalExpenses: 5000000,
      );

      expect(summary.netBalance, equals(3000000));
      expect(summary.isSaving, isTrue);
    });

    test('detecta sobregasto', () {
      const summary = MonthlyFlowSummary(
        month: 1,
        year: 2026,
        totalIncome: 5000000,
        totalExpenses: 7000000,
      );

      expect(summary.netBalance, equals(-2000000));
      expect(summary.isOverspending, isTrue);
    });

    test('calcula tasa de ahorro', () {
      const summary = MonthlyFlowSummary(
        month: 1,
        year: 2026,
        totalIncome: 10000000,
        totalExpenses: 7000000,
      );

      expect(summary.savingsRate, equals(30.0)); // 3M de 10M = 30%
    });

    test('periodName formatea correctamente', () {
      const summary = MonthlyFlowSummary(
        month: 12,
        year: 2026,
        totalIncome: 8000000,
        totalExpenses: 5000000,
      );

      expect(summary.periodName, equals('Diciembre 2026'));
    });
  });

  group('CategorySpending Entity', () {
    test('calcula porcentaje de presupuesto', () {
      const spending = CategorySpending(
        categoryId: 'cat-food',
        categoryName: 'Alimentación',
        amount: 600000,
        percentage: 25.0,
        budgetAmount: 800000,
      );

      expect(spending.hasBudget, isTrue);
      expect(spending.budgetPercentage, equals(75.0));
      expect(spending.isOverBudget, isFalse);
    });

    test('detecta presupuesto excedido', () {
      const spending = CategorySpending(
        categoryId: 'cat-food',
        categoryName: 'Alimentación',
        amount: 900000,
        percentage: 30.0,
        budgetAmount: 800000,
      );

      expect(spending.isOverBudget, isTrue);
      expect(spending.budgetRemaining, equals(-100000));
    });
  });

  group('AvailableBalance Entity', () {
    test('calcula saldo disponible real', () {
      final balance = AvailableBalance(
        cashAmount: 500000,
        bankAmount: 3000000,
        immediateDebts: 1500000,
        calculatedAt: DateTime.now(),
      );

      expect(balance.totalLiquid, equals(3500000));
      expect(balance.available, equals(2000000));
      expect(balance.isPositive, isTrue);
    });

    test('detecta saldo negativo', () {
      final balance = AvailableBalance(
        cashAmount: 200000,
        bankAmount: 500000,
        immediateDebts: 2000000,
        calculatedAt: DateTime.now(),
      );

      expect(balance.available, equals(-1300000));
      expect(balance.isNegative, isTrue);
    });

    test('calcula ratio de cobertura', () {
      final balance = AvailableBalance(
        cashAmount: 1000000,
        bankAmount: 2000000,
        immediateDebts: 1500000,
        calculatedAt: DateTime.now(),
      );

      expect(balance.debtCoverageRatio, equals(2.0)); // 3M / 1.5M = 2x
    });
  });
}
