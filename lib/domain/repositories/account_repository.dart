/// Interfaz de repositorio para operaciones de cuentas.
/// Define el contrato que la capa de dominio necesita sin depender de Drift.
abstract class AccountRepository {
  /// Obtiene una cuenta por ID.
  Future<AccountData?> getAccountById(String id);

  /// Obtiene una cuenta con su categoría por ID.
  Future<AccountWithCategoryData?> getAccountWithCategoryById(String id);

  /// Obtiene todas las cuentas activas.
  Future<List<AccountData>> getActiveAccounts();

  /// Actualiza el saldo de una cuenta.
  Future<void> updateBalance(String accountId, double newBalance);

  /// Verifica si una cuenta existe.
  Future<bool> accountExists(String accountId);
}

/// Modelo de datos de cuenta para la capa de dominio.
/// Independiente de Drift.
class AccountData {
  final String id;
  final String name;
  final String categoryId;
  final double balance;
  final bool isActive;
  final DateTime createdAt;
  final DateTime updatedAt;

  const AccountData({
    required this.id,
    required this.name,
    required this.categoryId,
    required this.balance,
    required this.isActive,
    required this.createdAt,
    required this.updatedAt,
  });
}

/// Modelo de cuenta con datos de su categoría.
/// Usado para validaciones que necesitan saber el tipo de cuenta.
class AccountWithCategoryData {
  final AccountData account;
  final String categoryType;
  final String categoryName;

  const AccountWithCategoryData({
    required this.account,
    required this.categoryType,
    required this.categoryName,
  });

  /// Indica si la cuenta es de activo líquido (efectivo, bancos, billeteras).
  /// Estas cuentas NO pueden tener saldo negativo.
  bool get isLiquidAsset => categoryType == 'asset';

  /// Indica si la cuenta es un pasivo (tarjetas de crédito, préstamos).
  /// Estas cuentas SÍ pueden tener saldo negativo (representan deuda).
  bool get isLiability => categoryType == 'liability';
}
