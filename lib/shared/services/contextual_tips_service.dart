import 'dart:math';

import '../../features/budgets/domain/models/budget_model.dart';
import '../../features/goals/domain/models/goal_model.dart';
import '../../features/transactions/domain/models/transaction_model.dart';
import '../utils/financial_health.dart';
import '../utils/ant_expense_analysis.dart';

/// Contexto para el que se genera el consejo
enum TipContext {
  welcome,
  highExpense,
  budgetNearLimit,
  budgetExceeded,
  goalNearCompletion,
  goodSavingsStreak,
  highDebt,
  lowFinancialHealth,
  antExpenses,
  goodFinancialHealth,
  general,
}

/// Consejo contextual de Fina
class FinaTip {
  final TipContext context;
  final String title;
  final String message;
  final String? actionText;
  final String? actionRoute;
  final String emoji;

  const FinaTip({
    required this.context,
    required this.title,
    required this.message,
    this.actionText,
    this.actionRoute,
    this.emoji = '💡',
  });
}

/// Servicio que genera consejos contextuales de Fina
class ContextualTipsService {
  static final Random _random = Random();

  /// Obtener consejo basado en el contexto financiero actual
  static FinaTip? getContextualTip({
    required List<TransactionModel> recentTransactions,
    required List<BudgetModel> budgets,
    required List<GoalModel> goals,
    FinancialHealth? financialHealth,
    AntExpenseAnalysis? antExpenseAnalysis,
    bool isFirstTime = false,
  }) {
    // 1. Bienvenida (primera vez)
    if (isFirstTime) {
      return _getWelcomeTip();
    }

    // 2. Verificar gastos hormiga
    if (antExpenseAnalysis != null &&
        antExpenseAnalysis.impact == AntExpenseImpact.high) {
      return _getAntExpenseTip(antExpenseAnalysis);
    }

    // 3. Verificar presupuestos excedidos
    final exceededBudgets = budgets.where((b) => b.isOverBudget).toList();
    if (exceededBudgets.isNotEmpty) {
      return _getBudgetExceededTip(exceededBudgets.first);
    }

    // 4. Verificar presupuestos cerca del límite
    final nearLimitBudgets = budgets.where((b) => b.isNearLimit && !b.isOverBudget).toList();
    if (nearLimitBudgets.isNotEmpty) {
      return _getBudgetNearLimitTip(nearLimitBudgets.first);
    }

    // 5. Verificar metas próximas a cumplirse
    final nearGoals = goals.where((g) => !g.isCompleted && g.percentComplete >= 80).toList();
    if (nearGoals.isNotEmpty) {
      return _getGoalNearCompletionTip(nearGoals.first);
    }

    // 6. Verificar salud financiera baja
    if (financialHealth != null &&
        financialHealth.healthLevel == HealthLevel.needsAttention) {
      return _getLowFinancialHealthTip(financialHealth);
    }

    // 7. Verificar salud financiera excelente
    if (financialHealth != null &&
        financialHealth.healthLevel == HealthLevel.excellent) {
      return _getGoodFinancialHealthTip();
    }

    // 8. Gasto alto reciente (últimos 3 días)
    final now = DateTime.now();
    final threeDaysAgo = now.subtract(const Duration(days: 3));
    final recentHighExpenses = recentTransactions
        .where((t) =>
            t.type == TransactionType.expense &&
            t.amount > 500000 &&
            t.date.isAfter(threeDaysAgo))
        .toList();
    if (recentHighExpenses.isNotEmpty) {
      return _getHighExpenseTip(recentHighExpenses.first);
    }

    // 9. Consejo general (motivacional o educativo)
    return _getGeneralTip();
  }

  static FinaTip _getWelcomeTip() {
    return const FinaTip(
      context: TipContext.welcome,
      emoji: '👋',
      title: '¡Hola! Soy Fina',
      message:
          'Tu asistente financiera. Estoy aquí para ayudarte a entender tu dinero y tomar mejores decisiones. ¡Empecemos registrando tus cuentas y transacciones!',
      actionText: 'Ver tutorial',
    );
  }

  static FinaTip _getAntExpenseTip(AntExpenseAnalysis analysis) {
    final topCategory = analysis.topCategories.isNotEmpty
        ? analysis.topCategories.first.name
        : 'gastos pequeños';

    return FinaTip(
      context: TipContext.antExpenses,
      emoji: '🐜',
      title: 'Detecté gastos hormiga',
      message:
          'Llevas \$${analysis.totalAmount.toStringAsFixed(0)} en $topCategory este mes. Son compras pequeñas que suman mucho. ¿Podrías reducirlas?',
      actionText: 'Ver análisis',
    );
  }

  static FinaTip _getBudgetExceededTip(BudgetModel budget) {
    final excess = budget.spent - budget.amount;
    return FinaTip(
      context: TipContext.budgetExceeded,
      emoji: '⚠️',
      title: 'Te pasaste del presupuesto',
      message:
          'Gastaste \$${excess.toStringAsFixed(0)} de más en ${budget.categoryName ?? "esta categoría"}. Intenta ajustar tus gastos el resto del mes.',
      actionText: 'Ver presupuestos',
      actionRoute: '/budgets',
    );
  }

  static FinaTip _getBudgetNearLimitTip(BudgetModel budget) {
    return FinaTip(
      context: TipContext.budgetNearLimit,
      emoji: '📊',
      title: 'Cerca del límite',
      message:
          'Vas en ${budget.percentSpent.toStringAsFixed(0)}% de tu presupuesto en ${budget.categoryName ?? "esta categoría"}. Ve con cuidado el resto del mes.',
      actionText: 'Ver detalles',
      actionRoute: '/budgets',
    );
  }

  static FinaTip _getGoalNearCompletionTip(GoalModel goal) {
    final remaining = goal.targetAmount - goal.currentAmount;
    return FinaTip(
      context: TipContext.goalNearCompletion,
      emoji: '🎯',
      title: '¡Casi llegas a tu meta!',
      message:
          'Solo te faltan \$${remaining.toStringAsFixed(0)} para ${goal.name}. ¡Un último esfuerzo!',
      actionText: 'Ver metas',
      actionRoute: '/goals',
    );
  }

  static FinaTip _getLowFinancialHealthTip(FinancialHealth health) {
    final mainIssue = health.recommendations.isNotEmpty
        ? health.recommendations.first
        : 'mejorar tu situación financiera';

    return FinaTip(
      context: TipContext.lowFinancialHealth,
      emoji: '🏥',
      title: 'Tu salud financiera necesita atención',
      message: mainIssue,
      actionText: 'Ver análisis',
      actionRoute: '/reports',
    );
  }

  static FinaTip _getGoodFinancialHealthTip() {
    return const FinaTip(
      context: TipContext.goodFinancialHealth,
      emoji: '🎉',
      title: '¡Excelente salud financiera!',
      message:
          'Tus finanzas están muy bien. Sigue así: ahorrando, controlando gastos y evitando deudas.',
      actionText: 'Ver detalles',
      actionRoute: '/reports',
    );
  }

  static FinaTip _getHighExpenseTip(TransactionModel transaction) {
    return FinaTip(
      context: TipContext.highExpense,
      emoji: '💸',
      title: 'Gasto grande detectado',
      message:
          'Gastaste \$${transaction.amount.toStringAsFixed(0)} en ${transaction.categoryName ?? "esta compra"}. ¿Era realmente necesario?',
    );
  }

  static FinaTip _getGeneralTip() {
    final tips = [
      const FinaTip(
        context: TipContext.general,
        emoji: '💰',
        title: 'Regla del 50/30/20',
        message:
            '50% para necesidades, 30% para gustos, 20% para ahorro. Esta fórmula simple te ayuda a balancear tu dinero.',
      ),
      const FinaTip(
        context: TipContext.general,
        emoji: '🏦',
        title: 'Fondo de emergencia',
        message:
            'Lo ideal es tener ahorrado el equivalente a 6 meses de tus gastos fijos. Así estarás preparado para imprevistos.',
      ),
      const FinaTip(
        context: TipContext.general,
        emoji: '📝',
        title: 'Registra cada gasto',
        message:
            'Aunque parezca pequeño, registra cada transacción. Los gastos hormiga (café, snacks) suman mucho al mes.',
      ),
      const FinaTip(
        context: TipContext.general,
        emoji: '🎯',
        title: 'Define metas claras',
        message:
            'Es más fácil ahorrar cuando tienes un objetivo claro: vacaciones, emergencias, educación. ¿Cuál es el tuyo?',
      ),
      const FinaTip(
        context: TipContext.general,
        emoji: '💳',
        title: 'Cuidado con las deudas',
        message:
            'Las tarjetas de crédito pueden ayudar, pero si no pagas el total cada mes, los intereses crecen rápido.',
      ),
      const FinaTip(
        context: TipContext.general,
        emoji: '📊',
        title: 'Revisa tus números semanalmente',
        message:
            'Dedicar 10 minutos cada semana a revisar tus finanzas te ayuda a detectar problemas temprano.',
      ),
    ];

    return tips[_random.nextInt(tips.length)];
  }
}
