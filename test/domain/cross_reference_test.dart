import 'package:flutter_test/flutter_test.dart';
import 'package:finanzas_familiares/domain/repositories/repositories.dart';
import 'package:finanzas_familiares/domain/services/budget_service.dart';
import 'package:finanzas_familiares/domain/services/dashboard_service.dart';
import 'package:finanzas_familiares/domain/entities/dashboard/dashboard.dart';

/// Cross-Reference Testing para Finanzas Familiares
///
/// Verifica consistencia entre entidades relacionadas y lógica de negocio.
/// NO verifica foreign keys (Drift ya lo hace), sino:
/// - Cálculos que involucran múltiples entidades
/// - Agregaciones y totales
/// - Jerarquías de categorías
/// - Consistencia de datos derivados
void main() {
  group('Cross-Reference: Budget ↔ Categories ↔ Transactions', () {
    late BudgetService budgetService;
    late InMemoryBudgetRepository budgetRepo;
    late InMemoryCategorySpendingRepository spendingRepo;

    setUp(() {
      budgetRepo = InMemoryBudgetRepository();
      spendingRepo = InMemoryCategorySpendingRepository();
      budgetService = BudgetService(
        budgetRepository: budgetRepo,
        spendingRepository: spendingRepo,
      );
    });

    test('progreso de presupuesto refleja gastos reales', () async {
      final now = DateTime.now();
      const categoryId = 'cat-alimentacion';

      // Crear presupuesto
      await budgetRepo.createBudget(
        'budget-1',
        CreateBudgetData(
          categoryId: categoryId,
          amount: 500000,
          month: now.month,
          year: now.year,
        ),
      );

      // Registrar gasto
      spendingRepo.recordSpending(categoryId, 200000);

      // Verificar progreso
      final progress = await budgetService.getBudgetProgress(categoryId);

      expect(progress, isNotNull);
      expect(progress!.spent, equals(200000));
      expect(progress.percentage, closeTo(40.0, 0.01));
      expect(progress.status, equals(BudgetStatus.safe));
    });

    test('presupuesto sin gastos tiene progreso 0%', () async {
      final now = DateTime.now();
      const categoryId = 'cat-transporte';

      await budgetRepo.createBudget(
        'budget-2',
        CreateBudgetData(
          categoryId: categoryId,
          amount: 300000,
          month: now.month,
          year: now.year,
        ),
      );

      final progress = await budgetService.getBudgetProgress(categoryId);

      expect(progress, isNotNull);
      expect(progress!.spent, equals(0));
      expect(progress.percentage, equals(0));
      expect(progress.status, equals(BudgetStatus.safe));
    });

    test('presupuesto excedido tiene status exceeded', () async {
      final now = DateTime.now();
      const categoryId = 'cat-entretenimiento';

      await budgetRepo.createBudget(
        'budget-3',
        CreateBudgetData(
          categoryId: categoryId,
          amount: 100000,
          month: now.month,
          year: now.year,
        ),
      );

      // Gastar más del 100%
      spendingRepo.recordSpending(categoryId, 150000);

      final progress = await budgetService.getBudgetProgress(categoryId);

      expect(progress, isNotNull);
      expect(progress!.percentage, equals(150.0));
      expect(progress.status, equals(BudgetStatus.exceeded));
    });

    test('presupuesto al 80-99% tiene status warning', () async {
      final now = DateTime.now();
      const categoryId = 'cat-servicios';

      await budgetRepo.createBudget(
        'budget-4',
        CreateBudgetData(
          categoryId: categoryId,
          amount: 200000,
          month: now.month,
          year: now.year,
        ),
      );

      // Gastar 85%
      spendingRepo.recordSpending(categoryId, 170000);

      final progress = await budgetService.getBudgetProgress(categoryId);

      expect(progress, isNotNull);
      expect(progress!.percentage, equals(85.0));
      expect(progress.status, equals(BudgetStatus.warning));
    });

    test('getAllBudgetProgress retorna todos los presupuestos del mes',
        () async {
      final now = DateTime.now();

      // Crear 3 presupuestos
      await budgetRepo.createBudget(
        'b1',
        CreateBudgetData(
          categoryId: 'cat-1',
          amount: 100000,
          month: now.month,
          year: now.year,
        ),
      );
      await budgetRepo.createBudget(
        'b2',
        CreateBudgetData(
          categoryId: 'cat-2',
          amount: 200000,
          month: now.month,
          year: now.year,
        ),
      );
      await budgetRepo.createBudget(
        'b3',
        CreateBudgetData(
          categoryId: 'cat-3',
          amount: 300000,
          month: now.month,
          year: now.year,
        ),
      );

      // Registrar gastos variados
      spendingRepo.recordSpending('cat-1', 50000); // 50%
      spendingRepo.recordSpending('cat-2', 180000); // 90%
      spendingRepo.recordSpending('cat-3', 350000); // 116%

      final allProgress = await budgetService.getAllBudgetProgress();

      expect(allProgress.length, equals(3));

      final p1 = allProgress.firstWhere((p) => p.budget.categoryId == 'cat-1');
      final p2 = allProgress.firstWhere((p) => p.budget.categoryId == 'cat-2');
      final p3 = allProgress.firstWhere((p) => p.budget.categoryId == 'cat-3');

      expect(p1.status, equals(BudgetStatus.safe));
      expect(p2.status, equals(BudgetStatus.warning));
      expect(p3.status, equals(BudgetStatus.exceeded));
    });

    test('presupuesto de mes diferente no afecta mes actual', () async {
      final now = DateTime.now();
      const categoryId = 'cat-test';

      // Presupuesto del mes pasado
      final prevMonth = now.month == 1 ? 12 : now.month - 1;
      final prevYear = now.month == 1 ? now.year - 1 : now.year;

      await budgetRepo.createBudget(
        'b-prev',
        CreateBudgetData(
          categoryId: categoryId,
          amount: 500000,
          month: prevMonth,
          year: prevYear,
        ),
      );

      // No hay presupuesto este mes
      final progress = await budgetService.getBudgetProgress(categoryId);

      expect(progress, isNull);
    });
  });

  group('Cross-Reference: Dashboard ↔ Transactions ↔ Accounts', () {
    late DashboardService dashboardService;

    setUp(() {
      dashboardService = DashboardService();
    });

    test('totalIncome = suma de todas las transacciones de ingreso', () {
      final now = DateTime.now();

      final transactions = <TransactionSummaryDto>[
        const TransactionSummaryDto(
          id: 't1',
          type: 'income',
          amount: 1000000,
          categoryId: 'cat-salary',
        ),
        const TransactionSummaryDto(
          id: 't2',
          type: 'income',
          amount: 500000,
          categoryId: 'cat-bonus',
        ),
        const TransactionSummaryDto(
          id: 't3',
          type: 'expense',
          amount: 200000,
          categoryId: 'cat-food',
        ),
      ];

      final summary = dashboardService.calculateDashboardSummary(
        accounts: const [],
        categories: _testCategories(),
        monthTransactions: transactions,
        budgets: const [],
        spentByBudgetCategory: const {},
        now: now,
      );

      expect(summary.totalIncome, equals(1500000));
      expect(summary.totalExpenses, equals(200000));
      expect(summary.netBalance, equals(1300000));
    });

    test('totalAssets = suma de balances de cuentas tipo asset', () {
      final now = DateTime.now();

      final accounts = <AccountBalanceDto>[
        const AccountBalanceDto(
          id: 'wallet',
          balance: 500000,
          categoryId: 'cat-asset',
        ),
        const AccountBalanceDto(
          id: 'bank',
          balance: 3000000,
          categoryId: 'cat-asset',
        ),
        const AccountBalanceDto(
          id: 'credit',
          balance: -800000,
          categoryId: 'cat-liability',
        ),
      ];

      final categories = <CategoryInfoDto>[
        const CategoryInfoDto(
          id: 'cat-asset',
          name: 'Activos',
          icon: null,
          type: 'asset',
          parentId: null,
          level: 0,
        ),
        const CategoryInfoDto(
          id: 'cat-liability',
          name: 'Pasivos',
          icon: null,
          type: 'liability',
          parentId: null,
          level: 0,
        ),
      ];

      final summary = dashboardService.calculateDashboardSummary(
        accounts: accounts,
        categories: categories,
        monthTransactions: const [],
        budgets: const [],
        spentByBudgetCategory: const {},
        now: now,
      );

      expect(summary.totalAssets, equals(3500000));
      expect(summary.totalLiabilities, equals(800000));
      expect(summary.netWorth, equals(2700000));
    });

    test('expensesByCategory agrupa correctamente por categoría', () {
      final now = DateTime.now();

      final transactions = <TransactionSummaryDto>[
        const TransactionSummaryDto(
          id: 't1',
          type: 'expense',
          amount: 100000,
          categoryId: 'cat-food',
        ),
        const TransactionSummaryDto(
          id: 't2',
          type: 'expense',
          amount: 50000,
          categoryId: 'cat-food',
        ),
        const TransactionSummaryDto(
          id: 't3',
          type: 'expense',
          amount: 200000,
          categoryId: 'cat-transport',
        ),
      ];

      final summary = dashboardService.calculateDashboardSummary(
        accounts: const [],
        categories: _testCategories(),
        monthTransactions: transactions,
        budgets: const [],
        spentByBudgetCategory: const {},
        now: now,
      );

      expect(summary.expensesByCategory.length, equals(2));

      final foodExpense = summary.expensesByCategory
          .firstWhere((e) => e.categoryId == 'cat-food');
      final transportExpense = summary.expensesByCategory
          .firstWhere((e) => e.categoryId == 'cat-transport');

      expect(foodExpense.amount, equals(150000));
      expect(transportExpense.amount, equals(200000));

      // Verificar porcentajes
      const totalExpenses = 350000.0;
      expect(
        foodExpense.percentage,
        closeTo((150000 / totalExpenses) * 100, 0.01),
      );
      expect(
        transportExpense.percentage,
        closeTo((200000 / totalExpenses) * 100, 0.01),
      );
    });

    test('budgetAlerts solo incluye presupuestos en warning o exceeded', () {
      final now = DateTime.now();

      final budgets = <BudgetInfoDto>[
        const BudgetInfoDto(id: 'b1', categoryId: 'cat-food', amount: 100000),
        const BudgetInfoDto(
            id: 'b2', categoryId: 'cat-transport', amount: 200000),
        const BudgetInfoDto(
            id: 'b3', categoryId: 'cat-entertainment', amount: 50000),
      ];

      final spentByCategory = <String, double>{
        'cat-food': 50000.0, // 50% - safe
        'cat-transport': 180000.0, // 90% - warning
        'cat-entertainment': 75000.0, // 150% - exceeded
      };

      final summary = dashboardService.calculateDashboardSummary(
        accounts: const [],
        categories: _testCategories(),
        monthTransactions: const [],
        budgets: budgets,
        spentByBudgetCategory: spentByCategory,
        now: now,
      );

      // Solo 2 alertas (warning y exceeded, no safe)
      expect(summary.budgetAlerts.length, equals(2));

      final transportAlert = summary.budgetAlerts
          .firstWhere((a) => a.categoryId == 'cat-transport');
      final entertainmentAlert = summary.budgetAlerts
          .firstWhere((a) => a.categoryId == 'cat-entertainment');

      expect(transportAlert.percentage, closeTo(90.0, 0.01));
      expect(entertainmentAlert.percentage, closeTo(150.0, 0.01));
    });

    test('netBalance = totalIncome - totalExpenses (invariante)', () {
      final now = DateTime.now();

      // Múltiples combinaciones de ingresos y gastos
      final testCases = [
        {'income': 1000000.0, 'expense': 500000.0},
        {'income': 0.0, 'expense': 100000.0},
        {'income': 500000.0, 'expense': 0.0},
        {'income': 1234567.89, 'expense': 987654.32},
      ];

      for (final testCase in testCases) {
        final income = testCase['income']!;
        final expense = testCase['expense']!;

        final transactions = <TransactionSummaryDto>[
          if (income > 0)
            TransactionSummaryDto(
              id: 'income',
              type: 'income',
              amount: income,
              categoryId: 'cat-salary',
            ),
          if (expense > 0)
            TransactionSummaryDto(
              id: 'expense',
              type: 'expense',
              amount: expense,
              categoryId: 'cat-food',
            ),
        ];

        final summary = dashboardService.calculateDashboardSummary(
          accounts: const [],
          categories: _testCategories(),
          monthTransactions: transactions,
          budgets: const [],
          spentByBudgetCategory: const {},
          now: now,
        );

        expect(
          summary.netBalance,
          closeTo(income - expense, 0.01),
          reason: 'netBalance debe ser income - expense',
        );
      }
    });

    test('netWorth = totalAssets - totalLiabilities (invariante)', () {
      final now = DateTime.now();

      final testCases = [
        {'assets': 5000000.0, 'liabilities': 1000000.0},
        {'assets': 1000000.0, 'liabilities': 2000000.0}, // Negativo
        {'assets': 0.0, 'liabilities': 500000.0},
        {'assets': 3000000.0, 'liabilities': 0.0},
      ];

      final categories = <CategoryInfoDto>[
        const CategoryInfoDto(
          id: 'cat-asset',
          name: 'Activos',
          icon: null,
          type: 'asset',
          parentId: null,
          level: 0,
        ),
        const CategoryInfoDto(
          id: 'cat-liability',
          name: 'Pasivos',
          icon: null,
          type: 'liability',
          parentId: null,
          level: 0,
        ),
      ];

      for (final testCase in testCases) {
        final assets = testCase['assets']!;
        final liabilities = testCase['liabilities']!;

        final accounts = <AccountBalanceDto>[
          if (assets > 0)
            AccountBalanceDto(
              id: 'asset-acc',
              balance: assets,
              categoryId: 'cat-asset',
            ),
          if (liabilities > 0)
            AccountBalanceDto(
              id: 'liability-acc',
              balance: -liabilities,
              categoryId: 'cat-liability',
            ),
        ];

        final summary = dashboardService.calculateDashboardSummary(
          accounts: accounts,
          categories: categories,
          monthTransactions: const [],
          budgets: const [],
          spentByBudgetCategory: const {},
          now: now,
        );

        expect(
          summary.netWorth,
          closeTo(assets - liabilities, 0.01),
          reason: 'netWorth debe ser assets - liabilities',
        );
      }
    });
  });

  group('Cross-Reference: Category Hierarchy ↔ Spending', () {
    late DashboardService dashboardService;

    setUp(() {
      dashboardService = DashboardService();
    });

    test('ExpenseGroups agrupa subcategorías bajo categoría maestra', () {
      final now = DateTime.now();

      // Jerarquía: Hogar (master) → Servicios, Mercado
      final categories = <CategoryInfoDto>[
        const CategoryInfoDto(
          id: 'cat-hogar',
          name: 'Hogar',
          icon: '🏠',
          type: 'expense',
          parentId: null,
          level: 1,
        ),
        const CategoryInfoDto(
          id: 'cat-servicios',
          name: 'Servicios',
          icon: '💡',
          type: 'expense',
          parentId: 'cat-hogar',
          level: 2,
        ),
        const CategoryInfoDto(
          id: 'cat-mercado',
          name: 'Mercado',
          icon: '🛒',
          type: 'expense',
          parentId: 'cat-hogar',
          level: 2,
        ),
        const CategoryInfoDto(
          id: 'cat-transporte',
          name: 'Transporte',
          icon: '🚗',
          type: 'expense',
          parentId: null,
          level: 1,
        ),
      ];

      final transactions = <TransactionSummaryDto>[
        const TransactionSummaryDto(
          id: 't1',
          type: 'expense',
          amount: 150000,
          categoryId: 'cat-servicios',
        ),
        const TransactionSummaryDto(
          id: 't2',
          type: 'expense',
          amount: 300000,
          categoryId: 'cat-mercado',
        ),
        const TransactionSummaryDto(
          id: 't3',
          type: 'expense',
          amount: 100000,
          categoryId: 'cat-transporte',
        ),
      ];

      final summary = dashboardService.calculateDashboardSummary(
        accounts: const [],
        categories: categories,
        monthTransactions: transactions,
        budgets: const [],
        spentByBudgetCategory: const {},
        now: now,
      );

      // Debe haber 2 grupos: Hogar y Transporte
      expect(summary.currentMonth.expenseGroups.length, equals(2));

      final hogarGroup = summary.currentMonth.expenseGroups
          .firstWhere((g) => g.masterCategoryId == 'cat-hogar');

      // Hogar agrupa servicios + mercado
      expect(hogarGroup.totalAmount, equals(450000));
      expect(hogarGroup.subcategories.length, equals(2));
    });

    test('categoría sin gastos no aparece en expensesByCategory', () {
      final now = DateTime.now();

      final transactions = <TransactionSummaryDto>[
        const TransactionSummaryDto(
          id: 't1',
          type: 'expense',
          amount: 100000,
          categoryId: 'cat-food',
        ),
      ];

      final summary = dashboardService.calculateDashboardSummary(
        accounts: const [],
        categories: _testCategories(),
        monthTransactions: transactions,
        budgets: const [],
        spentByBudgetCategory: const {},
        now: now,
      );

      // Solo cat-food tiene gastos
      expect(summary.expensesByCategory.length, equals(1));
      expect(summary.expensesByCategory.first.categoryId, equals('cat-food'));
    });

    test('suma de porcentajes de gastos = 100%', () {
      final now = DateTime.now();

      final transactions = <TransactionSummaryDto>[
        const TransactionSummaryDto(
          id: 't1',
          type: 'expense',
          amount: 100000,
          categoryId: 'cat-food',
        ),
        const TransactionSummaryDto(
          id: 't2',
          type: 'expense',
          amount: 200000,
          categoryId: 'cat-transport',
        ),
        const TransactionSummaryDto(
          id: 't3',
          type: 'expense',
          amount: 300000,
          categoryId: 'cat-entertainment',
        ),
      ];

      final summary = dashboardService.calculateDashboardSummary(
        accounts: const [],
        categories: _testCategories(),
        monthTransactions: transactions,
        budgets: const [],
        spentByBudgetCategory: const {},
        now: now,
      );

      final totalPercentage = summary.expensesByCategory
          .fold<double>(0, (sum, e) => sum + e.percentage);

      expect(totalPercentage, closeTo(100.0, 0.01));
    });
  });

  group('Cross-Reference: MonthSummary Consistency', () {
    late DashboardService dashboardService;

    setUp(() {
      dashboardService = DashboardService();
    });

    test('MonthSummary.netBalance = incomeTotal - expenseTotal', () {
      final transactions = <TransactionSummaryDto>[
        const TransactionSummaryDto(
          id: 't1',
          type: 'income',
          amount: 2000000,
          categoryId: 'cat-salary',
        ),
        const TransactionSummaryDto(
          id: 't2',
          type: 'expense',
          amount: 500000,
          categoryId: 'cat-food',
        ),
        const TransactionSummaryDto(
          id: 't3',
          type: 'expense',
          amount: 300000,
          categoryId: 'cat-transport',
        ),
      ];

      final summary = dashboardService.calculateMonthSummary(
        transactions: transactions,
        categories: _testCategories(),
        month: 1,
        year: 2026,
      );

      expect(summary.incomeTotal, equals(2000000));
      expect(summary.expenseTotal, equals(800000));
      expect(summary.netBalance, equals(1200000));
    });

    test('MonthSummary con solo gastos tiene netBalance negativo', () {
      final transactions = <TransactionSummaryDto>[
        const TransactionSummaryDto(
          id: 't1',
          type: 'expense',
          amount: 500000,
          categoryId: 'cat-food',
        ),
      ];

      final summary = dashboardService.calculateMonthSummary(
        transactions: transactions,
        categories: _testCategories(),
        month: 2,
        year: 2026,
      );

      expect(summary.incomeTotal, equals(0));
      expect(summary.expenseTotal, equals(500000));
      expect(summary.netBalance, equals(-500000));
    });
  });
}

// =============================================================================
// HELPERS Y MOCKS
// =============================================================================

List<CategoryInfoDto> _testCategories() {
  return const [
    CategoryInfoDto(
      id: 'cat-salary',
      name: 'Salario',
      icon: '💰',
      type: 'income',
      parentId: null,
      level: 1,
    ),
    CategoryInfoDto(
      id: 'cat-bonus',
      name: 'Bonificación',
      icon: '🎁',
      type: 'income',
      parentId: null,
      level: 1,
    ),
    CategoryInfoDto(
      id: 'cat-food',
      name: 'Alimentación',
      icon: '🍔',
      type: 'expense',
      parentId: null,
      level: 1,
    ),
    CategoryInfoDto(
      id: 'cat-transport',
      name: 'Transporte',
      icon: '🚗',
      type: 'expense',
      parentId: null,
      level: 1,
    ),
    CategoryInfoDto(
      id: 'cat-entertainment',
      name: 'Entretenimiento',
      icon: '🎬',
      type: 'expense',
      parentId: null,
      level: 1,
    ),
  ];
}

// =============================================================================
// IN-MEMORY REPOSITORIES PARA TESTING
// =============================================================================

class InMemoryBudgetRepository implements BudgetRepository {
  final _budgets = <String, BudgetData>{};

  @override
  Future<List<BudgetData>> getActiveBudgets() async {
    return _budgets.values.where((b) => b.isActive).toList();
  }

  @override
  Future<List<BudgetData>> getBudgetsForMonth(int month, int year) async {
    return _budgets.values
        .where((b) => b.month == month && b.year == year)
        .toList();
  }

  @override
  Future<BudgetData?> getBudgetForCategory(
    String categoryId,
    int month,
    int year,
  ) async {
    try {
      return _budgets.values.firstWhere(
        (b) => b.categoryId == categoryId && b.month == month && b.year == year,
      );
    } catch (_) {
      return null;
    }
  }

  @override
  Future<void> createBudget(String id, CreateBudgetData data) async {
    final now = DateTime.now();
    _budgets[id] = BudgetData(
      id: id,
      categoryId: data.categoryId,
      amount: data.amount,
      month: data.month,
      year: data.year,
      isActive: true,
      createdAt: now,
      updatedAt: now,
    );
  }

  @override
  Future<void> updateBudgetAmount(String id, double amount) async {
    final existing = _budgets[id];
    if (existing != null) {
      _budgets[id] = BudgetData(
        id: existing.id,
        categoryId: existing.categoryId,
        amount: amount,
        month: existing.month,
        year: existing.year,
        isActive: existing.isActive,
        createdAt: existing.createdAt,
        updatedAt: DateTime.now(),
      );
    }
  }

  @override
  Future<void> deleteBudget(String id) async {
    _budgets.remove(id);
  }

  @override
  Stream<List<BudgetData>> watchCurrentMonthBudgets() {
    final now = DateTime.now();
    return Stream.value(
      _budgets.values
          .where((b) => b.month == now.month && b.year == now.year)
          .toList(),
    );
  }
}

class InMemoryCategorySpendingRepository implements CategorySpendingRepository {
  final _spending = <String, double>{};

  void recordSpending(String categoryId, double amount) {
    _spending[categoryId] = (_spending[categoryId] ?? 0) + amount;
  }

  void clear() => _spending.clear();

  @override
  Future<double> getTotalSpentInPeriod(
    String categoryId,
    DateTime start,
    DateTime end,
  ) async {
    return _spending[categoryId] ?? 0;
  }
}
