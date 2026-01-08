import '../../data/local/daos/daos.dart';
import '../entities/financial_context.dart';

/// Construye el contexto financiero anónimo para el asistente IA
/// Solo incluye datos agregados, nunca transacciones individuales
class FinancialContextBuilder {
  final TransactionsDao transactionsDao;
  final CategoriesDao categoriesDao;
  final AccountsDao accountsDao;
  final JournalEntriesDao journalEntriesDao;

  FinancialContextBuilder({
    required this.transactionsDao,
    required this.categoriesDao,
    required this.accountsDao,
    required this.journalEntriesDao,
  });

  /// Construye el contexto para el período actual (mes actual)
  Future<FinancialContext> buildCurrentMonthContext() async {
    final now = DateTime.now();
    return buildContextForPeriod(
      year: now.year,
      month: now.month,
    );
  }

  /// Construye el contexto para un período específico
  Future<FinancialContext> buildContextForPeriod({
    required int year,
    required int month,
  }) async {
    final startDate = DateTime(year, month, 1);
    final endDate = DateTime(year, month + 1, 0, 23, 59, 59);
    final periodStr = '$year-${month.toString().padLeft(2, '0')}';

    // Obtener transacciones del período
    final transactions = await transactionsDao.getTransactionsInPeriod(
      startDate,
      endDate,
    );

    // Calcular totales
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
    final expensesByCategory = await _buildExpensesByCategory(
      transactions.where((tx) => tx.type == 'expense').toList(),
    );

    // Obtener cuentas
    final accounts = await _buildAccountsContext();

    // Calcular patrimonio
    double totalAssets = 0;
    double totalLiabilities = 0;

    for (final account in accounts) {
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
      accounts: accounts,
      currency: 'COP',
    );
  }

  Future<Map<String, CategoryExpenseContext>> _buildExpensesByCategory(
    List<dynamic> expenseTransactions,
  ) async {
    final categories = await categoriesDao.getAllCategories();
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

  Future<List<AccountContext>> _buildAccountsContext() async {
    final accounts = await accountsDao.getActiveAccounts();
    final categories = await categoriesDao.getAllCategories();
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
