import 'package:flutter_test/flutter_test.dart';
import 'package:finanzas_familiares/features/accounts/domain/models/account_model.dart';
import 'package:finanzas_familiares/features/transactions/domain/models/transaction_model.dart';
import 'package:finanzas_familiares/features/transactions/presentation/helpers/default_account_selector.dart';

void main() {
  group('DefaultAccountSelector', () {
    // Cuentas de prueba
    late List<AccountModel> mixedAccounts;
    late List<AccountModel> onlyAssets;
    late List<AccountModel> onlyLiabilities;

    setUp(() {
      mixedAccounts = [
        _createAccount('loan-1', 'Préstamo Banco', AccountType.loan),
        _createAccount('credit-1', 'Tarjeta Visa', AccountType.credit),
        _createAccount('bank-1', 'Cuenta Bancolombia', AccountType.bank),
        _createAccount('cash-1', 'Efectivo', AccountType.cash),
        _createAccount('wallet-1', 'Nequi', AccountType.wallet),
        _createAccount('savings-1', 'CDT', AccountType.savings),
      ];

      onlyAssets = [
        _createAccount('bank-1', 'Cuenta Bancolombia', AccountType.bank),
        _createAccount('cash-1', 'Efectivo', AccountType.cash),
        _createAccount('wallet-1', 'Nequi', AccountType.wallet),
      ];

      onlyLiabilities = [
        _createAccount('loan-1', 'Préstamo Banco', AccountType.loan),
        _createAccount('credit-1', 'Tarjeta Visa', AccountType.credit),
        _createAccount('payable-1', 'Deuda Juan', AccountType.payable),
      ];
    });

    group('Para GASTO (expense)', () {
      test('debe seleccionar cuenta bancaria primero si existe', () {
        final result = DefaultAccountSelector.selectDefaultAccount(
          accounts: mixedAccounts,
          transactionType: TransactionType.expense,
        );
        expect(result, 'bank-1');
      });

      test('debe seleccionar wallet si no hay banco', () {
        final accounts = [
          _createAccount('loan-1', 'Préstamo', AccountType.loan),
          _createAccount('wallet-1', 'Nequi', AccountType.wallet),
          _createAccount('cash-1', 'Efectivo', AccountType.cash),
        ];
        final result = DefaultAccountSelector.selectDefaultAccount(
          accounts: accounts,
          transactionType: TransactionType.expense,
        );
        expect(result, 'wallet-1');
      });

      test('debe seleccionar efectivo si no hay banco ni wallet', () {
        final accounts = [
          _createAccount('loan-1', 'Préstamo', AccountType.loan),
          _createAccount('cash-1', 'Efectivo', AccountType.cash),
          _createAccount('savings-1', 'CDT', AccountType.savings),
        ];
        final result = DefaultAccountSelector.selectDefaultAccount(
          accounts: accounts,
          transactionType: TransactionType.expense,
        );
        expect(result, 'cash-1');
      });

      test('debe seleccionar tarjeta de crédito si solo hay pasivos', () {
        final result = DefaultAccountSelector.selectDefaultAccount(
          accounts: onlyLiabilities,
          transactionType: TransactionType.expense,
        );
        expect(result, 'credit-1');
      });

      test('NO debe seleccionar Préstamo como primera opción', () {
        // Este es el bug original que se está corrigiendo
        final result = DefaultAccountSelector.selectDefaultAccount(
          accounts: mixedAccounts,
          transactionType: TransactionType.expense,
        );
        expect(result, isNot('loan-1'));
      });
    });

    group('Para INGRESO (income)', () {
      test('debe seleccionar cuenta bancaria primero si existe', () {
        final result = DefaultAccountSelector.selectDefaultAccount(
          accounts: mixedAccounts,
          transactionType: TransactionType.income,
        );
        expect(result, 'bank-1');
      });

      test('debe seleccionar wallet si no hay banco', () {
        final accounts = [
          _createAccount('wallet-1', 'Nequi', AccountType.wallet),
          _createAccount('cash-1', 'Efectivo', AccountType.cash),
          _createAccount('loan-1', 'Préstamo', AccountType.loan),
        ];
        final result = DefaultAccountSelector.selectDefaultAccount(
          accounts: accounts,
          transactionType: TransactionType.income,
        );
        expect(result, 'wallet-1');
      });

      test('NO debe seleccionar Préstamo como primera opción', () {
        final result = DefaultAccountSelector.selectDefaultAccount(
          accounts: mixedAccounts,
          transactionType: TransactionType.income,
        );
        expect(result, isNot('loan-1'));
      });
    });

    group('Para TRANSFERENCIA (transfer)', () {
      test('debe seleccionar cuenta de activo como origen', () {
        final result = DefaultAccountSelector.selectDefaultAccount(
          accounts: mixedAccounts,
          transactionType: TransactionType.transfer,
        );
        expect(result, 'bank-1');
      });

      test('NO debe seleccionar Préstamo como origen', () {
        final result = DefaultAccountSelector.selectDefaultAccount(
          accounts: mixedAccounts,
          transactionType: TransactionType.transfer,
        );
        expect(result, isNot('loan-1'));
      });

      test('selectTransferDestination debe excluir cuenta origen', () {
        final result = DefaultAccountSelector.selectTransferDestination(
          accounts: onlyAssets,
          originAccountId: 'bank-1',
        );
        expect(result, isNot('bank-1'));
        expect(result, isIn(['cash-1', 'wallet-1']));
      });

      test('selectTransferDestination debe retornar null si solo hay una cuenta', () {
        final accounts = [_createAccount('bank-1', 'Banco', AccountType.bank)];
        final result = DefaultAccountSelector.selectTransferDestination(
          accounts: accounts,
          originAccountId: 'bank-1',
        );
        expect(result, isNull);
      });
    });

    group('Casos edge', () {
      test('debe retornar null si no hay cuentas', () {
        final result = DefaultAccountSelector.selectDefaultAccount(
          accounts: [],
          transactionType: TransactionType.expense,
        );
        expect(result, isNull);
      });

      test('debe manejar lista con solo un tipo de cuenta', () {
        final accounts = [_createAccount('loan-1', 'Préstamo', AccountType.loan)];
        final result = DefaultAccountSelector.selectDefaultAccount(
          accounts: accounts,
          transactionType: TransactionType.expense,
        );
        expect(result, 'loan-1'); // Fallback a la única cuenta disponible
      });
    });
  });
}

/// Helper para crear cuentas de prueba
AccountModel _createAccount(String id, String name, AccountType type) {
  return AccountModel(
    id: id,
    userId: 'test-user',
    name: name,
    type: type,
    balance: 0,
    currency: 'COP',
    isActive: true,
    createdAt: DateTime.now(),
    updatedAt: DateTime.now(),
  );
}
