import '../../features/transactions/domain/models/transaction_model.dart';
import '../utils/ant_expense_analysis.dart';

/// Servicio para detectar y analizar gastos hormiga
///
/// Los gastos hormiga son compras pequeñas y frecuentes que individualmente
/// parecen insignificantes pero que sumadas pueden representar mucho dinero.
class AntExpenseService {
  /// Umbral para considerar un gasto como "hormiga" (COP)
  static const double antExpenseThreshold = 20000;

  /// Analizar gastos hormiga en una lista de transacciones
  static AntExpenseAnalysis analyzeAntExpenses(
    List<TransactionModel> transactions,
  ) {
    // Filtrar solo gastos pequeños
    final antExpenses = transactions.where((t) {
      return t.type == TransactionType.expense &&
          t.amount > 0 &&
          t.amount < antExpenseThreshold;
    }).toList();

    if (antExpenses.isEmpty) {
      return const AntExpenseAnalysis(
        categories: {},
        totalAmount: 0,
        totalTransactions: 0,
      );
    }

    // Agrupar por categoría
    final Map<String, List<TransactionModel>> grouped = {};
    for (final tx in antExpenses) {
      final categoryName = tx.categoryName ?? 'Sin categoría';
      grouped.putIfAbsent(categoryName, () => []);
      grouped[categoryName]!.add(tx);
    }

    // Calcular totales por categoría
    final Map<String, AntExpenseCategory> categories = {};
    for (final entry in grouped.entries) {
      final categoryName = entry.key;
      final txList = entry.value;

      final total = txList.fold<double>(0, (sum, tx) => sum + tx.amount);
      final frequency = txList.length;
      final average = total / frequency;

      categories[categoryName] = AntExpenseCategory(
        name: categoryName,
        total: total,
        frequency: frequency,
        average: average,
      );
    }

    // Total general
    final totalAmount = antExpenses.fold<double>(0, (sum, tx) => sum + tx.amount);
    final totalTransactions = antExpenses.length;

    return AntExpenseAnalysis(
      categories: categories,
      totalAmount: totalAmount,
      totalTransactions: totalTransactions,
    );
  }

  /// Analizar gastos hormiga del mes actual
  static AntExpenseAnalysis analyzeCurrentMonth(
    List<TransactionModel> allTransactions,
  ) {
    final now = DateTime.now();
    final startOfMonth = DateTime(now.year, now.month, 1);
    final endOfMonth = DateTime(now.year, now.month + 1, 0, 23, 59, 59);

    final monthTransactions = allTransactions.where((t) {
      return t.date.isAfter(startOfMonth.subtract(const Duration(seconds: 1))) &&
          t.date.isBefore(endOfMonth.add(const Duration(seconds: 1)));
    }).toList();

    return analyzeAntExpenses(monthTransactions);
  }

  /// Verificar si hay gastos hormiga significativos
  static bool hasSignificantAntExpenses(
    List<TransactionModel> transactions,
  ) {
    final analysis = analyzeAntExpenses(transactions);
    return analysis.impact != AntExpenseImpact.none;
  }

  /// Obtener mensaje de impacto corto
  static String getImpactMessage(AntExpenseAnalysis analysis) {
    if (analysis.impact == AntExpenseImpact.none) {
      return '✅ Sin gastos hormiga significativos';
    }

    return '${analysis.impactMessage}\n\$${analysis.totalAmount.toStringAsFixed(0)} en pequeñas compras';
  }
}
