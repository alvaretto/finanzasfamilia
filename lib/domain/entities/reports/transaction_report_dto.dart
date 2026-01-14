/// DTO para datos de transacción en reportes
class TransactionReportDto {
  final String id;
  final String type; // 'income', 'expense', 'transfer'
  final double amount;
  final String categoryId;
  final String? fromAccountId;
  final String? toAccountId;

  const TransactionReportDto({
    required this.id,
    required this.type,
    required this.amount,
    required this.categoryId,
    this.fromAccountId,
    this.toAccountId,
  });
}
