/// DTO liviano para información de presupuesto en Dashboard.
/// Contiene solo los campos necesarios para alertas de presupuesto.
class BudgetInfoDto {
  final String id;
  final String categoryId;
  final double amount;

  const BudgetInfoDto({
    required this.id,
    required this.categoryId,
    required this.amount,
  });
}
