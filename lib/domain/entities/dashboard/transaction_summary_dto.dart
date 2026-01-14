/// DTO liviano para resumen de transacción en Dashboard.
/// Contiene solo los campos necesarios para cálculos de totales.
class TransactionSummaryDto {
  final String id;
  final String type; // 'income', 'expense', 'transfer'
  final double amount;
  final String categoryId;

  const TransactionSummaryDto({
    required this.id,
    required this.type,
    required this.amount,
    required this.categoryId,
  });
}
