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

  /// Tipo de transacción: income, expense, transfer
  TextColumn get type => text()();

  /// Monto total de la transacción (suma de detalles)
  RealColumn get amount => real()();

  /// Descripción o nota de la transacción
  TextColumn get description => text().nullable()();

  /// Cuenta origen (de donde sale el dinero)
  TextColumn get fromAccountId => text().nullable().references(Accounts, #id)();

  /// Cuenta destino (a donde llega el dinero)
  TextColumn get toAccountId => text().nullable().references(Accounts, #id)();

  /// Categoría principal del gasto/ingreso (ej: "Alimentación", "Salario")
  TextColumn get categoryId => text().references(Categories, #id)();

  /// Lugar donde se realizó la transacción
  TextColumn get placeId => text().nullable().references(Places, #id)();

  /// Fecha de la transacción
  DateTimeColumn get transactionDate => dateTime()();

  /// Si la transacción está confirmada
  BoolColumn get isConfirmed => boolean().withDefault(const Constant(true))();

  /// Si tiene múltiples detalles (Shopping Cart)
  BoolColumn get hasDetails => boolean().withDefault(const Constant(false))();

  /// Número de items en el detalle
  IntColumn get itemCount => integer().withDefault(const Constant(1))();

  /// Estado de sincronización: pending, synced, error
  TextColumn get syncStatus => text().withDefault(const Constant('pending'))();

  /// Timestamps
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
  DateTimeColumn get updatedAt => dateTime().withDefault(currentDateAndTime)();

  @override
  Set<Column> get primaryKey => {id};
}
