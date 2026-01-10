/// Interfaz de repositorio para operaciones de cuentas.
/// Define el contrato que la capa de dominio necesita sin depender de Drift.
abstract class AccountRepository {
  /// Obtiene una cuenta por ID.
  Future<AccountData?> getAccountById(String id);

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
