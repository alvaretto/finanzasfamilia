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

/// Estado completo de sincronización
class SyncState {
  final SyncStatus status;
  final DateTime? lastSyncTime;
  final String? errorMessage;

  const SyncState({
    this.status = SyncStatus.idle,
    this.lastSyncTime,
    this.errorMessage,
  });

  SyncState copyWith({
    SyncStatus? status,
    DateTime? lastSyncTime,
    String? errorMessage,
  }) {
    return SyncState(
      status: status ?? this.status,
      lastSyncTime: lastSyncTime ?? this.lastSyncTime,
      errorMessage: errorMessage,
    );
  }

  /// Formatea el tiempo desde la última sincronización
  String get lastSyncFormatted {
    if (lastSyncTime == null) return 'Nunca';

    final now = DateTime.now();
    final diff = now.difference(lastSyncTime!);

    if (diff.inSeconds < 60) return 'Hace un momento';
    if (diff.inMinutes < 60) {
      return 'Hace ${diff.inMinutes} ${diff.inMinutes == 1 ? 'minuto' : 'minutos'}';
    }
    if (diff.inHours < 24) {
      return 'Hace ${diff.inHours} ${diff.inHours == 1 ? 'hora' : 'horas'}';
    }
    return 'Hace ${diff.inDays} ${diff.inDays == 1 ? 'día' : 'días'}';
  }
}

/// Servicio de sincronizacion offline-first
class SyncService extends StateNotifier<SyncState> {
  final Connectivity _connectivity = Connectivity();
  Timer? _syncTimer;
  bool _isOnline = true;

  SyncService() : super(const SyncState());

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
    state = state.copyWith(status: SyncStatus.syncing);

    if (!await checkConnectivity()) {
      state = state.copyWith(status: SyncStatus.offline);
      return SyncStatus.offline;
    }

    try {
      // TODO: Implementar sincronizacion de cada tabla
      // 1. Obtener registros no sincronizados (synced = false)
      // 2. Enviar a Supabase
      // 3. Marcar como sincronizados
      // 4. Descargar cambios remotos

      state = state.copyWith(
        status: SyncStatus.success,
        lastSyncTime: DateTime.now(),
      );
      return SyncStatus.success;
    } catch (e) {
      state = state.copyWith(
        status: SyncStatus.error,
        errorMessage: e.toString(),
      );
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
      state = state.copyWith(
        status: SyncStatus.success,
        lastSyncTime: DateTime.now(),
      );
      return SyncStatus.success;
    } catch (e) {
      return SyncStatus.error;
    }
  }

  @override
  void dispose() {
    _syncTimer?.cancel();
    super.dispose();
  }
}

/// Provider del servicio de sincronizacion
final syncServiceProvider = StateNotifierProvider<SyncService, SyncState>((ref) {
  return SyncService();
});

/// Provider del estado de conectividad
final connectivityProvider = StreamProvider<bool>((ref) {
  final service = ref.read(syncServiceProvider.notifier);
  return service.connectivityStream;
});
