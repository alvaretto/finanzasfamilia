import 'package:drift/drift.dart';

import 'transactions_table.dart';
import 'categories_table.dart';
import 'measurement_units_table.dart';
import 'payment_methods_table.dart';

/// Modo de transacción
enum TransactionMode {
  /// Pago de contado (inmediato)
  cash,

  /// Pago a crédito (diferido)
  credit,
}

/// Tabla de Detalles de Transacción (Shopping Cart)
/// Una transacción puede tener múltiples detalles (items)
/// Ej: Una compra en supermercado con múltiples productos
@DataClassName('TransactionDetailEntry')
class TransactionDetails extends Table {
  /// ID único (UUID)
  TextColumn get id => text()();

  /// ID del usuario propietario (para sincronización con PowerSync)
  TextColumn get userId => text().nullable()();

  /// ID de la transacción padre (Header)
  TextColumn get transactionId => text().references(Transactions, #id)();

  /// Concepto/Descripción del item
  TextColumn get concept => text().withLength(min: 1, max: 200)();

  /// Categoría específica del item (puede diferir del header)
  TextColumn get categoryId => text().references(Categories, #id)();

  /// Valor unitario
  RealColumn get unitValue => real()();

  /// Cantidad - Nullable para compatibilidad con PowerSync
  RealColumn get quantity => real().nullable()();

  /// Unidad de medida
  TextColumn get measurementUnitId =>
      text().nullable().references(MeasurementUnits, #id)();

  /// Valor total (unitValue * quantity)
  RealColumn get totalValue => real()();

  /// Método de pago usado para este item
  TextColumn get paymentMethodId =>
      text().nullable().references(PaymentMethods, #id)();

  /// Modo de pago (Contado/Crédito) - Nullable para compatibilidad con PowerSync
  TextColumn get mode => text().nullable()();

  /// Fecha de causación (puede diferir de fecha de transacción para créditos)
  DateTimeColumn get accrualDate => dateTime().nullable()();

  /// Descuento aplicado (si aplica) - Nullable para compatibilidad con PowerSync
  RealColumn get discount => real().nullable()();

  /// Notas adicionales
  TextColumn get notes => text().nullable()();

  /// Orden dentro de la transacción - Nullable para compatibilidad con PowerSync
  IntColumn get sortOrder => integer().nullable()();

  /// Orden global de sincronización (estilo Linear)
  IntColumn get syncSequence => integer().nullable()();

  /// Timestamps
  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get updatedAt => dateTime()();

  @override
  Set<Column> get primaryKey => {id};
}
