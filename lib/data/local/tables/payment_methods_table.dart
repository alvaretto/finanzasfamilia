import 'package:drift/drift.dart';

import 'accounts_table.dart';

/// Tabla de Métodos de Pago
/// Vincula nombres amigables con cuentas de activos
/// Ej: "Nequi Personal" -> Cuenta Nequi en Activos:Bancos:Nequi
@DataClassName('PaymentMethodEntry')
class PaymentMethods extends Table {
  /// ID único (UUID)
  TextColumn get id => text()();

  /// Nombre amigable (Efectivo Casa, Nequi Personal, TC Visa)
  TextColumn get name => text().withLength(min: 1, max: 100)();

  /// ID de la cuenta vinculada (referencia a Accounts)
  /// Esta cuenta debe ser de tipo Asset (Activo)
  TextColumn get accountId => text().references(Accounts, #id)();

  /// Icono opcional
  TextColumn get icon => text().withLength(max: 10).nullable()();

  /// Color para UI (hex)
  TextColumn get color => text().withLength(max: 7).nullable()();

  /// Si es el método de pago por defecto
  BoolColumn get isDefault => boolean().withDefault(const Constant(false))();

  /// Si está activo
  BoolColumn get isActive => boolean().withDefault(const Constant(true))();

  /// Orden de visualización
  IntColumn get sortOrder => integer().withDefault(const Constant(0))();

  /// Timestamps
  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get updatedAt => dateTime()();

  @override
  Set<Column> get primaryKey => {id};
}
