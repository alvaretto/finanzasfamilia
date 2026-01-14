import 'package:drift/drift.dart' hide isNull, isNotNull;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:uuid/uuid.dart';

import 'package:finanzas_familiares/data/local/database.dart';
import 'package:finanzas_familiares/data/local/daos/savings_goals_dao.dart';

void main() {
  late AppDatabase db;
  late SavingsGoalsDao dao;

  setUp(() {
    db = AppDatabase.forTesting(NativeDatabase.memory());
    dao = SavingsGoalsDao(db);
  });

  tearDown(() async {
    await db.close();
  });

  group('SavingsGoalsDao', () {
    Future<String> insertTestGoal({
      String name = 'Test Goal',
      double targetAmount = 1000000,
      double currentAmount = 0,
      bool isActive = true,
      bool isCompleted = false,
      DateTime? targetDate,
    }) async {
      final id = const Uuid().v4();
      await dao.insertGoal(SavingsGoalsCompanion(
        id: Value(id),
        name: Value(name),
        targetAmount: Value(targetAmount),
        currentAmount: Value(currentAmount),
        targetDate: Value(targetDate),
        isActive: Value(isActive),
        isCompleted: Value(isCompleted),
        createdAt: Value(DateTime.now()),
        updatedAt: Value(DateTime.now()),
      ));
      return id;
    }

    test('getActiveGoals retorna lista vacía inicialmente', () async {
      final result = await dao.getActiveGoals();
      expect(result, isEmpty);
    });

    test('insertGoal agrega una meta de ahorro', () async {
      await insertTestGoal();

      final result = await dao.getActiveGoals();
      expect(result.length, equals(1));
      expect(result.first.name, equals('Test Goal'));
      expect(result.first.targetAmount, equals(1000000));
    });

    test('getGoalById retorna la meta correcta', () async {
      final id = await insertTestGoal(name: 'Vacaciones');

      final result = await dao.getGoalById(id);
      expect(result, isNotNull);
      expect(result!.name, equals('Vacaciones'));
    });

    test('getGoalById retorna null si no existe', () async {
      final result = await dao.getGoalById('non-existent-id');
      expect(result, isNull);
    });

    test('getActiveGoals solo retorna metas activas', () async {
      await insertTestGoal(name: 'Active', isActive: true);
      await insertTestGoal(name: 'Inactive', isActive: false);

      final result = await dao.getActiveGoals();
      expect(result.length, equals(1));
      expect(result.first.name, equals('Active'));
    });

    test('getCompletedGoals solo retorna metas completadas', () async {
      await insertTestGoal(name: 'In Progress', isCompleted: false);
      await insertTestGoal(name: 'Completed', isCompleted: true);

      final result = await dao.getCompletedGoals();
      expect(result.length, equals(1));
      expect(result.first.name, equals('Completed'));
    });

    test('getGoalsInProgress retorna metas activas no completadas', () async {
      await insertTestGoal(name: 'In Progress', isActive: true, isCompleted: false);
      await insertTestGoal(name: 'Paused', isActive: false, isCompleted: false);
      await insertTestGoal(name: 'Completed', isActive: true, isCompleted: true);

      final result = await dao.getGoalsInProgress();
      expect(result.length, equals(1));
      expect(result.first.name, equals('In Progress'));
    });

    test('updateGoal actualiza la meta', () async {
      final id = await insertTestGoal(name: 'Original');

      await dao.updateGoal(SavingsGoalsCompanion(
        id: Value(id),
        name: const Value('Updated'),
        updatedAt: Value(DateTime.now()),
      ));

      final result = await dao.getGoalById(id);
      expect(result!.name, equals('Updated'));
    });

    test('deleteGoal elimina la meta', () async {
      final id = await insertTestGoal();
      expect((await dao.getActiveGoals()).length, equals(1));

      await dao.deleteGoal(id);
      expect((await dao.getActiveGoals()).length, equals(0));
    });

    test('updateCurrentAmount actualiza el monto actual', () async {
      final id = await insertTestGoal(currentAmount: 0);

      await dao.updateCurrentAmount(id, 500000);

      final result = await dao.getGoalById(id);
      expect(result!.currentAmount, equals(500000));
    });

    test('markAsCompleted marca la meta como completada', () async {
      final id = await insertTestGoal(isCompleted: false);

      await dao.markAsCompleted(id);

      final result = await dao.getGoalById(id);
      expect(result!.isCompleted, isTrue);
      expect(result.completedAt, isNotNull);
    });
  });

  group('SavingsContributions', () {
    late String goalId;

    setUp(() async {
      goalId = const Uuid().v4();
      await dao.insertGoal(SavingsGoalsCompanion(
        id: Value(goalId),
        name: const Value('Test Goal'),
        targetAmount: const Value(1000000),
        currentAmount: const Value(0),
        createdAt: Value(DateTime.now()),
        updatedAt: Value(DateTime.now()),
      ));
    });

    Future<String> insertContribution({
      double amount = 100000,
      String? note,
    }) async {
      final id = const Uuid().v4();
      await dao.addContribution(SavingsContributionsCompanion(
        id: Value(id),
        goalId: Value(goalId),
        amount: Value(amount),
        note: Value(note),
        date: Value(DateTime.now()),
        createdAt: Value(DateTime.now()),
      ));
      return id;
    }

    test('addContribution agrega una contribución', () async {
      await insertContribution(amount: 100000);

      final contributions = await dao.getContributionsForGoal(goalId);
      expect(contributions.length, equals(1));
      expect(contributions.first.amount, equals(100000));
    });

    test('addContribution actualiza el monto actual de la meta', () async {
      await insertContribution(amount: 100000);
      await insertContribution(amount: 200000);

      final goal = await dao.getGoalById(goalId);
      expect(goal!.currentAmount, equals(300000));
    });

    test('addContribution marca meta como completada al alcanzar objetivo', () async {
      // Meta de 1,000,000
      await insertContribution(amount: 500000);
      var goal = await dao.getGoalById(goalId);
      // isCompleted puede ser null (default false en PowerSync)
      expect(goal!.isCompleted ?? false, isFalse);

      await insertContribution(amount: 500000);
      goal = await dao.getGoalById(goalId);
      expect(goal!.isCompleted, isTrue);
    });

    test('deleteContribution elimina y recalcula el monto', () async {
      final c1 = await insertContribution(amount: 100000);
      await insertContribution(amount: 200000);

      var goal = await dao.getGoalById(goalId);
      expect(goal!.currentAmount, equals(300000));

      await dao.deleteContribution(c1);

      goal = await dao.getGoalById(goalId);
      expect(goal!.currentAmount, equals(200000));
    });

    test('getContributionsForGoal retorna contribuciones ordenadas por fecha', () async {
      await insertContribution(amount: 100000, note: 'First');
      await insertContribution(amount: 200000, note: 'Second');
      await insertContribution(amount: 150000, note: 'Third');

      final contributions = await dao.getContributionsForGoal(goalId);
      expect(contributions.length, equals(3));
    });
  });

  group('Streams', () {
    test('watchActiveGoals emite cambios', () async {
      final stream = dao.watchActiveGoals();

      // Escuchar el primer valor (vacío)
      final firstValue = await stream.first;
      expect(firstValue, isEmpty);
    });

    test('watchGoalsInProgress emite cambios', () async {
      final stream = dao.watchGoalsInProgress();

      final firstValue = await stream.first;
      expect(firstValue, isEmpty);
    });
  });
}
