import 'package:shared_preferences/shared_preferences.dart';

import '../../domain/services/budget_alert_service.dart';
import '../local/daos/categories_dao.dart';

/// Adaptador que usa CategoriesDao para resolver nombres de categorías.
class DriftCategoryNameResolver implements CategoryNameResolver {
  final CategoriesDao _dao;

  DriftCategoryNameResolver(this._dao);

  @override
  Future<String?> getCategoryName(String categoryId) async {
    final category = await _dao.getCategoryById(categoryId);
    return category?.name;
  }
}

/// Adaptador que usa SharedPreferences para tracking de alertas.
class SharedPrefsAlertTracker implements AlertTracker {
  static const String _alertsSentPrefix = 'budget_alert_sent_';

  @override
  Future<bool> wasAlertSent(String categoryId, BudgetAlertType type) async {
    final prefs = await SharedPreferences.getInstance();
    final key = _buildKey(categoryId, type);
    return prefs.containsKey(key);
  }

  @override
  Future<void> markAlertSent(String categoryId, BudgetAlertType type) async {
    final prefs = await SharedPreferences.getInstance();
    final key = _buildKey(categoryId, type);
    await prefs.setBool(key, true);
  }

  @override
  Future<void> clearAllSentAlerts() async {
    final prefs = await SharedPreferences.getInstance();
    final keys = prefs.getKeys();

    for (final key in keys) {
      if (key.startsWith(_alertsSentPrefix)) {
        await prefs.remove(key);
      }
    }
  }

  String _buildKey(String categoryId, BudgetAlertType type) {
    final now = DateTime.now();
    final monthKey = '${now.year}-${now.month}';
    final typeStr = type == BudgetAlertType.exceeded ? 'exceeded' : 'warning';
    return '$_alertsSentPrefix${typeStr}_${categoryId}_$monthKey';
  }
}
