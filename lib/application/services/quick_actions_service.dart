// Servicio para Quick Actions (shortcuts al mantener presionado el ícono).
// Permite acceso rápido a funciones desde el launcher.

import 'package:quick_actions/quick_actions.dart';

/// Tipos de acciones rápidas disponibles.
enum QuickActionType {
  newExpense('new_expense'),
  newIncome('new_income'),
  viewBalance('view_balance');

  final String value;
  const QuickActionType(this.value);

  static QuickActionType? fromString(String value) {
    return QuickActionType.values.cast<QuickActionType?>().firstWhere(
          (e) => e?.value == value,
          orElse: () => null,
        );
  }
}

/// Callback para cuando el usuario selecciona una acción rápida.
typedef QuickActionCallback = void Function(QuickActionType action);

/// Servicio para gestionar Quick Actions (shortcuts de app).
///
/// Configura los shortcuts que aparecen al mantener presionado
/// el ícono de la app en el launcher.
class QuickActionsService {
  final QuickActions _quickActions = const QuickActions();
  QuickActionCallback? _callback;

  /// Inicializa el servicio y configura los shortcuts.
  ///
  /// [onAction] - Callback cuando el usuario selecciona una acción.
  Future<void> initialize({QuickActionCallback? onAction}) async {
    _callback = onAction;

    // Configurar listener para acciones
    _quickActions.initialize((String shortcutType) {
      final actionType = QuickActionType.fromString(shortcutType);
      if (actionType != null && _callback != null) {
        _callback!(actionType);
      }
    });

    // Definir shortcuts disponibles
    await _quickActions.setShortcutItems([
      const ShortcutItem(
        type: 'new_expense',
        localizedTitle: 'Nuevo Gasto',
        icon: 'ic_expense',
      ),
      const ShortcutItem(
        type: 'new_income',
        localizedTitle: 'Nuevo Ingreso',
        icon: 'ic_income',
      ),
      const ShortcutItem(
        type: 'view_balance',
        localizedTitle: 'Ver Saldo',
        icon: 'ic_balance',
      ),
    ]);
  }

  /// Limpia todos los shortcuts.
  Future<void> clearShortcuts() async {
    await _quickActions.clearShortcutItems();
  }

  /// Actualiza el callback de acciones.
  void setCallback(QuickActionCallback callback) {
    _callback = callback;
  }
}
