import '../repositories/budget_repository.dart';
import 'budget_service.dart';

/// Datos de una alerta de presupuesto.
class BudgetAlertData {
  final String categoryId;
  final String categoryName;
  final BudgetAlertType type;
  final double percentage;
  final double budgetAmount;
  final double spentAmount;

  const BudgetAlertData({
    required this.categoryId,
    required this.categoryName,
    required this.type,
    required this.percentage,
    required this.budgetAmount,
    required this.spentAmount,
  });
}

/// Tipo de alerta de presupuesto.
enum BudgetAlertType {
  /// Advertencia: 80-99% del presupuesto
  warning,

  /// Excedido: >= 100% del presupuesto
  exceeded,
}

/// Interfaz para obtener nombres de categorías.
abstract class CategoryNameResolver {
  Future<String?> getCategoryName(String categoryId);
}

/// Interfaz para tracking de alertas enviadas.
abstract class AlertTracker {
  /// Verifica si ya se envió una alerta para esta categoría y tipo este mes.
  Future<bool> wasAlertSent(String categoryId, BudgetAlertType type);

  /// Marca una alerta como enviada para esta categoría y tipo este mes.
  Future<void> markAlertSent(String categoryId, BudgetAlertType type);

  /// Limpia todas las alertas enviadas (para nuevo mes).
  Future<void> clearAllSentAlerts();
}

/// Servicio de dominio para alertas de presupuesto.
///
/// Contiene la lógica de negocio para:
/// - Determinar qué presupuestos necesitan alertas
/// - Verificar si ya se enviaron alertas
/// - Generar datos de alerta
class BudgetAlertService {
  final BudgetService _budgetService;
  final CategoryNameResolver _categoryResolver;
  final AlertTracker _alertTracker;

  BudgetAlertService({
    required BudgetService budgetService,
    required CategoryNameResolver categoryResolver,
    required AlertTracker alertTracker,
  })  : _budgetService = budgetService,
        _categoryResolver = categoryResolver,
        _alertTracker = alertTracker;

  /// Obtiene las alertas pendientes de enviar (no enviadas este mes).
  Future<List<BudgetAlertData>> getPendingAlerts() async {
    final progressList = await _budgetService.getAllBudgetProgress();
    final pendingAlerts = <BudgetAlertData>[];

    for (final progress in progressList) {
      final alertType = _getAlertType(progress.status);
      if (alertType == null) continue;

      // Verificar si ya se envió
      final alreadySent = await _alertTracker.wasAlertSent(
        progress.budget.categoryId,
        alertType,
      );
      if (alreadySent) continue;

      // Obtener nombre de categoría
      final categoryName = await _categoryResolver.getCategoryName(
            progress.budget.categoryId,
          ) ??
          'Categoría';

      pendingAlerts.add(BudgetAlertData(
        categoryId: progress.budget.categoryId,
        categoryName: categoryName,
        type: alertType,
        percentage: progress.percentage,
        budgetAmount: progress.budget.amount,
        spentAmount: progress.spent,
      ));
    }

    return pendingAlerts;
  }

  /// Marca una alerta como enviada.
  Future<void> markAlertSent(String categoryId, BudgetAlertType type) {
    return _alertTracker.markAlertSent(categoryId, type);
  }

  /// Limpia todas las alertas enviadas (para nuevo mes).
  Future<void> clearSentAlerts() {
    return _alertTracker.clearAllSentAlerts();
  }

  BudgetAlertType? _getAlertType(BudgetStatus status) {
    switch (status) {
      case BudgetStatus.exceeded:
        return BudgetAlertType.exceeded;
      case BudgetStatus.warning:
        return BudgetAlertType.warning;
      case BudgetStatus.safe:
        return null;
    }
  }
}
