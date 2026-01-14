import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../services/backup_service.dart';
import 'database_provider.dart';

part 'backup_provider.g.dart';

/// Estado de backup
class BackupState {
  final bool isCreatingBackup;
  final bool isRestoringBackup;
  final DateTime? lastBackupTime;
  final List<BackupInfo> backups;
  final String? error;

  const BackupState({
    this.isCreatingBackup = false,
    this.isRestoringBackup = false,
    this.lastBackupTime,
    this.backups = const [],
    this.error,
  });

  /// Indica si hay un backup reciente (menos de 24 horas)
  bool get hasRecentBackup {
    if (lastBackupTime == null) return false;
    final diff = DateTime.now().difference(lastBackupTime!);
    return diff.inHours < 24;
  }

  BackupState copyWith({
    bool? isCreatingBackup,
    bool? isRestoringBackup,
    DateTime? lastBackupTime,
    List<BackupInfo>? backups,
    String? error,
  }) {
    return BackupState(
      isCreatingBackup: isCreatingBackup ?? this.isCreatingBackup,
      isRestoringBackup: isRestoringBackup ?? this.isRestoringBackup,
      lastBackupTime: lastBackupTime ?? this.lastBackupTime,
      backups: backups ?? this.backups,
      error: error,
    );
  }
}

/// Provider del directorio de backups
@Riverpod(keepAlive: true)
String backupDirectory(Ref ref) {
  // En producción esto vendría de path_provider
  return '/tmp/finanzas_backups';
}

/// Provider del servicio de backup
@Riverpod(keepAlive: true)
BackupService backupService(Ref ref) {
  final db = ref.watch(appDatabaseProvider);
  return BackupService(db: db);
}

/// Provider de estado de backups
@Riverpod(keepAlive: true)
class Backup extends _$Backup {
  @override
  BackupState build() => const BackupState();

  /// Crea un nuevo backup
  Future<void> createBackup({String? customPath}) async {
    state = state.copyWith(isCreatingBackup: true, error: null);

    try {
      final service = ref.read(backupServiceProvider);
      final directory = ref.read(backupDirectoryProvider);

      final path = customPath ?? directory;
      final result = await service.createBackup(path, autoName: customPath == null);

      if (result.success) {
        state = state.copyWith(
          isCreatingBackup: false,
          lastBackupTime: result.backupTime,
        );
        await loadBackups();
      } else {
        state = state.copyWith(
          isCreatingBackup: false,
          error: result.error,
        );
      }
    } catch (e) {
      state = state.copyWith(
        isCreatingBackup: false,
        error: 'Error creando backup: $e',
      );
    }
  }

  /// Carga la lista de backups disponibles
  Future<void> loadBackups() async {
    try {
      final service = ref.read(backupServiceProvider);
      final directory = ref.read(backupDirectoryProvider);

      final backups = await service.listBackups(directory);

      state = state.copyWith(backups: backups);

      // Actualizar lastBackupTime si hay backups
      if (backups.isNotEmpty) {
        state = state.copyWith(lastBackupTime: backups.first.createdAt);
      }
    } catch (e) {
      state = state.copyWith(error: 'Error cargando backups: $e');
    }
  }

  /// Elimina un backup
  Future<void> deleteBackup(String backupPath) async {
    try {
      final service = ref.read(backupServiceProvider);
      await service.deleteBackup(backupPath);
      await loadBackups();
    } catch (e) {
      state = state.copyWith(error: 'Error eliminando backup: $e');
    }
  }

  /// Establece un mensaje de error
  void setError(String error) {
    state = state.copyWith(error: error);
  }

  /// Limpia el mensaje de error
  void clearError() {
    state = state.copyWith(error: null);
  }
}

// ============================================================
// Providers Derivados
// ============================================================

/// Provider que indica si hay backup reciente
@riverpod
bool hasRecentBackup(Ref ref) {
  return ref.watch(backupProvider.select((s) => s.hasRecentBackup));
}

/// Provider con el conteo de backups
@riverpod
int backupCount(Ref ref) {
  return ref.watch(backupProvider.select((s) => s.backups.length));
}

/// Provider que indica si está creando backup
@riverpod
bool isCreatingBackup(Ref ref) {
  return ref.watch(backupProvider.select((s) => s.isCreatingBackup));
}

/// Provider con la última fecha de backup
@riverpod
DateTime? lastBackupTime(Ref ref) {
  return ref.watch(backupProvider.select((s) => s.lastBackupTime));
}
