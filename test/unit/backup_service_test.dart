import 'dart:io';

import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:finanzas_familiares/application/services/backup_service.dart';
import 'package:finanzas_familiares/data/local/database.dart';
import 'package:finanzas_familiares/data/local/daos/daos.dart';
import 'package:finanzas_familiares/data/local/seeders/seeders.dart';

/// Tests para el BackupService
/// Gestiona backups locales de la base de datos SQLite
void main() {
  late AppDatabase database;
  late CategoriesDao categoriesDao;
  late BackupService backupService;
  late Directory tempDir;

  setUp(() async {
    database = AppDatabase.forTesting(NativeDatabase.memory());
    categoriesDao = CategoriesDao(database);
    backupService = BackupService(db: database);

    tempDir = await Directory.systemTemp.createTemp('backup_test_');

    // Sembrar datos de prueba
    await seedCategories(categoriesDao);
  });

  tearDown(() async {
    await database.close();
    if (await tempDir.exists()) {
      await tempDir.delete(recursive: true);
    }
  });

  group('BackupService - Crear Backup', () {
    test('crea backup exitoso con metadata', () async {
      // Arrange
      final backupPath = '${tempDir.path}/backup_test.db';

      // Act
      final result = await backupService.createBackup(backupPath);

      // Assert
      expect(result.success, isTrue);
      expect(result.filePath, equals(backupPath));
      expect(result.backupTime, isNotNull);
      expect(result.sizeBytes, greaterThan(0));
    });

    test('backup incluye todos los datos', () async {
      // Arrange
      final backupPath = '${tempDir.path}/backup_data.db';
      final categoriesBefore = await categoriesDao.getAllCategories();

      // Act
      await backupService.createBackup(backupPath);

      // Assert - verificar que el archivo existe y tiene contenido
      final file = File(backupPath);
      expect(await file.exists(), isTrue);
      expect(await file.length(), greaterThan(0));

      // Verificar datos en backup abriendo la base de datos
      final backupDb = AppDatabase.forTesting(
        NativeDatabase(file),
      );
      final backupCategoriesDao = CategoriesDao(backupDb);
      final categoriesAfter = await backupCategoriesDao.getAllCategories();

      expect(categoriesAfter.length, equals(categoriesBefore.length));

      await backupDb.close();
    });

    test('crea directorio padre si no existe', () async {
      // Arrange
      final backupPath = '${tempDir.path}/nested/dir/backup.db';

      // Act
      final result = await backupService.createBackup(backupPath);

      // Assert
      expect(result.success, isTrue);
      expect(await File(backupPath).exists(), isTrue);
    });

    test('genera nombre de archivo automático si no se especifica', () async {
      // Act
      final result = await backupService.createBackup(
        tempDir.path,
        autoName: true,
      );

      // Assert
      expect(result.success, isTrue);
      expect(result.filePath, contains('finanzas_backup_'));
      expect(result.filePath, endsWith('.db'));
    });

    test('retorna error si la ruta es inválida', () async {
      // Arrange - ruta inválida (directorio root sin permisos)
      const invalidPath = '/root/forbidden/backup.db';

      // Act
      final result = await backupService.createBackup(invalidPath);

      // Assert
      expect(result.success, isFalse);
      expect(result.error, isNotNull);
    });
  });

  group('BackupService - Listar Backups', () {
    test('lista backups existentes en directorio', () async {
      // Arrange - crear varios backups
      await backupService.createBackup('${tempDir.path}/backup1.db');
      await backupService.createBackup('${tempDir.path}/backup2.db');
      await backupService.createBackup('${tempDir.path}/backup3.db');

      // Act
      final backups = await backupService.listBackups(tempDir.path);

      // Assert
      expect(backups.length, equals(3));
      expect(backups.every((b) => b.filePath.endsWith('.db')), isTrue);
    });

    test('ordena backups por fecha descendente', () async {
      // Arrange
      await backupService.createBackup('${tempDir.path}/old.db');
      await Future.delayed(const Duration(milliseconds: 100));
      await backupService.createBackup('${tempDir.path}/new.db');

      // Act
      final backups = await backupService.listBackups(tempDir.path);

      // Assert
      expect(backups.first.filePath, contains('new.db'));
      expect(backups.last.filePath, contains('old.db'));
    });

    test('retorna lista vacía si no hay backups', () async {
      // Act
      final backups = await backupService.listBackups(tempDir.path);

      // Assert
      expect(backups, isEmpty);
    });

    test('ignora archivos que no son backups', () async {
      // Arrange
      await File('${tempDir.path}/not_a_backup.txt').writeAsString('test');
      await backupService.createBackup('${tempDir.path}/real_backup.db');

      // Act
      final backups = await backupService.listBackups(tempDir.path);

      // Assert
      expect(backups.length, equals(1));
      expect(backups.first.filePath, contains('real_backup.db'));
    });
  });

  group('BackupService - Eliminar Backup', () {
    test('elimina backup existente', () async {
      // Arrange
      final backupPath = '${tempDir.path}/to_delete.db';
      await backupService.createBackup(backupPath);
      expect(await File(backupPath).exists(), isTrue);

      // Act
      final result = await backupService.deleteBackup(backupPath);

      // Assert
      expect(result, isTrue);
      expect(await File(backupPath).exists(), isFalse);
    });

    test('retorna false si el backup no existe', () async {
      // Act
      final result = await backupService.deleteBackup(
        '${tempDir.path}/nonexistent.db',
      );

      // Assert
      expect(result, isFalse);
    });
  });

  group('BackupService - Validar Backup', () {
    test('valida backup válido', () async {
      // Arrange
      final backupPath = '${tempDir.path}/valid.db';
      await backupService.createBackup(backupPath);

      // Act
      final result = await backupService.validateBackup(backupPath);

      // Assert
      expect(result.isValid, isTrue);
      expect(result.tableCount, greaterThan(0));
    });

    test('detecta archivo corrupto', () async {
      // Arrange
      final corruptPath = '${tempDir.path}/corrupt.db';
      await File(corruptPath).writeAsString('not a valid database');

      // Act
      final result = await backupService.validateBackup(corruptPath);

      // Assert
      expect(result.isValid, isFalse);
      expect(result.error, isNotNull);
    });

    test('detecta archivo inexistente', () async {
      // Act
      final result = await backupService.validateBackup(
        '${tempDir.path}/missing.db',
      );

      // Assert
      expect(result.isValid, isFalse);
      expect(result.error, contains('no existe'));
    });
  });

  group('BackupService - Metadata', () {
    test('obtiene metadata de backup', () async {
      // Arrange
      final backupPath = '${tempDir.path}/metadata.db';
      await backupService.createBackup(backupPath);

      // Act
      final metadata = await backupService.getBackupMetadata(backupPath);

      // Assert
      expect(metadata, isNotNull);
      expect(metadata!.filePath, equals(backupPath));
      expect(metadata.sizeBytes, greaterThan(0));
      expect(metadata.createdAt, isNotNull);
    });

    test('retorna null para archivo inexistente', () async {
      // Act
      final metadata = await backupService.getBackupMetadata(
        '${tempDir.path}/missing.db',
      );

      // Assert
      expect(metadata, isNull);
    });
  });
}
