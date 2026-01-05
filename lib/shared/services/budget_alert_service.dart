import '../../core/services/notification_service.dart';
import '../../features/accounts/domain/models/account_model.dart';
import '../../features/budgets/domain/models/budget_model.dart';
import '../../features/transactions/domain/models/transaction_model.dart';

/// Tipos de alerta
enum AlertType {
  budgetExceeded,
  budgetWarning,
  largeExpense,
  lowBalance,
}

/// Modelo de alerta
class BudgetAlert {
  final AlertType type;
  final String title;
  final String message;
  final String? categoryName;
  final double? amount;

  const BudgetAlert({
    required this.type,
    required this.title,
    required this.message,
    this.categoryName,
    this.amount,
  });

  /// Emoji según el tipo de alerta
  String get emoji {
    switch (type) {
      case AlertType.budgetExceeded:
        return '⚠️';
      case AlertType.budgetWarning:
        return '📊';
      case AlertType.largeExpense:
        return '💸';
      case AlertType.lowBalance:
        return '🔔';
    }
  }

  /// Mensaje completo con emoji
  String get fullMessage => '$emoji $message';
}

/// Servicio para detectar y notificar alertas de presupuesto
class BudgetAlertService {
  static final NotificationService _notificationService = NotificationService.instance;

  /// Monto mínimo para alerta de saldo bajo (COP)
  static const double _lowBalanceThreshold = 100000;

  /// Monto mínimo para alerta de gasto grande (COP)
  static const double _largeExpenseThreshold = 500000;

  /// Verificar alertas después de crear una transacción
  static Future<List<BudgetAlert>> checkAlertsAfterTransaction({
    required TransactionModel transaction,
    required List<BudgetModel> budgets,
    required AccountModel account,
    bool sendNotifications = true,
  }) async {
    final alerts = <BudgetAlert>[];

    // 1. Verificar alerta de presupuesto (solo para gastos)
    if (transaction.type == TransactionType.expense && transaction.categoryId != null) {
      final budgetAlert = _checkBudgetAlert(
        transaction: transaction,
        budgets: budgets,
      );
      if (budgetAlert != null) {
        alerts.add(budgetAlert);
        if (sendNotifications) {
          await _sendBudgetNotification(budgetAlert, budgets);
        }
      }
    }

    // 2. Verificar alerta de gasto grande
    if (transaction.type == TransactionType.expense) {
      final largeExpenseAlert = _checkLargeExpense(transaction);
      if (largeExpenseAlert != null) {
        alerts.add(largeExpenseAlert);
        if (sendNotifications) {
          await _sendLargeExpenseNotification(largeExpenseAlert);
        }
      }
    }

    // 3. Verificar alerta de saldo bajo
    final lowBalanceAlert = _checkLowBalance(account);
    if (lowBalanceAlert != null) {
      alerts.add(lowBalanceAlert);
      if (sendNotifications) {
        await _sendLowBalanceNotification(lowBalanceAlert, account);
      }
    }

    return alerts;
  }

  /// Verificar si se excedió o está cerca del presupuesto
  static BudgetAlert? _checkBudgetAlert({
    required TransactionModel transaction,
    required List<BudgetModel> budgets,
  }) {
    if (transaction.categoryId == null) return null;

    // Buscar presupuesto activo para esta categoría
    final budget = budgets.firstWhere(
      (b) => b.categoryId == transaction.categoryId,
      orElse: () => BudgetModel(
        id: '',
        userId: '',
        categoryId: 0,
        amount: 0,
        period: BudgetPeriod.monthly,
        startDate: DateTime.now(),
      ),
    );

    if (budget.id.isEmpty || budget.amount == 0) return null;

    // Verificar si se excedió el presupuesto
    if (budget.isOverBudget) {
      final excess = budget.spent - budget.amount;
      return BudgetAlert(
        type: AlertType.budgetExceeded,
        title: 'Presupuesto Excedido',
        message:
            'Te pasaste por \$${excess.toStringAsFixed(0)} en ${budget.categoryName ?? "esta categoría"}',
        categoryName: budget.categoryName,
        amount: excess,
      );
    }

    // Verificar si está cerca del límite (>= 80%)
    if (budget.isNearLimit) {
      return BudgetAlert(
        type: AlertType.budgetWarning,
        title: 'Alerta de Presupuesto',
        message:
            'Vas en ${budget.percentSpent.toStringAsFixed(0)}% del presupuesto en ${budget.categoryName ?? "esta categoría"}',
        categoryName: budget.categoryName,
        amount: budget.spent,
      );
    }

    return null;
  }

  /// Verificar si es un gasto grande
  static BudgetAlert? _checkLargeExpense(TransactionModel transaction) {
    if (transaction.amount < _largeExpenseThreshold) return null;

    return BudgetAlert(
      type: AlertType.largeExpense,
      title: 'Gasto Grande Detectado',
      message:
          'Gastaste \$${transaction.amount.toStringAsFixed(0)} en ${transaction.categoryName ?? "esta transacción"}',
      categoryName: transaction.categoryName,
      amount: transaction.amount,
    );
  }

  /// Verificar si el saldo de la cuenta está bajo
  static BudgetAlert? _checkLowBalance(AccountModel account) {
    // Solo alertar para cuentas bancarias y de ahorro
    if (account.type != AccountType.bank && account.type != AccountType.savings) {
      return null;
    }

    if (account.balance < _lowBalanceThreshold && account.balance >= 0) {
      return BudgetAlert(
        type: AlertType.lowBalance,
        title: 'Saldo Bajo',
        message: '${account.name}: \$${account.balance.toStringAsFixed(0)}',
        amount: account.balance,
      );
    }

    return null;
  }

  // ============ Métodos de notificación ============

  static Future<void> _sendBudgetNotification(
    BudgetAlert alert,
    List<BudgetModel> budgets,
  ) async {
    if (alert.categoryName == null) return;

    final budget = budgets.firstWhere(
      (b) => b.categoryName == alert.categoryName,
      orElse: () => BudgetModel(
        id: '',
        userId: '',
        categoryId: 0,
        amount: 0,
        period: BudgetPeriod.monthly,
        startDate: DateTime.now(),
      ),
    );

    if (budget.id.isEmpty) return;

    if (alert.type == AlertType.budgetExceeded) {
      await _notificationService.notifyBudgetExceeded(
        categoryName: alert.categoryName!,
        spent: budget.spent,
        limit: budget.amount,
      );
    } else if (alert.type == AlertType.budgetWarning) {
      await _notificationService.notifyBudgetWarning(
        categoryName: alert.categoryName!,
        spent: budget.spent,
        limit: budget.amount,
      );
    }
  }

  static Future<void> _sendLargeExpenseNotification(BudgetAlert alert) async {
    if (alert.amount == null) return;

    await _notificationService.showNotification(
      id: DateTime.now().millisecondsSinceEpoch,
      title: alert.title,
      body: alert.message,
      payload: 'large_expense',
    );
  }

  static Future<void> _sendLowBalanceNotification(
    BudgetAlert alert,
    AccountModel account,
  ) async {
    await _notificationService.showNotification(
      id: account.id.hashCode,
      title: alert.title,
      body: alert.message,
      payload: 'low_balance:${account.id}',
    );
  }
}
