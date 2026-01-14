import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:finanzas_familiares/data/local/database.dart';
import 'package:finanzas_familiares/data/local/daos/measurement_units_dao.dart';
import 'package:finanzas_familiares/data/local/seeders/measurement_units_seeder.dart';
import 'package:finanzas_familiares/data/local/tables/measurement_units_table.dart';

/// Tests para verificar que las unidades de medida
/// se siembran correctamente en la base de datos.
void main() {
  late AppDatabase database;
  late MeasurementUnitsDao unitsDao;

  setUp(() {
    database = AppDatabase.forTesting(NativeDatabase.memory());
    unitsDao = MeasurementUnitsDao(database);
  });

  tearDown(() async {
    await database.close();
  });

  group('Measurement Units Seeder', () {
    test('debe sembrar unidades de peso con Libra como base', () async {
      // Arrange & Act
      await seedMeasurementUnits(unitsDao);

      // Assert
      final weightUnits = await unitsDao.getUnitsByType(MeasurementType.weight);
      expect(weightUnits.length, greaterThanOrEqualTo(5));

      final unitNames = weightUnits.map((u) => u.name).toSet();
      expect(unitNames, contains('Libra'));
      expect(unitNames, contains('Kilogramo'));
      expect(unitNames, contains('Gramo'));
      expect(unitNames, contains('Arroba'));
      expect(unitNames, contains('Onza'));

      // Libra debe ser la unidad base (sin baseUnitId)
      final libra = weightUnits.firstWhere((u) => u.name == 'Libra');
      expect(libra.baseUnitId, isNull);
      expect(libra.conversionFactor, equals(1.0));
    });

    test('debe sembrar unidades de volumen con Litro como base', () async {
      // Arrange & Act
      await seedMeasurementUnits(unitsDao);

      // Assert
      final volumeUnits = await unitsDao.getUnitsByType(MeasurementType.volume);
      expect(volumeUnits.length, greaterThanOrEqualTo(4));

      final unitNames = volumeUnits.map((u) => u.name).toSet();
      expect(unitNames, contains('Litro'));
      expect(unitNames, contains('Mililitro'));
      expect(unitNames, contains('Galón'));

      // Litro debe ser la unidad base
      final litro = volumeUnits.firstWhere((u) => u.name == 'Litro');
      expect(litro.baseUnitId, isNull);
      expect(litro.conversionFactor, equals(1.0));
    });

    test('debe sembrar unidades individuales', () async {
      // Arrange & Act
      await seedMeasurementUnits(unitsDao);

      // Assert
      final unitUnits = await unitsDao.getUnitsByType(MeasurementType.unit);
      expect(unitUnits.length, greaterThanOrEqualTo(4));

      final unitNames = unitUnits.map((u) => u.name).toSet();
      expect(unitNames, contains('Unidad'));
      expect(unitNames, contains('Par'));
      expect(unitNames, contains('Docena'));
      expect(unitNames, contains('Media Docena'));

      // Verificar factor de conversión de Docena
      final docena = unitUnits.firstWhere((u) => u.name == 'Docena');
      expect(docena.conversionFactor, equals(12.0));
    });

    test('debe sembrar unidades de empaque', () async {
      // Arrange & Act
      await seedMeasurementUnits(unitsDao);

      // Assert
      final packageUnits =
          await unitsDao.getUnitsByType(MeasurementType.package);
      expect(packageUnits.length, greaterThanOrEqualTo(6));

      final unitNames = packageUnits.map((u) => u.name).toSet();
      expect(unitNames, contains('Paquete'));
      expect(unitNames, contains('Bolsa'));
      expect(unitNames, contains('Caja'));
      expect(unitNames, contains('Lata'));
      expect(unitNames, contains('Bandeja'));
      expect(unitNames, contains('Atado'));
    });

    test('debe tener abreviaciones correctas', () async {
      // Arrange & Act
      await seedMeasurementUnits(unitsDao);

      // Assert
      final allUnits = await unitsDao.getAllUnits();

      final libra = allUnits.firstWhere((u) => u.name == 'Libra');
      expect(libra.abbreviation, equals('lb'));

      final litro = allUnits.firstWhere((u) => u.name == 'Litro');
      expect(litro.abbreviation, equals('lt'));

      final unidad = allUnits.firstWhere((u) => u.name == 'Unidad');
      expect(unidad.abbreviation, equals('ud'));

      final caja = allUnits.firstWhere((u) => u.name == 'Caja');
      expect(caja.abbreviation, equals('cj'));
    });

    test('debe marcar todas las unidades como sistema', () async {
      // Arrange & Act
      await seedMeasurementUnits(unitsDao);

      // Assert
      final allUnits = await unitsDao.getAllUnits();
      for (final unit in allUnits) {
        expect(unit.isSystem, isTrue,
            reason: 'Unidad ${unit.name} debe ser isSystem=true');
      }
    });

    test('no debe sembrar duplicados si ya existen unidades', () async {
      // Arrange - Sembrar primero
      await seedMeasurementUnits(unitsDao);
      final countBefore = (await unitsDao.getAllUnits()).length;

      // Act - Intentar sembrar de nuevo
      await seedMeasurementUnits(unitsDao);
      final countAfter = (await unitsDao.getAllUnits()).length;

      // Assert - No deben haber cambiado
      expect(countAfter, equals(countBefore));
    });

    test('debe tener factores de conversión válidos', () async {
      // Arrange & Act
      await seedMeasurementUnits(unitsDao);

      // Assert - Verificar conversiones de peso
      final weightUnits = await unitsDao.getUnitsByType(MeasurementType.weight);

      final kilo = weightUnits.firstWhere((u) => u.name == 'Kilogramo');
      expect(kilo.conversionFactor, closeTo(2.2046, 0.001));

      final arroba = weightUnits.firstWhere((u) => u.name == 'Arroba');
      expect(arroba.conversionFactor, equals(25.0));

      // Verificar conversiones de volumen
      final volumeUnits = await unitsDao.getUnitsByType(MeasurementType.volume);

      final galon = volumeUnits.firstWhere((u) => u.name == 'Galón');
      expect(galon.conversionFactor, closeTo(3.785, 0.001));
    });

    test('debe ordenar unidades correctamente por sortOrder', () async {
      // Arrange & Act
      await seedMeasurementUnits(unitsDao);

      // Assert
      final weightUnits = await unitsDao.getUnitsByType(MeasurementType.weight);

      // Verificar que están ordenadas
      for (int i = 0; i < weightUnits.length - 1; i++) {
        expect(weightUnits[i].sortOrder ?? 0,
            lessThanOrEqualTo(weightUnits[i + 1].sortOrder ?? 0));
      }
    });
  });
}
