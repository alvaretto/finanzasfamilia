import 'package:flutter_test/flutter_test.dart';
import 'package:finanzas_familiares/features/accounts/domain/models/account_model.dart';

void main() {
  group('AccountModel', () {
    test('create() genera cuenta con valores correctos', () {
      final account = AccountModel.create(
        userId: 'user-123',
        name: 'Mi Cuenta',
        type: AccountType.bank,
        currency: 'MXN',
        balance: 1000.0,
      );

      expect(account.userId, 'user-123');
      expect(account.name, 'Mi Cuenta');
      expect(account.type, AccountType.bank);
      expect(account.currency, 'MXN');
      expect(account.balance, 1000.0);
      expect(account.isActive, true);
      expect(account.isSynced, false);
    });

    test('balance por defecto es 0', () {
      final account = AccountModel.create(
        userId: 'user-123',
        name: 'Cuenta Vacia',
        type: AccountType.savings,
        currency: 'MXN',
      );

      expect(account.balance, 0.0);
    });

    test('availableBalance calcula correctamente para credito', () {
      const creditAccount = AccountModel(
        id: 'acc-1',
        userId: 'user-123',
        name: 'Tarjeta',
        type: AccountType.credit,
        currency: 'MXN',
        balance: -5000.0,
        creditLimit: 20000.0,
      );

      expect(creditAccount.availableBalance, 15000.0);
    });

    test('availableBalance es igual a balance para cuenta normal', () {
      const account = AccountModel(
        id: 'acc-1',
        userId: 'user-123',
        name: 'Ahorro',
        type: AccountType.savings,
        currency: 'MXN',
        balance: 5000.0,
      );

      expect(account.availableBalance, 5000.0);
    });
  });

  group('AccountType', () {
    test('displayName devuelve nombre correcto', () {
      expect(AccountType.bank.displayName, 'Cuenta Bancaria');
      expect(AccountType.savings.displayName, 'Ahorros');
      expect(AccountType.credit.displayName, 'Tarjeta de Credito');
      expect(AccountType.cash.displayName, 'Efectivo');
      expect(AccountType.investment.displayName, 'Inversiones');
      expect(AccountType.wallet.displayName, 'Billetera Digital');
      expect(AccountType.loan.displayName, 'Prestamo');
      expect(AccountType.receivable.displayName, 'Me Deben');
      expect(AccountType.payable.displayName, 'Debo Pagar');
    });

    test('icon devuelve icono correcto', () {
      expect(AccountType.bank.icon, 'account_balance');
      expect(AccountType.savings.icon, 'savings');
      expect(AccountType.credit.icon, 'credit_card');
      expect(AccountType.cash.icon, 'payments');
      expect(AccountType.investment.icon, 'trending_up');
      expect(AccountType.wallet.icon, 'account_balance_wallet');
      expect(AccountType.loan.icon, 'real_estate_agent');
      expect(AccountType.receivable.icon, 'arrow_circle_down');
      expect(AccountType.payable.icon, 'arrow_circle_up');
    });

    test('isLiability identifica pasivos correctamente', () {
      expect(AccountType.credit.isLiability, true);
      expect(AccountType.loan.isLiability, true);
      expect(AccountType.payable.isLiability, true);
      expect(AccountType.bank.isLiability, false);
      expect(AccountType.cash.isLiability, false);
      expect(AccountType.savings.isLiability, false);
    });

    test('isAsset identifica activos correctamente', () {
      expect(AccountType.bank.isAsset, true);
      expect(AccountType.cash.isAsset, true);
      expect(AccountType.savings.isAsset, true);
      expect(AccountType.receivable.isAsset, true);
      expect(AccountType.credit.isAsset, false);
      expect(AccountType.loan.isAsset, false);
    });
  });
}
