import 'package:drift/drift.dart';

/// Tipos de unidad de medida
enum MeasurementType {
  /// Peso (Libra, Kilo, Gramo)
  weight,

  /// Volumen (Litro, Mililitro, Galón)
  volume,

  /// Unidad individual
  unit,

  /// Empaque (Caja, Bolsa, Paquete)
  package,
}

/// Tabla de Unidades de Medida
/// Para registrar cantidades en detalle de transacciones
@DataClassName('MeasurementUnitEntry')
class MeasurementUnits extends Table {
  /// ID único (UUID)
  TextColumn get id => text()();

  /// ID del usuario propietario (para sincronización con PowerSync)
  TextColumn get userId => text().nullable()();

  /// Nombre de la unidad (Libra, Litro, Unidad, etc.)
  TextColumn get name => text().withLength(min: 1, max: 50)();

  /// Abreviación (lb, lt, ud, cj)
  TextColumn get abbreviation => text().withLength(min: 1, max: 10)();

  /// Tipo de unidad
  TextColumn get type => text()();

  /// Factor de conversión a unidad base (ej: 1 kilo = 2.2 libras) - Nullable para PowerSync
  RealColumn get conversionFactor => real().nullable()();

  /// Unidad base para conversión (nullable si es unidad base)
  TextColumn get baseUnitId => text().nullable()();

  /// Si está activa - Nullable para compatibilidad con PowerSync
  BoolColumn get isActive => boolean().nullable()();

  /// Si es del sistema (no editable por usuario) - Nullable para compatibilidad con PowerSync
  BoolColumn get isSystem => boolean().nullable()();

  /// Orden de visualización - Nullable para compatibilidad con PowerSync
  IntColumn get sortOrder => integer().nullable()();

  /// Orden global de sincronización (estilo Linear)
  IntColumn get syncSequence => integer().nullable()();

  /// Timestamps
  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get updatedAt => dateTime()();

  @override
  Set<Column> get primaryKey => {id};
}
