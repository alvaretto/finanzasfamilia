import 'package:drift/drift.dart';
import '../database.dart';
import '../tables/recurring_transactions_table.dart';

part 'recurring_transactions_dao.g.dart';

/// DAO para operaciones CRUD de transacciones recurrentes
@DriftAccessor(tables: [RecurringTransactions])
class RecurringTransactionsDao extends DatabaseAccessor<AppDatabase>
    with _$RecurringTransactionsDaoMixin {
  RecurringTransactionsDao(super.db);

  /// Obtiene todas las transacciones recurrentes
  Future<List<RecurringTransactionEntry>> getAll() =>
      select(recurringTransactions).get();

  /// Obtiene solo las transacciones recurrentes activas
  /// Considera isActive = NULL como activo (valor por defecto)
  Future<List<RecurringTransactionEntry>> getActive() {
    return (select(recurringTransactions)
          ..where((r) => r.isActive.equals(true) | r.isActive.isNull())
          ..orderBy([(r) => OrderingTerm.asc(r.nextExecutionDate)]))
        .get();
  }

  /// Obtiene transacciones recurrentes que deben ejecutarse hoy o antes
  /// Considera isActive = NULL como activo (valor por defecto)
  Future<List<RecurringTransactionEntry>> getDueForExecution() {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day, 23, 59, 59);

    return (select(recurringTransactions)
          ..where((r) =>
              (r.isActive.equals(true) | r.isActive.isNull()) &
              r.nextExecutionDate.isSmallerOrEqualValue(today))
          ..orderBy([(r) => OrderingTerm.asc(r.nextExecutionDate)]))
        .get();
  }

  /// Obtiene transacciones recurrentes por tipo
  /// Considera isActive = NULL como activo (valor por defecto)
  Future<List<RecurringTransactionEntry>> getByType(String type) {
    return (select(recurringTransactions)
          ..where((r) =>
              r.type.equals(type) &
              (r.isActive.equals(true) | r.isActive.isNull())))
        .get();
  }

  /// Obtiene una transacción recurrente por ID
  Future<RecurringTransactionEntry?> getById(String id) {
    return (select(recurringTransactions)..where((r) => r.id.equals(id)))
        .getSingleOrNull();
  }

  /// Inserta una transacción recurrente
  Future<void> insert(RecurringTransactionsCompanion entry) {
    return into(recurringTransactions).insert(entry);
  }

  /// Actualiza una transacción recurrente
  Future<bool> updateEntry(RecurringTransactionsCompanion entry) {
    return (update(recurringTransactions)
          ..where((r) => r.id.equals(entry.id.value)))
        .write(entry)
        .then((rows) => rows > 0);
  }

  /// Marca como ejecutada y actualiza la próxima fecha
  Future<void> markAsExecuted(String id, DateTime nextDate) {
    return (update(recurringTransactions)..where((r) => r.id.equals(id))).write(
      RecurringTransactionsCompanion(
        lastExecutedAt: Value(DateTime.now()),
        nextExecutionDate: Value(nextDate),
        executionCount: const Value.absent(),
        updatedAt: Value(DateTime.now()),
      ),
    );
  }

  /// Incrementa el contador de ejecuciones
  Future<void> incrementExecutionCount(String id) async {
    final entry = await getById(id);
    if (entry != null) {
      await (update(recurringTransactions)..where((r) => r.id.equals(id)))
          .write(
        RecurringTransactionsCompanion(
          executionCount: Value((entry.executionCount ?? 0) + 1),
          updatedAt: Value(DateTime.now()),
        ),
      );
    }
  }

  /// Desactiva una transacción recurrente
  Future<void> deactivate(String id) {
    return (update(recurringTransactions)..where((r) => r.id.equals(id))).write(
      RecurringTransactionsCompanion(
        isActive: const Value(false),
        updatedAt: Value(DateTime.now()),
      ),
    );
  }

  /// Activa una transacción recurrente
  Future<void> activate(String id) {
    return (update(recurringTransactions)..where((r) => r.id.equals(id))).write(
      RecurringTransactionsCompanion(
        isActive: const Value(true),
        updatedAt: Value(DateTime.now()),
      ),
    );
  }

  /// Elimina una transacción recurrente
  Future<int> deleteEntry(String id) {
    return (delete(recurringTransactions)..where((r) => r.id.equals(id))).go();
  }

  /// Stream de transacciones recurrentes activas
  /// Considera isActive = NULL como activo (valor por defecto)
  Stream<List<RecurringTransactionEntry>> watchActive() {
    return (select(recurringTransactions)
          ..where((r) => r.isActive.equals(true) | r.isActive.isNull())
          ..orderBy([(r) => OrderingTerm.asc(r.nextExecutionDate)]))
        .watch();
  }

  /// Stream de transacciones que requieren confirmación
  /// Considera isActive = NULL como activo y requiresConfirmation = NULL como false
  Stream<List<RecurringTransactionEntry>> watchPendingConfirmation() {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day, 23, 59, 59);

    return (select(recurringTransactions)
          ..where((r) =>
              (r.isActive.equals(true) | r.isActive.isNull()) &
              r.requiresConfirmation.equals(true) &
              r.nextExecutionDate.isSmallerOrEqualValue(today)))
        .watch();
  }

  /// Obtiene transacciones que requieren confirmación (Future)
  /// Considera isActive = NULL como activo y requiresConfirmation = NULL como false
  Future<List<RecurringTransactionEntry>> getPendingConfirmation() {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day, 23, 59, 59);

    return (select(recurringTransactions)
          ..where((r) =>
              (r.isActive.equals(true) | r.isActive.isNull()) &
              r.requiresConfirmation.equals(true) &
              r.nextExecutionDate.isSmallerOrEqualValue(today)))
        .get();
  }
}
