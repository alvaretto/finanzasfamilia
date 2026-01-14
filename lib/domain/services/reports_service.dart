import '../entities/reports/reports.dart';

/// Servicio de dominio para generar reportes financieros.
/// Contiene lógica de negocio pura, sin dependencias de I/O.
class ReportsService {
  /// Genera el Balance General (Activos, Pasivos, Patrimonio)
  BalanceSheet generateBalanceSheet({
    required List<AccountReportDto> accounts,
    required List<CategoryReportDto> categories,
  }) {
    final categoryMap = {for (var c in categories) c.id: c};

    double totalAssets = 0;
    double totalLiabilities = 0;
    final assetItems = <BalanceItem>[];
    final liabilityItems = <BalanceItem>[];

    for (final account in accounts) {
      final category = categoryMap[account.categoryId];
      if (category == null) continue;

      final item = BalanceItem(
        name: account.name,
        amount: account.balance,
        icon: account.icon,
        categoryName: category.name,
      );

      if (category.type == 'asset') {
        totalAssets += account.balance;
        assetItems.add(item);
      } else if (category.type == 'liability') {
        totalLiabilities += account.balance;
        liabilityItems.add(item);
      }
    }

    return BalanceSheet(
      date: DateTime.now(),
      assets: assetItems,
      liabilities: liabilityItems,
      totalAssets: totalAssets,
      totalLiabilities: totalLiabilities,
      netWorth: totalAssets - totalLiabilities,
    );
  }

  /// Genera el Estado de Resultados (Ingresos - Gastos = Resultado)
  IncomeStatement generateIncomeStatement({
    required List<TransactionReportDto> transactions,
    required List<CategoryReportDto> categories,
    required DateTime startDate,
    required DateTime endDate,
  }) {
    final categoryMap = {for (var c in categories) c.id: c};

    // Agrupar por categoría
    final incomeByCategory = <String, double>{};
    final expenseByCategory = <String, double>{};

    for (final tx in transactions) {
      final category = categoryMap[tx.categoryId];
      if (category == null) continue;

      final categoryName = category.name;

      if (tx.type == 'income') {
        incomeByCategory[categoryName] =
            (incomeByCategory[categoryName] ?? 0) + tx.amount;
      } else if (tx.type == 'expense') {
        expenseByCategory[categoryName] =
            (expenseByCategory[categoryName] ?? 0) + tx.amount;
      }
    }

    final incomeItems = incomeByCategory.entries
        .map((e) => IncomeStatementItem(
              categoryName: e.key,
              amount: e.value,
            ))
        .toList()
      ..sort((a, b) => b.amount.compareTo(a.amount));

    final expenseItems = expenseByCategory.entries
        .map((e) => IncomeStatementItem(
              categoryName: e.key,
              amount: e.value,
            ))
        .toList()
      ..sort((a, b) => b.amount.compareTo(a.amount));

    final totalIncome =
        incomeItems.fold(0.0, (sum, item) => sum + item.amount);
    final totalExpenses =
        expenseItems.fold(0.0, (sum, item) => sum + item.amount);

    return IncomeStatement(
      startDate: startDate,
      endDate: endDate,
      incomeItems: incomeItems,
      expenseItems: expenseItems,
      totalIncome: totalIncome,
      totalExpenses: totalExpenses,
      netIncome: totalIncome - totalExpenses,
    );
  }

  /// Genera reporte de flujo de efectivo por cuenta
  CashFlowReport generateCashFlowReport({
    required List<TransactionReportDto> transactions,
    required List<AccountReportDto> accounts,
    required DateTime startDate,
    required DateTime endDate,
  }) {
    // Calcular flujo por cuenta
    final flowByAccount = <String, CashFlowItem>{};

    for (final account in accounts) {
      flowByAccount[account.id] = CashFlowItem(
        accountName: account.name,
        accountIcon: account.icon,
        inflows: 0,
        outflows: 0,
      );
    }

    for (final tx in transactions) {
      if (tx.type == 'income' && tx.toAccountId != null) {
        final item = flowByAccount[tx.toAccountId];
        if (item != null) {
          flowByAccount[tx.toAccountId!] = CashFlowItem(
            accountName: item.accountName,
            accountIcon: item.accountIcon,
            inflows: item.inflows + tx.amount,
            outflows: item.outflows,
          );
        }
      } else if (tx.type == 'expense' && tx.fromAccountId != null) {
        final item = flowByAccount[tx.fromAccountId];
        if (item != null) {
          flowByAccount[tx.fromAccountId!] = CashFlowItem(
            accountName: item.accountName,
            accountIcon: item.accountIcon,
            inflows: item.inflows,
            outflows: item.outflows + tx.amount,
          );
        }
      } else if (tx.type == 'transfer') {
        if (tx.fromAccountId != null) {
          final fromItem = flowByAccount[tx.fromAccountId];
          if (fromItem != null) {
            flowByAccount[tx.fromAccountId!] = CashFlowItem(
              accountName: fromItem.accountName,
              accountIcon: fromItem.accountIcon,
              inflows: fromItem.inflows,
              outflows: fromItem.outflows + tx.amount,
            );
          }
        }
        if (tx.toAccountId != null) {
          final toItem = flowByAccount[tx.toAccountId];
          if (toItem != null) {
            flowByAccount[tx.toAccountId!] = CashFlowItem(
              accountName: toItem.accountName,
              accountIcon: toItem.accountIcon,
              inflows: toItem.inflows + tx.amount,
              outflows: toItem.outflows,
            );
          }
        }
      }
    }

    final items = flowByAccount.values.toList();
    final totalInflows = items.fold(0.0, (sum, item) => sum + item.inflows);
    final totalOutflows = items.fold(0.0, (sum, item) => sum + item.outflows);

    return CashFlowReport(
      startDate: startDate,
      endDate: endDate,
      items: items,
      totalInflows: totalInflows,
      totalOutflows: totalOutflows,
      netCashFlow: totalInflows - totalOutflows,
    );
  }

  /// Genera resumen mensual
  MonthlySummary generateMonthlySummary({
    required IncomeStatement incomeStatement,
    required int transactionCount,
    required int year,
    required int month,
  }) {
    // Calcular promedio diario de gastos
    final endDate = DateTime(year, month + 1, 0);
    final daysInMonth = endDate.day;
    final avgDailyExpense = incomeStatement.totalExpenses / daysInMonth;

    // Categoría con más gasto
    String? topExpenseCategory;
    double topExpenseAmount = 0;
    for (final item in incomeStatement.expenseItems) {
      if (item.amount > topExpenseAmount) {
        topExpenseAmount = item.amount;
        topExpenseCategory = item.categoryName;
      }
    }

    return MonthlySummary(
      year: year,
      month: month,
      totalIncome: incomeStatement.totalIncome,
      totalExpenses: incomeStatement.totalExpenses,
      netResult: incomeStatement.netIncome,
      transactionCount: transactionCount,
      avgDailyExpense: avgDailyExpense,
      topExpenseCategory: topExpenseCategory,
      topExpenseAmount: topExpenseAmount,
      savingsRate: incomeStatement.totalIncome > 0
          ? (incomeStatement.netIncome / incomeStatement.totalIncome) * 100
          : 0,
    );
  }
}

/// Balance General
class BalanceSheet {
  final DateTime date;
  final List<BalanceItem> assets;
  final List<BalanceItem> liabilities;
  final double totalAssets;
  final double totalLiabilities;
  final double netWorth;

  BalanceSheet({
    required this.date,
    required this.assets,
    required this.liabilities,
    required this.totalAssets,
    required this.totalLiabilities,
    required this.netWorth,
  });
}

class BalanceItem {
  final String name;
  final double amount;
  final String? icon;
  final String categoryName;

  BalanceItem({
    required this.name,
    required this.amount,
    this.icon,
    required this.categoryName,
  });
}

/// Estado de Resultados
class IncomeStatement {
  final DateTime startDate;
  final DateTime endDate;
  final List<IncomeStatementItem> incomeItems;
  final List<IncomeStatementItem> expenseItems;
  final double totalIncome;
  final double totalExpenses;
  final double netIncome;

  IncomeStatement({
    required this.startDate,
    required this.endDate,
    required this.incomeItems,
    required this.expenseItems,
    required this.totalIncome,
    required this.totalExpenses,
    required this.netIncome,
  });
}

class IncomeStatementItem {
  final String categoryName;
  final double amount;

  IncomeStatementItem({
    required this.categoryName,
    required this.amount,
  });
}

/// Reporte de Flujo de Efectivo
class CashFlowReport {
  final DateTime startDate;
  final DateTime endDate;
  final List<CashFlowItem> items;
  final double totalInflows;
  final double totalOutflows;
  final double netCashFlow;

  CashFlowReport({
    required this.startDate,
    required this.endDate,
    required this.items,
    required this.totalInflows,
    required this.totalOutflows,
    required this.netCashFlow,
  });
}

class CashFlowItem {
  final String accountName;
  final String? accountIcon;
  final double inflows;
  final double outflows;

  CashFlowItem({
    required this.accountName,
    this.accountIcon,
    required this.inflows,
    required this.outflows,
  });

  double get netFlow => inflows - outflows;
}

/// Resumen Mensual
class MonthlySummary {
  final int year;
  final int month;
  final double totalIncome;
  final double totalExpenses;
  final double netResult;
  final int transactionCount;
  final double avgDailyExpense;
  final String? topExpenseCategory;
  final double topExpenseAmount;
  final double savingsRate;

  MonthlySummary({
    required this.year,
    required this.month,
    required this.totalIncome,
    required this.totalExpenses,
    required this.netResult,
    required this.transactionCount,
    required this.avgDailyExpense,
    this.topExpenseCategory,
    required this.topExpenseAmount,
    required this.savingsRate,
  });
}
