/// Interfaz de repositorio para operaciones de transacciones.
/// Define el contrato que la capa de dominio necesita sin depender de Drift.
abstract class TransactionRepository {
  /// Obtiene una transacción por ID.
  Future<TransactionData?> getTransactionById(String id);

  /// Inserta una nueva transacción.
  Future<void> insertTransaction(TransactionData transaction);

  /// Elimina una transacción por ID.
  Future<void> deleteTransaction(String id);

  /// Obtiene transacciones de un período.
  Future<List<TransactionData>> getTransactionsInPeriod(
    DateTime start,
    DateTime end,
  );
}

/// Modelo de datos de transacción para la capa de dominio.
/// Independiente de Drift.
class TransactionData {
  final String id;
  final String type;
  final double amount;
  final String? description;
  final String categoryId;
  final String? fromAccountId;
  final String? toAccountId;
  final DateTime transactionDate;
  final DateTime createdAt;
  final DateTime updatedAt;

  /// Nivel de satisfacción del gasto (solo para type='expense')
  /// Valores: 'low', 'medium', 'high', 'neutral'
  final String? satisfactionLevel;

  const TransactionData({
    required this.id,
    required this.type,
    required this.amount,
    this.description,
    required this.categoryId,
    this.fromAccountId,
    this.toAccountId,
    required this.transactionDate,
    required this.createdAt,
    required this.updatedAt,
    this.satisfactionLevel,
  });
}
