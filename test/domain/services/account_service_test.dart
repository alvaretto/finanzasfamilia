import 'package:flutter_test/flutter_test.dart';
import 'package:finanzas_familiares/domain/exceptions/accounting_exceptions.dart';
import 'package:finanzas_familiares/domain/repositories/account_repository.dart';
import 'package:finanzas_familiares/domain/services/account_service.dart';

class MockAccountRepository implements AccountRepository {
  final Map<String, AccountData> _accounts = {};

  void addAccount(String id, String name, double balance) {
    _accounts[id] = AccountData(
      id: id,
      name: name,
      categoryId: 'cat-$id',
      balance: balance,
      isActive: true,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );
  }

  @override
  Future<AccountData?> getAccountById(String id) async => _accounts[id];

  @override
  Future<AccountWithCategoryData?> getAccountWithCategoryById(String id) async {
    final account = _accounts[id];
    if (account == null) return null;
    return AccountWithCategoryData(
      account: account,
      categoryType: 'asset',
      categoryName: 'Test',
    );
  }

  @override
  Future<List<AccountData>> getActiveAccounts() async =>
      _accounts.values.toList();

  @override
  Future<void> updateBalance(String accountId, double newBalance) async {}

  @override
  Future<bool> accountExists(String accountId) async =>
      _accounts.containsKey(accountId);
}

void main() {
  group('AccountService - Validación de eliminación', () {
    late AccountService service;
    late MockAccountRepository accountRepo;

    setUp(() {
      accountRepo = MockAccountRepository();
      service = AccountService(accountRepository: accountRepo);
    });

    test('permite eliminar cuenta con saldo cero', () async {
      accountRepo.addAccount('cuenta1', 'Cuenta Vacía', 0);

      // No debería lanzar excepción
      await service.validateAccountDeletion('cuenta1');
    });

    test('rechaza eliminar cuenta con saldo positivo', () async {
      accountRepo.addAccount('cuenta1', 'Cuenta con Saldo', 50000);

      expect(
        () => service.validateAccountDeletion('cuenta1'),
        throwsA(isA<AccountHasBalanceException>()
            .having((e) => e.balance, 'balance', 50000)
            .having((e) => e.accountName, 'accountName', 'Cuenta con Saldo')),
      );
    });

    test('rechaza eliminar cuenta con saldo negativo (deuda)', () async {
      accountRepo.addAccount('tarjeta', 'Visa', -30000);

      expect(
        () => service.validateAccountDeletion('tarjeta'),
        throwsA(isA<AccountHasBalanceException>()
            .having((e) => e.balance, 'balance', -30000)),
      );
    });

    test('lanza error si la cuenta no existe', () async {
      expect(
        () => service.validateAccountDeletion('no-existe'),
        throwsA(isA<StateError>()),
      );
    });
  });

  group('AccountHasBalanceException', () {
    test('toString formatea correctamente el mensaje', () {
      const exception = AccountHasBalanceException(
        balance: 50000,
        accountName: 'Nequi',
      );

      expect(exception.toString(), contains('No se puede eliminar'));
      expect(exception.toString(), contains('Nequi'));
      expect(exception.toString(), contains('50000'));
    });
  });
}
