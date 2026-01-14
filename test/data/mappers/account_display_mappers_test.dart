import 'package:drift/drift.dart' hide isNull, isNotNull;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:uuid/uuid.dart';

import 'package:finanzas_familiares/data/local/database.dart';
import 'package:finanzas_familiares/data/mappers/account_display_mappers.dart';
import 'package:finanzas_familiares/domain/entities/accounts/account_display_dto.dart';

void main() {
  late AppDatabase db;
  const uuid = Uuid();

  setUp(() async {
    db = AppDatabase.forTesting(NativeDatabase.memory());
  });

  tearDown(() async {
    await db.close();
  });

  group('AccountDisplayMappers.accountToDto', () {
    test('convierte AccountEntry a AccountDisplayDto correctamente', () async {
      final categoryId = uuid.v4();
      final accountId = uuid.v4();

      // Crear categoría base
      await db.into(db.categories).insert(CategoriesCompanion(
            id: Value(categoryId),
            name: const Value('Activos'),
            type: const Value('asset'),
            level: const Value(1),
            createdAt: Value(DateTime.now()),
            updatedAt: Value(DateTime.now()),
          ));

      // Crear cuenta
      await db.into(db.accounts).insert(AccountsCompanion(
            id: Value(accountId),
            name: const Value('Nequi'),
            icon: const Value('💜'),
            color: const Value('#6A1B9A'),
            balance: const Value(1500000),
            categoryId: Value(categoryId),
            isSystem: const Value(false),
            isActive: const Value(true),
            includeInTotal: const Value(true),
            description: const Value('Mi billetera Nequi'),
            currency: const Value('COP'),
            createdAt: Value(DateTime.now()),
            updatedAt: Value(DateTime.now()),
          ));

      final accountEntry =
          await (db.select(db.accounts)..where((a) => a.id.equals(accountId)))
              .getSingle();

      final dto = AccountDisplayMappers.accountToDto(accountEntry);

      expect(dto.id, equals(accountId));
      expect(dto.name, equals('Nequi'));
      expect(dto.icon, equals('💜'));
      expect(dto.color, equals('#6A1B9A'));
      expect(dto.balance, equals(1500000));
      expect(dto.categoryId, equals(categoryId));
      expect(dto.isSystem, isFalse);
      expect(dto.isActive, isTrue);
      expect(dto.includeInTotal, isTrue);
      expect(dto.description, equals('Mi billetera Nequi'));
      expect(dto.currency, equals('COP'));
    });

    test('maneja campos opcionales nulos', () async {
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
            name: const Value('Cuenta Básica'),
            categoryId: Value(categoryId),
            balance: const Value(0),
            createdAt: Value(DateTime.now()),
            updatedAt: Value(DateTime.now()),
            // icon, color, description son opcionales
          ));

      final accountEntry =
          await (db.select(db.accounts)..where((a) => a.id.equals(accountId)))
              .getSingle();

      final dto = AccountDisplayMappers.accountToDto(accountEntry);

      expect(dto.icon, isNull);
      expect(dto.color, isNull);
      expect(dto.description, isNull);
    });

    test('conserva isSystem flag', () async {
      final categoryId = uuid.v4();
      final accountId = uuid.v4();

      await db.into(db.categories).insert(CategoriesCompanion(
            id: Value(categoryId),
            name: const Value('Sistema'),
            type: const Value('asset'),
            level: const Value(1),
            createdAt: Value(DateTime.now()),
            updatedAt: Value(DateTime.now()),
          ));

      await db.into(db.accounts).insert(AccountsCompanion(
            id: Value(accountId),
            name: const Value('Cuenta Sistema'),
            categoryId: Value(categoryId),
            balance: const Value(0),
            isSystem: const Value(true),
            createdAt: Value(DateTime.now()),
            updatedAt: Value(DateTime.now()),
          ));

      final accountEntry =
          await (db.select(db.accounts)..where((a) => a.id.equals(accountId)))
              .getSingle();

      final dto = AccountDisplayMappers.accountToDto(accountEntry);

      expect(dto.isSystem, isTrue);
    });
  });

  group('AccountDisplayMappers.accountsToDtoList', () {
    test('convierte lista de cuentas', () async {
      final categoryId = uuid.v4();

      await db.into(db.categories).insert(CategoriesCompanion(
            id: Value(categoryId),
            name: const Value('Activos'),
            type: const Value('asset'),
            level: const Value(1),
            createdAt: Value(DateTime.now()),
            updatedAt: Value(DateTime.now()),
          ));

      // Insertar múltiples cuentas
      for (var i = 0; i < 3; i++) {
        await db.into(db.accounts).insert(AccountsCompanion(
              id: Value(uuid.v4()),
              name: Value('Cuenta $i'),
              categoryId: Value(categoryId),
              balance: Value((i + 1) * 100000.0),
              createdAt: Value(DateTime.now()),
              updatedAt: Value(DateTime.now()),
            ));
      }

      final entries = await db.select(db.accounts).get();
      final dtos = AccountDisplayMappers.accountsToDtoList(entries);

      expect(dtos, hasLength(3));
      expect(dtos, everyElement(isA<AccountDisplayDto>()));
    });

    test('retorna lista vacía para input vacío', () {
      final dtos = AccountDisplayMappers.accountsToDtoList([]);

      expect(dtos, isEmpty);
    });

    test('preserva orden de entrada', () async {
      final categoryId = uuid.v4();

      await db.into(db.categories).insert(CategoriesCompanion(
            id: Value(categoryId),
            name: const Value('Activos'),
            type: const Value('asset'),
            level: const Value(1),
            createdAt: Value(DateTime.now()),
            updatedAt: Value(DateTime.now()),
          ));

      final names = ['Alpha', 'Beta', 'Gamma'];
      for (final name in names) {
        await db.into(db.accounts).insert(AccountsCompanion(
              id: Value(uuid.v4()),
              name: Value(name),
              categoryId: Value(categoryId),
              balance: const Value(0),
              createdAt: Value(DateTime.now()),
              updatedAt: Value(DateTime.now()),
            ));
      }

      final entries =
          await (db.select(db.accounts)..orderBy([(a) => OrderingTerm(expression: a.name)])).get();
      final dtos = AccountDisplayMappers.accountsToDtoList(entries);

      expect(dtos[0].name, equals('Alpha'));
      expect(dtos[1].name, equals('Beta'));
      expect(dtos[2].name, equals('Gamma'));
    });
  });

  group('AccountDisplayMappers.accountWithCategoryToDto', () {
    test('combina cuenta y categoría correctamente', () async {
      final categoryId = uuid.v4();
      final accountId = uuid.v4();

      await db.into(db.categories).insert(CategoriesCompanion(
            id: Value(categoryId),
            name: const Value('Billeteras Digitales'),
            type: const Value('asset'),
            level: const Value(2),
            createdAt: Value(DateTime.now()),
            updatedAt: Value(DateTime.now()),
          ));

      await db.into(db.accounts).insert(AccountsCompanion(
            id: Value(accountId),
            name: const Value('Nequi'),
            categoryId: Value(categoryId),
            balance: const Value(500000),
            createdAt: Value(DateTime.now()),
            updatedAt: Value(DateTime.now()),
          ));

      final accountEntry =
          await (db.select(db.accounts)..where((a) => a.id.equals(accountId)))
              .getSingle();
      final categoryEntry = await (db.select(db.categories)
            ..where((c) => c.id.equals(categoryId)))
          .getSingle();

      final dto = AccountDisplayMappers.accountWithCategoryToDto(
        accountEntry,
        categoryEntry,
      );

      expect(dto.account.name, equals('Nequi'));
      expect(dto.categoryName, equals('Billeteras Digitales'));
      expect(dto.categoryType, equals('asset'));
    });

    test('maneja categoría null con valores por defecto', () async {
      final categoryId = uuid.v4();
      final accountId = uuid.v4();

      await db.into(db.categories).insert(CategoriesCompanion(
            id: Value(categoryId),
            name: const Value('Temp'),
            type: const Value('asset'),
            level: const Value(1),
            createdAt: Value(DateTime.now()),
            updatedAt: Value(DateTime.now()),
          ));

      await db.into(db.accounts).insert(AccountsCompanion(
            id: Value(accountId),
            name: const Value('Cuenta Huérfana'),
            categoryId: Value(categoryId),
            balance: const Value(0),
            createdAt: Value(DateTime.now()),
            updatedAt: Value(DateTime.now()),
          ));

      final accountEntry =
          await (db.select(db.accounts)..where((a) => a.id.equals(accountId)))
              .getSingle();

      // Pasar null como categoría
      final dto = AccountDisplayMappers.accountWithCategoryToDto(
        accountEntry,
        null,
      );

      expect(dto.categoryName, equals('Sin categoría'));
      expect(dto.categoryType, equals('asset'));
    });

    test('tipo de categoría se preserva (liability)', () async {
      final categoryId = uuid.v4();
      final accountId = uuid.v4();

      await db.into(db.categories).insert(CategoriesCompanion(
            id: Value(categoryId),
            name: const Value('Tarjetas de Crédito'),
            type: const Value('liability'),
            level: const Value(2),
            createdAt: Value(DateTime.now()),
            updatedAt: Value(DateTime.now()),
          ));

      await db.into(db.accounts).insert(AccountsCompanion(
            id: Value(accountId),
            name: const Value('Visa'),
            categoryId: Value(categoryId),
            balance: const Value(-500000),
            createdAt: Value(DateTime.now()),
            updatedAt: Value(DateTime.now()),
          ));

      final accountEntry =
          await (db.select(db.accounts)..where((a) => a.id.equals(accountId)))
              .getSingle();
      final categoryEntry = await (db.select(db.categories)
            ..where((c) => c.id.equals(categoryId)))
          .getSingle();

      final dto = AccountDisplayMappers.accountWithCategoryToDto(
        accountEntry,
        categoryEntry,
      );

      expect(dto.categoryType, equals('liability'));
    });
  });

  group('AccountDisplayDto', () {
    test('constructor con valores requeridos', () {
      const dto = AccountDisplayDto(
        id: 'acc-1',
        name: 'Cuenta Test',
        balance: 1000,
        categoryId: 'cat-1',
        isSystem: false,
        isActive: true,
        includeInTotal: true,
      );

      expect(dto.id, equals('acc-1'));
      expect(dto.currency, equals('COP')); // default value
    });

    test('constructor con todos los valores', () {
      const dto = AccountDisplayDto(
        id: 'acc-1',
        name: 'Cuenta Completa',
        icon: '💰',
        color: '#FF0000',
        balance: 2500000,
        categoryId: 'cat-1',
        isSystem: true,
        isActive: false,
        includeInTotal: false,
        description: 'Descripción completa',
        currency: 'USD',
      );

      expect(dto.icon, equals('💰'));
      expect(dto.color, equals('#FF0000'));
      expect(dto.description, equals('Descripción completa'));
      expect(dto.currency, equals('USD'));
    });
  });

  group('AccountWithCategoryDto', () {
    test('constructor funciona correctamente', () {
      const account = AccountDisplayDto(
        id: 'acc-1',
        name: 'Test',
        balance: 0,
        categoryId: 'cat-1',
        isSystem: false,
        isActive: true,
        includeInTotal: true,
      );

      const dto = AccountWithCategoryDto(
        account: account,
        categoryName: 'Activos Líquidos',
        categoryType: 'asset',
      );

      expect(dto.account.id, equals('acc-1'));
      expect(dto.categoryName, equals('Activos Líquidos'));
      expect(dto.categoryType, equals('asset'));
    });
  });
}
