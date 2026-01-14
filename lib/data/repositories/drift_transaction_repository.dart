import 'package:drift/drift.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../domain/repositories/transaction_repository.dart';
import '../local/database.dart';

/// Implementación concreta de TransactionRepository usando Drift.
class DriftTransactionRepository implements TransactionRepository {
  final AppDatabase _db;

  DriftTransactionRepository(this._db);

  /// Obtiene el userId del usuario autenticado actual
  /// Retorna null si Supabase no está inicializado (en tests)
  String? get _currentUserId {
    try {
      return Supabase.instance.client.auth.currentUser?.id;
    } catch (_) {
      return null;
    }
  }

  @override
  Future<TransactionData?> getTransactionById(String id) async {
    final entry = await (_db.select(_db.transactions)
          ..where((t) => t.id.equals(id)))
        .getSingleOrNull();

    if (entry == null) return null;
    return _toTransactionData(entry);
  }

  @override
  Future<void> insertTransaction(TransactionData transaction) async {
    await _db.into(_db.transactions).insert(TransactionsCompanion.insert(
          id: transaction.id,
          userId: Value(_currentUserId),
          type: transaction.type,
          amount: transaction.amount,
          description: Value(transaction.description),
          categoryId: transaction.categoryId,
          fromAccountId: Value(transaction.fromAccountId),
          toAccountId: Value(transaction.toAccountId),
          transactionDate: transaction.transactionDate,
          createdAt: Value(transaction.createdAt),
          updatedAt: Value(transaction.updatedAt),
        ));
  }

  @override
  Future<void> deleteTransaction(String id) async {
    await (_db.delete(_db.transactions)..where((t) => t.id.equals(id))).go();
  }

  @override
  Future<List<TransactionData>> getTransactionsInPeriod(
    DateTime start,
    DateTime end,
  ) async {
    final entries = await (_db.select(_db.transactions)
          ..where((t) => t.transactionDate.isBetweenValues(start, end))
          ..orderBy([(t) => OrderingTerm.desc(t.transactionDate)]))
        .get();

    return entries.map(_toTransactionData).toList();
  }

  TransactionData _toTransactionData(TransactionEntry entry) {
    return TransactionData(
      id: entry.id,
      type: entry.type,
      amount: entry.amount,
      description: entry.description,
      categoryId: entry.categoryId,
      fromAccountId: entry.fromAccountId,
      toAccountId: entry.toAccountId,
      transactionDate: entry.transactionDate,
      createdAt: entry.createdAt ?? DateTime.now(),
      updatedAt: entry.updatedAt ?? DateTime.now(),
    );
  }
}
