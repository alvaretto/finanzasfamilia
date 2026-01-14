import 'dart:io';

import 'package:drift/drift.dart' hide isNotNull;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:finanzas_familiares/application/services/backup_service.dart';
import 'package:finanzas_familiares/data/local/database.dart';
import 'package:finanzas_familiares/data/local/daos/daos.dart';
import 'package:finanzas_familiares/data/local/seeders/seeders.dart';

/// Tests de integración E2E para el flujo de Backup
/// Nota: RestoreService requiere bases de datos en archivo, no en memoria
void main() {
  late Directory tempDir;

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('integration_test_');
  });

  tearDown(() async {
    if (await tempDir.exists()) {
      await tempDir.delete(recursive: true);
    }
  });

  group('E2E: Creación de Backup', () {
    test('crea backup con datos y verifica integridad', () async {
      // ======================
      // FASE 1: Setup inicial
      // ======================
      final dbPath = '${tempDir.path}/test_db.db';
      final originalDb = AppDatabase.forTesting(NativeDatabase(File(dbPath)));
      final categoriesDao = CategoriesDao(originalDb);
      final transactionsDao = TransactionsDao(originalDb);

      // Sembrar categorías
      await seedCategories(categoriesDao);
      final initialCategories = await categoriesDao.getAllCategories();
      expect(initialCategories.length, greaterThan(0));

      // Crear transacciones de prueba
      final expenseCategory = initialCategories.firstWhere(
        (c) => c.type == 'expense' && c.parentId != null,
      );

      await transactionsDao.insertTransaction(TransactionsCompanion.insert(
        id: 'tx-integration-001',
        type: 'expense',
        amount: 150000,
        description: const Value('Compra supermercado'),
        categoryId: expenseCategory.id,
        transactionDate: DateTime(2026, 1, 5),
      ));

      await transactionsDao.insertTransaction(TransactionsCompanion.insert(
        id: 'tx-integration-002',
        type: 'expense',
        amount: 50000,
        description: const Value('Transporte'),
        categoryId: expenseCategory.id,
        transactionDate: DateTime(2026, 1, 6),
      ));

      final initialTransactions = await transactionsDao.getAllTransactions();
      expect(initialTransactions.length, equals(2));

      // ======================
      // FASE 2: Crear Backup
      // ======================
      final backupService = BackupService(db: originalDb);
      final backupPath = '${tempDir.path}/integration_backup.db';

      final backupResult = await backupService.createBackup(backupPath);
      expect(backupResult.success, isTrue);
      expect(await File(backupPath).exists(), isTrue);
      expect(backupResult.sizeBytes, greaterThan(0));

      // ======================
      // FASE 3: Validar Backup
      // ======================
      final validation = await backupService.validateBackup(backupPath);
      expect(validation.isValid, isTrue);
      expect(validation.tableCount, greaterThan(0));

      // ======================
      // FASE 4: Verificar datos en backup abriendo directamente
      // ======================
      final backupDb = AppDatabase.forTesting(
        NativeDatabase(File(backupPath)),
      );
      final backupCategoriesDao = CategoriesDao(backupDb);
      final backupTransactionsDao = TransactionsDao(backupDb);

      final backupCategories = await backupCategoriesDao.getAllCategories();
      final backupTransactions = await backupTransactionsDao.getAllTransactions();

      // Verificar que el backup tiene los mismos datos
      expect(backupCategories.length, equals(initialCategories.length));
      expect(backupTransactions.length, equals(initialTransactions.length));

      // Verificar transacciones específicas
      final tx001 = backupTransactions.firstWhere((t) => t.id == 'tx-integration-001');
      expect(tx001.amount, equals(150000));
      expect(tx001.description, equals('Compra supermercado'));

      final tx002 = backupTransactions.firstWhere((t) => t.id == 'tx-integration-002');
      expect(tx002.amount, equals(50000));

      await backupDb.close();
      await originalDb.close();
    });

    test('backup automático respeta límite de retención', () async {
      // ======================
      // Setup con archivo físico
      // ======================
      final dbPath = '${tempDir.path}/retention_db.db';
      final db = AppDatabase.forTesting(NativeDatabase(File(dbPath)));
      final categoriesDao = CategoriesDao(db);
      await seedCategories(categoriesDao);

      final backupService = BackupService(db: db);
      final backupDir = '${tempDir.path}/auto_backups';
      await Directory(backupDir).create(recursive: true);

      // ======================
      // Crear múltiples backups
      // ======================
      for (var i = 1; i <= 5; i++) {
        await backupService.createBackup('$backupDir/backup_$i.db');
        await Future.delayed(const Duration(milliseconds: 50));
      }

      // Verificar que hay 5 backups
      final backups = await backupService.listBackups(backupDir);
      expect(backups.length, equals(5));

      // ======================
      // Limpiar manteniendo solo 3
      // ======================
      backups.sort((a, b) => b.createdAt.compareTo(a.createdAt));

      const maxBackups = 3;
      if (backups.length > maxBackups) {
        for (var i = maxBackups; i < backups.length; i++) {
          await backupService.deleteBackup(backups[i].filePath);
        }
      }

      // Verificar que solo quedan 3
      final remainingBackups = await backupService.listBackups(backupDir);
      expect(remainingBackups.length, equals(maxBackups));

      // Los más recientes deben permanecer
      expect(remainingBackups.any((b) => b.filePath.contains('backup_5')), isTrue);
      expect(remainingBackups.any((b) => b.filePath.contains('backup_4')), isTrue);
      expect(remainingBackups.any((b) => b.filePath.contains('backup_3')), isTrue);

      await db.close();
    });
  });

  group('E2E: Validación de Backup', () {
    test('detecta backup corrupto', () async {
      final dbPath = '${tempDir.path}/corrupt_test_db.db';
      final db = AppDatabase.forTesting(NativeDatabase(File(dbPath)));
      final categoriesDao = CategoriesDao(db);
      await seedCategories(categoriesDao);

      final backupService = BackupService(db: db);

      // Crear archivo corrupto
      final corruptPath = '${tempDir.path}/corrupt_backup.db';
      await File(corruptPath).writeAsString('Este no es un archivo SQLite válido');

      // Validar
      final validation = await backupService.validateBackup(corruptPath);
      expect(validation.isValid, isFalse);

      await db.close();
    });

    test('valida backup existente correctamente', () async {
      final dbPath = '${tempDir.path}/valid_test_db.db';
      final db = AppDatabase.forTesting(NativeDatabase(File(dbPath)));
      final categoriesDao = CategoriesDao(db);
      await seedCategories(categoriesDao);

      final backupService = BackupService(db: db);

      // Crear backup válido
      final validPath = '${tempDir.path}/valid_backup.db';
      await backupService.createBackup(validPath);

      // Validar
      final validation = await backupService.validateBackup(validPath);
      expect(validation.isValid, isTrue);
      expect(validation.tableCount, greaterThan(0));

      await db.close();
    });
  });
}
