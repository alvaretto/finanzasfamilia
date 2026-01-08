import 'package:drift/drift.dart';
import 'categories_table.dart';

/// Tabla de presupuestos mensuales por categoría
/// Para el "Semáforo de Presupuesto" (Traffic Light)
@DataClassName('BudgetEntry')
class Budgets extends Table {
  /// UUID único del presupuesto
  TextColumn get id => text()();

  /// Categoría del presupuesto
  TextColumn get categoryId => text().references(Categories, #id)();

  /// Monto límite del presupuesto
  RealColumn get amount => real()();

  /// Mes del presupuesto (1-12)
  IntColumn get month => integer()();

  /// Año del presupuesto
  IntColumn get year => integer()();

  /// Si el presupuesto está activo
  BoolColumn get isActive => boolean().withDefault(const Constant(true))();

  /// Timestamps
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
  DateTimeColumn get updatedAt => dateTime().withDefault(currentDateAndTime)();

  @override
  Set<Column> get primaryKey => {id};
}
