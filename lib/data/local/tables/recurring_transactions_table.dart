import 'package:drift/drift.dart';
import 'accounts_table.dart';
import 'categories_table.dart';

/// Frecuencia de recurrencia
enum RecurrenceFrequency {
  /// Diario
  daily,

  /// Semanal
  weekly,

  /// Quincenal
  biweekly,

  /// Mensual
  monthly,

  /// Bimestral
  bimonthly,

  /// Trimestral
  quarterly,

  /// Semestral
  semiannual,

  /// Anual
  yearly,
}

/// Tabla de transacciones recurrentes
/// Permite configurar pagos automáticos como servicios públicos, suscripciones, etc.
@DataClassName('RecurringTransactionEntry')
class RecurringTransactions extends Table {
  /// UUID único
  TextColumn get id => text()();

  /// ID del usuario propietario (para sincronización con PowerSync)
  TextColumn get userId => text().nullable()();

  /// Nombre descriptivo (ej: "EDEQ - Luz", "Netflix")
  TextColumn get name => text()();

  /// Tipo: income o expense
  TextColumn get type => text()();

  /// Monto fijo de la transacción
  RealColumn get amount => real()();

  /// Descripción adicional
  TextColumn get description => text().nullable()();

  /// Cuenta de origen (de donde sale el dinero)
  @ReferenceName('recurringFromAccount')
  TextColumn get fromAccountId =>
      text().nullable().references(Accounts, #id)();

  /// Cuenta destino (a donde llega el dinero)
  @ReferenceName('recurringToAccount')
  TextColumn get toAccountId => text().nullable().references(Accounts, #id)();

  /// Categoría de la transacción
  TextColumn get categoryId => text().references(Categories, #id)();

  /// Frecuencia de recurrencia (monthly, weekly, etc.)
  TextColumn get frequency => text()();

  /// Día del mes/semana para ejecutar (1-31 para mensual, 1-7 para semanal)
  /// Nullable para compatibilidad con PowerSync
  IntColumn get dayOfExecution => integer().nullable()();

  /// Fecha de inicio de la recurrencia
  DateTimeColumn get startDate => dateTime()();

  /// Fecha de fin (opcional, null = indefinido)
  DateTimeColumn get endDate => dateTime().nullable()();

  /// Última fecha de ejecución
  DateTimeColumn get lastExecutedAt => dateTime().nullable()();

  /// Próxima fecha de ejecución
  DateTimeColumn get nextExecutionDate => dateTime()();

  /// Si la transacción recurrente está activa - Nullable para compatibilidad con PowerSync
  BoolColumn get isActive => boolean().nullable()();

  /// Si requiere confirmación antes de ejecutar - Nullable para compatibilidad con PowerSync
  BoolColumn get requiresConfirmation => boolean().nullable()();

  /// Número de ejecuciones realizadas - Nullable para compatibilidad con PowerSync
  IntColumn get executionCount => integer().nullable()();

  /// Orden global de sincronización (estilo Linear)
  IntColumn get syncSequence => integer().nullable()();

  /// Timestamps - Nullable para compatibilidad con PowerSync
  DateTimeColumn get createdAt => dateTime().nullable()();
  DateTimeColumn get updatedAt => dateTime().nullable()();

  @override
  Set<Column> get primaryKey => {id};
}
