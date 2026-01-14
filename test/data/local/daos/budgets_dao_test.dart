import 'package:drift/drift.dart' hide isNull, isNotNull;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:uuid/uuid.dart';

import 'package:finanzas_familiares/data/local/database.dart';
import 'package:finanzas_familiares/data/local/daos/budgets_dao.dart';

void main() {
  late AppDatabase db;
  late BudgetsDao dao;
  const uuid = Uuid();
  late String categoryId;

  setUp(() async {
    db = AppDatabase.forTesting(NativeDatabase.memory());
    dao = BudgetsDao(db);

    // Crear categoría base para foreign keys
    categoryId = uuid.v4();
    await db.into(db.categories).insert(CategoriesCompanion(
          id: Value(categoryId),
          name: const Value('Alimentación'),
          type: const Value('expense'),
          level: const Value(1),
          createdAt: Value(DateTime.now()),
          updatedAt: Value(DateTime.now()),
        ));
  });

  tearDown(() async {
    await db.close();
  });

  group('BudgetsDao - CRUD', () {
    test('insertBudget crea un presupuesto correctamente', () async {
      final budgetId = uuid.v4();
      await dao.insertBudget(BudgetsCompanion(
        id: Value(budgetId),
        categoryId: Value(categoryId),
        amount: const Value(500000),
        month: const Value(1),
        year: const Value(2026),
        isActive: const Value(true),
        createdAt: Value(DateTime.now()),
        updatedAt: Value(DateTime.now()),
      ));

      final result = await dao.getBudgetForCategory(categoryId, 1, 2026);
      expect(result, isNotNull);
      expect(result!.amount, equals(500000));
      expect(result.month, equals(1));
      expect(result.year, equals(2026));
    });

    test('updateBudget actualiza correctamente', () async {
      final budgetId = uuid.v4();
      await dao.insertBudget(BudgetsCompanion(
        id: Value(budgetId),
        categoryId: Value(categoryId),
        amount: const Value(500000),
        month: const Value(1),
        year: const Value(2026),
        isActive: const Value(true),
        createdAt: Value(DateTime.now()),
        updatedAt: Value(DateTime.now()),
      ));

      final updated = await dao.updateBudget(BudgetsCompanion(
        id: Value(budgetId),
        categoryId: Value(categoryId),
        amount: const Value(750000),
        month: const Value(1),
        year: const Value(2026),
        isActive: const Value(true),
        updatedAt: Value(DateTime.now()),
      ));

      expect(updated, isTrue);

      final result = await dao.getBudgetForCategory(categoryId, 1, 2026);
      expect(result!.amount, equals(750000));
    });

    test('updateBudget retorna false para ID inexistente', () async {
      final result = await dao.updateBudget(BudgetsCompanion(
        id: Value(uuid.v4()),
        categoryId: Value(categoryId),
        amount: const Value(100000),
        month: const Value(1),
        year: const Value(2026),
        updatedAt: Value(DateTime.now()),
      ));

      expect(result, isFalse);
    });

    test('deleteBudget elimina un presupuesto', () async {
      final budgetId = uuid.v4();
      await dao.insertBudget(BudgetsCompanion(
        id: Value(budgetId),
        categoryId: Value(categoryId),
        amount: const Value(500000),
        month: const Value(1),
        year: const Value(2026),
        isActive: const Value(true),
        createdAt: Value(DateTime.now()),
        updatedAt: Value(DateTime.now()),
      ));

      final count = await dao.deleteBudget(budgetId);
      expect(count, equals(1));

      final result = await dao.getBudgetForCategory(categoryId, 1, 2026);
      expect(result, isNull);
    });

    test('deleteBudget retorna 0 para ID inexistente', () async {
      final count = await dao.deleteBudget('non-existent');
      expect(count, equals(0));
    });
  });

  group('BudgetsDao - getActiveBudgets', () {
    test('retorna solo presupuestos activos', () async {
      // Crear segunda categoría
      final categoryId2 = uuid.v4();
      await db.into(db.categories).insert(CategoriesCompanion(
            id: Value(categoryId2),
            name: const Value('Transporte'),
            type: const Value('expense'),
            level: const Value(1),
            createdAt: Value(DateTime.now()),
            updatedAt: Value(DateTime.now()),
          ));

      await dao.insertBudget(BudgetsCompanion(
        id: Value(uuid.v4()),
        categoryId: Value(categoryId),
        amount: const Value(500000),
        month: const Value(1),
        year: const Value(2026),
        isActive: const Value(true),
        createdAt: Value(DateTime.now()),
        updatedAt: Value(DateTime.now()),
      ));

      await dao.insertBudget(BudgetsCompanion(
        id: Value(uuid.v4()),
        categoryId: Value(categoryId2),
        amount: const Value(200000),
        month: const Value(1),
        year: const Value(2026),
        isActive: const Value(false),
        createdAt: Value(DateTime.now()),
        updatedAt: Value(DateTime.now()),
      ));

      final result = await dao.getActiveBudgets();
      expect(result, hasLength(1));
      expect(result.first.amount, equals(500000));
    });

    test('retorna lista vacía si no hay presupuestos activos', () async {
      await dao.insertBudget(BudgetsCompanion(
        id: Value(uuid.v4()),
        categoryId: Value(categoryId),
        amount: const Value(500000),
        month: const Value(1),
        year: const Value(2026),
        isActive: const Value(false),
        createdAt: Value(DateTime.now()),
        updatedAt: Value(DateTime.now()),
      ));

      final result = await dao.getActiveBudgets();
      expect(result, isEmpty);
    });
  });

  group('BudgetsDao - getBudgetForCategory', () {
    test('retorna presupuesto correcto para categoría y mes', () async {
      await dao.insertBudget(BudgetsCompanion(
        id: Value(uuid.v4()),
        categoryId: Value(categoryId),
        amount: const Value(500000),
        month: const Value(3),
        year: const Value(2026),
        isActive: const Value(true),
        createdAt: Value(DateTime.now()),
        updatedAt: Value(DateTime.now()),
      ));

      await dao.insertBudget(BudgetsCompanion(
        id: Value(uuid.v4()),
        categoryId: Value(categoryId),
        amount: const Value(600000),
        month: const Value(4),
        year: const Value(2026),
        isActive: const Value(true),
        createdAt: Value(DateTime.now()),
        updatedAt: Value(DateTime.now()),
      ));

      final result = await dao.getBudgetForCategory(categoryId, 3, 2026);
      expect(result, isNotNull);
      expect(result!.amount, equals(500000));
      expect(result.month, equals(3));
    });

    test('retorna null para categoría sin presupuesto en ese mes', () async {
      await dao.insertBudget(BudgetsCompanion(
        id: Value(uuid.v4()),
        categoryId: Value(categoryId),
        amount: const Value(500000),
        month: const Value(1),
        year: const Value(2026),
        isActive: const Value(true),
        createdAt: Value(DateTime.now()),
        updatedAt: Value(DateTime.now()),
      ));

      final result = await dao.getBudgetForCategory(categoryId, 2, 2026);
      expect(result, isNull);
    });

    test('retorna null para categoría inexistente', () async {
      final result = await dao.getBudgetForCategory('non-existent', 1, 2026);
      expect(result, isNull);
    });

    test('diferencia entre años', () async {
      await dao.insertBudget(BudgetsCompanion(
        id: Value(uuid.v4()),
        categoryId: Value(categoryId),
        amount: const Value(500000),
        month: const Value(1),
        year: const Value(2025),
        isActive: const Value(true),
        createdAt: Value(DateTime.now()),
        updatedAt: Value(DateTime.now()),
      ));

      await dao.insertBudget(BudgetsCompanion(
        id: Value(uuid.v4()),
        categoryId: Value(categoryId),
        amount: const Value(600000),
        month: const Value(1),
        year: const Value(2026),
        isActive: const Value(true),
        createdAt: Value(DateTime.now()),
        updatedAt: Value(DateTime.now()),
      ));

      final result2025 = await dao.getBudgetForCategory(categoryId, 1, 2025);
      final result2026 = await dao.getBudgetForCategory(categoryId, 1, 2026);

      expect(result2025!.amount, equals(500000));
      expect(result2026!.amount, equals(600000));
    });
  });

  group('BudgetsDao - getBudgetsForMonth', () {
    test('retorna todos los presupuestos activos del mes', () async {
      // Crear segunda categoría
      final categoryId2 = uuid.v4();
      await db.into(db.categories).insert(CategoriesCompanion(
            id: Value(categoryId2),
            name: const Value('Transporte'),
            type: const Value('expense'),
            level: const Value(1),
            createdAt: Value(DateTime.now()),
            updatedAt: Value(DateTime.now()),
          ));

      await dao.insertBudget(BudgetsCompanion(
        id: Value(uuid.v4()),
        categoryId: Value(categoryId),
        amount: const Value(500000),
        month: const Value(2),
        year: const Value(2026),
        isActive: const Value(true),
        createdAt: Value(DateTime.now()),
        updatedAt: Value(DateTime.now()),
      ));

      await dao.insertBudget(BudgetsCompanion(
        id: Value(uuid.v4()),
        categoryId: Value(categoryId2),
        amount: const Value(200000),
        month: const Value(2),
        year: const Value(2026),
        isActive: const Value(true),
        createdAt: Value(DateTime.now()),
        updatedAt: Value(DateTime.now()),
      ));

      await dao.insertBudget(BudgetsCompanion(
        id: Value(uuid.v4()),
        categoryId: Value(categoryId),
        amount: const Value(300000),
        month: const Value(3),
        year: const Value(2026),
        isActive: const Value(true),
        createdAt: Value(DateTime.now()),
        updatedAt: Value(DateTime.now()),
      ));

      final result = await dao.getBudgetsForMonth(2, 2026);
      expect(result, hasLength(2));
    });

    test('excluye presupuestos inactivos del mes', () async {
      await dao.insertBudget(BudgetsCompanion(
        id: Value(uuid.v4()),
        categoryId: Value(categoryId),
        amount: const Value(500000),
        month: const Value(2),
        year: const Value(2026),
        isActive: const Value(false),
        createdAt: Value(DateTime.now()),
        updatedAt: Value(DateTime.now()),
      ));

      final result = await dao.getBudgetsForMonth(2, 2026);
      expect(result, isEmpty);
    });

    test('retorna lista vacía para mes sin presupuestos', () async {
      final result = await dao.getBudgetsForMonth(12, 2030);
      expect(result, isEmpty);
    });
  });

  group('BudgetsDao - watchCurrentMonthBudgets', () {
    test('emite presupuestos del mes actual', () async {
      final now = DateTime.now();

      await dao.insertBudget(BudgetsCompanion(
        id: Value(uuid.v4()),
        categoryId: Value(categoryId),
        amount: const Value(500000),
        month: Value(now.month),
        year: Value(now.year),
        isActive: const Value(true),
        createdAt: Value(DateTime.now()),
        updatedAt: Value(DateTime.now()),
      ));

      final stream = dao.watchCurrentMonthBudgets();
      final result = await stream.first;

      expect(result, hasLength(1));
      expect(result.first.amount, equals(500000));
    });

    test('stream se actualiza al insertar nuevo presupuesto', () async {
      final now = DateTime.now();
      final stream = dao.watchCurrentMonthBudgets();

      // Primera emisión vacía
      final emissions = <List<BudgetEntry>>[];
      final subscription = stream.listen((data) {
        emissions.add(data);
      });

      await Future.delayed(const Duration(milliseconds: 50));

      // Insertar presupuesto
      await dao.insertBudget(BudgetsCompanion(
        id: Value(uuid.v4()),
        categoryId: Value(categoryId),
        amount: const Value(500000),
        month: Value(now.month),
        year: Value(now.year),
        isActive: const Value(true),
        createdAt: Value(DateTime.now()),
        updatedAt: Value(DateTime.now()),
      ));

      await Future.delayed(const Duration(milliseconds: 50));
      await subscription.cancel();

      // Debe haber al menos 2 emisiones
      expect(emissions.length, greaterThanOrEqualTo(2));
      expect(emissions.last, hasLength(1));
    });

    test('no incluye presupuestos de otros meses', () async {
      final now = DateTime.now();
      final otherMonth = now.month == 12 ? 1 : now.month + 1;
      final otherYear = now.month == 12 ? now.year + 1 : now.year;

      await dao.insertBudget(BudgetsCompanion(
        id: Value(uuid.v4()),
        categoryId: Value(categoryId),
        amount: const Value(500000),
        month: Value(otherMonth),
        year: Value(otherYear),
        isActive: const Value(true),
        createdAt: Value(DateTime.now()),
        updatedAt: Value(DateTime.now()),
      ));

      final stream = dao.watchCurrentMonthBudgets();
      final result = await stream.first;

      expect(result, isEmpty);
    });
  });
}
