import 'dart:io';

import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:finanzas_familiares/application/services/auto_backup_service.dart';
import 'package:finanzas_familiares/application/services/backup_service.dart';
import 'package:finanzas_familiares/data/local/database.dart';
import 'package:finanzas_familiares/data/local/daos/daos.dart';
import 'package:finanzas_familiares/data/local/seeders/seeders.dart';

/// Tests para AutoBackupService
/// Gestiona backups automáticos programados
void main() {
  late AppDatabase database;
  late CategoriesDao categoriesDao;
  late BackupService backupService;
  late Directory tempDir;

  setUp(() async {
    database = AppDatabase.forTesting(NativeDatabase.memory());
    categoriesDao = CategoriesDao(database);
    backupService = BackupService(db: database);

    tempDir = await Directory.systemTemp.createTemp('auto_backup_test_');

    await seedCategories(categoriesDao);
  });

  tearDown(() async {
    await database.close();
    if (await tempDir.exists()) {
      await tempDir.delete(recursive: true);
    }
  });

  group('AutoBackupConfig', () {
    test('configuración por defecto correcta', () {
      // Act
      const config = AutoBackupConfig();

      // Assert
      expect(config.enabled, isTrue);
      expect(config.intervalHours, equals(24));
      expect(config.maxBackups, equals(5));
      expect(config.backupOnAppStart, isTrue);
    });

    test('configuración personalizada', () {
      // Act
      const config = AutoBackupConfig(
        enabled: false,
        intervalHours: 12,
        maxBackups: 10,
        backupOnAppStart: false,
      );

      // Assert
      expect(config.enabled, isFalse);
      expect(config.intervalHours, equals(12));
      expect(config.maxBackups, equals(10));
      expect(config.backupOnAppStart, isFalse);
    });
  });

  group('AutoBackupService - Verificar Necesidad', () {
    test('necesita backup si nunca se hizo uno', () async {
      // Arrange
      final autoBackup = AutoBackupService(
        backupService: backupService,
        backupDirectory: tempDir.path,
      );

      // Act
      final needsBackup = await autoBackup.needsBackup();

      // Assert
      expect(needsBackup, isTrue);
    });

    test('no necesita backup si hay uno reciente', () async {
      // Arrange
      await backupService.createBackup(tempDir.path, autoName: true);

      final autoBackup = AutoBackupService(
        backupService: backupService,
        backupDirectory: tempDir.path,
      );

      // Act
      final needsBackup = await autoBackup.needsBackup();

      // Assert
      expect(needsBackup, isFalse);
    });

    test('necesita backup si el último es muy antiguo', () async {
      // Arrange - crear backup "antiguo" (modificar timestamp)
      final result = await backupService.createBackup(tempDir.path, autoName: true);
      final file = File(result.filePath);

      // Simular que el backup es de hace 2 días
      final oldTime = DateTime.now().subtract(const Duration(days: 2));
      await file.setLastModified(oldTime);

      final autoBackup = AutoBackupService(
        backupService: backupService,
        backupDirectory: tempDir.path,
        config: const AutoBackupConfig(intervalHours: 24),
      );

      // Act
      final needsBackup = await autoBackup.needsBackup();

      // Assert
      expect(needsBackup, isTrue);
    });
  });

  group('AutoBackupService - Ejecutar Backup', () {
    test('ejecuta backup automático si es necesario', () async {
      // Arrange
      final autoBackup = AutoBackupService(
        backupService: backupService,
        backupDirectory: tempDir.path,
      );

      // Act
      final result = await autoBackup.runIfNeeded();

      // Assert
      expect(result.wasExecuted, isTrue);
      expect(result.success, isTrue);

      final backups = await backupService.listBackups(tempDir.path);
      expect(backups.length, equals(1));
    });

    test('no ejecuta backup si no es necesario', () async {
      // Arrange - crear backup primero
      await backupService.createBackup(tempDir.path, autoName: true);

      final autoBackup = AutoBackupService(
        backupService: backupService,
        backupDirectory: tempDir.path,
      );

      // Act
      final result = await autoBackup.runIfNeeded();

      // Assert
      expect(result.wasExecuted, isFalse);
    });

    test('no ejecuta si autobackup está deshabilitado', () async {
      // Arrange
      final autoBackup = AutoBackupService(
        backupService: backupService,
        backupDirectory: tempDir.path,
        config: const AutoBackupConfig(enabled: false),
      );

      // Act
      final result = await autoBackup.runIfNeeded();

      // Assert
      expect(result.wasExecuted, isFalse);
    });
  });

  group('AutoBackupService - Limpieza', () {
    test('elimina backups antiguos al exceder máximo', () async {
      // Arrange - crear múltiples backups con nombres únicos
      for (var i = 0; i < 7; i++) {
        await backupService.createBackup('${tempDir.path}/backup_$i.db');
        await Future.delayed(const Duration(milliseconds: 50));
      }

      var backups = await backupService.listBackups(tempDir.path);
      expect(backups.length, equals(7));

      final autoBackup = AutoBackupService(
        backupService: backupService,
        backupDirectory: tempDir.path,
        config: const AutoBackupConfig(maxBackups: 5),
      );

      // Act
      await autoBackup.cleanupOldBackups();

      // Assert
      backups = await backupService.listBackups(tempDir.path);
      expect(backups.length, equals(5));
    });

    test('mantiene los backups más recientes', () async {
      // Arrange
      for (var i = 0; i < 3; i++) {
        await backupService.createBackup('${tempDir.path}/backup_$i.db');
        await Future.delayed(const Duration(milliseconds: 50));
      }

      final autoBackup = AutoBackupService(
        backupService: backupService,
        backupDirectory: tempDir.path,
        config: const AutoBackupConfig(maxBackups: 2),
      );

      // Act
      await autoBackup.cleanupOldBackups();

      // Assert
      final backups = await backupService.listBackups(tempDir.path);
      expect(backups.length, equals(2));

      // Verificar que son los más recientes
      expect(backups.first.fileName, contains('backup_2'));
      expect(backups.last.fileName, contains('backup_1'));
    });

    test('no elimina nada si está dentro del límite', () async {
      // Arrange
      await backupService.createBackup('${tempDir.path}/limit_1.db');
      await backupService.createBackup('${tempDir.path}/limit_2.db');

      final autoBackup = AutoBackupService(
        backupService: backupService,
        backupDirectory: tempDir.path,
        config: const AutoBackupConfig(maxBackups: 5),
      );

      // Act
      await autoBackup.cleanupOldBackups();

      // Assert
      final backups = await backupService.listBackups(tempDir.path);
      expect(backups.length, equals(2));
    });
  });

  group('AutoBackupService - Estadísticas', () {
    test('obtiene estadísticas de backups', () async {
      // Arrange
      await backupService.createBackup('${tempDir.path}/stats_1.db');
      await backupService.createBackup('${tempDir.path}/stats_2.db');

      final autoBackup = AutoBackupService(
        backupService: backupService,
        backupDirectory: tempDir.path,
      );

      // Act
      final stats = await autoBackup.getBackupStats();

      // Assert
      expect(stats.totalBackups, equals(2));
      expect(stats.totalSizeBytes, greaterThan(0));
      expect(stats.oldestBackup, isNotNull);
      expect(stats.newestBackup, isNotNull);
    });

    test('estadísticas vacías sin backups', () async {
      // Arrange
      final autoBackup = AutoBackupService(
        backupService: backupService,
        backupDirectory: tempDir.path,
      );

      // Act
      final stats = await autoBackup.getBackupStats();

      // Assert
      expect(stats.totalBackups, equals(0));
      expect(stats.totalSizeBytes, equals(0));
      expect(stats.oldestBackup, isNull);
      expect(stats.newestBackup, isNull);
    });
  });
}
