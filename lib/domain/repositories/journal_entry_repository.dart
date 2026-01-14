/// Interfaz de repositorio para operaciones de asientos contables.
/// Define el contrato que la capa de dominio necesita sin depender de Drift.
abstract class JournalEntryRepository {
  /// Obtiene el siguiente número de asiento.
  Future<int> getNextEntryNumber();

  /// Inserta múltiples asientos contables.
  Future<void> insertEntries(List<JournalEntryData> entries);

  /// Elimina todos los asientos de una transacción.
  Future<void> deleteEntriesByTransaction(String transactionId);

  /// Obtiene asientos por transacción.
  Future<List<JournalEntryData>> getEntriesByTransaction(String transactionId);
}

/// Modelo de datos de asiento contable para la capa de dominio.
/// Independiente de Drift.
class JournalEntryData {
  final String id;
  final String transactionId;
  final String? accountId;
  final String? categoryId;
  final String entryType; // 'debit' o 'credit'
  final double amount;
  final String? description;
  final int? entryNumber;
  final DateTime entryDate;
  final DateTime createdAt;
  final DateTime updatedAt;

  const JournalEntryData({
    required this.id,
    required this.transactionId,
    this.accountId,
    this.categoryId,
    required this.entryType,
    required this.amount,
    this.description,
    this.entryNumber,
    required this.entryDate,
    required this.createdAt,
    required this.updatedAt,
  });
}
