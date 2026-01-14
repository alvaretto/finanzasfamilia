import 'package:drift/drift.dart' hide isNull, isNotNull;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:uuid/uuid.dart';

import 'package:finanzas_familiares/data/local/database.dart';
import 'package:finanzas_familiares/data/local/daos/accounts_dao.dart';
import 'package:finanzas_familiares/data/local/daos/categories_dao.dart';
import 'package:finanzas_familiares/data/repositories/drift_financial_indicators_repository.dart';
import 'package:finanzas_familiares/domain/services/financial_indicators_service.dart';

void main() {
  late AppDatabase db;
  late AccountsDao accountsDao;
  late CategoriesDao categoriesDao;
  late DriftAccountDataRepository repository;
  const uuid = Uuid();

  setUp(() async {
    db = AppDatabase.forTesting(NativeDatabase.memory());
    accountsDao = AccountsDao(db);
    categoriesDao = CategoriesDao(db);
    repository = DriftAccountDataRepository(
      accountsDao: accountsDao,
      categoriesDao: categoriesDao,
    );
  });

  tearDown(() async {
    await db.close();
  });

  group('DriftAccountDataRepository - getAllAccountBalances', () {
    test('retorna lista vacía sin cuentas', () async {
      final balances = await repository.getAllAccountBalances();
      expect(balances, isEmpty);
    });

    test('retorna balances de cuentas activas', () async {
      final categoryId = uuid.v4();
      final accountId1 = uuid.v4();
      final accountId2 = uuid.v4();

      // Crear categoría
      await db.into(db.categories).insert(CategoriesCompanion(
            id: Value(categoryId),
            name: const Value('Activos'),
            type: const Value('asset'),
            level: const Value(1),
            createdAt: Value(DateTime.now()),
            updatedAt: Value(DateTime.now()),
          ));

      // Crear cuentas
      await db.into(db.accounts).insert(AccountsCompanion(
            id: Value(accountId1),
            name: const Value('Nequi'),
            categoryId: Value(categoryId),
            balance: const Value(1000000),
            isActive: const Value(true),
            createdAt: Value(DateTime.now()),
            updatedAt: Value(DateTime.now()),
          ));

      await db.into(db.accounts).insert(AccountsCompanion(
            id: Value(accountId2),
            name: const Value('Efectivo'),
            categoryId: Value(categoryId),
            balance: const Value(500000),
            isActive: const Value(true),
            createdAt: Value(DateTime.now()),
            updatedAt: Value(DateTime.now()),
          ));

      final balances = await repository.getAllAccountBalances();

      expect(balances, hasLength(2));
      expect(balances.map((b) => b.balance), containsAll([1000000, 500000]));
    });

    test('solo retorna cuentas activas', () async {
      final categoryId = uuid.v4();

      await db.into(db.categories).insert(CategoriesCompanion(
            id: Value(categoryId),
            name: const Value('Activos'),
            type: const Value('asset'),
            level: const Value(1),
            createdAt: Value(DateTime.now()),
            updatedAt: Value(DateTime.now()),
          ));

      // Cuenta activa
      await db.into(db.accounts).insert(AccountsCompanion(
            id: Value(uuid.v4()),
            name: const Value('Activa'),
            categoryId: Value(categoryId),
            balance: const Value(1000000),
            isActive: const Value(true),
            createdAt: Value(DateTime.now()),
            updatedAt: Value(DateTime.now()),
          ));

      // Cuenta inactiva
      await db.into(db.accounts).insert(AccountsCompanion(
            id: Value(uuid.v4()),
            name: const Value('Inactiva'),
            categoryId: Value(categoryId),
            balance: const Value(500000),
            isActive: const Value(false),
            createdAt: Value(DateTime.now()),
            updatedAt: Value(DateTime.now()),
          ));

      final balances = await repository.getAllAccountBalances();

      expect(balances, hasLength(1));
      expect(balances.first.balance, equals(1000000));
    });

    test('retorna AccountBalance con campos correctos', () async {
      final categoryId = uuid.v4();
      final accountId = uuid.v4();

      await db.into(db.categories).insert(CategoriesCompanion(
            id: Value(categoryId),
            name: const Value('Activos'),
            type: const Value('asset'),
            level: const Value(1),
            createdAt: Value(DateTime.now()),
            updatedAt: Value(DateTime.now()),
          ));

      await db.into(db.accounts).insert(AccountsCompanion(
            id: Value(accountId),
            name: const Value('Test'),
            categoryId: Value(categoryId),
            balance: const Value(750000),
            isActive: const Value(true),
            createdAt: Value(DateTime.now()),
            updatedAt: Value(DateTime.now()),
          ));

      final balances = await repository.getAllAccountBalances();

      expect(balances, hasLength(1));
      final balance = balances.first;
      expect(balance.id, equals(accountId));
      expect(balance.categoryId, equals(categoryId));
      expect(balance.balance, equals(750000));
    });

    test('maneja balances negativos', () async {
      final categoryId = uuid.v4();

      await db.into(db.categories).insert(CategoriesCompanion(
            id: Value(categoryId),
            name: const Value('Pasivos'),
            type: const Value('liability'),
            level: const Value(1),
            createdAt: Value(DateTime.now()),
            updatedAt: Value(DateTime.now()),
          ));

      await db.into(db.accounts).insert(AccountsCompanion(
            id: Value(uuid.v4()),
            name: const Value('Tarjeta Crédito'),
            categoryId: Value(categoryId),
            balance: const Value(-500000),
            isActive: const Value(true),
            createdAt: Value(DateTime.now()),
            updatedAt: Value(DateTime.now()),
          ));

      final balances = await repository.getAllAccountBalances();

      expect(balances.first.balance, equals(-500000));
    });
  });

  group('DriftAccountDataRepository - getCategoriesByType', () {
    test('retorna lista vacía sin categorías del tipo', () async {
      // Solo crear categoría de tipo 'asset'
      await db.into(db.categories).insert(CategoriesCompanion(
            id: Value(uuid.v4()),
            name: const Value('Activos'),
            type: const Value('asset'),
            level: const Value(1),
            createdAt: Value(DateTime.now()),
            updatedAt: Value(DateTime.now()),
          ));

      final categories = await repository.getCategoriesByType('liability');

      expect(categories, isEmpty);
    });

    test('retorna categorías del tipo especificado', () async {
      // Crear categorías de tipo asset
      await db.into(db.categories).insert(CategoriesCompanion(
            id: Value(uuid.v4()),
            name: const Value('Efectivo'),
            type: const Value('asset'),
            level: const Value(2),
            createdAt: Value(DateTime.now()),
            updatedAt: Value(DateTime.now()),
          ));

      await db.into(db.categories).insert(CategoriesCompanion(
            id: Value(uuid.v4()),
            name: const Value('Banco'),
            type: const Value('asset'),
            level: const Value(2),
            createdAt: Value(DateTime.now()),
            updatedAt: Value(DateTime.now()),
          ));

      // Crear categoría de otro tipo
      await db.into(db.categories).insert(CategoriesCompanion(
            id: Value(uuid.v4()),
            name: const Value('Tarjetas'),
            type: const Value('liability'),
            level: const Value(2),
            createdAt: Value(DateTime.now()),
            updatedAt: Value(DateTime.now()),
          ));

      final assetCategories = await repository.getCategoriesByType('asset');
      final liabilityCategories = await repository.getCategoriesByType('liability');

      expect(assetCategories, hasLength(2));
      expect(liabilityCategories, hasLength(1));
    });

    test('retorna CategoryInfo con campos correctos', () async {
      final categoryId = uuid.v4();

      await db.into(db.categories).insert(CategoriesCompanion(
            id: Value(categoryId),
            name: const Value('Billeteras Digitales'),
            type: const Value('asset'),
            level: const Value(2),
            createdAt: Value(DateTime.now()),
            updatedAt: Value(DateTime.now()),
          ));

      final categories = await repository.getCategoriesByType('asset');

      expect(categories, hasLength(1));
      final category = categories.first;
      expect(category.id, equals(categoryId));
      expect(category.name, equals('Billeteras Digitales'));
      expect(category.type, equals('asset'));
    });

    test('filtra por tipo income', () async {
      await db.into(db.categories).insert(CategoriesCompanion(
            id: Value(uuid.v4()),
            name: const Value('Salario'),
            type: const Value('income'),
            level: const Value(2),
            createdAt: Value(DateTime.now()),
            updatedAt: Value(DateTime.now()),
          ));

      await db.into(db.categories).insert(CategoriesCompanion(
            id: Value(uuid.v4()),
            name: const Value('Freelance'),
            type: const Value('income'),
            level: const Value(2),
            createdAt: Value(DateTime.now()),
            updatedAt: Value(DateTime.now()),
          ));

      final categories = await repository.getCategoriesByType('income');

      expect(categories, hasLength(2));
      expect(categories.map((c) => c.name), containsAll(['Salario', 'Freelance']));
    });

    test('filtra por tipo expense', () async {
      await db.into(db.categories).insert(CategoriesCompanion(
            id: Value(uuid.v4()),
            name: const Value('Alimentación'),
            type: const Value('expense'),
            level: const Value(2),
            createdAt: Value(DateTime.now()),
            updatedAt: Value(DateTime.now()),
          ));

      final categories = await repository.getCategoriesByType('expense');

      expect(categories, hasLength(1));
      expect(categories.first.name, equals('Alimentación'));
    });
  });

  group('DriftAccountDataRepository implements AccountDataRepository', () {
    test('es instancia de AccountDataRepository', () {
      expect(repository, isA<AccountDataRepository>());
    });

    test('puede ser usado con FinancialIndicatorsService', () async {
      final categoryId = uuid.v4();

      // Crear categoría
      await db.into(db.categories).insert(CategoriesCompanion(
            id: Value(categoryId),
            name: const Value('Banco Ahorros'),
            type: const Value('asset'),
            level: const Value(2),
            createdAt: Value(DateTime.now()),
            updatedAt: Value(DateTime.now()),
          ));

      // Crear cuenta
      await db.into(db.accounts).insert(AccountsCompanion(
            id: Value(uuid.v4()),
            name: const Value('Cuenta'),
            categoryId: Value(categoryId),
            balance: const Value(1000000),
            isActive: const Value(true),
            createdAt: Value(DateTime.now()),
            updatedAt: Value(DateTime.now()),
          ));

      // Usar con servicio
      final service = FinancialIndicatorsService(repository: repository);
      final result = await service.calculateDebtCoverage();

      expect(result.availableCash, equals(1000000));
      expect(result.immediateDebts, equals(0));
    });
  });
}
