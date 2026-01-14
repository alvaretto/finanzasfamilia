import 'backup_service.dart';

/// Configuración de backup automático
class AutoBackupConfig {
  /// Si el backup automático está habilitado
  final bool enabled;

  /// Intervalo entre backups en horas
  final int intervalHours;

  /// Número máximo de backups a mantener
  final int maxBackups;

  /// Si se debe hacer backup al iniciar la app
  final bool backupOnAppStart;

  const AutoBackupConfig({
    this.enabled = true,
    this.intervalHours = 24,
    this.maxBackups = 5,
    this.backupOnAppStart = true,
  });
}

/// Resultado de ejecución de backup automático
class AutoBackupResult {
  final bool wasExecuted;
  final bool success;
  final String? error;
  final DateTime? backupTime;

  AutoBackupResult({
    required this.wasExecuted,
    this.success = false,
    this.error,
    this.backupTime,
  });

  factory AutoBackupResult.skipped() {
    return AutoBackupResult(wasExecuted: false);
  }

  factory AutoBackupResult.success(DateTime backupTime) {
    return AutoBackupResult(
      wasExecuted: true,
      success: true,
      backupTime: backupTime,
    );
  }

  factory AutoBackupResult.failure(String error) {
    return AutoBackupResult(
      wasExecuted: true,
      success: false,
      error: error,
    );
  }
}

/// Estadísticas de backups
class BackupStats {
  final int totalBackups;
  final int totalSizeBytes;
  final DateTime? oldestBackup;
  final DateTime? newestBackup;

  BackupStats({
    required this.totalBackups,
    required this.totalSizeBytes,
    this.oldestBackup,
    this.newestBackup,
  });

  /// Tamaño total formateado
  String get formattedSize {
    if (totalSizeBytes < 1024) return '$totalSizeBytes B';
    if (totalSizeBytes < 1024 * 1024) {
      return '${(totalSizeBytes / 1024).toStringAsFixed(1)} KB';
    }
    return '${(totalSizeBytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }
}

/// Servicio de Backup Automático
///
/// Gestiona backups automáticos programados con:
/// - Verificación de necesidad de backup
/// - Ejecución condicional
/// - Limpieza de backups antiguos
/// - Estadísticas de uso
class AutoBackupService {
  final BackupService backupService;
  final String backupDirectory;
  final AutoBackupConfig config;

  AutoBackupService({
    required this.backupService,
    required this.backupDirectory,
    this.config = const AutoBackupConfig(),
  });

  // ============================================================
  // Verificación de Necesidad
  // ============================================================

  /// Verifica si es necesario realizar un backup
  Future<bool> needsBackup() async {
    if (!config.enabled) return false;

    final backups = await backupService.listBackups(backupDirectory);

    // Sin backups previos, definitivamente necesita uno
    if (backups.isEmpty) return true;

    // Verificar si el último backup es muy antiguo
    final lastBackup = backups.first;
    final elapsed = DateTime.now().difference(lastBackup.createdAt);

    return elapsed.inHours >= config.intervalHours;
  }

  // ============================================================
  // Ejecución de Backup
  // ============================================================

  /// Ejecuta backup si es necesario
  Future<AutoBackupResult> runIfNeeded() async {
    if (!config.enabled) {
      return AutoBackupResult.skipped();
    }

    final needs = await needsBackup();
    if (!needs) {
      return AutoBackupResult.skipped();
    }

    return await _executeBackup();
  }

  /// Fuerza ejecución de backup
  Future<AutoBackupResult> forceRun() async {
    return await _executeBackup();
  }

  Future<AutoBackupResult> _executeBackup() async {
    try {
      final result = await backupService.createBackup(
        backupDirectory,
        autoName: true,
      );

      if (result.success) {
        // Limpiar backups antiguos después de crear uno nuevo
        await cleanupOldBackups();
        return AutoBackupResult.success(result.backupTime!);
      } else {
        return AutoBackupResult.failure(result.error ?? 'Error desconocido');
      }
    } catch (e) {
      return AutoBackupResult.failure('Error en backup automático: $e');
    }
  }

  // ============================================================
  // Limpieza
  // ============================================================

  /// Elimina backups antiguos que excedan el máximo configurado
  Future<void> cleanupOldBackups() async {
    final backups = await backupService.listBackups(backupDirectory);

    if (backups.length <= config.maxBackups) return;

    // Los backups están ordenados por fecha descendente
    // Eliminar los más antiguos (al final de la lista)
    final toDelete = backups.skip(config.maxBackups).toList();

    for (final backup in toDelete) {
      await backupService.deleteBackup(backup.filePath);
    }
  }

  // ============================================================
  // Estadísticas
  // ============================================================

  /// Obtiene estadísticas de backups
  Future<BackupStats> getBackupStats() async {
    final backups = await backupService.listBackups(backupDirectory);

    if (backups.isEmpty) {
      return BackupStats(
        totalBackups: 0,
        totalSizeBytes: 0,
      );
    }

    final totalSize = backups.fold<int>(0, (sum, b) => sum + b.sizeBytes);

    return BackupStats(
      totalBackups: backups.length,
      totalSizeBytes: totalSize,
      oldestBackup: backups.last.createdAt,
      newestBackup: backups.first.createdAt,
    );
  }
}
