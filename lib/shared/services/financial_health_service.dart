import '../../features/accounts/domain/models/account_model.dart';
import '../../features/transactions/domain/models/transaction_model.dart';
import '../utils/financial_health.dart';

/// Servicio para calcular la salud financiera del usuario
class FinancialHealthService {
  /// Calcula la salud financiera basándose en las cuentas y transacciones
  static FinancialHealth calculate({
    required List<AccountModel> accounts,
    required List<TransactionModel> transactions,
    required double monthlyIncome,
    required double monthlyExpenses,
  }) {
    // Calcular activos totales (cuentas con balance positivo)
    final totalAssets = accounts
        .where((acc) => acc.type.isAsset)
        .fold(0.0, (sum, acc) => sum + acc.balance);

    // Calcular pasivos totales (deudas)
    final totalLiabilities = accounts
        .where((acc) => acc.type.isLiability)
        .fold(0.0, (sum, acc) => sum + acc.balance.abs());

    // Calcular gastos fijos (aproximación: 60% de los gastos mensuales)
    // TODO: Mejorar con clasificación de categorías fijas vs variables
    final fixedExpenses = monthlyExpenses * 0.6;

    // Calcular fondo de emergencia (efectivo + cuentas bancarias + ahorros)
    final emergencyFund = accounts
        .where((acc) =>
            acc.type == AccountType.bank ||
            acc.type == AccountType.savings ||
            acc.type == AccountType.cash)
        .fold(0.0, (sum, acc) => sum + acc.balance);

    return FinancialHealth(
      monthlyIncome: monthlyIncome,
      monthlyExpenses: monthlyExpenses,
      totalAssets: totalAssets,
      totalLiabilities: totalLiabilities,
      fixedExpenses: fixedExpenses,
      emergencyFund: emergencyFund,
    );
  }

  /// Calcula gastos fijos reales basándose en categorías
  static double calculateFixedExpenses(List<TransactionModel> transactions) {
    // Categorías consideradas gastos fijos
    final fixedCategories = [
      'vivienda',
      'renta',
      'hipoteca',
      'administracion',
      'agua',
      'energia',
      'gas',
      'internet',
      'seguro',
      'impuesto',
    ];

    return transactions
        .where((tx) {
          if (tx.type != TransactionType.expense) return false;
          final categoryName = tx.categoryName?.toLowerCase() ?? '';
          return fixedCategories.any((cat) => categoryName.contains(cat));
        })
        .fold(0.0, (sum, tx) => sum + tx.amount);
  }

  /// Identifica si el usuario tiene un fondo de emergencia adecuado
  static bool hasAdequateEmergencyFund({
    required double emergencyFund,
    required double fixedExpenses,
  }) {
    if (fixedExpenses == 0) return false;
    final months = emergencyFund / fixedExpenses;
    return months >= 6;
  }

  /// Calcula el patrimonio neto (activos - pasivos)
  static double calculateNetWorth({
    required List<AccountModel> accounts,
  }) {
    final assets = accounts
        .where((acc) => acc.type.isAsset)
        .fold(0.0, (sum, acc) => sum + acc.balance);

    final liabilities = accounts
        .where((acc) => acc.type.isLiability)
        .fold(0.0, (sum, acc) => sum + acc.balance.abs());

    return assets - liabilities;
  }
}
