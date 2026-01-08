import 'package:drift/drift.dart';
import 'categories_table.dart';

/// Tabla de cuentas/billeteras del usuario
/// Representa: Nequi, DaviPlata, Efectivo, Tarjetas, etc.
@DataClassName('AccountEntry')
class Accounts extends Table {
  /// UUID único de la cuenta
  TextColumn get id => text()();

  /// Nombre de la cuenta (ej: "Nequi", "Billetera Personal", "Visa")
  TextColumn get name => text().withLength(min: 1, max: 100)();

  /// Icono emoji o código de icono
  TextColumn get icon => text().withLength(max: 10).nullable()();

  /// Categoría a la que pertenece (ej: "Billeteras Digitales", "Efectivo")
  TextColumn get categoryId => text().references(Categories, #id)();

  /// Saldo actual de la cuenta
  RealColumn get balance => real().withDefault(const Constant(0.0))();

  /// Moneda (COP por defecto)
  TextColumn get currency => text().withDefault(const Constant('COP'))();

  /// Color para identificación visual (hex)
  TextColumn get color => text().withLength(max: 7).nullable()();

  /// Descripción opcional
  TextColumn get description => text().nullable()();

  /// Si incluir en el balance total
  BoolColumn get includeInTotal => boolean().withDefault(const Constant(true))();

  /// Si la cuenta está activa
  BoolColumn get isActive => boolean().withDefault(const Constant(true))();

  /// Timestamps
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
  DateTimeColumn get updatedAt => dateTime().withDefault(currentDateAndTime)();

  @override
  Set<Column> get primaryKey => {id};
}
