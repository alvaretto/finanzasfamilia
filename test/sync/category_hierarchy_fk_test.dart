/// Tests de ordenamiento FK en categorías jerárquicas
///
/// Verifican que las categorías se insertan en el orden correcto
/// para evitar FK violations. Supabase REST API no es transaccional,
/// por lo que debemos garantizar que padres existan antes que hijos.
///
/// CRÍTICO: Este fue el bug principal que causaba pérdida de datos.
/// La solución es insertar categorías por nivel: 0 → 1 → 2 → 3...
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:uuid/uuid.dart';
import 'package:matcher/matcher.dart' as m;

import 'package:finanzas_familiares/data/local/database.dart';
import 'package:finanzas_familiares/data/local/daos/categories_dao.dart';
import 'package:finanzas_familiares/data/local/seeders/category_seeder.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('CategoryHierarchyFK - Ordenamiento de Categorías', () {
    late AppDatabase db;
    late CategoriesDao categoriesDao;

    setUp(() async {
      db = AppDatabase.forTesting(NativeDatabase.memory());
      categoriesDao = CategoriesDao(db);
    });

    tearDown(() async {
      await db.close();
    });

    group('Fase 1: Estructura de Niveles', () {
      test('Todas las categorías raíz tienen level 0', () async {
        await seedCategories(categoriesDao);
        final categories = await categoriesDao.getAllCategories();

        final roots = categories.where((c) => c.parentId == null);
        for (final root in roots) {
          expect(root.level ?? 0, m.equals(0),
              reason: 'Categoría raíz "${root.name}" debe tener level 0');
        }
      });

      test('Categorías hijas tienen level = parent.level + 1', () async {
        await seedCategories(categoriesDao);
        final categories = await categoriesDao.getAllCategories();
        final byId = {for (final c in categories) c.id: c};

        for (final category in categories) {
          if (category.parentId != null) {
            final parent = byId[category.parentId];
            expect(parent, m.isNotNull,
                reason: 'Padre de "${category.name}" debe existir');
            expect((category.level ?? 0), m.equals((parent!.level ?? 0) + 1),
                reason:
                    '"${category.name}" (level ${category.level}) debe ser '
                    'parent "${parent.name}" (${parent.level}) + 1');
          }
        }
      });

      test('Existen categorías en niveles 0, 1, 2 y 3', () async {
        await seedCategories(categoriesDao);
        final categories = await categoriesDao.getAllCategories();

        final levels = categories.map((c) => c.level ?? 0).toSet();

        expect(levels, m.contains(0), reason: 'Debe haber categorías nivel 0');
        expect(levels, m.contains(1), reason: 'Debe haber categorías nivel 1');
        expect(levels, m.contains(2), reason: 'Debe haber categorías nivel 2');
        expect(levels, m.contains(3), reason: 'Debe haber categorías nivel 3');
      });

      test('Distribución de categorías por nivel es razonable', () async {
        await seedCategories(categoriesDao);
        final categories = await categoriesDao.getAllCategories();

        final byLevel = <int, int>{};
        for (final c in categories) {
          final level = c.level ?? 0;
          byLevel[level] = (byLevel[level] ?? 0) + 1;
        }

        // Nivel 0: 4 raíces (asset, liability, income, expense)
        expect(byLevel[0], m.equals(4),
            reason: 'Debe haber exactamente 4 categorías raíz');

        // Niveles 1, 2, 3 deben tener categorías
        expect(byLevel[1], m.greaterThan(0),
            reason: 'Nivel 1 debe tener categorías');
        expect(byLevel[2], m.greaterThan(0),
            reason: 'Nivel 2 debe tener categorías');
        expect(byLevel[3], m.greaterThan(0),
            reason: 'Nivel 3 debe tener categorías');
      });
    });

    group('Fase 2: Simulación de Ordenamiento para Sync', () {
      test('Categorías ordenadas por nivel: 0 → 1 → 2 → 3', () async {
        await seedCategories(categoriesDao);
        final categories = await categoriesDao.getAllCategories();

        // Simular ordenamiento que haría _upsertCategoriesByLevel
        final byLevel = <int, List<CategoryEntry>>{};
        for (final c in categories) {
          final level = c.level ?? 0;
          byLevel.putIfAbsent(level, () => []);
          byLevel[level]!.add(c);
        }

        final levels = byLevel.keys.toList()..sort();

        // Verificar orden estricto
        expect(levels, m.orderedEquals([0, 1, 2, 3]),
            reason: 'Niveles deben ser 0, 1, 2, 3 en ese orden');

        // Simular inserción ordenada
        final insertionOrder = <String>[];
        for (final level in levels) {
          for (final category in byLevel[level]!) {
            // Al insertar este, verificar que su padre ya fue insertado
            if (category.parentId != null) {
              expect(insertionOrder.contains(category.parentId), m.isTrue,
                  reason:
                      'Padre de "${category.name}" debe insertarse antes');
            }
            insertionOrder.add(category.id);
          }
        }
      });

      test('Inserción desordenada causa FK violation', () async {
        // Crear categoría padre e hijo
        final parentId = const Uuid().v4();
        final childId = const Uuid().v4();

        final parent = CategoriesCompanion.insert(
          id: parentId,
          name: 'Padre',
          type: 'expense',
          level: const Value(0),
        );

        final child = CategoriesCompanion.insert(
          id: childId,
          name: 'Hijo',
          type: 'expense',
          parentId: Value(parentId),
          level: const Value(1),
        );

        // Insertar hijo ANTES que padre → debe fallar
        expect(
          () async => await categoriesDao.insertCategories([child]),
          throwsA(anything),
          reason: 'Insertar hijo sin padre debe fallar por FK',
        );

        // Insertar en orden correcto → debe funcionar
        await categoriesDao.insertCategories([parent]);
        await categoriesDao.insertCategories([child]);

        final all = await categoriesDao.getAllCategories();
        expect(all, m.hasLength(2));
      });

      test('Batch insert en orden correcto funciona', () async {
        final rootId = const Uuid().v4();
        final level1Id = const Uuid().v4();
        final level2Id = const Uuid().v4();

        // Crear jerarquía de 3 niveles
        final categories = [
          CategoriesCompanion.insert(
            id: rootId,
            name: 'Raíz',
            type: 'expense',
            level: const Value(0),
          ),
          CategoriesCompanion.insert(
            id: level1Id,
            name: 'Nivel 1',
            type: 'expense',
            parentId: Value(rootId),
            level: const Value(1),
          ),
          CategoriesCompanion.insert(
            id: level2Id,
            name: 'Nivel 2',
            type: 'expense',
            parentId: Value(level1Id),
            level: const Value(2),
          ),
        ];

        // Insertar en orden → debe funcionar
        await categoriesDao.insertCategories(categories);

        final all = await categoriesDao.getAllCategories();
        expect(all, m.hasLength(3));

        // Verificar jerarquía
        final root = all.firstWhere((c) => c.id == rootId);
        final l1 = all.firstWhere((c) => c.id == level1Id);
        final l2 = all.firstWhere((c) => c.id == level2Id);

        expect(root.parentId, m.isNull);
        expect(l1.parentId, m.equals(rootId));
        expect(l2.parentId, m.equals(level1Id));
      });
    });

    group('Fase 3: Escenarios de Sync Real', () {
      test('Categorías con mismo nombre pero diferente tipo son independientes', () async {
        await seedCategories(categoriesDao);
        final categories = await categoriesDao.getAllCategories();

        // Buscar categorías con nombres que podrían repetirse
        final grouped = <String, List<CategoryEntry>>{};
        for (final c in categories) {
          grouped.putIfAbsent(c.name, () => []);
          grouped[c.name]!.add(c);
        }

        // Verificar que categorías con mismo nombre tienen diferentes tipos
        for (final entry in grouped.entries) {
          if (entry.value.length > 1) {
            final types = entry.value.map((c) => c.type).toSet();
            expect(types.length, m.equals(entry.value.length),
                reason:
                    'Categorías con nombre "${entry.key}" deben tener tipos diferentes');
          }
        }
      });

      test('Todas las categorías del sistema tienen isSystem = true', () async {
        await seedCategories(categoriesDao);
        final categories = await categoriesDao.getAllCategories();

        for (final category in categories) {
          expect(category.isSystem ?? false, m.isTrue,
              reason:
                  'Categoría "${category.name}" debe ser del sistema (isSystem=true)');
        }
      });

      test('Todas las categorías del sistema tienen isActive = true', () async {
        await seedCategories(categoriesDao);
        final categories = await categoriesDao.getAllCategories();

        for (final category in categories) {
          expect(category.isActive ?? true, m.isTrue,
              reason:
                  'Categoría "${category.name}" debe estar activa (isActive=true)');
        }
      });
    });

    group('Fase 4: Profundidad de Jerarquía', () {
      test('La profundidad máxima es 3 niveles', () async {
        await seedCategories(categoriesDao);
        final categories = await categoriesDao.getAllCategories();

        final maxLevel = categories.map((c) => c.level ?? 0).reduce(
            (a, b) => a > b ? a : b);

        expect(maxLevel, m.equals(3),
            reason: 'La profundidad máxima debe ser nivel 3');
      });

      test('Cada rama tiene al menos 2 niveles', () async {
        await seedCategories(categoriesDao);
        final categories = await categoriesDao.getAllCategories();

        final roots = categories.where((c) => c.parentId == null);
        for (final root in roots) {
          final children = categories.where((c) => c.parentId == root.id);
          expect(children, m.isNotEmpty,
              reason: 'Raíz "${root.name}" debe tener al menos un hijo');
        }
      });

      test('Verificar camino completo raíz → hoja para tipo expense', () async {
        await seedCategories(categoriesDao);
        final categories = await categoriesDao.getAllCategories();
        final byId = {for (final c in categories) c.id: c};

        // Encontrar una hoja de nivel 3 en expenses
        final leaf = categories.firstWhere(
          (c) => c.type == 'expense' && (c.level ?? 0) == 3,
        );

        // Recorrer hacia arriba hasta la raíz
        var current = leaf;
        var depth = 0;
        final path = <String>[current.name];

        while (current.parentId != null) {
          current = byId[current.parentId]!;
          path.insert(0, current.name);
          depth++;
        }

        expect(depth, m.equals(3),
            reason: 'Profundidad desde hoja hasta raíz debe ser 3');
        expect(current.parentId, m.isNull,
            reason: 'Debe terminar en una categoría raíz');
        expect(current.type, m.equals('expense'),
            reason: 'La raíz debe ser de tipo expense');
      });
    });

    group('Fase 5: Consistencia de Tipos', () {
      test('Hijos heredan el tipo del padre', () async {
        await seedCategories(categoriesDao);
        final categories = await categoriesDao.getAllCategories();
        final byId = {for (final c in categories) c.id: c};

        for (final category in categories) {
          if (category.parentId != null) {
            final parent = byId[category.parentId];
            expect(category.type, m.equals(parent!.type),
                reason:
                    '"${category.name}" (${category.type}) debe heredar tipo de '
                    '"${parent.name}" (${parent.type})');
          }
        }
      });

      test('Existen exactamente 4 tipos de categorías', () async {
        await seedCategories(categoriesDao);
        final categories = await categoriesDao.getAllCategories();

        final types = categories.map((c) => c.type).toSet();

        expect(types, m.hasLength(4));
        expect(types, m.containsAll(['asset', 'liability', 'income', 'expense']));
      });

      test('Cada tipo tiene una distribución razonable', () async {
        await seedCategories(categoriesDao);
        final categories = await categoriesDao.getAllCategories();

        final byType = <String, int>{};
        for (final c in categories) {
          byType[c.type] = (byType[c.type] ?? 0) + 1;
        }

        // Assets: efectivo, bancos, inversiones
        expect(byType['asset'], m.greaterThanOrEqualTo(10),
            reason: 'Debe haber suficientes categorías de activos');

        // Liabilities: TC, préstamos, CxP
        expect(byType['liability'], m.greaterThanOrEqualTo(10),
            reason: 'Debe haber suficientes categorías de pasivos');

        // Income: fijos, variables
        expect(byType['income'], m.greaterThanOrEqualTo(5),
            reason: 'Debe haber suficientes categorías de ingresos');

        // Expense: la mayoría de categorías
        expect(byType['expense'], m.greaterThanOrEqualTo(30),
            reason: 'Gastos debe ser la categoría más numerosa');
      });
    });
  });
}
