import '../../domain/entities/reports/reports.dart';
import '../local/database.dart';

/// Mappers para convertir Drift entries a DTOs de Reports.
class ReportsMappers {
  const ReportsMappers._();

  /// Convierte AccountEntry a AccountReportDto
  static AccountReportDto accountToDto(AccountEntry entry) {
    return AccountReportDto(
      id: entry.id,
      name: entry.name,
      icon: entry.icon,
      categoryId: entry.categoryId,
      balance: entry.balance ?? 0.0,
    );
  }

  /// Convierte lista de AccountEntry a lista de AccountReportDto
  static List<AccountReportDto> accountsToDtoList(List<AccountEntry> entries) {
    return entries.map(accountToDto).toList();
  }

  /// Convierte CategoryEntry a CategoryReportDto
  static CategoryReportDto categoryToDto(CategoryEntry entry) {
    return CategoryReportDto(
      id: entry.id,
      name: entry.name,
      type: entry.type,
    );
  }

  /// Convierte lista de CategoryEntry a lista de CategoryReportDto
  static List<CategoryReportDto> categoriesToDtoList(
      List<CategoryEntry> entries) {
    return entries.map(categoryToDto).toList();
  }

  /// Convierte TransactionEntry a TransactionReportDto
  static TransactionReportDto transactionToDto(TransactionEntry entry) {
    return TransactionReportDto(
      id: entry.id,
      type: entry.type,
      amount: entry.amount,
      categoryId: entry.categoryId,
      fromAccountId: entry.fromAccountId,
      toAccountId: entry.toAccountId,
    );
  }

  /// Convierte lista de TransactionEntry a lista de TransactionReportDto
  static List<TransactionReportDto> transactionsToDtoList(
      List<TransactionEntry> entries) {
    return entries.map(transactionToDto).toList();
  }
}
