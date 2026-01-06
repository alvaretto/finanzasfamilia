import '../../../accounts/domain/models/account_model.dart';
import '../../domain/models/transaction_model.dart';

/// Helper para seleccionar cuenta predeterminada según el tipo de transacción.
///
/// ## Flujos por Tipo de Transacción
///
/// ### GASTO (expense)
/// - El dinero SALE de una cuenta
/// - Prioridad: cuentas de ACTIVO más líquidas
/// - Orden: bank > wallet > cash > savings > investment
/// - Si solo hay pasivos: usar credit primero (pago con tarjeta)
///
/// ### INGRESO (income)
/// - El dinero ENTRA a una cuenta
/// - Prioridad: cuentas de ACTIVO donde recibimos dinero
/// - Orden: bank > wallet > cash > savings
/// - Excluir: receivable (cuentas por cobrar no reciben ingresos normales)
///
/// ### TRANSFERENCIA (transfer)
/// - Origen: cuenta de ACTIVO preferentemente
/// - Destino: cualquier cuenta diferente al origen
/// - Orden origen: bank > wallet > cash > savings
///
class DefaultAccountSelector {
  /// Orden de prioridad para cuentas de activo (más líquidas primero)
  static const _assetPriority = [
    AccountType.bank,
    AccountType.wallet,
    AccountType.cash,
    AccountType.savings,
    AccountType.investment,
    AccountType.receivable,
  ];

  /// Orden de prioridad para pasivos (cuando no hay activos)
  static const _liabilityPriority = [
    AccountType.credit,
    AccountType.loan,
    AccountType.payable,
  ];

  /// Selecciona la cuenta predeterminada según el tipo de transacción.
  ///
  /// [accounts] - Lista de cuentas activas disponibles
  /// [transactionType] - Tipo de transacción (expense, income, transfer)
  /// [excludeAccountId] - ID de cuenta a excluir (para transferencias)
  ///
  /// Retorna el ID de la cuenta predeterminada o null si no hay cuentas.
  static String? selectDefaultAccount({
    required List<AccountModel> accounts,
    required TransactionType transactionType,
    String? excludeAccountId,
  }) {
    if (accounts.isEmpty) return null;

    // Filtrar cuenta excluida (para transferencias)
    final availableAccounts = excludeAccountId != null
        ? accounts.where((a) => a.id != excludeAccountId).toList()
        : accounts;

    if (availableAccounts.isEmpty) return null;

    switch (transactionType) {
      case TransactionType.expense:
        return _selectForExpense(availableAccounts);
      case TransactionType.income:
        return _selectForIncome(availableAccounts);
      case TransactionType.transfer:
        return _selectForTransferOrigin(availableAccounts);
    }
  }

  /// Selecciona cuenta para GASTO
  /// Prioriza activos líquidos, luego tarjeta de crédito
  static String _selectForExpense(List<AccountModel> accounts) {
    // 1. Buscar en activos por orden de prioridad
    for (final type in _assetPriority) {
      final account = accounts.firstWhereOrNull((a) => a.type == type);
      if (account != null) return account.id;
    }

    // 2. Si no hay activos, buscar en pasivos (ej: pagar con tarjeta)
    for (final type in _liabilityPriority) {
      final account = accounts.firstWhereOrNull((a) => a.type == type);
      if (account != null) return account.id;
    }

    // 3. Fallback: primera cuenta
    return accounts.first.id;
  }

  /// Selecciona cuenta para INGRESO
  /// Prioriza activos donde típicamente recibimos dinero
  static String _selectForIncome(List<AccountModel> accounts) {
    // Orden específico para ingresos (excluye receivable al inicio)
    const incomePriority = [
      AccountType.bank,
      AccountType.wallet,
      AccountType.cash,
      AccountType.savings,
    ];

    // 1. Buscar en activos principales
    for (final type in incomePriority) {
      final account = accounts.firstWhereOrNull((a) => a.type == type);
      if (account != null) return account.id;
    }

    // 2. Buscar en otros activos
    final assetAccount = accounts.firstWhereOrNull((a) => a.type.isAsset);
    if (assetAccount != null) return assetAccount.id;

    // 3. Fallback: primera cuenta
    return accounts.first.id;
  }

  /// Selecciona cuenta origen para TRANSFERENCIA
  /// Similar a gasto pero solo activos
  static String _selectForTransferOrigin(List<AccountModel> accounts) {
    // Priorizar activos líquidos
    for (final type in _assetPriority) {
      final account = accounts.firstWhereOrNull((a) => a.type == type);
      if (account != null) return account.id;
    }

    // Fallback: primera cuenta
    return accounts.first.id;
  }

  /// Selecciona cuenta destino para TRANSFERENCIA
  /// Puede ser cualquier cuenta diferente al origen
  static String? selectTransferDestination({
    required List<AccountModel> accounts,
    required String originAccountId,
  }) {
    final available = accounts.where((a) => a.id != originAccountId).toList();
    if (available.isEmpty) return null;

    // Priorizar activos, luego pasivos (ej: pagar tarjeta)
    for (final type in _assetPriority) {
      final account = available.firstWhereOrNull((a) => a.type == type);
      if (account != null) return account.id;
    }

    for (final type in _liabilityPriority) {
      final account = available.firstWhereOrNull((a) => a.type == type);
      if (account != null) return account.id;
    }

    return available.first.id;
  }
}

/// Extension para firstWhereOrNull (evita importar collection)
extension _ListExtension<T> on List<T> {
  T? firstWhereOrNull(bool Function(T) test) {
    for (final element in this) {
      if (test(element)) return element;
    }
    return null;
  }
}
