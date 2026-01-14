import 'package:drift/drift.dart';
import 'package:uuid/uuid.dart';

import '../database.dart';
import '../daos/measurement_units_dao.dart';
import '../tables/measurement_units_table.dart';

const _uuid = Uuid();

/// Namespace UUID para generar IDs determinísticos de unidades del sistema.
const _systemUnitNamespace = '6ba7b811-9dad-11d1-80b4-00c04fd430c8';

/// Genera un UUID determinístico para una unidad del sistema.
String _deterministicId(String unitName, MeasurementType type) {
  return _uuid.v5(_systemUnitNamespace, 'unit:${type.name}:$unitName');
}

/// Siembra las unidades de medida predefinidas para Colombia
/// Incluye unidades de peso, volumen, unidad y empaque
Future<void> seedMeasurementUnits(MeasurementUnitsDao dao) async {
  final existingUnits = await dao.getAllUnits();
  if (existingUnits.isNotEmpty) {
    return; // Ya sembrado
  }

  final units = <MeasurementUnitsCompanion>[];

  // ==========================================
  // PESO (Weight)
  // ==========================================
  // Libra es la unidad base en Colombia para compras diarias
  final libraId = _deterministicId('Libra', MeasurementType.weight);
  units.add(_unit(
    id: libraId,
    name: 'Libra',
    abbreviation: 'lb',
    type: MeasurementType.weight,
    conversionFactor: 1.0,
    sortOrder: 1,
  ));

  units.addAll([
    _unit(
      name: 'Kilogramo',
      abbreviation: 'kg',
      type: MeasurementType.weight,
      conversionFactor: 2.2046, // 1 kg = 2.2046 lb
      baseUnitId: libraId,
      sortOrder: 2,
    ),
    _unit(
      name: 'Gramo',
      abbreviation: 'g',
      type: MeasurementType.weight,
      conversionFactor: 0.0022, // 1 g = 0.0022 lb
      baseUnitId: libraId,
      sortOrder: 3,
    ),
    _unit(
      name: 'Arroba',
      abbreviation: 'arr',
      type: MeasurementType.weight,
      conversionFactor: 25.0, // 1 arroba = 25 lb en Colombia
      baseUnitId: libraId,
      sortOrder: 4,
    ),
    _unit(
      name: 'Onza',
      abbreviation: 'oz',
      type: MeasurementType.weight,
      conversionFactor: 0.0625, // 1 oz = 1/16 lb
      baseUnitId: libraId,
      sortOrder: 5,
    ),
  ]);

  // ==========================================
  // VOLUMEN (Volume)
  // ==========================================
  // Litro es la unidad base para volumen
  final litroId = _deterministicId('Litro', MeasurementType.volume);
  units.add(_unit(
    id: litroId,
    name: 'Litro',
    abbreviation: 'lt',
    type: MeasurementType.volume,
    conversionFactor: 1.0,
    sortOrder: 10,
  ));

  units.addAll([
    _unit(
      name: 'Mililitro',
      abbreviation: 'ml',
      type: MeasurementType.volume,
      conversionFactor: 0.001, // 1 ml = 0.001 lt
      baseUnitId: litroId,
      sortOrder: 11,
    ),
    _unit(
      name: 'Galón',
      abbreviation: 'gal',
      type: MeasurementType.volume,
      conversionFactor: 3.785, // 1 galón US = 3.785 lt
      baseUnitId: litroId,
      sortOrder: 12,
    ),
    _unit(
      name: 'Botella (750ml)',
      abbreviation: 'bot',
      type: MeasurementType.volume,
      conversionFactor: 0.75,
      baseUnitId: litroId,
      sortOrder: 13,
    ),
  ]);

  // ==========================================
  // UNIDAD (Unit)
  // ==========================================
  units.addAll([
    _unit(
      name: 'Unidad',
      abbreviation: 'ud',
      type: MeasurementType.unit,
      conversionFactor: 1.0,
      sortOrder: 20,
    ),
    _unit(
      name: 'Par',
      abbreviation: 'par',
      type: MeasurementType.unit,
      conversionFactor: 2.0,
      sortOrder: 21,
    ),
    _unit(
      name: 'Docena',
      abbreviation: 'doc',
      type: MeasurementType.unit,
      conversionFactor: 12.0,
      sortOrder: 22,
    ),
    _unit(
      name: 'Media Docena',
      abbreviation: '½doc',
      type: MeasurementType.unit,
      conversionFactor: 6.0,
      sortOrder: 23,
    ),
  ]);

  // ==========================================
  // EMPAQUE (Package)
  // ==========================================
  units.addAll([
    _unit(
      name: 'Paquete',
      abbreviation: 'paq',
      type: MeasurementType.package,
      conversionFactor: 1.0,
      sortOrder: 30,
    ),
    _unit(
      name: 'Bolsa',
      abbreviation: 'bol',
      type: MeasurementType.package,
      conversionFactor: 1.0,
      sortOrder: 31,
    ),
    _unit(
      name: 'Caja',
      abbreviation: 'cj',
      type: MeasurementType.package,
      conversionFactor: 1.0,
      sortOrder: 32,
    ),
    _unit(
      name: 'Lata',
      abbreviation: 'lat',
      type: MeasurementType.package,
      conversionFactor: 1.0,
      sortOrder: 33,
    ),
    _unit(
      name: 'Bandeja',
      abbreviation: 'bdj',
      type: MeasurementType.package,
      conversionFactor: 1.0,
      sortOrder: 34,
    ),
    _unit(
      name: 'Sobre',
      abbreviation: 'sob',
      type: MeasurementType.package,
      conversionFactor: 1.0,
      sortOrder: 35,
    ),
    _unit(
      name: 'Atado',
      abbreviation: 'atd',
      type: MeasurementType.package,
      conversionFactor: 1.0,
      sortOrder: 36,
    ),
  ]);

  await dao.insertUnits(units);
}

/// Helper para crear una unidad de medida con ID determinístico
MeasurementUnitsCompanion _unit({
  String? id,
  required String name,
  required String abbreviation,
  required MeasurementType type,
  required double conversionFactor,
  String? baseUnitId,
  required int sortOrder,
}) {
  final now = DateTime.now();
  return MeasurementUnitsCompanion(
    id: Value(id ?? _deterministicId(name, type)),
    name: Value(name),
    abbreviation: Value(abbreviation),
    type: Value(type.name),
    conversionFactor: Value(conversionFactor),
    baseUnitId: Value(baseUnitId),
    isActive: const Value(true),
    isSystem: const Value(true),
    sortOrder: Value(sortOrder),
    createdAt: Value(now),
    updatedAt: Value(now),
  );
}
