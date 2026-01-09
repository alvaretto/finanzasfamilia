import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'budget_provider.dart';
import 'database_provider.dart';
import 'notification_provider.dart';

part 'budget_alert_provider.g.dart';

/// Provider que verifica presupuestos y dispara notificaciones
@riverpod
class BudgetAlertChecker extends _$BudgetAlertChecker {
  // Keys para tracking de alertas enviadas
  static const String _alertsSentPrefix = 'budget_alert_sent_';

  @override
  Future<void> build() async {
    // No hace nada al construirse, se llama checkAndNotify() manualmente
  }

  /// Verifica todos los presupuestos y envía notificaciones si es necesario
  Future<void> checkAndNotify() async {
    final progressList = await ref.read(allBudgetProgressProvider.future);
    final notificationService = ref.read(notificationServiceProvider);
    final categoriesDao = ref.read(categoriesDaoProvider);
    final prefs = await SharedPreferences.getInstance();

    for (final progress in progressList) {
      final categoryId = progress.budget.categoryId;
      final monthKey = '${DateTime.now().year}-${DateTime.now().month}';
      final warningKey = '${_alertsSentPrefix}warning_${categoryId}_$monthKey';
      final exceededKey =
          '${_alertsSentPrefix}exceeded_${categoryId}_$monthKey';

      // Obtener nombre de categoría
      final category = await categoriesDao.getCategoryById(categoryId);
      final categoryName = category?.name ?? 'Categoría';

      if (progress.status == BudgetStatus.exceeded) {
        // Solo enviar si no se ha enviado este mes
        if (!prefs.containsKey(exceededKey)) {
          await notificationService.showBudgetExceeded(
            categoryName: categoryName,
            percentUsed: progress.percentage,
            budgetAmount: progress.budget.amount,
            spentAmount: progress.spent,
          );
          await prefs.setBool(exceededKey, true);
        }
      } else if (progress.status == BudgetStatus.warning) {
        // Solo enviar warning si no se ha enviado este mes
        if (!prefs.containsKey(warningKey)) {
          await notificationService.showBudgetWarning(
            categoryName: categoryName,
            percentUsed: progress.percentage,
            budgetAmount: progress.budget.amount,
            spentAmount: progress.spent,
          );
          await prefs.setBool(warningKey, true);
        }
      }
    }
  }

  /// Limpia las alertas enviadas (para nuevo mes)
  Future<void> clearSentAlerts() async {
    final prefs = await SharedPreferences.getInstance();
    final keys = prefs.getKeys();

    for (final key in keys) {
      if (key.startsWith(_alertsSentPrefix)) {
        await prefs.remove(key);
      }
    }
  }
}
