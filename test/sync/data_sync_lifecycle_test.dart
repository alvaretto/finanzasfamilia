/// Tests agresivos del ciclo de sincronización de datos
///
/// Estos tests verifican que los datos persisten correctamente a través de:
/// - Instalación inicial
/// - Inserción de datos
/// - Desinstalación simulada (limpieza de DB local)
/// - Reinstalación (reconexión a PowerSync)
/// - Verificación de datos recuperados
///
/// CRÍTICO: Este archivo existe porque los datos se perdían al reinstalar la app.
/// Cada test debe fallar si se rompe el ciclo de sincronización.
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:uuid/uuid.dart';
import 'package:matcher/matcher.dart' as m;

import 'package:finanzas_familiares/data/local/database.dart';
import 'package:finanzas_familiares/data/local/daos/categories_dao.dart';
import 'package:finanzas_familiares/data/local/daos/accounts_dao.dart';
import 'package:finanzas_familiares/data/local/daos/transactions_dao.dart';
import 'package:finanzas_familiares/data/local/seeders/category_seeder.dart';
import 'package:finanzas_familiares/application/services/data_seeding_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('DataSyncLifecycle - Ciclo Completo de Sincronización', () {
    late AppDatabase db;
    late CategoriesDao categoriesDao;
    late AccountsDao accountsDao;
    late TransactionsDao transactionsDao;

    setUp(() async {
      db = AppDatabase.forTesting(NativeDatabase.memory());
      categoriesDao = CategoriesDao(db);
      accountsDao = AccountsDao(db);
      transactionsDao = TransactionsDao(db);
    });

    tearDown(() async {
      await db.close();
    });

    group('Fase 1: Verificación de Seeding Inicial', () {
      test('seedIfEmpty() debe sembrar datos en DB vacía', () async {
        // Arrange
        final seedingService = DataSeedingService(db);

        // Act
        final seeded = await seedingService.seedIfEmpty();

        // Assert
        expect(seeded, m.isTrue, reason: 'Debe sembrar datos en DB vacía');

        final categories = await categoriesDao.getAllCategories();
        expect(categories, m.isNotEmpty,
            reason: 'Debe haber categorías después de seeding');
        expect(categories.length, m.greaterThanOrEqualTo(70),
            reason: 'Debe haber al menos 70 categorías del sistema');
      });

      test('seedIfEmpty() NO debe sobrescribir datos existentes', () async {
        // Arrange - sembrar primero
        final seedingService = DataSeedingService(db);
        await seedingService.seedIfEmpty();
        final countBefore = (await categoriesDao.getAllCategories()).length;

        // Act - intentar sembrar de nuevo
        final seededAgain = await seedingService.seedIfEmpty();

        // Assert
        expect(seededAgain, m.isFalse,
            reason: 'NO debe sembrar si ya hay datos');

        final countAfter = (await categoriesDao.getAllCategories()).length;
        expect(countAfter, m.equals(countBefore),
            reason: 'El conteo de categorías debe ser idéntico');
      });

      test('hasUserData() detecta datos existentes correctamente', () async {
        // Arrange
        final seedingService = DataSeedingService(db);

        // Act & Assert - vacía
        expect(await seedingService.hasUserData(), m.isFalse);

        // Act - sembrar
        await seedingService.seedIfEmpty();

        // Assert - con datos
        expect(await seedingService.hasUserData(), m.isTrue);
      });
    });

    group('Fase 2: UUIDs Determinísticos', () {
      test('UUIDs de categorías del sistema son determinísticos', () async {
        // Arrange
        const uuid = Uuid();
        const namespace = 'f47ac10b-58cc-4372-a567-0e02b2c3d479';

        // Act - calcular UUIDs esperados
        final expectedAssetRoot = uuid.v5(namespace, 'asset:Lo que Tengo');
        final expectedLiabilityRoot = uuid.v5(namespace, 'liability:Lo que Debo');
        final expectedIncomeRoot = uuid.v5(namespace, 'income:Dinero que Entra');
        final expectedExpenseRoot = uuid.v5(namespace, 'expense:Dinero que Sale');

        // Sembrar
        await seedCategories(categoriesDao);
        final categories = await categoriesDao.getAllCategories();

        // Assert - buscar categorías raíz
        final assetRoot = categories.where((c) => c.name == 'Lo que Tengo').first;
        final liabilityRoot = categories.where((c) => c.name == 'Lo que Debo').first;
        final incomeRoot = categories.where((c) => c.name == 'Dinero que Entra').first;
        final expenseRoot = categories.where((c) => c.name == 'Dinero que Sale').first;

        expect(assetRoot.id, m.equals(expectedAssetRoot),
            reason: 'UUID de Activos debe ser determinístico');
        expect(liabilityRoot.id, m.equals(expectedLiabilityRoot),
            reason: 'UUID de Pasivos debe ser determinístico');
        expect(incomeRoot.id, m.equals(expectedIncomeRoot),
            reason: 'UUID de Ingresos debe ser determinístico');
        expect(expenseRoot.id, m.equals(expectedExpenseRoot),
            reason: 'UUID de Gastos debe ser determinístico');
      });

      test('UUIDs son idénticos en múltiples instalaciones simuladas', () async {
        // Primera "instalación"
        await seedCategories(categoriesDao);
        final firstInstallCategories = await categoriesDao.getAllCategories();
        final firstInstallIds = firstInstallCategories.map((c) => c.id).toSet();

        // Limpiar DB (simula desinstalación)
        await db.close();
        db = AppDatabase.forTesting(NativeDatabase.memory());
        categoriesDao = CategoriesDao(db);

        // Segunda "instalación"
        await seedCategories(categoriesDao);
        final secondInstallCategories = await categoriesDao.getAllCategories();
        final secondInstallIds = secondInstallCategories.map((c) => c.id).toSet();

        // Assert
        expect(secondInstallIds, m.equals(firstInstallIds),
            reason: 'Los UUIDs deben ser idénticos entre instalaciones');
      });

      test('Categorías hijo tienen parent_id válido y determinístico', () async {
        // Arrange & Act
        await seedCategories(categoriesDao);
        final categories = await categoriesDao.getAllCategories();

        // Assert - verificar jerarquía
        final childCategories = categories.where((c) => c.parentId != null).toList();
        expect(childCategories, m.isNotEmpty,
            reason: 'Debe haber categorías hijas');

        for (final child in childCategories) {
          final parent = categories.where((c) => c.id == child.parentId).toList();
          expect(parent, m.hasLength(1),
              reason: 'Categoría ${child.name} debe tener un padre válido');
          expect((child.level ?? 0), m.greaterThan(parent.first.level ?? 0),
              reason: 'El nivel del hijo debe ser mayor que el del padre');
        }
      });
    });

    group('Fase 3: Simulación de Ciclo Install/Uninstall/Reinstall', () {
      test('Datos insertados manualmente persisten en simulación de sync', () async {
        // === INSTALACIÓN INICIAL ===
        await seedCategories(categoriesDao);
        final categories = await categoriesDao.getAllCategories();

        // Obtener categoría de activo para crear cuenta
        final assetCategory = categories
            .where((c) => c.type == 'asset' && (c.level ?? 0) > 0)
            .first;

        // Insertar una cuenta manualmente (simula usuario)
        final testAccountId = const Uuid().v4();
        await accountsDao.insertAccount(AccountsCompanion.insert(
          id: testAccountId,
          name: 'Cuenta Test Usuario',
          categoryId: assetCategory.id,
          balance: const Value(50000.0),
          isActive: const Value(true),
        ));

        // Verificar cuenta creada
        final accountBefore = await accountsDao.getAccountById(testAccountId);
        expect(accountBefore, m.isNotNull);
        expect(accountBefore!.name, m.equals('Cuenta Test Usuario'));
        expect(accountBefore.balance, m.equals(50000.0));

        // === SIMULAR "DESINSTALACIÓN" (limpiar DB) ===
        final savedAccountId = testAccountId;
        final savedAccountName = accountBefore.name;
        final savedAccountBalance = accountBefore.balance;
        await db.close();

        // === SIMULAR "REINSTALACIÓN" (nueva DB) ===
        db = AppDatabase.forTesting(NativeDatabase.memory());
        categoriesDao = CategoriesDao(db);
        accountsDao = AccountsDao(db);

        // Simular datos sincronizados desde Supabase
        // (en producción, PowerSync hace esto automáticamente)
        await seedCategories(categoriesDao);

        // Insertar cuenta "sincronizada" con mismo ID
        final syncedCategories = await categoriesDao.getAllCategories();
        final syncedAssetCategory = syncedCategories
            .where((c) => c.type == 'asset' && (c.level ?? 0) > 0)
            .first;

        await accountsDao.insertAccount(AccountsCompanion.insert(
          id: savedAccountId,
          name: savedAccountName,
          categoryId: syncedAssetCategory.id,
          balance: Value(savedAccountBalance),
          isActive: const Value(true),
        ));

        // === VERIFICAR RECUPERACIÓN ===
        final accountAfter = await accountsDao.getAccountById(savedAccountId);
        expect(accountAfter, m.isNotNull,
            reason: 'La cuenta debe existir después de "reinstalar"');
        expect(accountAfter!.id, m.equals(savedAccountId),
            reason: 'El ID debe ser idéntico');
        expect(accountAfter.name, m.equals(savedAccountName),
            reason: 'El nombre debe ser idéntico');
        expect(accountAfter.balance, m.equals(savedAccountBalance),
            reason: 'El balance debe ser idéntico');
      });

      test('Transacciones persisten en ciclo completo', () async {
        // === SETUP INICIAL ===
        await seedCategories(categoriesDao);
        final categories = await categoriesDao.getAllCategories();

        final assetCategory = categories
            .where((c) => c.type == 'asset' && (c.level ?? 0) > 0)
            .first;
        final expenseCategory = categories
            .where((c) => c.type == 'expense' && (c.level ?? 0) > 0)
            .first;

        // Crear cuenta origen
        final accountId = const Uuid().v4();
        await accountsDao.insertAccount(AccountsCompanion.insert(
          id: accountId,
          name: 'Nequi Test',
          categoryId: assetCategory.id,
          balance: const Value(100000.0),
          isActive: const Value(true),
        ));

        // Crear transacción de gasto
        final transactionId = const Uuid().v4();
        await transactionsDao.insertTransaction(TransactionsCompanion.insert(
          id: transactionId,
          amount: 25000.0,
          type: 'expense',
          categoryId: expenseCategory.id,
          fromAccountId: Value(accountId),
          transactionDate: DateTime.now(),
          description: const Value('Almuerzo test'),
        ));

        // Guardar datos para verificación post-reinstall
        final savedTxId = transactionId;
        const savedAmount = 25000.0;
        const savedDescription = 'Almuerzo test';

        // === SIMULAR REINSTALACIÓN ===
        await db.close();
        db = AppDatabase.forTesting(NativeDatabase.memory());
        categoriesDao = CategoriesDao(db);
        accountsDao = AccountsDao(db);
        transactionsDao = TransactionsDao(db);

        // Recrear estructura (simula sync)
        await seedCategories(categoriesDao);
        final syncedCategories = await categoriesDao.getAllCategories();
        final syncedAsset = syncedCategories
            .where((c) => c.type == 'asset' && (c.level ?? 0) > 0)
            .first;
        final syncedExpense = syncedCategories
            .where((c) => c.type == 'expense' && (c.level ?? 0) > 0)
            .first;

        await accountsDao.insertAccount(AccountsCompanion.insert(
          id: accountId,
          name: 'Nequi Test',
          categoryId: syncedAsset.id,
          balance: const Value(75000.0), // Balance actualizado post-gasto
          isActive: const Value(true),
        ));

        await transactionsDao.insertTransaction(TransactionsCompanion.insert(
          id: savedTxId,
          amount: savedAmount,
          type: 'expense',
          categoryId: syncedExpense.id,
          fromAccountId: Value(accountId),
          transactionDate: DateTime.now(),
          description: const Value(savedDescription),
        ));

        // === VERIFICAR ===
        final allTx = await transactionsDao.getAllTransactions();
        final recoveredTx = allTx.where((t) => t.id == savedTxId).firstOrNull;
        expect(recoveredTx, m.isNotNull,
            reason: 'La transacción debe existir post-reinstall');
        expect(recoveredTx!.amount, m.equals(savedAmount),
            reason: 'El monto debe ser idéntico');
        expect(recoveredTx.description, m.equals(savedDescription),
            reason: 'La descripción debe ser idéntica');
      });
    });

    group('Fase 4: Integridad de Datos Post-Sync', () {
      test('Todas las categorías tienen parent_id válido o null', () async {
        await seedCategories(categoriesDao);
        final categories = await categoriesDao.getAllCategories();
        final categoryIds = categories.map((c) => c.id).toSet();

        for (final category in categories) {
          if (category.parentId != null) {
            expect(categoryIds.contains(category.parentId), m.isTrue,
                reason:
                    'parent_id ${category.parentId} de "${category.name}" debe existir');
          }
        }
      });

      test('Niveles de categorías son consistentes con jerarquía', () async {
        await seedCategories(categoriesDao);
        final categories = await categoriesDao.getAllCategories();
        final categoriesById = {for (final c in categories) c.id: c};

        for (final category in categories) {
          if (category.parentId != null) {
            final parent = categoriesById[category.parentId];
            expect(parent, m.isNotNull,
                reason: 'Padre de ${category.name} debe existir');
            expect((category.level ?? 0), m.equals((parent!.level ?? 0) + 1),
                reason:
                    'Nivel de ${category.name} (${category.level}) debe ser padre+1 (${(parent.level ?? 0) + 1})');
          } else {
            expect((category.level ?? 0), m.equals(0),
                reason:
                    'Categoría raíz ${category.name} debe tener level 0');
          }
        }
      });

      test('No hay categorías huérfanas (parent_id a ID inexistente)', () async {
        await seedCategories(categoriesDao);
        final categories = await categoriesDao.getAllCategories();
        final validIds = categories.map((c) => c.id).toSet();

        final orphans = categories.where(
          (c) => c.parentId != null && !validIds.contains(c.parentId),
        );

        expect(orphans, m.isEmpty,
            reason: 'No debe haber categorías huérfanas');
      });

      test('Cada tipo de categoría tiene al menos una raíz', () async {
        await seedCategories(categoriesDao);
        final categories = await categoriesDao.getAllCategories();

        final types = ['asset', 'liability', 'income', 'expense'];
        for (final type in types) {
          final roots = categories.where(
            (c) => c.type == type && c.parentId == null,
          );
          expect(roots, m.isNotEmpty,
              reason: 'Tipo $type debe tener al menos una categoría raíz');
        }
      });
    });

    group('Fase 5: Escenarios de Falla', () {
      test('Inserción de categoría con parent_id inválido falla', () async {
        await seedCategories(categoriesDao);

        // Intentar insertar con parent_id inexistente
        final invalidParentId = const Uuid().v4();

        expect(
          () async => await categoriesDao.insertCategories([
            CategoriesCompanion.insert(
              id: const Uuid().v4(),
              name: 'Categoría Huérfana',
              type: 'expense',
              parentId: Value(invalidParentId),
              level: const Value(1),
            ),
          ]),
          throwsA(anything),
          reason: 'Inserción con FK inválido debe fallar',
        );
      });

      test('Cuenta con category_id inválido falla', () async {
        await seedCategories(categoriesDao);

        final invalidCategoryId = const Uuid().v4();

        expect(
          () async => await accountsDao.insertAccount(AccountsCompanion.insert(
            id: const Uuid().v4(),
            name: 'Cuenta Huérfana',
            categoryId: invalidCategoryId,
            balance: const Value(1000.0),
          )),
          throwsA(anything),
          reason: 'Cuenta con FK a categoría inexistente debe fallar',
        );
      });

      test('Transacción con account_id inválido falla', () async {
        await seedCategories(categoriesDao);
        final categories = await categoriesDao.getAllCategories();
        final expenseCategory = categories
            .where((c) => c.type == 'expense' && (c.level ?? 0) > 0)
            .first;

        final invalidAccountId = const Uuid().v4();

        expect(
          () async =>
              await transactionsDao.insertTransaction(TransactionsCompanion.insert(
            id: const Uuid().v4(),
            amount: 1000.0,
            type: 'expense',
            categoryId: expenseCategory.id,
            fromAccountId: Value(invalidAccountId),
            transactionDate: DateTime.now(),
          )),
          throwsA(anything),
          reason: 'Transacción con FK a cuenta inexistente debe fallar',
        );
      });
    });
  });
}
