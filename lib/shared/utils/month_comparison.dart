import '../../features/transactions/domain/models/transaction_model.dart';

/// Comparación entre dos meses
class MonthComparison {
  final String currentMonthName;
  final String previousMonthName;

  final double currentIncome;
  final double previousIncome;

  final double currentExpenses;
  final double previousExpenses;

  final int currentTransactionCount;
  final int previousTransactionCount;

  const MonthComparison({
    required this.currentMonthName,
    required this.previousMonthName,
    required this.currentIncome,
    required this.previousIncome,
    required this.currentExpenses,
    required this.previousExpenses,
    required this.currentTransactionCount,
    required this.previousTransactionCount,
  });

  /// Diferencia de ingresos (positivo = aumentó, negativo = disminuyó)
  double get incomeDifference => currentIncome - previousIncome;

  /// Porcentaje de cambio en ingresos
  double get incomeChangePercent {
    if (previousIncome == 0) return currentIncome > 0 ? 100 : 0;
    return ((currentIncome - previousIncome) / previousIncome) * 100;
  }

  /// Diferencia de gastos (positivo = aumentó, negativo = disminuyó)
  double get expensesDifference => currentExpenses - previousExpenses;

  /// Porcentaje de cambio en gastos
  double get expensesChangePercent {
    if (previousExpenses == 0) return currentExpenses > 0 ? 100 : 0;
    return ((currentExpenses - previousExpenses) / previousExpenses) * 100;
  }

  /// Balance neto del mes actual
  double get currentBalance => currentIncome - currentExpenses;

  /// Balance neto del mes anterior
  double get previousBalance => previousIncome - previousExpenses;

  /// Diferencia de balance
  double get balanceDifference => currentBalance - previousBalance;

  /// Porcentaje de cambio en balance
  double get balanceChangePercent {
    if (previousBalance == 0 && currentBalance == 0) return 0;
    if (previousBalance == 0) return 100;
    return ((currentBalance - previousBalance) / previousBalance.abs()) * 100;
  }

  /// Indica si los ingresos mejoraron
  bool get incomeImproved => incomeDifference > 0;

  /// Indica si los gastos disminuyeron (bueno)
  bool get expensesReduced => expensesDifference < 0;

  /// Indica si el balance mejoró
  bool get balanceImproved => balanceDifference > 0;

  /// Mensaje sobre ingresos
  String get incomeMessage {
    if (incomeDifference.abs() < 100) return 'Ingresos similares';
    if (incomeImproved) {
      return '↗️ +${incomeChangePercent.toStringAsFixed(0)}%';
    } else {
      return '↘️ ${incomeChangePercent.toStringAsFixed(0)}%';
    }
  }

  /// Mensaje sobre gastos
  String get expensesMessage {
    if (expensesDifference.abs() < 100) return 'Gastos similares';
    if (expensesReduced) {
      return '↘️ ${expensesChangePercent.toStringAsFixed(0)}%';
    } else {
      return '↗️ +${expensesChangePercent.toStringAsFixed(0)}%';
    }
  }

  /// Mensaje sobre balance
  String get balanceMessage {
    if (balanceDifference.abs() < 100) return 'Balance similar';
    if (balanceImproved) {
      return '↗️ Mejor';
    } else {
      return '↘️ Peor';
    }
  }

  /// Resumen general del mes
  String get summaryMessage {
    if (incomeImproved && expensesReduced) {
      return '¡Excelente! Ganaste más y gastaste menos';
    } else if (incomeImproved && !expensesReduced) {
      return 'Ganaste más, pero también gastaste más';
    } else if (!incomeImproved && expensesReduced) {
      return 'Ganaste menos, pero controlaste los gastos';
    } else if (balanceImproved) {
      return 'El balance general mejoró';
    } else {
      return 'Intenta mejorar para el próximo mes';
    }
  }

  /// Emoji según el rendimiento
  String get performanceEmoji {
    if (incomeImproved && expensesReduced) return '🎉';
    if (balanceImproved) return '👍';
    if (balanceDifference.abs() < 100) return '😐';
    return '⚠️';
  }

  /// Calcular comparación desde lista de transacciones
  static MonthComparison fromTransactions(List<TransactionModel> transactions) {
    final now = DateTime.now();
    final currentYear = now.year;
    final currentMonth = now.month;

    // Mes anterior
    final previousMonth = currentMonth == 1 ? 12 : currentMonth - 1;
    final previousYear = currentMonth == 1 ? currentYear - 1 : currentYear;

    // Nombres de meses
    final months = [
      'Enero', 'Febrero', 'Marzo', 'Abril', 'Mayo', 'Junio',
      'Julio', 'Agosto', 'Septiembre', 'Octubre', 'Noviembre', 'Diciembre'
    ];

    // Filtrar transacciones del mes actual
    final currentMonthTxs = transactions.where((t) {
      return t.date.year == currentYear && t.date.month == currentMonth;
    }).toList();

    // Filtrar transacciones del mes anterior
    final previousMonthTxs = transactions.where((t) {
      return t.date.year == previousYear && t.date.month == previousMonth;
    }).toList();

    // Calcular ingresos y gastos
    final currentIncome = currentMonthTxs
        .where((t) => t.type == TransactionType.income)
        .fold<double>(0, (sum, t) => sum + t.amount);

    final previousIncome = previousMonthTxs
        .where((t) => t.type == TransactionType.income)
        .fold<double>(0, (sum, t) => sum + t.amount);

    final currentExpenses = currentMonthTxs
        .where((t) => t.type == TransactionType.expense)
        .fold<double>(0, (sum, t) => sum + t.amount);

    final previousExpenses = previousMonthTxs
        .where((t) => t.type == TransactionType.expense)
        .fold<double>(0, (sum, t) => sum + t.amount);

    return MonthComparison(
      currentMonthName: months[currentMonth - 1],
      previousMonthName: months[previousMonth - 1],
      currentIncome: currentIncome,
      previousIncome: previousIncome,
      currentExpenses: currentExpenses,
      previousExpenses: previousExpenses,
      currentTransactionCount: currentMonthTxs.length,
      previousTransactionCount: previousMonthTxs.length,
    );
  }
}
