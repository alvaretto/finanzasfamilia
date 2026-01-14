import '../exceptions/accounting_exceptions.dart';
import '../repositories/account_repository.dart';

/// Servicio de dominio para operaciones de cuentas.
/// Contiene lógica de negocio que no pertenece a los repositorios.
class AccountService {
  final AccountRepository accountRepository;

  AccountService({required this.accountRepository});

  /// Valida si una cuenta puede ser eliminada.
  ///
  /// Throws [AccountHasBalanceException] si la cuenta tiene saldo != 0.
  Future<void> validateAccountDeletion(String accountId) async {
    final account = await accountRepository.getAccountById(accountId);
    if (account == null) {
      throw StateError('La cuenta no existe: $accountId');
    }

    // No permitir eliminar cuentas con saldo
    if (account.balance != 0) {
      throw AccountHasBalanceException(
        balance: account.balance,
        accountName: account.name,
      );
    }
  }

  /// Obtiene el saldo disponible de una cuenta.
  Future<double> getAvailableBalance(String accountId) async {
    final account = await accountRepository.getAccountById(accountId);
    if (account == null) {
      throw StateError('La cuenta no existe: $accountId');
    }
    return account.balance;
  }
}
