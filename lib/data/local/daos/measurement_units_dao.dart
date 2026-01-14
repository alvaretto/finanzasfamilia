import 'package:drift/drift.dart';
import '../database.dart';
import '../tables/measurement_units_table.dart';

part 'measurement_units_dao.g.dart';

/// DAO para operaciones con unidades de medida
@DriftAccessor(tables: [MeasurementUnits])
class MeasurementUnitsDao extends DatabaseAccessor<AppDatabase>
    with _$MeasurementUnitsDaoMixin {
  MeasurementUnitsDao(super.db);

  /// Obtiene todas las unidades de medida activas
  /// Considera isActive = NULL como activo (valor por defecto)
  Future<List<MeasurementUnitEntry>> getAllActiveUnits() {
    return (select(measurementUnits)
          ..where((u) => u.isActive.equals(true) | u.isActive.isNull())
          ..orderBy([(u) => OrderingTerm.asc(u.sortOrder)]))
        .get();
  }

  /// Obtiene todas las unidades de medida
  Future<List<MeasurementUnitEntry>> getAllUnits() {
    return (select(measurementUnits)
          ..orderBy([(u) => OrderingTerm.asc(u.sortOrder)]))
        .get();
  }

  /// Obtiene unidades por tipo
  /// Considera isActive = NULL como activo (valor por defecto)
  Future<List<MeasurementUnitEntry>> getUnitsByType(MeasurementType type) {
    return (select(measurementUnits)
          ..where((u) => u.type.equals(type.name))
          ..where((u) => u.isActive.equals(true) | u.isActive.isNull())
          ..orderBy([(u) => OrderingTerm.asc(u.sortOrder)]))
        .get();
  }

  /// Obtiene una unidad por ID
  Future<MeasurementUnitEntry?> getUnitById(String id) {
    return (select(measurementUnits)..where((u) => u.id.equals(id)))
        .getSingleOrNull();
  }

  /// Inserta una nueva unidad
  Future<void> insertUnit(MeasurementUnitsCompanion unit) {
    return into(measurementUnits).insert(unit);
  }

  /// Inserta múltiples unidades
  Future<void> insertUnits(List<MeasurementUnitsCompanion> units) {
    return batch((batch) {
      batch.insertAll(measurementUnits, units);
    });
  }

  /// Actualiza una unidad
  Future<bool> updateUnit(MeasurementUnitEntry unit) {
    return update(measurementUnits).replace(unit);
  }

  /// Elimina una unidad (soft delete)
  Future<int> deactivateUnit(String id) {
    return (update(measurementUnits)..where((u) => u.id.equals(id)))
        .write(const MeasurementUnitsCompanion(isActive: Value(false)));
  }

  /// Cuenta unidades por tipo
  Future<int> countByType(MeasurementType type) async {
    final count = measurementUnits.id.count();
    final query = selectOnly(measurementUnits)
      ..addColumns([count])
      ..where(measurementUnits.type.equals(type.name));
    final result = await query.getSingle();
    return result.read(count) ?? 0;
  }
}
