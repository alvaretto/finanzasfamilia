import '../../domain/entities/ai/financial_context_dto.dart';
import '../local/database.dart';

/// Mappers para convertir Drift entries a DTOs del Contexto Financiero.
class FinancialContextMappers {
  const FinancialContextMappers._();

  /// Convierte TransactionEntry a FinancialTransactionDto
  static FinancialTransactionDto transactionToDto(TransactionEntry entry) {
    return FinancialTransactionDto(
      id: entry.id,
      type: entry.type,
      amount: entry.amount,
      categoryId: entry.categoryId,
    );
  }

  /// Convierte lista de TransactionEntry a lista de FinancialTransactionDto
  static List<FinancialTransactionDto> transactionsToDtoList(
      List<TransactionEntry> entries) {
    return entries.map(transactionToDto).toList();
  }

  /// Convierte CategoryEntry a FinancialCategoryDto
  static FinancialCategoryDto categoryToDto(CategoryEntry entry) {
    return FinancialCategoryDto(
      id: entry.id,
      name: entry.name,
      type: entry.type,
      parentId: entry.parentId,
    );
  }

  /// Convierte lista de CategoryEntry a lista de FinancialCategoryDto
  static List<FinancialCategoryDto> categoriesToDtoList(
      List<CategoryEntry> entries) {
    return entries.map(categoryToDto).toList();
  }

  /// Convierte AccountEntry a FinancialAccountDto
  static FinancialAccountDto accountToDto(AccountEntry entry) {
    return FinancialAccountDto(
      id: entry.id,
      name: entry.name,
      categoryId: entry.categoryId,
      balance: entry.balance ?? 0.0,
    );
  }

  /// Convierte lista de AccountEntry a lista de FinancialAccountDto
  static List<FinancialAccountDto> accountsToDtoList(
      List<AccountEntry> entries) {
    return entries.map(accountToDto).toList();
  }
}
