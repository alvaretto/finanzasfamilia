import 'dart:async';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'connectivity_provider.g.dart';

/// Estado de conectividad de la aplicación
enum ConnectivityStatus {
  /// Conectado a internet (WiFi o móvil)
  online,

  /// Sin conexión a internet
  offline,

  /// Verificando estado de conexión
  checking,
}

/// Provider que monitorea el estado de conectividad de red
///
/// Usa `connectivity_plus` para detectar cambios en tiempo real.
/// Cuando detecta reconexión, puede disparar sincronización automática.
@Riverpod(keepAlive: true)
class ConnectivityNotifier extends _$ConnectivityNotifier {
  StreamSubscription<List<ConnectivityResult>>? _subscription;

  @override
  ConnectivityStatus build() {
    // Iniciar monitoreo de conectividad
    _startMonitoring();

    // Verificar estado inicial
    _checkInitialConnectivity();

    // Limpiar cuando el provider se destruya
    ref.onDispose(_stopMonitoring);

    return ConnectivityStatus.checking;
  }

  /// Inicia el monitoreo de cambios de conectividad
  void _startMonitoring() {
    _subscription = Connectivity().onConnectivityChanged.listen(
      _handleConnectivityChange,
    );
  }

  /// Detiene el monitoreo
  void _stopMonitoring() {
    _subscription?.cancel();
    _subscription = null;
  }

  /// Verifica el estado inicial de conectividad
  Future<void> _checkInitialConnectivity() async {
    try {
      final result = await Connectivity().checkConnectivity();
      _handleConnectivityChange(result);
    } catch (_) {
      state = ConnectivityStatus.offline;
    }
  }

  /// Maneja cambios en la conectividad
  void _handleConnectivityChange(List<ConnectivityResult> results) {
    final hasConnection = results.any(
      (r) => r != ConnectivityResult.none,
    );

    final newStatus =
        hasConnection ? ConnectivityStatus.online : ConnectivityStatus.offline;

    // Si pasamos de offline a online, notificar para sync
    if (state == ConnectivityStatus.offline &&
        newStatus == ConnectivityStatus.online) {
      _onReconnected();
    }

    state = newStatus;
  }

  /// Callback cuando se reconecta a internet
  void _onReconnected() {
    // Aquí se puede disparar sincronización automática
    // Por ahora solo actualizamos el estado
    // En una fase posterior, integrar con PowerSync:
    // ref.read(powerSyncProvider).triggerSync();
  }

  /// Fuerza una verificación de conectividad
  Future<void> checkNow() async {
    state = ConnectivityStatus.checking;
    await _checkInitialConnectivity();
  }
}

// ============================================================
// Providers Derivados
// ============================================================

/// Provider que indica si hay conexión a internet
@riverpod
bool isOnline(Ref ref) {
  final status = ref.watch(connectivityNotifierProvider);
  return status == ConnectivityStatus.online;
}

/// Provider que indica si está verificando conectividad
@riverpod
bool isCheckingConnectivity(Ref ref) {
  final status = ref.watch(connectivityNotifierProvider);
  return status == ConnectivityStatus.checking;
}
