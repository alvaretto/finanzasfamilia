import 'dart:io';

import 'package:drift/native.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:finanzas_familiares/application/providers/backup_provider.dart';
import 'package:finanzas_familiares/application/services/backup_service.dart';
import 'package:finanzas_familiares/data/local/database.dart';
import 'package:finanzas_familiares/data/local/daos/daos.dart';
import 'package:finanzas_familiares/data/local/seeders/seeders.dart';

/// Tests para BackupProvider
/// Gestiona estado y operaciones de backup via Riverpod
void main() {
  late AppDatabase database;
  late CategoriesDao categoriesDao;
  late Directory tempDir;

  setUp(() async {
    database = AppDatabase.forTesting(NativeDatabase.memory());
    categoriesDao = CategoriesDao(database);

    tempDir = await Directory.systemTemp.createTemp('backup_provider_test_');

    await seedCategories(categoriesDao);
  });

  tearDown(() async {
    await database.close();
    if (await tempDir.exists()) {
      await tempDir.delete(recursive: true);
    }
  });

  group('BackupState', () {
    test('estado inicial correcto', () {
      // Act
      const state = BackupState();

      // Assert
      expect(state.isCreatingBackup, isFalse);
      expect(state.isRestoringBackup, isFalse);
      expect(state.lastBackupTime, isNull);
      expect(state.backups, isEmpty);
      expect(state.error, isNull);
    });

    test('copyWith actualiza valores', () {
      // Arrange
      const original = BackupState();

      // Act
      final updated = original.copyWith(
        isCreatingBackup: true,
        lastBackupTime: DateTime(2024, 6, 15),
      );

      // Assert
      expect(updated.isCreatingBackup, isTrue);
      expect(updated.lastBackupTime, equals(DateTime(2024, 6, 15)));
      expect(original.isCreatingBackup, isFalse);
    });

    test('hasRecentBackup detecta backup reciente', () {
      // Arrange
      final recentState = BackupState(
        lastBackupTime: DateTime.now().subtract(const Duration(hours: 12)),
      );
      final oldState = BackupState(
        lastBackupTime: DateTime.now().subtract(const Duration(days: 2)),
      );
      const noBackupState = BackupState();

      // Assert
      expect(recentState.hasRecentBackup, isTrue);
      expect(oldState.hasRecentBackup, isFalse);
      expect(noBackupState.hasRecentBackup, isFalse);
    });
  });

  group('BackupNotifier', () {
    test('createBackup actualiza estado correctamente', () async {
      // Arrange
      final container = ProviderContainer(
        overrides: [
          backupServiceProvider.overrideWith((ref) => BackupService(db: database)),
          backupDirectoryProvider.overrideWithValue(tempDir.path),
        ],
      );
      addTearDown(container.dispose);

      // Act
      await container.read(backupProvider.notifier).createBackup();

      // Assert
      final state = container.read(backupProvider);
      expect(state.lastBackupTime, isNotNull);
      expect(state.error, isNull);
    });

    test('loadBackups carga lista de backups', () async {
      // Arrange
      final backupService = BackupService(db: database);
      await backupService.createBackup('${tempDir.path}/backup1.db');
      await backupService.createBackup('${tempDir.path}/backup2.db');

      final container = ProviderContainer(
        overrides: [
          backupServiceProvider.overrideWith((ref) => backupService),
          backupDirectoryProvider.overrideWithValue(tempDir.path),
        ],
      );
      addTearDown(container.dispose);

      // Act
      await container.read(backupProvider.notifier).loadBackups();

      // Assert
      final state = container.read(backupProvider);
      expect(state.backups.length, equals(2));
    });

    test('deleteBackup elimina backup y actualiza lista', () async {
      // Arrange
      final backupService = BackupService(db: database);
      final result = await backupService.createBackup('${tempDir.path}/to_delete.db');

      final container = ProviderContainer(
        overrides: [
          backupServiceProvider.overrideWith((ref) => backupService),
          backupDirectoryProvider.overrideWithValue(tempDir.path),
        ],
      );
      addTearDown(container.dispose);

      await container.read(backupProvider.notifier).loadBackups();
      expect(container.read(backupProvider).backups.length, equals(1));

      // Act
      await container.read(backupProvider.notifier).deleteBackup(result.filePath);

      // Assert
      final state = container.read(backupProvider);
      expect(state.backups, isEmpty);
    });

    test('setError establece mensaje de error', () {
      // Arrange
      final container = ProviderContainer(
        overrides: [
          backupServiceProvider.overrideWith((ref) => BackupService(db: database)),
          backupDirectoryProvider.overrideWithValue(tempDir.path),
        ],
      );
      addTearDown(container.dispose);

      // Act
      container.read(backupProvider.notifier).setError('Test error');

      // Assert
      expect(container.read(backupProvider).error, equals('Test error'));
    });

    test('clearError limpia mensaje de error', () {
      // Arrange
      final container = ProviderContainer(
        overrides: [
          backupServiceProvider.overrideWith((ref) => BackupService(db: database)),
          backupDirectoryProvider.overrideWithValue(tempDir.path),
        ],
      );
      addTearDown(container.dispose);

      container.read(backupProvider.notifier).setError('Test error');

      // Act
      container.read(backupProvider.notifier).clearError();

      // Assert
      expect(container.read(backupProvider).error, isNull);
    });
  });

  group('Providers Derivados', () {
    test('hasRecentBackupProvider refleja estado', () {
      // Arrange
      final container = ProviderContainer(
        overrides: [
          backupServiceProvider.overrideWith((ref) => BackupService(db: database)),
          backupDirectoryProvider.overrideWithValue(tempDir.path),
        ],
      );
      addTearDown(container.dispose);

      // Assert - sin backup
      expect(container.read(hasRecentBackupProvider), isFalse);
    });

    test('backupCountProvider cuenta backups', () async {
      // Arrange
      final backupService = BackupService(db: database);
      await backupService.createBackup('${tempDir.path}/count1.db');
      await backupService.createBackup('${tempDir.path}/count2.db');
      await backupService.createBackup('${tempDir.path}/count3.db');

      final container = ProviderContainer(
        overrides: [
          backupServiceProvider.overrideWith((ref) => backupService),
          backupDirectoryProvider.overrideWithValue(tempDir.path),
        ],
      );
      addTearDown(container.dispose);

      await container.read(backupProvider.notifier).loadBackups();

      // Assert
      expect(container.read(backupCountProvider), equals(3));
    });
  });
}
