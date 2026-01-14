/// DTO para mostrar cuentas en la UI.
/// Contiene los campos necesarios para presentación y navegación.
class AccountDisplayDto {
  final String id;
  final String name;
  final String? icon;
  final String? color;
  final double balance;
  final String categoryId;
  final bool isSystem;
  final bool isActive;
  final bool includeInTotal;
  final String? description;
  final String currency;

  const AccountDisplayDto({
    required this.id,
    required this.name,
    this.icon,
    this.color,
    required this.balance,
    required this.categoryId,
    required this.isSystem,
    required this.isActive,
    required this.includeInTotal,
    this.description,
    this.currency = 'COP',
  });
}

/// DTO para cuenta con información de su categoría.
/// Usado para mostrar cuentas agrupadas por tipo (activos, pasivos).
class AccountWithCategoryDto {
  final AccountDisplayDto account;
  final String categoryName;
  final String categoryType;

  const AccountWithCategoryDto({
    required this.account,
    required this.categoryName,
    required this.categoryType,
  });
}
