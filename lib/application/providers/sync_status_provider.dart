import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'sync_status_provider.g.dart';

/// Estado de sincronización de PowerSync
///
/// Representa el estado actual de la sincronización incluyendo:
/// - Estado de conexión
/// - Actividad de descarga/subida
/// - Última sincronización exitosa
/// - Errores recientes
/// - Operaciones pendientes de upload
class SyncState {
  final bool isConnected;
  final bool isDownloading;
  final bool isUploading;
  final DateTime? lastSyncTime;
  final List<String> errors;
  final int pendingUploads;

  const SyncState({
    this.isConnected = false,
    this.isDownloading = false,
    this.isUploading = false,
    this.lastSyncTime,
    this.errors = const [],
    this.pendingUploads = 0,
  });

  /// Indica si hay sincronización activa (descarga o subida)
  bool get isSyncing => isDownloading || isUploading;

  /// Indica si hay operaciones pendientes de subir
  bool get hasPendingUploads => pendingUploads > 0;

  /// Crea una copia con valores actualizados
  SyncState copyWith({
    bool? isConnected,
    bool? isDownloading,
    bool? isUploading,
    DateTime? lastSyncTime,
    List<String>? errors,
    int? pendingUploads,
  }) {
    return SyncState(
      isConnected: isConnected ?? this.isConnected,
      isDownloading: isDownloading ?? this.isDownloading,
      isUploading: isUploading ?? this.isUploading,
      lastSyncTime: lastSyncTime ?? this.lastSyncTime,
      errors: errors ?? this.errors,
      pendingUploads: pendingUploads ?? this.pendingUploads,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other is! SyncState) return false;
    return isConnected == other.isConnected &&
        isDownloading == other.isDownloading &&
        isUploading == other.isUploading &&
        lastSyncTime == other.lastSyncTime &&
        pendingUploads == other.pendingUploads &&
        _listEquals(errors, other.errors);
  }

  @override
  int get hashCode => Object.hash(
        isConnected,
        isDownloading,
        isUploading,
        lastSyncTime,
        pendingUploads,
        Object.hashAll(errors),
      );

  static bool _listEquals<T>(List<T> a, List<T> b) {
    if (a.length != b.length) return false;
    for (var i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }
}

/// Provider del estado de sincronización
///
/// Mantiene el estado de sincronización de PowerSync y proporciona
/// métodos para actualizarlo desde los listeners de PowerSync.
@Riverpod(keepAlive: true)
class SyncStatus extends _$SyncStatus {
  @override
  SyncState build() => const SyncState();

  /// Actualiza el estado de sincronización
  void updateStatus({
    bool? isConnected,
    bool? isDownloading,
    bool? isUploading,
  }) {
    state = state.copyWith(
      isConnected: isConnected,
      isDownloading: isDownloading,
      isUploading: isUploading,
    );
  }

  /// Marca la última sincronización exitosa
  void markSynced() {
    state = state.copyWith(lastSyncTime: DateTime.now());
  }

  /// Agrega un error a la lista
  void addError(String error) {
    state = state.copyWith(errors: [...state.errors, error]);
  }

  /// Limpia todos los errores
  void clearErrors() {
    state = state.copyWith(errors: []);
  }

  /// Establece modo offline (desconectado)
  void setOfflineMode() {
    state = state.copyWith(
      isConnected: false,
      isDownloading: false,
      isUploading: false,
    );
  }

  /// Actualiza desde el SyncStatus de PowerSync
  void updateFromPowerSync({
    required bool connected,
    required bool downloading,
    required bool uploading,
    List<String>? lastErrors,
  }) {
    state = state.copyWith(
      isConnected: connected,
      isDownloading: downloading,
      isUploading: uploading,
      errors: lastErrors ?? state.errors,
    );
  }

  /// Actualiza el contador de operaciones pendientes de upload
  void setPendingUploads(int count) {
    state = state.copyWith(pendingUploads: count);
  }
}

// ============================================================
// Providers Derivados (Selectores)
// ============================================================

/// Provider que indica si está conectado
@riverpod
bool isConnected(Ref ref) {
  return ref.watch(syncStatusProvider.select((s) => s.isConnected));
}

/// Provider que indica si está sincronizando
@riverpod
bool isSyncing(Ref ref) {
  return ref.watch(syncStatusProvider.select((s) => s.isSyncing));
}

/// Provider con los errores de sincronización
@riverpod
List<String> syncErrors(Ref ref) {
  return ref.watch(syncStatusProvider.select((s) => s.errors));
}

/// Provider con la última sincronización exitosa
@riverpod
DateTime? lastSyncTime(Ref ref) {
  return ref.watch(syncStatusProvider.select((s) => s.lastSyncTime));
}

/// Provider con el conteo de operaciones pendientes de upload
@riverpod
int pendingUploads(Ref ref) {
  return ref.watch(syncStatusProvider.select((s) => s.pendingUploads));
}

/// Provider que indica si hay operaciones pendientes de upload
@riverpod
bool hasPendingUploads(Ref ref) {
  return ref.watch(syncStatusProvider.select((s) => s.hasPendingUploads));
}
