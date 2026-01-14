// DTOs livianos para la construcción de contexto financiero del IA.
// Estos DTOs viven en domain/ y no dependen de data/.

/// DTO para transacciones usadas en el contexto financiero
class FinancialTransactionDto {
  final String id;
  final String type;
  final double amount;
  final String categoryId;

  const FinancialTransactionDto({
    required this.id,
    required this.type,
    required this.amount,
    required this.categoryId,
  });
}

/// DTO para categorías usadas en el contexto financiero
class FinancialCategoryDto {
  final String id;
  final String name;
  final String type;
  final String? parentId;

  const FinancialCategoryDto({
    required this.id,
    required this.name,
    required this.type,
    this.parentId,
  });
}

/// DTO para cuentas usadas en el contexto financiero
class FinancialAccountDto {
  final String id;
  final String name;
  final String categoryId;
  final double balance;

  const FinancialAccountDto({
    required this.id,
    required this.name,
    required this.categoryId,
    required this.balance,
  });
}
