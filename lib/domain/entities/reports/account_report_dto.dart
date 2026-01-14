/// DTO para datos de cuenta en reportes
class AccountReportDto {
  final String id;
  final String name;
  final String? icon;
  final String categoryId;
  final double balance;

  const AccountReportDto({
    required this.id,
    required this.name,
    this.icon,
    required this.categoryId,
    required this.balance,
  });
}
