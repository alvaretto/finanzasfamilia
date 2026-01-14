import 'package:drift/drift.dart';
import 'categories_table.dart';

/// Tabla de cuentas/billeteras del usuario
/// Representa: Nequi, DaviPlata, Efectivo, Tarjetas, etc.
@DataClassName('AccountEntry')
class Accounts extends Table {
  /// UUID único de la cuenta
  TextColumn get id => text()();

  /// ID del usuario propietario (para sincronización con PowerSync)
  TextColumn get userId => text().nullable()();

  /// Nombre de la cuenta (ej: "Nequi", "Billetera Personal", "Visa")
  TextColumn get name => text().withLength(min: 1, max: 100)();

  /// Tipo de cuenta (wallet, bank, credit_card, etc.)
  /// Nullable para compatibilidad con PowerSync, default: wallet
  TextColumn get type => text().nullable()();

  /// Icono emoji o código de icono
  TextColumn get icon => text().withLength(max: 10).nullable()();

  /// Categoría a la que pertenece (ej: "Billeteras Digitales", "Efectivo")
  TextColumn get categoryId => text().references(Categories, #id)();

  /// Saldo actual de la cuenta
  /// Nullable para compatibilidad con PowerSync
  RealColumn get balance => real().nullable()();

  /// Moneda (COP por defecto)
  /// Nullable para compatibilidad con PowerSync
  TextColumn get currency => text().nullable()();

  /// Color para identificación visual (hex)
  TextColumn get color => text().withLength(max: 7).nullable()();

  /// Descripción opcional
  TextColumn get description => text().nullable()();

  /// Si incluir en el balance total
  /// Nullable para compatibilidad con PowerSync
  BoolColumn get includeInTotal => boolean().nullable()();

  /// Si la cuenta está activa
  /// Nullable para compatibilidad con PowerSync
  BoolColumn get isActive => boolean().nullable()();

  /// Si es una cuenta del sistema (predefinida, no eliminable)
  /// Nullable para compatibilidad con PowerSync
  BoolColumn get isSystem => boolean().nullable()();

  /// Orden global de sincronización (estilo Linear)
  IntColumn get syncSequence => integer().nullable()();

  /// Timestamps - Nullable para compatibilidad con PowerSync
  DateTimeColumn get createdAt => dateTime().nullable()();
  DateTimeColumn get updatedAt => dateTime().nullable()();

  @override
  Set<Column> get primaryKey => {id};
}
