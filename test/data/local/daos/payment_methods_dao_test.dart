import 'package:drift/drift.dart' hide isNull, isNotNull;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:uuid/uuid.dart';

import 'package:finanzas_familiares/data/local/database.dart';
import 'package:finanzas_familiares/data/local/daos/payment_methods_dao.dart';

void main() {
  late AppDatabase db;
  late PaymentMethodsDao dao;
  const uuid = Uuid();
  late String accountId;
  late String categoryId;

  setUp(() async {
    db = AppDatabase.forTesting(NativeDatabase.memory());
    dao = PaymentMethodsDao(db);

    // Crear datos base para foreign keys
    categoryId = uuid.v4();
    accountId = uuid.v4();

    // Insertar categoría
    await db.into(db.categories).insert(CategoriesCompanion(
          id: Value(categoryId),
          name: const Value('Activos'),
          type: const Value('asset'),
          level: const Value(1),
          createdAt: Value(DateTime.now()),
          updatedAt: Value(DateTime.now()),
        ));

    // Insertar cuenta
    await db.into(db.accounts).insert(AccountsCompanion(
          id: Value(accountId),
          name: const Value('Nequi'),
          categoryId: Value(categoryId),
          balance: const Value(1000000),
          createdAt: Value(DateTime.now()),
          updatedAt: Value(DateTime.now()),
        ));
  });

  tearDown(() async {
    await db.close();
  });

  group('PaymentMethodsDao - CRUD', () {
    test('insertMethod crea un método de pago correctamente', () async {
      final methodId = uuid.v4();
      await dao.insertMethod(PaymentMethodsCompanion(
        id: Value(methodId),
        name: const Value('Tarjeta Personal'),
        accountId: Value(accountId),
        icon: const Value('💳'),
        isDefault: const Value(false),
        isActive: const Value(true),
        sortOrder: const Value(0),
        createdAt: Value(DateTime.now()),
        updatedAt: Value(DateTime.now()),
      ));

      final method = await dao.getMethodById(methodId);
      expect(method, isNotNull);
      expect(method!.name, equals('Tarjeta Personal'));
      expect(method.accountId, equals(accountId));
      expect(method.icon, equals('💳'));
    });

    test('insertMethods inserta múltiples métodos', () async {
      final methods = List.generate(
        3,
        (i) => PaymentMethodsCompanion(
          id: Value(uuid.v4()),
          name: Value('Método $i'),
          accountId: Value(accountId),
          isDefault: Value(i == 0),
          isActive: const Value(true),
          sortOrder: Value(i),
          createdAt: Value(DateTime.now()),
          updatedAt: Value(DateTime.now()),
        ),
      );

      await dao.insertMethods(methods);
      final result = await dao.getAllMethods();

      expect(result, hasLength(3));
    });

    test('getMethodById retorna null para ID inexistente', () async {
      final result = await dao.getMethodById('non-existent');
      expect(result, isNull);
    });

    test('updateMethod actualiza correctamente', () async {
      final methodId = uuid.v4();
      await dao.insertMethod(PaymentMethodsCompanion(
        id: Value(methodId),
        name: const Value('Original'),
        accountId: Value(accountId),
        isDefault: const Value(false),
        isActive: const Value(true),
        sortOrder: const Value(0),
        createdAt: Value(DateTime.now()),
        updatedAt: Value(DateTime.now()),
      ));

      final original = await dao.getMethodById(methodId);
      final updated = PaymentMethodEntry(
        id: original!.id,
        name: 'Actualizado',
        accountId: original.accountId,
        icon: '🔄',
        color: original.color,
        isDefault: original.isDefault,
        isActive: original.isActive,
        sortOrder: original.sortOrder,
        createdAt: original.createdAt,
        updatedAt: DateTime.now(),
      );

      await dao.updateMethod(updated);
      final result = await dao.getMethodById(methodId);

      expect(result!.name, equals('Actualizado'));
      expect(result.icon, equals('🔄'));
    });

    test('deactivateMethod desactiva un método (soft delete)', () async {
      final methodId = uuid.v4();
      await dao.insertMethod(PaymentMethodsCompanion(
        id: Value(methodId),
        name: const Value('A desactivar'),
        accountId: Value(accountId),
        isDefault: const Value(false),
        isActive: const Value(true),
        sortOrder: const Value(0),
        createdAt: Value(DateTime.now()),
        updatedAt: Value(DateTime.now()),
      ));

      final count = await dao.deactivateMethod(methodId);
      expect(count, equals(1));

      final result = await dao.getMethodById(methodId);
      expect(result!.isActive, isFalse);
    });
  });

  group('PaymentMethodsDao - Consultas', () {
    test('getAllActiveMethods solo retorna métodos activos', () async {
      await dao.insertMethods([
        PaymentMethodsCompanion(
          id: Value(uuid.v4()),
          name: const Value('Activo 1'),
          accountId: Value(accountId),
          isActive: const Value(true),
          isDefault: const Value(false),
          sortOrder: const Value(0),
          createdAt: Value(DateTime.now()),
          updatedAt: Value(DateTime.now()),
        ),
        PaymentMethodsCompanion(
          id: Value(uuid.v4()),
          name: const Value('Inactivo'),
          accountId: Value(accountId),
          isActive: const Value(false),
          isDefault: const Value(false),
          sortOrder: const Value(1),
          createdAt: Value(DateTime.now()),
          updatedAt: Value(DateTime.now()),
        ),
        PaymentMethodsCompanion(
          id: Value(uuid.v4()),
          name: const Value('Activo 2'),
          accountId: Value(accountId),
          isActive: const Value(true),
          isDefault: const Value(false),
          sortOrder: const Value(2),
          createdAt: Value(DateTime.now()),
          updatedAt: Value(DateTime.now()),
        ),
      ]);

      final result = await dao.getAllActiveMethods();

      expect(result, hasLength(2));
      expect(result.every((m) => m.isActive ?? true), isTrue);
    });

    test('getAllActiveMethods ordena por isDefault primero', () async {
      await dao.insertMethods([
        PaymentMethodsCompanion(
          id: Value(uuid.v4()),
          name: const Value('Normal'),
          accountId: Value(accountId),
          isActive: const Value(true),
          isDefault: const Value(false),
          sortOrder: const Value(0),
          createdAt: Value(DateTime.now()),
          updatedAt: Value(DateTime.now()),
        ),
        PaymentMethodsCompanion(
          id: Value(uuid.v4()),
          name: const Value('Default'),
          accountId: Value(accountId),
          isActive: const Value(true),
          isDefault: const Value(true),
          sortOrder: const Value(1),
          createdAt: Value(DateTime.now()),
          updatedAt: Value(DateTime.now()),
        ),
      ]);

      final result = await dao.getAllActiveMethods();

      expect(result.first.name, equals('Default'));
      expect(result.first.isDefault, isTrue);
    });

    test('getDefaultMethod retorna el método por defecto activo', () async {
      await dao.insertMethods([
        PaymentMethodsCompanion(
          id: Value(uuid.v4()),
          name: const Value('Normal'),
          accountId: Value(accountId),
          isActive: const Value(true),
          isDefault: const Value(false),
          sortOrder: const Value(0),
          createdAt: Value(DateTime.now()),
          updatedAt: Value(DateTime.now()),
        ),
        PaymentMethodsCompanion(
          id: Value(uuid.v4()),
          name: const Value('El Default'),
          accountId: Value(accountId),
          isActive: const Value(true),
          isDefault: const Value(true),
          sortOrder: const Value(1),
          createdAt: Value(DateTime.now()),
          updatedAt: Value(DateTime.now()),
        ),
      ]);

      final result = await dao.getDefaultMethod();

      expect(result, isNotNull);
      expect(result!.name, equals('El Default'));
      expect(result.isDefault, isTrue);
    });

    test('getDefaultMethod retorna null si no hay default', () async {
      await dao.insertMethod(PaymentMethodsCompanion(
        id: Value(uuid.v4()),
        name: const Value('Sin default'),
        accountId: Value(accountId),
        isActive: const Value(true),
        isDefault: const Value(false),
        sortOrder: const Value(0),
        createdAt: Value(DateTime.now()),
        updatedAt: Value(DateTime.now()),
      ));

      final result = await dao.getDefaultMethod();
      expect(result, isNull);
    });

    test('getDefaultMethod ignora default inactivo', () async {
      await dao.insertMethod(PaymentMethodsCompanion(
        id: Value(uuid.v4()),
        name: const Value('Default Inactivo'),
        accountId: Value(accountId),
        isActive: const Value(false),
        isDefault: const Value(true),
        sortOrder: const Value(0),
        createdAt: Value(DateTime.now()),
        updatedAt: Value(DateTime.now()),
      ));

      final result = await dao.getDefaultMethod();
      expect(result, isNull);
    });

    test('getMethodsByAccount filtra por cuenta', () async {
      final otherAccountId = uuid.v4();
      await db.into(db.accounts).insert(AccountsCompanion(
            id: Value(otherAccountId),
            name: const Value('Otra Cuenta'),
            categoryId: Value(categoryId),
            balance: const Value(500000),
            createdAt: Value(DateTime.now()),
            updatedAt: Value(DateTime.now()),
          ));

      await dao.insertMethods([
        PaymentMethodsCompanion(
          id: Value(uuid.v4()),
          name: const Value('Método Cuenta 1'),
          accountId: Value(accountId),
          isActive: const Value(true),
          isDefault: const Value(false),
          sortOrder: const Value(0),
          createdAt: Value(DateTime.now()),
          updatedAt: Value(DateTime.now()),
        ),
        PaymentMethodsCompanion(
          id: Value(uuid.v4()),
          name: const Value('Método Otra Cuenta'),
          accountId: Value(otherAccountId),
          isActive: const Value(true),
          isDefault: const Value(false),
          sortOrder: const Value(1),
          createdAt: Value(DateTime.now()),
          updatedAt: Value(DateTime.now()),
        ),
      ]);

      final result = await dao.getMethodsByAccount(accountId);

      expect(result, hasLength(1));
      expect(result.first.name, equals('Método Cuenta 1'));
    });

    test('getMethodsByAccount solo retorna activos', () async {
      await dao.insertMethods([
        PaymentMethodsCompanion(
          id: Value(uuid.v4()),
          name: const Value('Activo'),
          accountId: Value(accountId),
          isActive: const Value(true),
          isDefault: const Value(false),
          sortOrder: const Value(0),
          createdAt: Value(DateTime.now()),
          updatedAt: Value(DateTime.now()),
        ),
        PaymentMethodsCompanion(
          id: Value(uuid.v4()),
          name: const Value('Inactivo'),
          accountId: Value(accountId),
          isActive: const Value(false),
          isDefault: const Value(false),
          sortOrder: const Value(1),
          createdAt: Value(DateTime.now()),
          updatedAt: Value(DateTime.now()),
        ),
      ]);

      final result = await dao.getMethodsByAccount(accountId);

      expect(result, hasLength(1));
      expect(result.first.name, equals('Activo'));
    });
  });

  group('PaymentMethodsDao - setAsDefault', () {
    test('setAsDefault cambia el método por defecto', () async {
      final method1Id = uuid.v4();
      final method2Id = uuid.v4();

      await dao.insertMethods([
        PaymentMethodsCompanion(
          id: Value(method1Id),
          name: const Value('Método 1'),
          accountId: Value(accountId),
          isActive: const Value(true),
          isDefault: const Value(true),
          sortOrder: const Value(0),
          createdAt: Value(DateTime.now()),
          updatedAt: Value(DateTime.now()),
        ),
        PaymentMethodsCompanion(
          id: Value(method2Id),
          name: const Value('Método 2'),
          accountId: Value(accountId),
          isActive: const Value(true),
          isDefault: const Value(false),
          sortOrder: const Value(1),
          createdAt: Value(DateTime.now()),
          updatedAt: Value(DateTime.now()),
        ),
      ]);

      // Verificar estado inicial
      var method1 = await dao.getMethodById(method1Id);
      expect(method1!.isDefault, isTrue);

      // Cambiar default
      await dao.setAsDefault(method2Id);

      // Verificar cambio
      method1 = await dao.getMethodById(method1Id);
      final method2 = await dao.getMethodById(method2Id);

      expect(method1!.isDefault, isFalse);
      expect(method2!.isDefault, isTrue);
    });

    test('setAsDefault solo deja un default', () async {
      await dao.insertMethods([
        PaymentMethodsCompanion(
          id: Value(uuid.v4()),
          name: const Value('Método 1'),
          accountId: Value(accountId),
          isActive: const Value(true),
          isDefault: const Value(true),
          sortOrder: const Value(0),
          createdAt: Value(DateTime.now()),
          updatedAt: Value(DateTime.now()),
        ),
        PaymentMethodsCompanion(
          id: Value(uuid.v4()),
          name: const Value('Método 2'),
          accountId: Value(accountId),
          isActive: const Value(true),
          isDefault: const Value(true),
          sortOrder: const Value(1),
          createdAt: Value(DateTime.now()),
          updatedAt: Value(DateTime.now()),
        ),
        PaymentMethodsCompanion(
          id: Value(uuid.v4()),
          name: const Value('Método 3'),
          accountId: Value(accountId),
          isActive: const Value(true),
          isDefault: const Value(false),
          sortOrder: const Value(2),
          createdAt: Value(DateTime.now()),
          updatedAt: Value(DateTime.now()),
        ),
      ]);

      final method3 =
          (await dao.getAllMethods()).firstWhere((m) => m.name == 'Método 3');
      await dao.setAsDefault(method3.id);

      final allMethods = await dao.getAllMethods();
      final defaults = allMethods.where((m) => m.isDefault ?? false).toList();

      expect(defaults, hasLength(1));
      expect(defaults.first.name, equals('Método 3'));
    });
  });
}
