import 'package:drift/drift.dart' hide isNull, isNotNull;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:uuid/uuid.dart';

import 'package:finanzas_familiares/data/local/database.dart';
import 'package:finanzas_familiares/data/mappers/category_tree_mappers.dart';
import 'package:finanzas_familiares/domain/entities/categories/category_tree_dto.dart';

void main() {
  late AppDatabase db;
  const uuid = Uuid();

  setUp(() async {
    db = AppDatabase.forTesting(NativeDatabase.memory());
  });

  tearDown(() async {
    await db.close();
  });

  group('CategoryTreeMappers.categoryToDto', () {
    test('convierte CategoryEntry a CategoryTreeDto', () async {
      final categoryId = uuid.v4();

      await db.into(db.categories).insert(CategoriesCompanion(
            id: Value(categoryId),
            name: const Value('Alimentación'),
            icon: const Value('🍽️'),
            type: const Value('expense'),
            level: const Value(2),
            sortOrder: const Value(1),
            createdAt: Value(DateTime.now()),
            updatedAt: Value(DateTime.now()),
          ));

      final entry = await (db.select(db.categories)
            ..where((c) => c.id.equals(categoryId)))
          .getSingle();

      final dto = CategoryTreeMappers.categoryToDto(entry);

      expect(dto.id, equals(categoryId));
      expect(dto.name, equals('Alimentación'));
      expect(dto.icon, equals('🍽️'));
      expect(dto.type, equals('expense'));
      expect(dto.level, equals(2));
      expect(dto.sortOrder, equals(1));
      expect(dto.parentId, isNull);
    });

    test('convierte categoría con parentId', () async {
      final parentId = uuid.v4();
      final childId = uuid.v4();

      // Crear padre
      await db.into(db.categories).insert(CategoriesCompanion(
            id: Value(parentId),
            name: const Value('Gastos'),
            type: const Value('expense'),
            level: const Value(1),
            sortOrder: const Value(0),
            createdAt: Value(DateTime.now()),
            updatedAt: Value(DateTime.now()),
          ));

      // Crear hijo
      await db.into(db.categories).insert(CategoriesCompanion(
            id: Value(childId),
            name: const Value('Alimentación'),
            type: const Value('expense'),
            parentId: Value(parentId),
            level: const Value(2),
            sortOrder: const Value(0),
            createdAt: Value(DateTime.now()),
            updatedAt: Value(DateTime.now()),
          ));

      final entry =
          await (db.select(db.categories)..where((c) => c.id.equals(childId)))
              .getSingle();

      final dto = CategoryTreeMappers.categoryToDto(entry);

      expect(dto.parentId, equals(parentId));
    });

    test('maneja campos opcionales nulos', () async {
      final categoryId = uuid.v4();

      await db.into(db.categories).insert(CategoriesCompanion(
            id: Value(categoryId),
            name: const Value('Sin icono'),
            type: const Value('asset'),
            level: const Value(1),
            sortOrder: const Value(0),
            createdAt: Value(DateTime.now()),
            updatedAt: Value(DateTime.now()),
          ));

      final entry = await (db.select(db.categories)
            ..where((c) => c.id.equals(categoryId)))
          .getSingle();

      final dto = CategoryTreeMappers.categoryToDto(entry);

      expect(dto.icon, isNull);
      expect(dto.parentId, isNull);
    });
  });

  group('CategoryTreeMappers.categoriesToDtoList', () {
    test('convierte lista de categorías', () async {
      for (var i = 0; i < 3; i++) {
        await db.into(db.categories).insert(CategoriesCompanion(
              id: Value(uuid.v4()),
              name: Value('Categoría $i'),
              type: const Value('expense'),
              level: const Value(1),
              sortOrder: Value(i),
              createdAt: Value(DateTime.now()),
              updatedAt: Value(DateTime.now()),
            ));
      }

      final entries = await db.select(db.categories).get();
      final dtos = CategoryTreeMappers.categoriesToDtoList(entries);

      expect(dtos, hasLength(3));
      expect(dtos, everyElement(isA<CategoryTreeDto>()));
    });

    test('retorna lista vacía para input vacío', () {
      final dtos = CategoryTreeMappers.categoriesToDtoList([]);

      expect(dtos, isEmpty);
    });

    test('preserva orden de entrada', () async {
      final names = ['Ahorros', 'Banco', 'Crédito'];
      for (var i = 0; i < names.length; i++) {
        await db.into(db.categories).insert(CategoriesCompanion(
              id: Value(uuid.v4()),
              name: Value(names[i]),
              type: const Value('asset'),
              level: const Value(1),
              sortOrder: Value(i),
              createdAt: Value(DateTime.now()),
              updatedAt: Value(DateTime.now()),
            ));
      }

      final entries = await (db.select(db.categories)
            ..orderBy([(c) => OrderingTerm(expression: c.sortOrder)]))
          .get();
      final dtos = CategoryTreeMappers.categoriesToDtoList(entries);

      expect(dtos[0].name, equals('Ahorros'));
      expect(dtos[1].name, equals('Banco'));
      expect(dtos[2].name, equals('Crédito'));
    });

    test('preserva sortOrder en cada DTO', () async {
      await db.into(db.categories).insert(CategoriesCompanion(
            id: Value(uuid.v4()),
            name: const Value('Primero'),
            type: const Value('expense'),
            level: const Value(1),
            sortOrder: const Value(10),
            createdAt: Value(DateTime.now()),
            updatedAt: Value(DateTime.now()),
          ));

      await db.into(db.categories).insert(CategoriesCompanion(
            id: Value(uuid.v4()),
            name: const Value('Segundo'),
            type: const Value('expense'),
            level: const Value(1),
            sortOrder: const Value(20),
            createdAt: Value(DateTime.now()),
            updatedAt: Value(DateTime.now()),
          ));

      final entries = await db.select(db.categories).get();
      final dtos = CategoryTreeMappers.categoriesToDtoList(entries);

      final primero = dtos.firstWhere((d) => d.name == 'Primero');
      final segundo = dtos.firstWhere((d) => d.name == 'Segundo');

      expect(primero.sortOrder, equals(10));
      expect(segundo.sortOrder, equals(20));
    });
  });

  group('CategoryTreeDto', () {
    test('constructor con valores requeridos', () {
      const dto = CategoryTreeDto(
        id: 'cat-1',
        name: 'Test',
        type: 'expense',
        level: 1,
        sortOrder: 0,
      );

      expect(dto.id, equals('cat-1'));
      expect(dto.name, equals('Test'));
      expect(dto.type, equals('expense'));
      expect(dto.level, equals(1));
      expect(dto.sortOrder, equals(0));
      expect(dto.icon, isNull);
      expect(dto.parentId, isNull);
    });

    test('constructor con todos los valores', () {
      const dto = CategoryTreeDto(
        id: 'cat-1',
        name: 'Alimentación',
        icon: '🍽️',
        type: 'expense',
        parentId: 'parent-1',
        level: 2,
        sortOrder: 5,
      );

      expect(dto.icon, equals('🍽️'));
      expect(dto.parentId, equals('parent-1'));
    });
  });
}
