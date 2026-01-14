import '../entities/dashboard/dashboard.dart';
import '../entities/dashboard/indicator_status.dart';

/// Servicio de dominio para cálculos del Dashboard.
/// Contiene lógica de negocio pura, sin dependencias de UI o framework.
/// Usa DTOs livianos en lugar de clases de Drift para cumplir Clean Architecture.
class DashboardService {
  /// Calcula el resumen completo del dashboard para el mes actual.
  DashboardSummary calculateDashboardSummary({
    required List<AccountBalanceDto> accounts,
    required List<CategoryInfoDto> categories,
    required List<TransactionSummaryDto> monthTransactions,
    required List<BudgetInfoDto> budgets,
    required Map<String, double> spentByBudgetCategory,
    required DateTime now,
  }) {
    // Calcular totales de activos y pasivos
    final assetLiabilityTotals = _calculateAssetLiabilityTotals(
      accounts: accounts,
      categories: categories,
    );

    // Calcular ingresos y gastos del mes
    final monthlyTotals = _calculateMonthlyTotals(monthTransactions);

    // Construir gastos por categoría
    final expensesByCategory = _buildExpensesByCategory(
      expenseMap: monthlyTotals.expenseMap,
      categories: categories,
      totalExpenses: monthlyTotals.totalExpenses,
      now: now,
    );

    // Obtener alertas de presupuesto
    final budgetAlerts = _buildBudgetAlerts(
      budgets: budgets,
      spentByCategory: spentByBudgetCategory,
      categories: categories,
      now: now,
    );

    // Construir grupos de gastos
    final expenseGroups = _buildExpenseGroups(
      expenseMap: monthlyTotals.expenseMap,
      categories: categories,
      totalExpenses: monthlyTotals.totalExpenses,
    );

    // Construir resumen del mes
    final currentMonth = MonthSummary(
      month: now.month,
      year: now.year,
      incomeTotal: monthlyTotals.totalIncome,
      expenseTotal: monthlyTotals.totalExpenses,
      netBalance: monthlyTotals.totalIncome - monthlyTotals.totalExpenses,
      expenseGroups: expenseGroups,
    );

    return DashboardSummary(
      totalIncome: monthlyTotals.totalIncome,
      totalExpenses: monthlyTotals.totalExpenses,
      netBalance: monthlyTotals.totalIncome - monthlyTotals.totalExpenses,
      totalAssets: assetLiabilityTotals.totalAssets,
      totalLiabilities: assetLiabilityTotals.totalLiabilities,
      netWorth: assetLiabilityTotals.totalAssets -
          assetLiabilityTotals.totalLiabilities,
      availableBalance: assetLiabilityTotals.totalAssets -
          assetLiabilityTotals.totalLiabilities,
      expensesByCategory: expensesByCategory,
      budgetAlerts: budgetAlerts,
      currentMonth: currentMonth,
    );
  }

  /// Calcula el resumen de un mes específico.
  MonthSummary calculateMonthSummary({
    required List<TransactionSummaryDto> transactions,
    required List<CategoryInfoDto> categories,
    required int month,
    required int year,
  }) {
    final monthlyTotals = _calculateMonthlyTotals(transactions);

    final expenseGroups = _buildExpenseGroups(
      expenseMap: monthlyTotals.expenseMap,
      categories: categories,
      totalExpenses: monthlyTotals.totalExpenses,
    );

    return MonthSummary(
      month: month,
      year: year,
      incomeTotal: monthlyTotals.totalIncome,
      expenseTotal: monthlyTotals.totalExpenses,
      netBalance: monthlyTotals.totalIncome - monthlyTotals.totalExpenses,
      expenseGroups: expenseGroups,
    );
  }

  // ============================================================
  // MÉTODOS PRIVADOS DE CÁLCULO
  // ============================================================

  _AssetLiabilityTotals _calculateAssetLiabilityTotals({
    required List<AccountBalanceDto> accounts,
    required List<CategoryInfoDto> categories,
  }) {
    double totalAssets = 0;
    double totalLiabilities = 0;

    final assetCategoryIds =
        categories.where((c) => c.type == 'asset').map((c) => c.id).toSet();

    final liabilityCategoryIds = categories
        .where((c) => c.type == 'liability')
        .map((c) => c.id)
        .toSet();

    for (final account in accounts) {
      if (assetCategoryIds.contains(account.categoryId)) {
        totalAssets += account.balance;
      } else if (liabilityCategoryIds.contains(account.categoryId)) {
        totalLiabilities += account.balance.abs();
      }
    }

    return _AssetLiabilityTotals(
      totalAssets: totalAssets,
      totalLiabilities: totalLiabilities,
    );
  }

  _MonthlyTotals _calculateMonthlyTotals(
      List<TransactionSummaryDto> transactions) {
    double totalIncome = 0;
    double totalExpenses = 0;
    final expenseMap = <String, double>{};

    for (final tx in transactions) {
      if (tx.type == 'income') {
        totalIncome += tx.amount;
      } else if (tx.type == 'expense') {
        totalExpenses += tx.amount;
        expenseMap[tx.categoryId] =
            (expenseMap[tx.categoryId] ?? 0) + tx.amount;
      }
    }

    return _MonthlyTotals(
      totalIncome: totalIncome,
      totalExpenses: totalExpenses,
      expenseMap: expenseMap,
    );
  }

  List<CategoryExpense> _buildExpensesByCategory({
    required Map<String, double> expenseMap,
    required List<CategoryInfoDto> categories,
    required double totalExpenses,
    required DateTime now,
  }) {
    final expensesByCategory = <CategoryExpense>[];

    for (final entry in expenseMap.entries) {
      final category = categories.firstWhere(
        (c) => c.id == entry.key,
        orElse: () => _createUnknownCategory(entry.key),
      );

      expensesByCategory.add(CategoryExpense(
        categoryId: entry.key,
        categoryName: category.name,
        icon: category.icon,
        amount: entry.value,
        percentage:
            totalExpenses > 0 ? (entry.value / totalExpenses) * 100 : 0,
      ));
    }

    expensesByCategory.sort((a, b) => b.amount.compareTo(a.amount));
    return expensesByCategory;
  }

  List<BudgetAlert> _buildBudgetAlerts({
    required List<BudgetInfoDto> budgets,
    required Map<String, double> spentByCategory,
    required List<CategoryInfoDto> categories,
    required DateTime now,
  }) {
    final budgetAlerts = <BudgetAlert>[];

    for (final budget in budgets) {
      final spent = spentByCategory[budget.categoryId] ?? 0;
      final percentage =
          budget.amount > 0 ? (spent / budget.amount) * 100 : 0.0;
      final status = calculateIndicatorStatus(percentage);

      if (status != IndicatorStatus.good) {
        final category = categories.firstWhere(
          (c) => c.id == budget.categoryId,
          orElse: () => _createUnknownCategory(budget.categoryId),
        );

        budgetAlerts.add(BudgetAlert(
          categoryId: budget.categoryId,
          categoryName: category.name,
          budgetAmount: budget.amount,
          spentAmount: spent,
          percentage: percentage,
          status: status,
        ));
      }
    }

    return budgetAlerts;
  }

  List<ExpenseGroup> _buildExpenseGroups({
    required Map<String, double> expenseMap,
    required List<CategoryInfoDto> categories,
    required double totalExpenses,
  }) {
    final masterCategories =
        categories.where((c) => c.type == 'expense' && c.level == 1);
    final groups = <ExpenseGroup>[];

    for (final master in masterCategories) {
      final subcategoryIds = _findAllDescendants(master.id, categories);
      subcategoryIds.add(master.id);

      double totalAmount = 0;
      final subcategories = <CategoryExpense>[];

      for (final subId in subcategoryIds) {
        final amount = expenseMap[subId] ?? 0;
        if (amount > 0) {
          totalAmount += amount;
          final subCategory = categories.firstWhere((c) => c.id == subId);
          subcategories.add(CategoryExpense(
            categoryId: subId,
            categoryName: subCategory.name,
            icon: subCategory.icon,
            amount: amount,
            percentage:
                totalExpenses > 0 ? (amount / totalExpenses) * 100 : 0,
          ));
        }
      }

      if (totalAmount > 0) {
        groups.add(ExpenseGroup(
          masterCategoryId: master.id,
          masterCategoryName: master.name,
          icon: master.icon,
          totalAmount: totalAmount,
          subcategories: subcategories
            ..sort((a, b) => b.amount.compareTo(a.amount)),
        ));
      }
    }

    groups.sort((a, b) => b.totalAmount.compareTo(a.totalAmount));
    return groups;
  }

  Set<String> _findAllDescendants(
      String parentId, List<CategoryInfoDto> categories) {
    final descendants = <String>{};
    final children = categories.where((c) => c.parentId == parentId);

    for (final child in children) {
      descendants.add(child.id);
      descendants.addAll(_findAllDescendants(child.id, categories));
    }

    return descendants;
  }

  CategoryInfoDto _createUnknownCategory(String id) {
    return CategoryInfoDto(
      id: id,
      name: 'Desconocido',
      icon: null,
      type: 'expense',
      parentId: null,
      level: 0,
    );
  }
}

// ============================================================
// CLASES AUXILIARES INTERNAS
// ============================================================

class _AssetLiabilityTotals {
  final double totalAssets;
  final double totalLiabilities;

  const _AssetLiabilityTotals({
    required this.totalAssets,
    required this.totalLiabilities,
  });
}

class _MonthlyTotals {
  final double totalIncome;
  final double totalExpenses;
  final Map<String, double> expenseMap;

  const _MonthlyTotals({
    required this.totalIncome,
    required this.totalExpenses,
    required this.expenseMap,
  });
}
