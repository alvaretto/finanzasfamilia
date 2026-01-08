import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../data/local/database.dart';
import 'database_provider.dart';
import 'financial_indicators_provider.dart';

part 'dashboard_provider.g.dart';

// ============================================================
// MODELOS DE DASHBOARD
// ============================================================

/// Gasto por categoría
class CategoryExpense {
  final String categoryId;
  final String categoryName;
  final String? icon;
  final double amount;
  final double percentage; // % del total de gastos

  const CategoryExpense({
    required this.categoryId,
    required this.categoryName,
    this.icon,
    required this.amount,
    required this.percentage,
  });
}

/// Alerta de presupuesto
class BudgetAlert {
  final String categoryId;
  final String categoryName;
  final double budgetAmount;
  final double spentAmount;
  final double percentage;
  final IndicatorStatus status;

  const BudgetAlert({
    required this.categoryId,
    required this.categoryName,
    required this.budgetAmount,
    required this.spentAmount,
    required this.percentage,
    required this.status,
  });

  bool get isOverBudget => percentage >= 100;
  bool get isWarning => percentage >= 80 && percentage < 100;
}

/// Grupo de gastos agrupados por categoría maestra
class ExpenseGroup {
  final String masterCategoryId;
  final String masterCategoryName;
  final String? icon;
  final double totalAmount;
  final List<CategoryExpense> subcategories;

  const ExpenseGroup({
    required this.masterCategoryId,
    required this.masterCategoryName,
    this.icon,
    required this.totalAmount,
    required this.subcategories,
  });
}

/// Resumen del mes
class MonthSummary {
  final int month;
  final int year;
  final double incomeTotal;
  final double expenseTotal;
  final double netBalance;
  final List<ExpenseGroup> expenseGroups;

  const MonthSummary({
    required this.month,
    required this.year,
    required this.incomeTotal,
    required this.expenseTotal,
    required this.netBalance,
    required this.expenseGroups,
  });
}

/// Resumen completo del dashboard "¿Cómo Voy?"
class DashboardSummary {
  final double totalIncome;
  final double totalExpenses;
  final double netBalance;
  final double totalAssets;
  final double totalLiabilities;
  final double netWorth;
  final double availableBalance;
  final List<CategoryExpense> expensesByCategory;
  final List<BudgetAlert> budgetAlerts;
  final MonthSummary currentMonth;

  const DashboardSummary({
    required this.totalIncome,
    required this.totalExpenses,
    required this.netBalance,
    required this.totalAssets,
    required this.totalLiabilities,
    required this.netWorth,
    required this.availableBalance,
    required this.expensesByCategory,
    required this.budgetAlerts,
    required this.currentMonth,
  });
}

// ============================================================
// PROVIDERS
// ============================================================

/// Provider del resumen del dashboard
@riverpod
Future<DashboardSummary> dashboardSummary(DashboardSummaryRef ref) async {
  final db = ref.watch(appDatabaseProvider);
  final categoriesDao = ref.watch(categoriesDaoProvider);
  final transactionsDao = ref.watch(transactionsDaoProvider);
  final budgetsDao = ref.watch(budgetsDaoProvider);

  final now = DateTime.now();
  final startOfMonth = DateTime(now.year, now.month, 1);
  final endOfMonth = DateTime(now.year, now.month + 1, 0, 23, 59, 59);

  // Obtener todas las cuentas para calcular activos/pasivos
  final accounts = await db.select(db.accounts).get();
  final categories = await categoriesDao.getAllCategories();

  // Calcular totales de activos y pasivos
  double totalAssets = 0;
  double totalLiabilities = 0;

  final assetCategoryIds = categories
      .where((c) => c.type == 'asset')
      .map((c) => c.id)
      .toSet();

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

  // Obtener transacciones del mes
  final monthTransactions = await transactionsDao.getTransactionsInPeriod(
    startOfMonth,
    endOfMonth,
  );

  // Calcular ingresos y gastos del mes
  double totalIncome = 0;
  double totalExpenses = 0;
  final expenseMap = <String, double>{};

  for (final tx in monthTransactions) {
    if (tx.type == 'income') {
      totalIncome += tx.amount;
    } else if (tx.type == 'expense') {
      totalExpenses += tx.amount;
      expenseMap[tx.categoryId] = (expenseMap[tx.categoryId] ?? 0) + tx.amount;
    }
  }

  // Construir gastos por categoría
  final expensesByCategory = <CategoryExpense>[];
  for (final entry in expenseMap.entries) {
    final category = categories.firstWhere(
      (c) => c.id == entry.key,
      orElse: () => CategoryEntry(
        id: entry.key,
        name: 'Desconocido',
        icon: null,
        type: 'expense',
        parentId: null,
        level: 0,
        sortOrder: 0,
        isActive: true,
        isSystem: false,
        createdAt: now,
        updatedAt: now,
      ),
    );

    expensesByCategory.add(CategoryExpense(
      categoryId: entry.key,
      categoryName: category.name,
      icon: category.icon,
      amount: entry.value,
      percentage: totalExpenses > 0 ? (entry.value / totalExpenses) * 100 : 0,
    ));
  }

  // Ordenar por monto descendente
  expensesByCategory.sort((a, b) => b.amount.compareTo(a.amount));

  // Obtener alertas de presupuesto
  final budgets = await budgetsDao.getBudgetsForMonth(now.month, now.year);
  final budgetAlerts = <BudgetAlert>[];

  for (final budget in budgets) {
    final spent = await transactionsDao.getTotalByCategoryInPeriod(
      budget.categoryId,
      startOfMonth,
      endOfMonth,
    );

    final percentage = budget.amount > 0 ? (spent / budget.amount) * 100 : 0.0;
    final status = _calculateStatus(percentage.toDouble());

    // Solo alertar si está en warning o danger
    if (status != IndicatorStatus.good) {
      final category = categories.firstWhere(
        (c) => c.id == budget.categoryId,
        orElse: () => CategoryEntry(
          id: budget.categoryId,
          name: 'Desconocido',
          icon: null,
          type: 'expense',
          parentId: null,
          level: 0,
          sortOrder: 0,
          isActive: true,
          isSystem: false,
          createdAt: now,
          updatedAt: now,
        ),
      );

      budgetAlerts.add(BudgetAlert(
        categoryId: budget.categoryId,
        categoryName: category.name,
        budgetAmount: budget.amount,
        spentAmount: spent,
        percentage: percentage.toDouble(),
        status: status,
      ));
    }
  }

  // Calcular saldo disponible real
  final availableBalance = totalAssets - totalLiabilities;

  // Construir resumen del mes
  final currentMonth = MonthSummary(
    month: now.month,
    year: now.year,
    incomeTotal: totalIncome,
    expenseTotal: totalExpenses,
    netBalance: totalIncome - totalExpenses,
    expenseGroups: await _buildExpenseGroups(
      expenseMap,
      categories,
      totalExpenses,
    ),
  );

  return DashboardSummary(
    totalIncome: totalIncome,
    totalExpenses: totalExpenses,
    netBalance: totalIncome - totalExpenses,
    totalAssets: totalAssets,
    totalLiabilities: totalLiabilities,
    netWorth: totalAssets - totalLiabilities,
    availableBalance: availableBalance,
    expensesByCategory: expensesByCategory,
    budgetAlerts: budgetAlerts,
    currentMonth: currentMonth,
  );
}

/// Provider del resumen de un mes específico
@riverpod
Future<MonthSummary> monthSummary(
  MonthSummaryRef ref,
  int month,
  int year,
) async {
  final categoriesDao = ref.watch(categoriesDaoProvider);
  final transactionsDao = ref.watch(transactionsDaoProvider);

  final startOfMonth = DateTime(year, month, 1);
  final endOfMonth = DateTime(year, month + 1, 0, 23, 59, 59);

  final categories = await categoriesDao.getAllCategories();
  final transactions = await transactionsDao.getTransactionsInPeriod(
    startOfMonth,
    endOfMonth,
  );

  double incomeTotal = 0;
  double expenseTotal = 0;
  final expenseMap = <String, double>{};

  for (final tx in transactions) {
    if (tx.type == 'income') {
      incomeTotal += tx.amount;
    } else if (tx.type == 'expense') {
      expenseTotal += tx.amount;
      expenseMap[tx.categoryId] = (expenseMap[tx.categoryId] ?? 0) + tx.amount;
    }
  }

  return MonthSummary(
    month: month,
    year: year,
    incomeTotal: incomeTotal,
    expenseTotal: expenseTotal,
    netBalance: incomeTotal - expenseTotal,
    expenseGroups: await _buildExpenseGroups(expenseMap, categories, expenseTotal),
  );
}

/// Construye grupos de gastos agrupados por categoría maestra
Future<List<ExpenseGroup>> _buildExpenseGroups(
  Map<String, double> expenseMap,
  List<CategoryEntry> categories,
  double totalExpenses,
) async {
  final masterCategories = categories.where((c) => c.type == 'expense' && c.level == 1);
  final groups = <ExpenseGroup>[];

  for (final master in masterCategories) {
    // Encontrar todas las subcategorías de esta categoría maestra
    final subcategoryIds = _findAllDescendants(master.id, categories);
    subcategoryIds.add(master.id);

    // Sumar gastos de todas las subcategorías
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
          percentage: totalExpenses > 0 ? (amount / totalExpenses) * 100 : 0,
        ));
      }
    }

    if (totalAmount > 0) {
      groups.add(ExpenseGroup(
        masterCategoryId: master.id,
        masterCategoryName: master.name,
        icon: master.icon,
        totalAmount: totalAmount,
        subcategories: subcategories..sort((a, b) => b.amount.compareTo(a.amount)),
      ));
    }
  }

  // Ordenar por monto total descendente
  groups.sort((a, b) => b.totalAmount.compareTo(a.totalAmount));
  return groups;
}

/// Encuentra todos los descendientes de una categoría
Set<String> _findAllDescendants(String parentId, List<CategoryEntry> categories) {
  final descendants = <String>{};
  final children = categories.where((c) => c.parentId == parentId);

  for (final child in children) {
    descendants.add(child.id);
    descendants.addAll(_findAllDescendants(child.id, categories));
  }

  return descendants;
}

/// Calcula el estado del indicador basado en porcentaje
IndicatorStatus _calculateStatus(double percentage) {
  if (percentage >= 100) return IndicatorStatus.danger;
  if (percentage >= 80) return IndicatorStatus.warning;
  return IndicatorStatus.good;
}
