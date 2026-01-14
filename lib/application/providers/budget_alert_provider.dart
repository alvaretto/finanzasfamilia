import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../data/adapters/budget_alert_adapters.dart';
import '../../domain/services/budget_alert_service.dart';
import 'budget_provider.dart';
import 'database_provider.dart';
import 'notification_provider.dart';

// Re-exportar tipos del dominio para acceso desde presentation layer
export '../../domain/services/budget_alert_service.dart'
    show BudgetAlertData, BudgetAlertType;

part 'budget_alert_provider.g.dart';

// ============================================================
// PROVIDERS DE INFRAESTRUCTURA
// ============================================================

/// Provider del resolver de nombres de categorías
@riverpod
CategoryNameResolver categoryNameResolver(Ref ref) {
  final dao = ref.watch(categoriesDaoProvider);
  return DriftCategoryNameResolver(dao);
}

/// Provider del tracker de alertas
@riverpod
AlertTracker alertTracker(Ref ref) {
  return SharedPrefsAlertTracker();
}

/// Provider del servicio de alertas de presupuesto
@riverpod
BudgetAlertService budgetAlertService(Ref ref) {
  return BudgetAlertService(
    budgetService: ref.watch(budgetServiceProvider),
    categoryResolver: ref.watch(categoryNameResolverProvider),
    alertTracker: ref.watch(alertTrackerProvider),
  );
}

// ============================================================
// NOTIFIER PRINCIPAL
// ============================================================

/// Notifier que verifica presupuestos y dispara notificaciones
@riverpod
class BudgetAlertChecker extends _$BudgetAlertChecker {
  @override
  Future<void> build() async {
    // No hace nada al construirse, se llama checkAndNotify() manualmente
  }

  BudgetAlertService get _service => ref.read(budgetAlertServiceProvider);

  /// Verifica todos los presupuestos y envía notificaciones si es necesario
  Future<void> checkAndNotify() async {
    final pendingAlerts = await _service.getPendingAlerts();
    final notificationService = ref.read(notificationServiceProvider);

    for (final alert in pendingAlerts) {
      if (alert.type == BudgetAlertType.exceeded) {
        await notificationService.showBudgetExceeded(
          categoryName: alert.categoryName,
          percentUsed: alert.percentage,
          budgetAmount: alert.budgetAmount,
          spentAmount: alert.spentAmount,
        );
      } else {
        await notificationService.showBudgetWarning(
          categoryName: alert.categoryName,
          percentUsed: alert.percentage,
          budgetAmount: alert.budgetAmount,
          spentAmount: alert.spentAmount,
        );
      }

      // Marcar como enviada
      await _service.markAlertSent(alert.categoryId, alert.type);
    }
  }

  /// Limpia las alertas enviadas (para nuevo mes)
  Future<void> clearSentAlerts() async {
    await _service.clearSentAlerts();
  }
}
