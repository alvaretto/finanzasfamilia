/// DTO liviano para cálculos de balance en Dashboard.
/// Contiene solo los campos necesarios para calcular totales.
class AccountBalanceDto {
  final String id;
  final String categoryId;
  final double balance;

  const AccountBalanceDto({
    required this.id,
    required this.categoryId,
    required this.balance,
  });
}
