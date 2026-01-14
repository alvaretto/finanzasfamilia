import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../services/in_app_update_service.dart';

/// Provider para el servicio de actualizaciones in-app
final inAppUpdateServiceProvider = Provider<InAppUpdateService>((ref) {
  return InAppUpdateService();
});

/// Provider que verifica si hay una actualización disponible
final updateAvailableProvider = FutureProvider<bool>((ref) async {
  final service = ref.watch(inAppUpdateServiceProvider);
  return service.checkForUpdate();
});

/// Estado de la actualización flexible
enum FlexibleUpdateStatus {
  idle,
  downloading,
  downloaded,
  failed,
}

/// Notifier para manejar el estado de actualizaciones flexibles
class FlexibleUpdateNotifier extends Notifier<FlexibleUpdateStatus> {
  @override
  FlexibleUpdateStatus build() => FlexibleUpdateStatus.idle;

  Future<void> startUpdate() async {
    state = FlexibleUpdateStatus.downloading;

    try {
      final service = ref.read(inAppUpdateServiceProvider);
      await service.startFlexibleUpdate();
      state = FlexibleUpdateStatus.downloaded;
    } catch (e) {
      state = FlexibleUpdateStatus.failed;
    }
  }

  Future<void> completeUpdate() async {
    final service = ref.read(inAppUpdateServiceProvider);
    await service.completeFlexibleUpdate();
  }

  void reset() {
    state = FlexibleUpdateStatus.idle;
  }
}

/// Provider del notifier de actualizaciones flexibles
final flexibleUpdateNotifierProvider =
    NotifierProvider<FlexibleUpdateNotifier, FlexibleUpdateStatus>(
  FlexibleUpdateNotifier.new,
);
