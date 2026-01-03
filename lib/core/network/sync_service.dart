import 'dart:async';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Estado de sincronizacion
enum SyncStatus {
  idle,
  syncing,
  success,
  error,
  offline,
}

/// Servicio de sincronizacion offline-first
class SyncService {
  final Connectivity _connectivity = Connectivity();
  Timer? _syncTimer;
  bool _isOnline = true;

  /// Stream de estado de conectividad
  Stream<bool> get connectivityStream => _connectivity.onConnectivityChanged.map(
        (results) => !results.contains(ConnectivityResult.none),
      );

  /// Verifica si hay conexion
  Future<bool> checkConnectivity() async {
    final result = await _connectivity.checkConnectivity();
    _isOnline = !result.contains(ConnectivityResult.none);
    return _isOnline;
  }

  /// Inicia sincronizacion periodica
  void startPeriodicSync({Duration interval = const Duration(minutes: 5)}) {
    _syncTimer?.cancel();
    _syncTimer = Timer.periodic(interval, (_) => syncAll());
  }

  /// Detiene sincronizacion periodica
  void stopPeriodicSync() {
    _syncTimer?.cancel();
    _syncTimer = null;
  }

  /// Sincroniza todos los datos pendientes
  Future<SyncStatus> syncAll() async {
    if (!await checkConnectivity()) {
      return SyncStatus.offline;
    }

    try {
      // TODO: Implementar sincronizacion de cada tabla
      // 1. Obtener registros no sincronizados (synced = false)
      // 2. Enviar a Supabase
      // 3. Marcar como sincronizados
      // 4. Descargar cambios remotos

      return SyncStatus.success;
    } catch (e) {
      return SyncStatus.error;
    }
  }

  /// Sincroniza una tabla especifica
  Future<SyncStatus> syncTable(String tableName) async {
    if (!await checkConnectivity()) {
      return SyncStatus.offline;
    }

    try {
      // TODO: Implementar sincronizacion de tabla especifica
      return SyncStatus.success;
    } catch (e) {
      return SyncStatus.error;
    }
  }

  void dispose() {
    _syncTimer?.cancel();
  }
}

/// Provider del servicio de sincronizacion
final syncServiceProvider = Provider<SyncService>((ref) {
  final service = SyncService();
  ref.onDispose(() => service.dispose());
  return service;
});

/// Provider del estado de conectividad
final connectivityProvider = StreamProvider<bool>((ref) {
  final service = ref.watch(syncServiceProvider);
  return service.connectivityStream;
});
