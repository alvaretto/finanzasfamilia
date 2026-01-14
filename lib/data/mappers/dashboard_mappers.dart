import '../../domain/entities/dashboard/dashboard.dart';
import '../local/database.dart';

/// Mappers para convertir Drift entries a DTOs del Dashboard.
/// Estos mappers viven en la capa data/ y conocen tanto Drift como Domain.
class DashboardMappers {
  const DashboardMappers._();

  /// Convierte AccountEntry a AccountBalanceDto
  static AccountBalanceDto accountToDto(AccountEntry entry) {
    return AccountBalanceDto(
      id: entry.id,
      categoryId: entry.categoryId,
      balance: entry.balance ?? 0.0,
    );
  }

  /// Convierte lista de AccountEntry a lista de AccountBalanceDto
  static List<AccountBalanceDto> accountsToDtoList(List<AccountEntry> entries) {
    return entries.map(accountToDto).toList();
  }

  /// Convierte CategoryEntry a CategoryInfoDto
  static CategoryInfoDto categoryToDto(CategoryEntry entry) {
    return CategoryInfoDto(
      id: entry.id,
      name: entry.name,
      icon: entry.icon,
      type: entry.type,
      parentId: entry.parentId,
      level: entry.level ?? 0,
    );
  }

  /// Convierte lista de CategoryEntry a lista de CategoryInfoDto
  static List<CategoryInfoDto> categoriesToDtoList(
      List<CategoryEntry> entries) {
    return entries.map(categoryToDto).toList();
  }

  /// Convierte TransactionEntry a TransactionSummaryDto
  static TransactionSummaryDto transactionToDto(TransactionEntry entry) {
    return TransactionSummaryDto(
      id: entry.id,
      type: entry.type,
      amount: entry.amount,
      categoryId: entry.categoryId,
    );
  }

  /// Convierte lista de TransactionEntry a lista de TransactionSummaryDto
  static List<TransactionSummaryDto> transactionsToDtoList(
      List<TransactionEntry> entries) {
    return entries.map(transactionToDto).toList();
  }

  /// Convierte BudgetEntry a BudgetInfoDto
  static BudgetInfoDto budgetToDto(BudgetEntry entry) {
    return BudgetInfoDto(
      id: entry.id,
      categoryId: entry.categoryId,
      amount: entry.amount,
    );
  }

  /// Convierte lista de BudgetEntry a lista de BudgetInfoDto
  static List<BudgetInfoDto> budgetsToDtoList(List<BudgetEntry> entries) {
    return entries.map(budgetToDto).toList();
  }
}
