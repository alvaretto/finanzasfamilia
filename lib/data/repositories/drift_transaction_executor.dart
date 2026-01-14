import '../../domain/services/accounting_service.dart';
import '../local/database.dart';

/// Implementación concreta de TransactionExecutor usando Drift.
class DriftTransactionExecutor implements TransactionExecutor {
  final AppDatabase _db;

  DriftTransactionExecutor(this._db);

  @override
  Future<T> execute<T>(Future<T> Function() action) {
    return _db.transaction(action);
  }
}
