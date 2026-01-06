import 'package:flutter_test/flutter_test.dart';
import 'package:finanzas_familiares/features/transactions/domain/models/unit_model.dart';

void main() {
  group('UnitCategory', () {
    test('fromValue devuelve categoría correcta', () {
      expect(UnitCategory.fromValue('weight'), UnitCategory.weight);
      expect(UnitCategory.fromValue('volume'), UnitCategory.volume);
      expect(UnitCategory.fromValue('length'), UnitCategory.length);
      expect(UnitCategory.fromValue('unit'), UnitCategory.unit);
    });

    test('fromValue devuelve unit para valor desconocido', () {
      expect(UnitCategory.fromValue('desconocido'), UnitCategory.unit);
    });

    test('cada categoría tiene displayName y icono', () {
      expect(UnitCategory.weight.displayName, 'Peso');
      expect(UnitCategory.weight.icon, 'scale');

      expect(UnitCategory.volume.displayName, 'Volumen');
      expect(UnitCategory.volume.icon, 'water_drop');

      expect(UnitCategory.length.displayName, 'Longitud');
      expect(UnitCategory.length.icon, 'straighten');

      expect(UnitCategory.unit.displayName, 'Unidades');
      expect(UnitCategory.unit.icon, 'inventory_2');
    });
  });

  group('UnitModel', () {
    test('se crea correctamente', () {
      final unit = UnitModel(
        id: 'unit_kg',
        name: 'Kilogramo',
        shortName: 'kg',
        category: 'weight',
        isSystem: true,
        createdAt: DateTime.now(),
      );

      expect(unit.id, 'unit_kg');
      expect(unit.name, 'Kilogramo');
      expect(unit.shortName, 'kg');
      expect(unit.category, 'weight');
      expect(unit.isSystem, true);
    });

    test('categoryEnum retorna categoría tipada', () {
      final unit = UnitModel(
        id: 'test',
        name: 'Test',
        shortName: 't',
        category: 'weight',
      );

      expect(unit.categoryEnum, UnitCategory.weight);
    });

    test('displayNameWithShort formatea correctamente', () {
      final unit = UnitModel(
        id: 'test',
        name: 'Kilogramo',
        shortName: 'kg',
        category: 'weight',
      );

      expect(unit.displayNameWithShort, 'Kilogramo (kg)');
    });

    test('isSystem es true por defecto', () {
      final unit = UnitModel(
        id: 'test',
        name: 'Test',
        shortName: 't',
        category: 'unit',
      );

      expect(unit.isSystem, true);
    });

    test('fromJson y toJson son consistentes', () {
      final original = UnitModel(
        id: 'unit_l',
        name: 'Litro',
        shortName: 'L',
        category: 'volume',
        isSystem: true,
        createdAt: DateTime(2024, 1, 1),
      );

      final json = original.toJson();
      final restored = UnitModel.fromJson(json);

      expect(restored.id, original.id);
      expect(restored.name, original.name);
      expect(restored.shortName, original.shortName);
      expect(restored.category, original.category);
      expect(restored.isSystem, original.isSystem);
    });
  });

  group('Unidades de sistema predefinidas', () {
    final defaultUnits = [
      ('Kilogramo', 'kg', 'weight'),
      ('Gramo', 'g', 'weight'),
      ('Libra', 'lb', 'weight'),
      ('Litro', 'L', 'volume'),
      ('Mililitro', 'ml', 'volume'),
      ('Metro', 'm', 'length'),
      ('Centímetro', 'cm', 'length'),
      ('Unidad', 'u', 'unit'),
      ('Docena', 'doc', 'unit'),
    ];

    for (final (name, shortName, category) in defaultUnits) {
      test('unidad "$name" ($shortName) es válida', () {
        final unit = UnitModel(
          id: 'unit_$shortName',
          name: name,
          shortName: shortName,
          category: category,
        );

        expect(unit.name, isNotEmpty);
        expect(unit.shortName, isNotEmpty);
        expect(unit.categoryEnum, isNotNull);
      });
    }
  });
}
