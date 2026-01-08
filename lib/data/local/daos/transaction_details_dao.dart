import 'package:drift/drift.dart';
import '../database.dart';
import '../tables/transaction_details_table.dart';

part 'transaction_details_dao.g.dart';

/// DAO para operaciones con detalles de transacción (Shopping Cart)
@DriftAccessor(tables: [TransactionDetails])
class TransactionDetailsDao extends DatabaseAccessor<AppDatabase>
    with _$TransactionDetailsDaoMixin {
  TransactionDetailsDao(super.db);

  /// Obtiene todos los detalles de una transacción
  Future<List<TransactionDetailEntry>> getDetailsByTransaction(
    String transactionId,
  ) {
    return (select(transactionDetails)
          ..where((td) => td.transactionId.equals(transactionId))
          ..orderBy([(td) => OrderingTerm.asc(td.sortOrder)]))
        .get();
  }

  /// Obtiene un detalle por ID
  Future<TransactionDetailEntry?> getDetailById(String id) {
    return (select(transactionDetails)..where((td) => td.id.equals(id)))
        .getSingleOrNull();
  }

  /// Inserta un nuevo detalle
  Future<void> insertDetail(TransactionDetailsCompanion detail) {
    return into(transactionDetails).insert(detail);
  }

  /// Inserta múltiples detalles (para carrito completo)
  Future<void> insertDetails(List<TransactionDetailsCompanion> details) {
    return batch((batch) {
      batch.insertAll(transactionDetails, details);
    });
  }

  /// Actualiza un detalle
  Future<bool> updateDetail(TransactionDetailEntry detail) {
    return update(transactionDetails).replace(detail);
  }

  /// Elimina un detalle
  Future<int> deleteDetail(String id) {
    return (delete(transactionDetails)..where((td) => td.id.equals(id))).go();
  }

  /// Elimina todos los detalles de una transacción
  Future<int> deleteDetailsByTransaction(String transactionId) {
    return (delete(transactionDetails)
          ..where((td) => td.transactionId.equals(transactionId)))
        .go();
  }

  /// Obtiene el total de una transacción (suma de detalles)
  Future<double> getTransactionTotal(String transactionId) async {
    final total = transactionDetails.totalValue.sum();
    final query = selectOnly(transactionDetails)
      ..addColumns([total])
      ..where(transactionDetails.transactionId.equals(transactionId));
    final result = await query.getSingle();
    return result.read(total) ?? 0.0;
  }

  /// Obtiene la cantidad de items de una transacción
  Future<int> getItemCount(String transactionId) async {
    final count = transactionDetails.id.count();
    final query = selectOnly(transactionDetails)
      ..addColumns([count])
      ..where(transactionDetails.transactionId.equals(transactionId));
    final result = await query.getSingle();
    return result.read(count) ?? 0;
  }

  /// Obtiene detalles por categoría en un período
  Future<List<TransactionDetailEntry>> getDetailsByCategoryInPeriod(
    String categoryId,
    DateTime start,
    DateTime end,
  ) {
    return (select(transactionDetails)
          ..where((td) => td.categoryId.equals(categoryId))
          ..where((td) => td.createdAt.isBiggerOrEqualValue(start))
          ..where((td) => td.createdAt.isSmallerOrEqualValue(end)))
        .get();
  }

  /// Obtiene el total gastado por categoría en un período
  Future<double> getTotalByCategoryInPeriod(
    String categoryId,
    DateTime start,
    DateTime end,
  ) async {
    final total = transactionDetails.totalValue.sum();
    final query = selectOnly(transactionDetails)
      ..addColumns([total])
      ..where(transactionDetails.categoryId.equals(categoryId))
      ..where(transactionDetails.createdAt.isBiggerOrEqualValue(start))
      ..where(transactionDetails.createdAt.isSmallerOrEqualValue(end));
    final result = await query.getSingle();
    return result.read(total) ?? 0.0;
  }
}
