import 'dart:io';

import 'package:drift/native.dart';
import 'package:path/path.dart' as p;
import 'package:intl/intl.dart';

import '../../data/local/database.dart';

/// Resultado de operación de backup
class BackupResult {
  final bool success;
  final String filePath;
  final DateTime? backupTime;
  final int sizeBytes;
  final String? error;

  BackupResult({
    required this.success,
    required this.filePath,
    this.backupTime,
    this.sizeBytes = 0,
    this.error,
  });

  factory BackupResult.success({
    required String filePath,
    required DateTime backupTime,
    required int sizeBytes,
  }) {
    return BackupResult(
      success: true,
      filePath: filePath,
      backupTime: backupTime,
      sizeBytes: sizeBytes,
    );
  }

  factory BackupResult.failure(String error, {String filePath = ''}) {
    return BackupResult(
      success: false,
      filePath: filePath,
      error: error,
    );
  }
}

/// Información de un backup existente
class BackupInfo {
  final String filePath;
  final String fileName;
  final int sizeBytes;
  final DateTime createdAt;

  BackupInfo({
    required this.filePath,
    required this.fileName,
    required this.sizeBytes,
    required this.createdAt,
  });

  /// Tamaño formateado para mostrar
  String get formattedSize {
    if (sizeBytes < 1024) return '$sizeBytes B';
    if (sizeBytes < 1024 * 1024) {
      return '${(sizeBytes / 1024).toStringAsFixed(1)} KB';
    }
    return '${(sizeBytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }
}

/// Resultado de validación de backup
class BackupValidation {
  final bool isValid;
  final int tableCount;
  final String? error;

  BackupValidation({
    required this.isValid,
    this.tableCount = 0,
    this.error,
  });

  factory BackupValidation.valid(int tableCount) {
    return BackupValidation(isValid: true, tableCount: tableCount);
  }

  factory BackupValidation.invalid(String error) {
    return BackupValidation(isValid: false, error: error);
  }
}

/// Servicio de Backup Local
///
/// Gestiona backups de la base de datos SQLite:
/// - Crear backups completos
/// - Listar backups existentes
/// - Validar integridad de backups
/// - Eliminar backups antiguos
class BackupService {
  final AppDatabase db;
  static const _backupPrefix = 'finanzas_backup_';
  static const _backupExtension = '.db';

  BackupService({required this.db});

  // ============================================================
  // Crear Backup
  // ============================================================

  /// Crea un backup de la base de datos
  ///
  /// [outputPath] - Ruta donde guardar el backup
  /// [autoName] - Si true, genera nombre automático con timestamp
  Future<BackupResult> createBackup(
    String outputPath, {
    bool autoName = false,
  }) async {
    try {
      final filePath = _resolveBackupPath(outputPath, autoName);
      await _ensureDirectoryExists(filePath);

      // Exportar la base de datos usando Drift
      final dbFile = File(filePath);
      await _exportDatabase(dbFile);

      final stat = await dbFile.stat();

      return BackupResult.success(
        filePath: filePath,
        backupTime: DateTime.now(),
        sizeBytes: stat.size,
      );
    } catch (e) {
      return BackupResult.failure('Error creando backup: $e');
    }
  }

  String _resolveBackupPath(String outputPath, bool autoName) {
    if (!autoName) return outputPath;

    final timestamp = DateFormat('yyyyMMdd_HHmmss').format(DateTime.now());
    final fileName = '$_backupPrefix$timestamp$_backupExtension';

    if (outputPath.endsWith('/') || !outputPath.contains('.')) {
      return p.join(outputPath, fileName);
    }
    return outputPath;
  }

  Future<void> _ensureDirectoryExists(String filePath) async {
    final dir = Directory(p.dirname(filePath));
    if (!await dir.exists()) {
      await dir.create(recursive: true);
    }
  }

  Future<void> _exportDatabase(File targetFile) async {
    // Eliminar archivo existente (VACUUM INTO requiere archivo vacío/nuevo)
    if (await targetFile.exists()) {
      await targetFile.delete();
    }

    // Usar VACUUM INTO para exportar la base de datos
    await db.customStatement('VACUUM INTO ?', [targetFile.path]);
  }

  // ============================================================
  // Listar Backups
  // ============================================================

  /// Lista todos los backups en un directorio
  ///
  /// Retorna lista ordenada por fecha descendente (más reciente primero)
  Future<List<BackupInfo>> listBackups(String directoryPath) async {
    try {
      final dir = Directory(directoryPath);
      if (!await dir.exists()) return [];

      final backups = <BackupInfo>[];

      await for (final entity in dir.list()) {
        if (entity is File && _isBackupFile(entity.path)) {
          final stat = await entity.stat();
          backups.add(BackupInfo(
            filePath: entity.path,
            fileName: p.basename(entity.path),
            sizeBytes: stat.size,
            createdAt: stat.modified,
          ));
        }
      }

      // Ordenar por fecha descendente
      backups.sort((a, b) => b.createdAt.compareTo(a.createdAt));

      return backups;
    } catch (e) {
      return [];
    }
  }

  bool _isBackupFile(String path) {
    final fileName = p.basename(path);
    return fileName.endsWith(_backupExtension);
  }

  // ============================================================
  // Eliminar Backup
  // ============================================================

  /// Elimina un archivo de backup
  Future<bool> deleteBackup(String backupPath) async {
    try {
      final file = File(backupPath);
      if (!await file.exists()) return false;

      await file.delete();
      return true;
    } catch (e) {
      return false;
    }
  }

  // ============================================================
  // Validar Backup
  // ============================================================

  /// Valida la integridad de un backup
  Future<BackupValidation> validateBackup(String backupPath) async {
    try {
      final file = File(backupPath);
      if (!await file.exists()) {
        return BackupValidation.invalid('El archivo no existe');
      }

      // Intentar abrir la base de datos
      final testDb = AppDatabase.forTesting(NativeDatabase(file));

      try {
        // Contar tablas para verificar estructura
        final tables = await testDb.customSelect(
          "SELECT name FROM sqlite_master WHERE type='table'",
        ).get();

        await testDb.close();

        return BackupValidation.valid(tables.length);
      } catch (e) {
        await testDb.close();
        return BackupValidation.invalid('Base de datos corrupta: $e');
      }
    } catch (e) {
      return BackupValidation.invalid('Error validando backup: $e');
    }
  }

  // ============================================================
  // Metadata
  // ============================================================

  /// Obtiene metadata de un backup
  Future<BackupInfo?> getBackupMetadata(String backupPath) async {
    try {
      final file = File(backupPath);
      if (!await file.exists()) return null;

      final stat = await file.stat();

      return BackupInfo(
        filePath: backupPath,
        fileName: p.basename(backupPath),
        sizeBytes: stat.size,
        createdAt: stat.modified,
      );
    } catch (e) {
      return null;
    }
  }
}
