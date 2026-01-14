import '../../domain/entities/accounts/account_display_dto.dart';
import '../local/database.dart';

/// Mappers para convertir Drift AccountEntry a DTOs de display.
class AccountDisplayMappers {
  const AccountDisplayMappers._();

  /// Convierte AccountEntry a AccountDisplayDto
  static AccountDisplayDto accountToDto(AccountEntry entry) {
    return AccountDisplayDto(
      id: entry.id,
      name: entry.name,
      icon: entry.icon,
      color: entry.color,
      balance: entry.balance ?? 0.0,
      categoryId: entry.categoryId,
      isSystem: entry.isSystem ?? false,
      isActive: entry.isActive ?? true,
      includeInTotal: entry.includeInTotal ?? true,
      description: entry.description,
      currency: entry.currency ?? 'COP',
    );
  }

  /// Convierte lista de AccountEntry a lista de AccountDisplayDto
  static List<AccountDisplayDto> accountsToDtoList(
      List<AccountEntry> entries) {
    return entries.map(accountToDto).toList();
  }

  /// Crea AccountWithCategoryDto desde AccountEntry y CategoryEntry
  static AccountWithCategoryDto accountWithCategoryToDto(
    AccountEntry account,
    CategoryEntry? category,
  ) {
    return AccountWithCategoryDto(
      account: accountToDto(account),
      categoryName: category?.name ?? 'Sin categoría',
      categoryType: category?.type ?? 'asset',
    );
  }
}
