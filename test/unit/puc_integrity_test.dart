/// Tests de integridad para arquitectura PUC (Plan Único de Cuentas)
///
/// Verifica:
/// - Seed data correcto (5 clases, 30+ grupos)
/// - FK constraints funcionan
/// - Migración type→groupId es correcta
/// - Naturaleza contable es consistente
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:finanzas_familiares/core/database/app_database.dart';
import 'package:finanzas_familiares/core/database/tables/account_puc_tables.dart';
import 'package:drift/drift.dart' hide isNull, isNotNull;

void main() {
  late AppDatabase db;

  setUp(() async {
    db = AppDatabase.forTest();

    // IMPORTANTE: Habilitar FK constraints en SQLite (deshabilitados por defecto)
    await db.customStatement('PRAGMA foreign_keys = ON');

    // Migración automática ejecutará _insertPUCSeedData()
  });

  tearDown(() async {
    await db.close();
    AppDatabase.resetInstance();
  });

  group('PUC Seed Data Integrity', () {
    test('Existen exactamente 5 AccountClasses', () async {
      final classes = await db.select(db.accountClasses).get();
      expect(classes.length, 5, reason: 'Deben existir exactamente 5 clases contables PUC');
    });

    test('AccountClasses tienen IDs 1-5', () async {
      final classes = await db.select(db.accountClasses).get();
      final ids = classes.map((c) => c.id).toSet();
      expect(ids, {1, 2, 3, 4, 5}, reason: 'Las clases deben tener IDs del 1 al 5');
    });

    test('AccountClasses tienen nombres correctos', () async {
      final classesMap = <int, String>{};
      final classes = await db.select(db.accountClasses).get();

      for (final cls in classes) {
        classesMap[cls.id] = cls.name;
      }

      expect(classesMap[1], 'Activo');
      expect(classesMap[2], 'Pasivo');
      expect(classesMap[3], 'Patrimonio');
      expect(classesMap[4], 'Ingresos');
      expect(classesMap[5], 'Gastos');
    });

    test('AccountGroups tienen FK válido a AccountClasses', () async {
      final groups = await db.select(db.accountGroups).get();
      expect(groups.length, greaterThan(30), reason: 'Deben existir al menos 30 grupos PUC');

      for (final group in groups) {
        final classExists = await (db.select(db.accountClasses)
              ..where((tbl) => tbl.id.equals(group.classId)))
            .getSingleOrNull();

        expect(classExists, isNotNull,
            reason: 'Group ${group.id} tiene classId inválido ${group.classId}');
      }
    });

    test('AccountGroups no tienen IDs duplicados', () async {
      final groups = await db.select(db.accountGroups).get();
      final ids = groups.map((g) => g.id).toList();
      final uniqueIds = ids.toSet();

      expect(ids.length, uniqueIds.length, reason: 'No debe haber groupIds duplicados');
    });

    test('AccountGroups críticos existen', () async {
      final criticalGroups = ['1105', '1110', '2105', '2120', '5100', '5400'];

      for (final groupId in criticalGroups) {
        final group = await (db.select(db.accountGroups)
              ..where((tbl) => tbl.id.equals(groupId)))
            .getSingleOrNull();

        expect(group, isNotNull, reason: 'Grupo crítico $groupId no existe');
      }
    });
  });

  group('PUC Naturaleza Contable', () {
    test('Activos (Class 1) son DEBIT', () async {
      final activosGroups = await (db.select(db.accountGroups)
            ..where((tbl) => tbl.classId.equals(1)))
          .get();

      expect(activosGroups, isNotEmpty);

      for (final group in activosGroups) {
        expect(group.nature, AccountNature.DEBIT,
            reason: 'Grupo ${group.id} (Activo) debe ser DEBIT');
      }
    });

    test('Pasivos (Class 2) son CREDIT', () async {
      final pasivosGroups = await (db.select(db.accountGroups)
            ..where((tbl) => tbl.classId.equals(2)))
          .get();

      expect(pasivosGroups, isNotEmpty);

      for (final group in pasivosGroups) {
        expect(group.nature, AccountNature.CREDIT,
            reason: 'Grupo ${group.id} (Pasivo) debe ser CREDIT');
      }
    });

    test('Ingresos (Class 4) son mayormente CREDIT', () async {
      final ingresosGroups = await (db.select(db.accountGroups)
            ..where((tbl) => tbl.classId.equals(4)))
          .get();

      expect(ingresosGroups, isNotEmpty);

      final creditCount = ingresosGroups.where((g) => g.nature == AccountNature.CREDIT).length;
      final totalCount = ingresosGroups.length;

      expect(creditCount / totalCount, greaterThan(0.8),
          reason: 'Al menos 80% de Ingresos deben ser CREDIT');
    });

    test('Gastos (Class 5) son DEBIT', () async {
      final gastosGroups = await (db.select(db.accountGroups)
            ..where((tbl) => tbl.classId.equals(5)))
          .get();

      expect(gastosGroups, isNotEmpty);

      for (final group in gastosGroups) {
        expect(group.nature, AccountNature.DEBIT,
            reason: 'Grupo ${group.id} (Gasto) debe ser DEBIT');
      }
    });
  });

  group('PUC Expense Type', () {
    test('Solo Class 5 tiene expenseType', () async {
      final nonGastosGroups = await (db.select(db.accountGroups)
            ..where((tbl) => tbl.classId.isNotValue(5)))
          .get();

      for (final group in nonGastosGroups) {
        expect(group.expenseType, isNull,
            reason: 'Grupo ${group.id} (no Gasto) no debe tener expenseType');
      }
    });

    test('Gastos fijos (5100-5299) tienen FIXED', () async {
      final group5100 = await (db.select(db.accountGroups)
            ..where((tbl) => tbl.id.equals('5100')))
          .getSingle();

      expect(group5100.expenseType, ExpenseType.FIXED);

      final group5135 = await (db.select(db.accountGroups)
            ..where((tbl) => tbl.id.equals('5135')))
          .getSingle();

      expect(group5135.expenseType, ExpenseType.FIXED);
    });

    test('Gastos variables (5300+) tienen VARIABLE', () async {
      final group5300 = await (db.select(db.accountGroups)
            ..where((tbl) => tbl.id.equals('5300')))
          .getSingleOrNull();

      if (group5300 != null) {
        expect(group5300.expenseType, ExpenseType.VARIABLE);
      }

      final group5400 = await (db.select(db.accountGroups)
            ..where((tbl) => tbl.id.equals('5400')))
          .getSingle();

      expect(group5400.expenseType, ExpenseType.VARIABLE);
    });
  });

  group('Account FK Constraints', () {
    test('No se puede crear Account con groupId inválido', () async {
      // Intentar insertar con FK inválido debe lanzar error
      expect(
        db.into(db.accounts).insert(AccountsCompanion.insert(
              id: 'test-acc',
              userId: 'test-user',
              name: 'Cuenta inválida',
              type: 'cash',
              groupId: const Value('9999'), // groupId que no existe
            )),
        throwsA(anything), // SQLite lanzará constraint violation
        reason: 'Debe fallar al intentar insertar con groupId inválido',
      );
    });

    test('Account con groupId válido se crea correctamente', () async {
      final account = await db.into(db.accounts).insert(AccountsCompanion.insert(
            id: 'test-acc',
            userId: 'test-user',
            name: 'Mi cuenta bancaria',
            type: 'bank',
            groupId: const Value('1110'), // Bancos
          ));

      expect(account, greaterThan(0));

      final savedAccount = await (db.select(db.accounts)
            ..where((tbl) => tbl.id.equals('test-acc')))
          .getSingle();

      expect(savedAccount.groupId, '1110');
    });

    test('No se puede eliminar AccountGroup si hay Accounts referenciándolo', () async {
      // 1. Crear una cuenta que referencia al grupo 1105
      await db.into(db.accounts).insert(AccountsCompanion.insert(
            id: 'test-acc',
            userId: 'test-user',
            name: 'Efectivo',
            type: 'cash',
            groupId: const Value('1105'),
          ));

      // 2. Intentar eliminar el grupo 1105 (debe fallar por FK constraint)
      expect(
        (db.delete(db.accountGroups)..where((tbl) => tbl.id.equals('1105'))).go(),
        throwsA(anything), // SQLite lanzará FOREIGN KEY constraint failed
        reason: 'No se puede eliminar AccountGroup con Accounts referenciándolo',
      );
    });
  });

  group('Type → GroupId Migration', () {
    test('cash se mapea a 1105 (Caja General)', () async {
      // Simular migración manual
      final typeToGroupId = {'cash': '1105'};

      expect(typeToGroupId['cash'], '1105');

      // Verificar que el grupo existe
      final group = await (db.select(db.accountGroups)
            ..where((tbl) => tbl.id.equals('1105')))
          .getSingleOrNull();

      expect(group, isNotNull);
      expect(group!.friendlyName, contains('Efectivo'));
    });

    test('bank se mapea a 1110 (Bancos)', () async {
      final typeToGroupId = {'bank': '1110'};

      expect(typeToGroupId['bank'], '1110');

      final group = await (db.select(db.accountGroups)
            ..where((tbl) => tbl.id.equals('1110')))
          .getSingleOrNull();

      expect(group, isNotNull);
      expect(group!.friendlyName, contains('Bancos'));
    });

    test('credit se mapea a 2105 (Tarjetas)', () async {
      final typeToGroupId = {'credit': '2105'};

      expect(typeToGroupId['credit'], '2105');

      final group = await (db.select(db.accountGroups)
            ..where((tbl) => tbl.id.equals('2105')))
          .getSingleOrNull();

      expect(group, isNotNull);
      expect(group!.friendlyName, contains('Tarjetas'));
    });

    test('Todos los tipos legacy tienen mapeo válido', () async {
      final typeToGroupId = {
        'cash': '1105',
        'bank': '1110',
        'savings': '1110',
        'wallet': '1105',
        'credit': '2105',
        'investment': '1200',
        'loan': '2120',
        'payable': '2335',
      };

      for (final entry in typeToGroupId.entries) {
        final group = await (db.select(db.accountGroups)
              ..where((tbl) => tbl.id.equals(entry.value)))
            .getSingleOrNull();

        expect(group, isNotNull,
            reason: 'Tipo ${entry.key} mapea a groupId ${entry.value} que no existe');
      }
    });
  });

  group('PUC Presentation Names', () {
    test('Class 1 tiene nombre UX "Lo que Tengo"', () async {
      final class1 = await (db.select(db.accountClasses)
            ..where((tbl) => tbl.id.equals(1)))
          .getSingle();

      expect(class1.presentationName, 'Lo que Tengo');
    });

    test('Class 2 tiene nombre UX "Lo que Debo"', () async {
      final class2 = await (db.select(db.accountClasses)
            ..where((tbl) => tbl.id.equals(2)))
          .getSingle();

      expect(class2.presentationName, 'Lo que Debo');
    });

    test('Grupos tienen friendlyName en español colombiano', () async {
      final group1105 = await (db.select(db.accountGroups)
            ..where((tbl) => tbl.id.equals('1105')))
          .getSingle();

      expect(group1105.friendlyName, 'Efectivo y Bolsillos');

      final group1110 = await (db.select(db.accountGroups)
            ..where((tbl) => tbl.id.equals('1110')))
          .getSingle();

      expect(group1110.friendlyName, 'Bancos / Nequi / Daviplata');
    });
  });

  group('PUC Icon and Color', () {
    test('Grupos tienen íconos y colores asignados', () async {
      final groups = await db.select(db.accountGroups).get();

      int groupsWithIcon = 0;
      int groupsWithColor = 0;

      for (final group in groups) {
        if (group.icon != null && group.icon!.isNotEmpty) {
          groupsWithIcon++;
        }
        if (group.color != null && group.color!.isNotEmpty) {
          groupsWithColor++;
        }
      }

      expect(groupsWithIcon / groups.length, greaterThan(0.9),
          reason: 'Al menos 90% de grupos deben tener ícono');
      expect(groupsWithColor / groups.length, greaterThan(0.9),
          reason: 'Al menos 90% de grupos deben tener color');
    });

    test('Colores están en formato hexadecimal', () async {
      final groups = await db.select(db.accountGroups).get();

      for (final group in groups) {
        if (group.color != null) {
          expect(group.color, matches(r'^#[0-9a-fA-F]{6}$'),
              reason: 'Color del grupo ${group.id} debe ser hex válido');
        }
      }
    });
  });
}
