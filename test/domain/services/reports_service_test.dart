import 'package:flutter_test/flutter_test.dart';

import 'package:finanzas_familiares/domain/entities/reports/reports.dart';
import 'package:finanzas_familiares/domain/services/reports_service.dart';

void main() {
  late ReportsService service;

  setUp(() {
    service = ReportsService();
  });

  group('ReportsService - generateBalanceSheet', () {
    test('calcula totales de activos y pasivos correctamente', () {
      final accounts = [
        const AccountReportDto(
          id: 'acc1',
          name: 'Cuenta Ahorros',
          categoryId: 'cat1',
          balance: 1000000,
        ),
        const AccountReportDto(
          id: 'acc2',
          name: 'Nequi',
          categoryId: 'cat1',
          balance: 500000,
        ),
        const AccountReportDto(
          id: 'acc3',
          name: 'Tarjeta Crédito',
          categoryId: 'cat2',
          balance: 300000,
        ),
      ];

      final categories = [
        const CategoryReportDto(id: 'cat1', name: 'Activos', type: 'asset'),
        const CategoryReportDto(id: 'cat2', name: 'Pasivos', type: 'liability'),
      ];

      final result = service.generateBalanceSheet(
        accounts: accounts,
        categories: categories,
      );

      expect(result.totalAssets, equals(1500000));
      expect(result.totalLiabilities, equals(300000));
      expect(result.netWorth, equals(1200000));
      expect(result.assets, hasLength(2));
      expect(result.liabilities, hasLength(1));
    });

    test('maneja cuentas sin categoría', () {
      final accounts = [
        const AccountReportDto(
          id: 'acc1',
          name: 'Cuenta sin cat',
          categoryId: 'cat-no-existe',
          balance: 1000,
        ),
      ];

      final categories = <CategoryReportDto>[];

      final result = service.generateBalanceSheet(
        accounts: accounts,
        categories: categories,
      );

      expect(result.totalAssets, equals(0));
      expect(result.totalLiabilities, equals(0));
      expect(result.netWorth, equals(0));
    });

    test('retorna listas vacías si no hay cuentas', () {
      final result = service.generateBalanceSheet(
        accounts: [],
        categories: [],
      );

      expect(result.assets, isEmpty);
      expect(result.liabilities, isEmpty);
      expect(result.netWorth, equals(0));
    });

    test('incluye icono de cuenta en BalanceItem', () {
      final accounts = [
        const AccountReportDto(
          id: 'acc1',
          name: 'Nequi',
          icon: '💜',
          categoryId: 'cat1',
          balance: 100000,
        ),
      ];

      final categories = [
        const CategoryReportDto(id: 'cat1', name: 'Billeteras', type: 'asset'),
      ];

      final result = service.generateBalanceSheet(
        accounts: accounts,
        categories: categories,
      );

      expect(result.assets.first.icon, equals('💜'));
      expect(result.assets.first.categoryName, equals('Billeteras'));
    });
  });

  group('ReportsService - generateIncomeStatement', () {
    test('agrupa ingresos y gastos por categoría', () {
      final transactions = [
        const TransactionReportDto(
          id: 'tx1',
          type: 'income',
          amount: 5000000,
          categoryId: 'cat1',
          toAccountId: 'acc1',
        ),
        const TransactionReportDto(
          id: 'tx2',
          type: 'expense',
          amount: 200000,
          categoryId: 'cat2',
          fromAccountId: 'acc1',
        ),
        const TransactionReportDto(
          id: 'tx3',
          type: 'expense',
          amount: 150000,
          categoryId: 'cat2',
          fromAccountId: 'acc1',
        ),
        const TransactionReportDto(
          id: 'tx4',
          type: 'expense',
          amount: 500000,
          categoryId: 'cat3',
          fromAccountId: 'acc1',
        ),
      ];

      final categories = [
        const CategoryReportDto(id: 'cat1', name: 'Salario', type: 'income'),
        const CategoryReportDto(
            id: 'cat2', name: 'Alimentación', type: 'expense'),
        const CategoryReportDto(id: 'cat3', name: 'Transporte', type: 'expense'),
      ];

      final now = DateTime.now();
      final result = service.generateIncomeStatement(
        transactions: transactions,
        categories: categories,
        startDate: DateTime(now.year, now.month, 1),
        endDate: DateTime(now.year, now.month + 1, 0),
      );

      expect(result.totalIncome, equals(5000000));
      expect(result.totalExpenses, equals(850000));
      expect(result.netIncome, equals(4150000));
      expect(result.incomeItems, hasLength(1));
      expect(result.expenseItems, hasLength(2));

      // Alimentación tiene 350000 (200k + 150k)
      final alimentacion =
          result.expenseItems.firstWhere((e) => e.categoryName == 'Alimentación');
      expect(alimentacion.amount, equals(350000));
    });

    test('ordena items por monto descendente', () {
      final transactions = [
        const TransactionReportDto(
          id: 'tx1',
          type: 'expense',
          amount: 100000,
          categoryId: 'cat1',
        ),
        const TransactionReportDto(
          id: 'tx2',
          type: 'expense',
          amount: 500000,
          categoryId: 'cat2',
        ),
        const TransactionReportDto(
          id: 'tx3',
          type: 'expense',
          amount: 300000,
          categoryId: 'cat3',
        ),
      ];

      final categories = [
        const CategoryReportDto(id: 'cat1', name: 'Pequeño', type: 'expense'),
        const CategoryReportDto(id: 'cat2', name: 'Grande', type: 'expense'),
        const CategoryReportDto(id: 'cat3', name: 'Medio', type: 'expense'),
      ];

      final result = service.generateIncomeStatement(
        transactions: transactions,
        categories: categories,
        startDate: DateTime(2026, 1, 1),
        endDate: DateTime(2026, 1, 31),
      );

      expect(result.expenseItems[0].categoryName, equals('Grande'));
      expect(result.expenseItems[1].categoryName, equals('Medio'));
      expect(result.expenseItems[2].categoryName, equals('Pequeño'));
    });

    test('ignora transacciones tipo transfer', () {
      final transactions = [
        const TransactionReportDto(
          id: 'tx1',
          type: 'transfer',
          amount: 1000000,
          categoryId: 'cat1',
          fromAccountId: 'acc1',
          toAccountId: 'acc2',
        ),
      ];

      final categories = [
        const CategoryReportDto(id: 'cat1', name: 'Transferencia', type: 'transfer'),
      ];

      final result = service.generateIncomeStatement(
        transactions: transactions,
        categories: categories,
        startDate: DateTime(2026, 1, 1),
        endDate: DateTime(2026, 1, 31),
      );

      expect(result.totalIncome, equals(0));
      expect(result.totalExpenses, equals(0));
    });
  });

  group('ReportsService - generateCashFlowReport', () {
    test('calcula flujos de entrada y salida por cuenta', () {
      final accounts = [
        const AccountReportDto(
          id: 'acc1',
          name: 'Cuenta Ahorros',
          categoryId: 'cat1',
          balance: 0,
        ),
        const AccountReportDto(
          id: 'acc2',
          name: 'Nequi',
          categoryId: 'cat1',
          balance: 0,
        ),
      ];

      final transactions = [
        const TransactionReportDto(
          id: 'tx1',
          type: 'income',
          amount: 5000000,
          categoryId: 'cat1',
          toAccountId: 'acc1',
        ),
        const TransactionReportDto(
          id: 'tx2',
          type: 'expense',
          amount: 200000,
          categoryId: 'cat2',
          fromAccountId: 'acc1',
        ),
        const TransactionReportDto(
          id: 'tx3',
          type: 'transfer',
          amount: 500000,
          categoryId: 'cat3',
          fromAccountId: 'acc1',
          toAccountId: 'acc2',
        ),
      ];

      final result = service.generateCashFlowReport(
        transactions: transactions,
        accounts: accounts,
        startDate: DateTime(2026, 1, 1),
        endDate: DateTime(2026, 1, 31),
      );

      // Cuenta Ahorros: +5M income, -200k expense, -500k transfer = 4.3M net
      final ahorros = result.items.firstWhere((i) => i.accountName == 'Cuenta Ahorros');
      expect(ahorros.inflows, equals(5000000));
      expect(ahorros.outflows, equals(700000)); // 200k + 500k

      // Nequi: +500k transfer
      final nequi = result.items.firstWhere((i) => i.accountName == 'Nequi');
      expect(nequi.inflows, equals(500000));
      expect(nequi.outflows, equals(0));

      expect(result.totalInflows, equals(5500000));
      expect(result.totalOutflows, equals(700000));
      expect(result.netCashFlow, equals(4800000));
    });

    test('CashFlowItem.netFlow calcula diferencia', () {
      final item = CashFlowItem(
        accountName: 'Test',
        inflows: 1000,
        outflows: 300,
      );

      expect(item.netFlow, equals(700));
    });
  });

  group('ReportsService - generateMonthlySummary', () {
    test('calcula promedio diario y tasa de ahorro', () {
      final incomeStatement = IncomeStatement(
        startDate: DateTime(2026, 1, 1),
        endDate: DateTime(2026, 1, 31),
        incomeItems: [
          IncomeStatementItem(categoryName: 'Salario', amount: 5000000),
        ],
        expenseItems: [
          IncomeStatementItem(categoryName: 'Alimentación', amount: 800000),
          IncomeStatementItem(categoryName: 'Transporte', amount: 200000),
        ],
        totalIncome: 5000000,
        totalExpenses: 1000000,
        netIncome: 4000000,
      );

      final result = service.generateMonthlySummary(
        incomeStatement: incomeStatement,
        transactionCount: 50,
        year: 2026,
        month: 1,
      );

      expect(result.year, equals(2026));
      expect(result.month, equals(1));
      expect(result.totalIncome, equals(5000000));
      expect(result.totalExpenses, equals(1000000));
      expect(result.netResult, equals(4000000));
      expect(result.transactionCount, equals(50));

      // Enero tiene 31 días, avg = 1000000 / 31 ≈ 32258
      expect(result.avgDailyExpense, closeTo(32258.06, 1));

      // Savings rate = 4M / 5M * 100 = 80%
      expect(result.savingsRate, equals(80));

      // Top expense category
      expect(result.topExpenseCategory, equals('Alimentación'));
      expect(result.topExpenseAmount, equals(800000));
    });

    test('maneja cero ingresos sin dividir por cero', () {
      final incomeStatement = IncomeStatement(
        startDate: DateTime(2026, 1, 1),
        endDate: DateTime(2026, 1, 31),
        incomeItems: [],
        expenseItems: [
          IncomeStatementItem(categoryName: 'Gastos', amount: 100000),
        ],
        totalIncome: 0,
        totalExpenses: 100000,
        netIncome: -100000,
      );

      final result = service.generateMonthlySummary(
        incomeStatement: incomeStatement,
        transactionCount: 10,
        year: 2026,
        month: 1,
      );

      expect(result.savingsRate, equals(0));
    });

    test('topExpenseCategory es null si no hay gastos', () {
      final incomeStatement = IncomeStatement(
        startDate: DateTime(2026, 1, 1),
        endDate: DateTime(2026, 1, 31),
        incomeItems: [
          IncomeStatementItem(categoryName: 'Salario', amount: 5000000),
        ],
        expenseItems: [],
        totalIncome: 5000000,
        totalExpenses: 0,
        netIncome: 5000000,
      );

      final result = service.generateMonthlySummary(
        incomeStatement: incomeStatement,
        transactionCount: 1,
        year: 2026,
        month: 1,
      );

      expect(result.topExpenseCategory, isNull);
      expect(result.topExpenseAmount, equals(0));
    });

    test('calcula días correctos para febrero bisiesto', () {
      final incomeStatement = IncomeStatement(
        startDate: DateTime(2024, 2, 1),
        endDate: DateTime(2024, 2, 29),
        incomeItems: [],
        expenseItems: [
          IncomeStatementItem(categoryName: 'Gastos', amount: 290000),
        ],
        totalIncome: 0,
        totalExpenses: 290000,
        netIncome: -290000,
      );

      final result = service.generateMonthlySummary(
        incomeStatement: incomeStatement,
        transactionCount: 29,
        year: 2024,
        month: 2, // Febrero 2024 es bisiesto (29 días)
      );

      // 290000 / 29 = 10000
      expect(result.avgDailyExpense, equals(10000));
    });
  });
}
