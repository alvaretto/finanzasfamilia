import 'package:drift/drift.dart';
import 'accounts_table.dart';
import 'categories_table.dart';
import 'places_table.dart';

/// Tabla de transacciones financieras (Header)
/// Registra: ingresos, gastos y transferencias
/// Los detalles se almacenan en TransactionDetails (Shopping Cart)
@DataClassName('TransactionEntry')
class Transactions extends Table {
  /// UUID único de la transacción
  TextColumn get id => text()();

  /// ID del usuario propietario (para sincronización con PowerSync)
  TextColumn get userId => text().nullable()();

  /// Tipo de transacción: income, expense, transfer
  TextColumn get type => text()();

  /// Monto total de la transacción (suma de detalles)
  RealColumn get amount => real()();

  /// Descripción o nota de la transacción
  TextColumn get description => text().nullable()();

  /// Cuenta origen (de donde sale el dinero)
  @ReferenceName('transactionsFromAccount')
  TextColumn get fromAccountId => text().nullable().references(Accounts, #id)();

  /// Cuenta destino (a donde llega el dinero)
  @ReferenceName('transactionsToAccount')
  TextColumn get toAccountId => text().nullable().references(Accounts, #id)();

  /// Categoría principal del gasto/ingreso (ej: "Alimentación", "Salario")
  TextColumn get categoryId => text().references(Categories, #id)();

  /// Lugar donde se realizó la transacción
  TextColumn get placeId => text().nullable().references(Places, #id)();

  /// Fecha de la transacción
  DateTimeColumn get transactionDate => dateTime()();

  /// Si la transacción está confirmada
  /// Nullable para compatibilidad con PowerSync (datos pueden llegar sin este campo)
  BoolColumn get isConfirmed => boolean().nullable()();

  /// Si tiene múltiples detalles (Shopping Cart)
  /// Nullable para compatibilidad con PowerSync
  BoolColumn get hasDetails => boolean().nullable()();

  /// Número de items en el detalle
  /// Nullable para compatibilidad con PowerSync
  IntColumn get itemCount => integer().nullable()();

  /// Estado de sincronización: pending, synced, error
  /// Nullable para compatibilidad con PowerSync
  TextColumn get syncStatus => text().nullable()();

  /// Orden global de sincronización (estilo Linear)
  IntColumn get syncSequence => integer().nullable()();

  /// Timestamps - Nullable para compatibilidad con PowerSync
  DateTimeColumn get createdAt => dateTime().nullable()();
  DateTimeColumn get updatedAt => dateTime().nullable()();

  @override
  Set<Column> get primaryKey => {id};
}
