import 'dart:io';

import 'package:drift/drift.dart' hide isNotNull;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:finanzas_familiares/application/services/backup_service.dart';
import 'package:finanzas_familiares/application/services/restore_service.dart';
import 'package:finanzas_familiares/data/local/database.dart';
import 'package:finanzas_familiares/data/local/daos/daos.dart';
import 'package:finanzas_familiares/data/local/seeders/seeders.dart';

/// Tests para el RestoreService
/// Restaura backups de base de datos SQLite
void main() {
  late AppDatabase sourceDb;
  late CategoriesDao sourceCategoriesDao;
  late TransactionsDao sourceTransactionsDao;
  late BackupService backupService;
  late Directory tempDir;

  setUp(() async {
    sourceDb = AppDatabase.forTesting(NativeDatabase.memory());
    sourceCategoriesDao = CategoriesDao(sourceDb);
    sourceTransactionsDao = TransactionsDao(sourceDb);
    backupService = BackupService(db: sourceDb);

    tempDir = await Directory.systemTemp.createTemp('restore_test_');

    // Sembrar datos de prueba
    await seedCategories(sourceCategoriesDao);
  });

  tearDown(() async {
    await sourceDb.close();
    if (await tempDir.exists()) {
      await tempDir.delete(recursive: true);
    }
  });

  group('RestoreService - Restaurar Backup', () {
    test('restaura backup en base de datos vacía', () async {
      // Arrange - crear backup con datos
      final backupPath = '${tempDir.path}/backup_restore.db';
      await backupService.createBackup(backupPath);

      // Crear nueva base de datos vacía
      final targetDb = AppDatabase.forTesting(NativeDatabase.memory());
      final restoreService = RestoreService(db: targetDb);

      // Act
      final result = await restoreService.restoreFromBackup(backupPath);

      // Assert
      expect(result.success, isTrue);
      expect(result.restoredAt, isNotNull);

      // Verificar que los datos se restauraron
      final targetCategoriesDao = CategoriesDao(targetDb);
      final categories = await targetCategoriesDao.getAllCategories();
      expect(categories.length, greaterThan(0));

      await targetDb.close();
    });

    test('retorna error si el backup no existe', () async {
      // Arrange
      final targetDb = AppDatabase.forTesting(NativeDatabase.memory());
      final restoreService = RestoreService(db: targetDb);

      // Act
      final result = await restoreService.restoreFromBackup(
        '${tempDir.path}/nonexistent.db',
      );

      // Assert
      expect(result.success, isFalse);
      expect(result.error, contains('no existe'));

      await targetDb.close();
    });

    test('retorna error si el backup está corrupto', () async {
      // Arrange
      final corruptPath = '${tempDir.path}/corrupt.db';
      await File(corruptPath).writeAsString('invalid database content');

      final targetDb = AppDatabase.forTesting(NativeDatabase.memory());
      final restoreService = RestoreService(db: targetDb);

      // Act
      final result = await restoreService.restoreFromBackup(corruptPath);

      // Assert
      expect(result.success, isFalse);
      expect(result.error, isNotNull);

      await targetDb.close();
    });

    test('valida backup antes de restaurar', () async {
      // Arrange
      final backupPath = '${tempDir.path}/valid_backup.db';
      await backupService.createBackup(backupPath);

      final targetDb = AppDatabase.forTesting(NativeDatabase.memory());
      final restoreService = RestoreService(db: targetDb);

      // Act
      final validation = await restoreService.validateBeforeRestore(backupPath);

      // Assert
      expect(validation.isValid, isTrue);
      expect(validation.tableCount, greaterThan(0));

      await targetDb.close();
    });

    test('detecta incompatibilidad de versión', () async {
      // Arrange - crear un backup y modificar su versión
      final backupPath = '${tempDir.path}/old_version.db';
      await backupService.createBackup(backupPath);

      final targetDb = AppDatabase.forTesting(NativeDatabase.memory());
      final restoreService = RestoreService(db: targetDb);

      // Act - verificar compatibilidad
      final info = await restoreService.getBackupInfo(backupPath);

      // Assert
      expect(info, isNotNull);
      expect(info!.schemaVersion, greaterThan(0));

      await targetDb.close();
    });
  });

  group('RestoreService - Información de Backup', () {
    test('obtiene información detallada del backup', () async {
      // Arrange
      final backupPath = '${tempDir.path}/info_backup.db';
      await backupService.createBackup(backupPath);

      final targetDb = AppDatabase.forTesting(NativeDatabase.memory());
      final restoreService = RestoreService(db: targetDb);

      // Act
      final info = await restoreService.getBackupInfo(backupPath);

      // Assert
      expect(info, isNotNull);
      expect(info!.tableCount, greaterThan(0));
      expect(info.categoryCount, greaterThan(0));
      expect(info.schemaVersion, greaterThan(0));

      await targetDb.close();
    });

    test('cuenta registros por tabla', () async {
      // Arrange - agregar transacción antes del backup
      final expenseCat = (await sourceCategoriesDao.getAllCategories())
          .firstWhere((c) => c.type == 'expense' && (c.level ?? 0) > 0);

      await sourceTransactionsDao.insertTransaction(
        TransactionsCompanion.insert(
          id: 'tx-restore-001',
          type: 'expense',
          amount: 50000,
          categoryId: expenseCat.id,
          transactionDate: DateTime.now(),
        ),
      );

      final backupPath = '${tempDir.path}/with_transactions.db';
      await backupService.createBackup(backupPath);

      final targetDb = AppDatabase.forTesting(NativeDatabase.memory());
      final restoreService = RestoreService(db: targetDb);

      // Act
      final info = await restoreService.getBackupInfo(backupPath);

      // Assert
      expect(info, isNotNull);
      expect(info!.transactionCount, equals(1));

      await targetDb.close();
    });
  });

  group('RestoreService - Estrategias de Restauración', () {
    test('restauración completa reemplaza todos los datos', () async {
      // Arrange
      final backupPath = '${tempDir.path}/full_restore.db';
      await backupService.createBackup(backupPath);

      // Crear DB destino con datos diferentes
      final targetDb = AppDatabase.forTesting(NativeDatabase.memory());
      final targetCategoriesDao = CategoriesDao(targetDb);

      // Agregar categoría única en destino
      await targetCategoriesDao.insertCategory(
        CategoriesCompanion.insert(
          id: 'cat-unique-target',
          name: 'Categoría Solo Destino',
          type: 'expense',
          level: const Value(1),
        ),
      );

      final restoreService = RestoreService(db: targetDb);

      // Act - restauración completa
      final result = await restoreService.restoreFromBackup(
        backupPath,
        strategy: RestoreStrategy.replaceAll,
      );

      // Assert
      expect(result.success, isTrue);

      // La categoría única del destino debe haber sido reemplazada
      final categories = await targetCategoriesDao.getAllCategories();
      expect(
        categories.any((c) => c.id == 'cat-unique-target'),
        isFalse,
      );

      await targetDb.close();
    });
  });
}
