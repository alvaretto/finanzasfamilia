import 'package:drift/drift.dart';
import 'categories_table.dart';

/// Tabla de presupuestos mensuales por categoría
/// Para el "Semáforo de Presupuesto" (Traffic Light)
@DataClassName('BudgetEntry')
class Budgets extends Table {
  /// UUID único del presupuesto
  TextColumn get id => text()();

  /// ID del usuario propietario (para sincronización con PowerSync)
  TextColumn get userId => text().nullable()();

  /// Categoría del presupuesto
  TextColumn get categoryId => text().references(Categories, #id)();

  /// Monto límite del presupuesto
  RealColumn get amount => real()();

  /// Mes del presupuesto (1-12)
  IntColumn get month => integer()();

  /// Año del presupuesto
  IntColumn get year => integer()();

  /// Si el presupuesto está activo
  /// Nullable para compatibilidad con PowerSync
  BoolColumn get isActive => boolean().nullable()();

  /// Orden global de sincronización (estilo Linear)
  IntColumn get syncSequence => integer().nullable()();

  /// Timestamps - Nullable para compatibilidad con PowerSync
  DateTimeColumn get createdAt => dateTime().nullable()();
  DateTimeColumn get updatedAt => dateTime().nullable()();

  @override
  Set<Column> get primaryKey => {id};
}
