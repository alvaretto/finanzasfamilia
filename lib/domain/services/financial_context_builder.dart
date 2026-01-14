import '../entities/ai/financial_context_dto.dart';
import '../entities/financial_context.dart';

/// Construye el contexto financiero anónimo para el asistente IA.
/// Solo incluye datos agregados, nunca transacciones individuales.
///
/// Este servicio es puro: recibe datos y retorna resultados sin I/O.
class FinancialContextBuilder {
  const FinancialContextBuilder();

  /// Construye el contexto para un período específico.
  /// Recibe datos ya obtenidos desde la capa de aplicación.
  FinancialContext buildContext({
    required int year,
    required int month,
    required List<FinancialTransactionDto> transactions,
    required List<FinancialCategoryDto> categories,
    required List<FinancialAccountDto> accounts,
  }) {
    final periodStr = '$year-${month.toString().padLeft(2, '0')}';

    // Calcular totales de transacciones
    double totalIncome = 0;
    double totalExpenses = 0;

    for (final tx in transactions) {
      if (tx.type == 'income') {
        totalIncome += tx.amount;
      } else if (tx.type == 'expense') {
        totalExpenses += tx.amount;
      }
    }

    // Obtener gastos por categoría
    final expenseTransactions =
        transactions.where((tx) => tx.type == 'expense').toList();
    final expensesByCategory = _buildExpensesByCategory(
      expenseTransactions: expenseTransactions,
      categories: categories,
    );

    // Construir contexto de cuentas
    final accountContexts = _buildAccountsContext(
      accounts: accounts,
      categories: categories,
    );

    // Calcular patrimonio
    double totalAssets = 0;
    double totalLiabilities = 0;

    for (final account in accountContexts) {
      if (account.type == 'asset') {
        totalAssets += account.balance;
      } else {
        totalLiabilities += account.balance.abs();
      }
    }

    return FinancialContext(
      period: periodStr,
      summary: FinancialSummary(
        totalIncome: totalIncome,
        totalExpenses: totalExpenses,
        balance: totalIncome - totalExpenses,
        netWorth: totalAssets - totalLiabilities,
        totalAssets: totalAssets,
        totalLiabilities: totalLiabilities,
      ),
      expensesByCategory: expensesByCategory,
      accounts: accountContexts,
      currency: 'COP',
    );
  }

  Map<String, CategoryExpenseContext> _buildExpensesByCategory({
    required List<FinancialTransactionDto> expenseTransactions,
    required List<FinancialCategoryDto> categories,
  }) {
    final categoryMap = {for (var c in categories) c.id: c};
    final expensesByCategory = <String, Map<String, double>>{};

    for (final tx in expenseTransactions) {
      final category = categoryMap[tx.categoryId];
      if (category == null) continue;

      // Encontrar categoría raíz
      var rootCategory = category;
      while (rootCategory.parentId != null) {
        final parent = categoryMap[rootCategory.parentId];
        if (parent == null) break;
        rootCategory = parent;
      }

      final rootName = rootCategory.name;
      final subName = category.name;

      expensesByCategory[rootName] ??= {};
      expensesByCategory[rootName]![subName] =
          (expensesByCategory[rootName]![subName] ?? 0) + tx.amount;
    }

    // Convertir a formato final
    return expensesByCategory.map((rootName, subcategories) {
      final total = subcategories.values.fold(0.0, (a, b) => a + b);
      return MapEntry(
        rootName,
        CategoryExpenseContext(
          total: total,
          subcategories: subcategories,
        ),
      );
    });
  }

  List<AccountContext> _buildAccountsContext({
    required List<FinancialAccountDto> accounts,
    required List<FinancialCategoryDto> categories,
  }) {
    final categoryMap = {for (var c in categories) c.id: c};

    return accounts.map((account) {
      final category = categoryMap[account.categoryId];
      final type = category?.type ?? 'asset';

      return AccountContext(
        name: account.name,
        type: type,
        balance: account.balance,
      );
    }).toList();
  }
}
