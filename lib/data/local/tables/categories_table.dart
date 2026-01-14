import 'package:drift/drift.dart';

/// Tabla de categorías jerárquicas
/// Representa la taxonomía: Activos, Pasivos, Ingresos, Gastos
/// con sus subcategorías anidadas (parent_id)
@DataClassName('CategoryEntry')
class Categories extends Table {
  /// UUID único de la categoría
  TextColumn get id => text()();

  /// ID del usuario propietario (para sincronización con PowerSync)
  TextColumn get userId => text().nullable()();

  /// Nombre de la categoría (ej: "Alimentación", "Mercado", "Frutas")
  TextColumn get name => text().withLength(min: 1, max: 100)();

  /// Icono emoji (ej: "🥦", "💵", "🏦")
  TextColumn get icon => text().withLength(max: 10).nullable()();

  /// Tipo de cuenta: asset, liability, income, expense
  TextColumn get type => text()();

  /// ID del padre para jerarquía (null = categoría raíz)
  TextColumn get parentId => text().nullable().references(Categories, #id)();

  /// Nivel en la jerarquía (0 = raíz, 1 = hijo, 2 = nieto, etc.)
  /// Nullable para compatibilidad con PowerSync
  IntColumn get level => integer().nullable()();

  /// Orden de visualización dentro del mismo nivel
  /// Nullable para compatibilidad con PowerSync
  IntColumn get sortOrder => integer().nullable()();

  /// Si la categoría está activa
  /// Nullable para compatibilidad con PowerSync
  BoolColumn get isActive => boolean().nullable()();

  /// Si es una categoría del sistema (no editable por usuario)
  /// Nullable para compatibilidad con PowerSync
  BoolColumn get isSystem => boolean().nullable()();

  /// Orden global de sincronización (estilo Linear)
  /// Garantiza que padres se sincronicen antes que hijos
  IntColumn get syncSequence => integer().nullable()();

  /// Timestamps - Nullable para compatibilidad con PowerSync
  DateTimeColumn get createdAt => dateTime().nullable()();
  DateTimeColumn get updatedAt => dateTime().nullable()();

  @override
  Set<Column> get primaryKey => {id};
}
