// Provider para integrar el widget de home screen con el estado de la app.

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../services/home_widget_service.dart';
import '../services/quick_actions_service.dart';
import 'accounting_provider.dart';

part 'home_widget_provider.g.dart';

/// Provider para el servicio de home widget.
@riverpod
HomeWidgetService homeWidgetService(Ref ref) {
  return HomeWidgetService();
}

/// Provider para el servicio de quick actions.
@riverpod
QuickActionsService quickActionsService(Ref ref) {
  return QuickActionsService();
}

/// Notifier para sincronizar el widget con el saldo actual.
@riverpod
class HomeWidgetSync extends _$HomeWidgetSync {
  @override
  Future<bool> build() async {
    // Escuchar cambios en el saldo total y actualizar widget
    final totalBalance = await ref.watch(totalBalanceProvider.future);
    return _updateWidget(totalBalance.netWorth);
  }

  Future<bool> _updateWidget(double balance) async {
    final service = ref.read(homeWidgetServiceProvider);
    return service.updateBalance(balance);
  }

  /// Fuerza una actualización del widget.
  Future<void> refresh() async {
    final totalBalance = await ref.read(totalBalanceProvider.future);
    await _updateWidget(totalBalance.netWorth);
    ref.invalidateSelf();
  }

  /// Limpia el widget (logout).
  Future<void> clear() async {
    final service = ref.read(homeWidgetServiceProvider);
    await service.clearWidget();
  }
}
