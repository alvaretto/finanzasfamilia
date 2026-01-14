import 'package:drift/drift.dart' hide isNull, isNotNull;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:uuid/uuid.dart';

import 'package:finanzas_familiares/data/local/database.dart';
import 'package:finanzas_familiares/data/local/daos/recurring_transactions_dao.dart';
import 'package:finanzas_familiares/data/local/tables/recurring_transactions_table.dart';

void main() {
  late AppDatabase db;
  late RecurringTransactionsDao dao;

  setUp(() {
    db = AppDatabase.forTesting(NativeDatabase.memory());
    dao = RecurringTransactionsDao(db);
  });

  tearDown(() async {
    await db.close();
  });

  group('RecurringTransactionsDao', () {
    Future<void> seedCategory() async {
      await db.into(db.categories).insert(const CategoriesCompanion(
            id: Value('cat-test'),
            name: Value('Test Category'),
            type: Value('expense'),
          ));
    }

    Future<String> insertTestRecurring({
      bool isActive = true,
      DateTime? nextExecutionDate,
    }) async {
      final id = const Uuid().v4();
      await dao.insert(RecurringTransactionsCompanion(
        id: Value(id),
        name: const Value('Test Recurring'),
        type: const Value('expense'),
        amount: const Value(100000),
        categoryId: const Value('cat-test'),
        frequency: const Value('monthly'),
        dayOfExecution: const Value(15),
        startDate: Value(DateTime.now()),
        nextExecutionDate:
            Value(nextExecutionDate ?? DateTime.now().add(const Duration(days: 30))),
        isActive: Value(isActive),
      ));
      return id;
    }

    test('getAll retorna lista vacía inicialmente', () async {
      final result = await dao.getAll();
      expect(result, isEmpty);
    });

    test('insert agrega una transacción recurrente', () async {
      await seedCategory();
      await insertTestRecurring();

      final result = await dao.getAll();
      expect(result.length, equals(1));
      expect(result.first.name, equals('Test Recurring'));
    });

    test('getActive solo retorna activas', () async {
      await seedCategory();
      await insertTestRecurring(isActive: true);
      await insertTestRecurring(isActive: false);

      final result = await dao.getActive();
      expect(result.length, equals(1));
      expect(result.first.isActive, isTrue);
    });

    test('getDueForExecution retorna transacciones vencidas', () async {
      await seedCategory();
      // Una vencida (ayer)
      await insertTestRecurring(
        nextExecutionDate: DateTime.now().subtract(const Duration(days: 1)),
      );
      // Una futura
      await insertTestRecurring(
        nextExecutionDate: DateTime.now().add(const Duration(days: 30)),
      );

      final result = await dao.getDueForExecution();
      expect(result.length, equals(1));
    });

    test('getById retorna la transacción correcta', () async {
      await seedCategory();
      final id = await insertTestRecurring();

      final result = await dao.getById(id);
      expect(result, isNotNull);
      expect(result!.id, equals(id));
    });

    test('deactivate desactiva la transacción', () async {
      await seedCategory();
      final id = await insertTestRecurring(isActive: true);

      await dao.deactivate(id);

      final result = await dao.getById(id);
      expect(result!.isActive, isFalse);
    });

    test('activate activa la transacción', () async {
      await seedCategory();
      final id = await insertTestRecurring(isActive: false);

      await dao.activate(id);

      final result = await dao.getById(id);
      expect(result!.isActive, isTrue);
    });

    test('deleteEntry elimina la transacción', () async {
      await seedCategory();
      final id = await insertTestRecurring();

      final deleted = await dao.deleteEntry(id);
      expect(deleted, equals(1));

      final result = await dao.getById(id);
      expect(result, isNull);
    });

    test('markAsExecuted actualiza lastExecutedAt y nextExecutionDate',
        () async {
      await seedCategory();
      final id = await insertTestRecurring();
      final nextDate = DateTime.now().add(const Duration(days: 30));

      await dao.markAsExecuted(id, nextDate);

      final result = await dao.getById(id);
      expect(result!.lastExecutedAt, isNotNull);
      expect(
        result.nextExecutionDate.day,
        equals(nextDate.day),
      );
    });

    test('incrementExecutionCount incrementa el contador', () async {
      await seedCategory();
      final id = await insertTestRecurring();

      final before = await dao.getById(id);
      // executionCount puede ser null (default 0 en PowerSync)
      expect(before!.executionCount ?? 0, equals(0));

      await dao.incrementExecutionCount(id);

      final after = await dao.getById(id);
      expect(after!.executionCount, equals(1));
    });
  });

  group('RecurrenceFrequency', () {
    test('tiene todos los valores esperados', () {
      expect(RecurrenceFrequency.values.length, equals(8));
      expect(RecurrenceFrequency.daily.name, equals('daily'));
      expect(RecurrenceFrequency.weekly.name, equals('weekly'));
      expect(RecurrenceFrequency.biweekly.name, equals('biweekly'));
      expect(RecurrenceFrequency.monthly.name, equals('monthly'));
      expect(RecurrenceFrequency.bimonthly.name, equals('bimonthly'));
      expect(RecurrenceFrequency.quarterly.name, equals('quarterly'));
      expect(RecurrenceFrequency.semiannual.name, equals('semiannual'));
      expect(RecurrenceFrequency.yearly.name, equals('yearly'));
    });
  });
}
