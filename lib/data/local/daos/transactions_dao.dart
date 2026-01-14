import 'package:drift/drift.dart';
import '../database.dart';
import '../tables/transactions_table.dart';

part 'transactions_dao.g.dart';

/// DAO para operaciones CRUD de transacciones
@DriftAccessor(tables: [Transactions])
class TransactionsDao extends DatabaseAccessor<AppDatabase>
    with _$TransactionsDaoMixin {
  TransactionsDao(super.db);

  /// Obtiene todas las transacciones
  Future<List<TransactionEntry>> getAllTransactions() =>
      select(transactions).get();

  /// Obtiene transacciones por tipo
  Future<List<TransactionEntry>> getTransactionsByType(String type) {
    return (select(transactions)..where((t) => t.type.equals(type))).get();
  }

  /// Obtiene transacciones de un período
  Future<List<TransactionEntry>> getTransactionsInPeriod(
    DateTime start,
    DateTime end,
  ) {
    return (select(transactions)
          ..where((t) => t.transactionDate.isBetweenValues(start, end))
          ..orderBy([(t) => OrderingTerm.desc(t.transactionDate)]))
        .get();
  }

  /// Obtiene transacciones por categoría en un período
  Future<List<TransactionEntry>> getTransactionsByCategoryInPeriod(
    String categoryId,
    DateTime start,
    DateTime end,
  ) {
    return (select(transactions)
          ..where((t) =>
              t.categoryId.equals(categoryId) &
              t.transactionDate.isBetweenValues(start, end)))
        .get();
  }

  /// Calcula el total gastado en una categoría en un período
  Future<double> getTotalByCategoryInPeriod(
    String categoryId,
    DateTime start,
    DateTime end,
  ) async {
    final txns = await getTransactionsByCategoryInPeriod(categoryId, start, end);
    return txns.fold<double>(0.0, (sum, t) => sum + t.amount);
  }

  /// Obtiene transacciones pendientes de sincronizar
  Future<List<TransactionEntry>> getPendingSyncTransactions() {
    return (select(transactions)
          ..where((t) => t.syncStatus.equals('pending')))
        .get();
  }

  /// Inserta una transacción
  Future<void> insertTransaction(TransactionsCompanion transaction) {
    return into(transactions).insert(transaction);
  }

  /// Actualiza una transacción
  Future<bool> updateTransaction(TransactionsCompanion transaction) {
    return (update(transactions)..where((t) => t.id.equals(transaction.id.value)))
        .write(transaction)
        .then((rows) => rows > 0);
  }

  /// Marca transacción como sincronizada
  Future<void> markAsSynced(String id) {
    return (update(transactions)..where((t) => t.id.equals(id))).write(
      const TransactionsCompanion(
        syncStatus: Value('synced'),
        updatedAt: Value.absent(),
      ),
    );
  }

  /// Elimina una transacción
  Future<int> deleteTransaction(String id) {
    return (delete(transactions)..where((t) => t.id.equals(id))).go();
  }

  /// Stream de transacciones del mes actual
  Stream<List<TransactionEntry>> watchCurrentMonthTransactions() {
    final now = DateTime.now();
    final startOfMonth = DateTime(now.year, now.month, 1);
    final endOfMonth = DateTime(now.year, now.month + 1, 0, 23, 59, 59);

    return (select(transactions)
          ..where((t) => t.transactionDate.isBetweenValues(startOfMonth, endOfMonth))
          ..orderBy([(t) => OrderingTerm.desc(t.transactionDate)]))
        .watch();
  }
}
