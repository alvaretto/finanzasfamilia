import 'package:drift/drift.dart';

/// Tabla de categorías jerárquicas
/// Representa la taxonomía: Activos, Pasivos, Ingresos, Gastos
/// con sus subcategorías anidadas (parent_id)
@DataClassName('CategoryEntry')
class Categories extends Table {
  /// UUID único de la categoría
  TextColumn get id => text()();

  /// Nombre de la categoría (ej: "Alimentación", "Mercado", "Frutas")
  TextColumn get name => text().withLength(min: 1, max: 100)();

  /// Icono emoji (ej: "🥦", "💵", "🏦")
  TextColumn get icon => text().withLength(max: 10).nullable()();

  /// Tipo de cuenta: asset, liability, income, expense
  TextColumn get type => text()();

  /// ID del padre para jerarquía (null = categoría raíz)
  TextColumn get parentId => text().nullable().references(Categories, #id)();

  /// Nivel en la jerarquía (0 = raíz, 1 = hijo, 2 = nieto, etc.)
  IntColumn get level => integer().withDefault(const Constant(0))();

  /// Orden de visualización dentro del mismo nivel
  IntColumn get sortOrder => integer().withDefault(const Constant(0))();

  /// Si la categoría está activa
  BoolColumn get isActive => boolean().withDefault(const Constant(true))();

  /// Si es una categoría del sistema (no editable por usuario)
  BoolColumn get isSystem => boolean().withDefault(const Constant(false))();

  /// Timestamps
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
  DateTimeColumn get updatedAt => dateTime().withDefault(currentDateAndTime)();

  @override
  Set<Column> get primaryKey => {id};
}
