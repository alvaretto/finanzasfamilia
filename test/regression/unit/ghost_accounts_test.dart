// Test de regresion para ERR-0003: Cuentas fantasma 'Prestamos' en Dashboard
//
// Este test verifica que las cuentas fantasma (pasivos vacios con nombres genericos)
// sean filtradas correctamente del dashboard y eliminadas de la base de datos.
//
// Referencia: .error-tracker/errors/ERR-0003.json

import 'package:flutter_test/flutter_test.dart';
import 'package:finanzas_familiares/features/accounts/domain/models/account_model.dart';
import 'package:finanzas_familiares/features/accounts/presentation/providers/account_provider.dart';

void main() {
  group('ERR-0003: Ghost Accounts Regression', () {
    group('uniqueActiveAccounts filtering', () {
      test('should filter out empty liability accounts with generic names', () {
        // Arrange: Crear estado con cuentas fantasma
        final ghostAccounts = [
          AccountModel.create(
            userId: 'test-user',
            name: 'Prestamos',
            type: AccountType.loan,
            balance: 0,
          ),
          AccountModel.create(
            userId: 'test-user',
            name: 'Prestamo Bancario',
            type: AccountType.loan,
            balance: 0,
          ),
          AccountModel.create(
            userId: 'test-user',
            name: 'Tarjeta de Credito',
            type: AccountType.credit,
            balance: 0,
          ),
        ];

        final state = AccountsState(accounts: ghostAccounts);

        // Act
        final uniqueAccounts = state.uniqueActiveAccounts;

        // Assert: No deben aparecer cuentas fantasma
        expect(uniqueAccounts, isEmpty,
            reason: 'Las cuentas fantasma (pasivos vacios con nombres genericos) deben ser filtradas');
      });

      test('should NOT filter liability accounts with balance > 0', () {
        // Arrange: Cuenta de prestamo con balance real
        final realLoan = AccountModel.create(
          userId: 'test-user',
          name: 'Prestamos',
          type: AccountType.loan,
          balance: 5000000, // $5M COP
        );

        final state = AccountsState(accounts: [realLoan]);

        // Act
        final uniqueAccounts = state.uniqueActiveAccounts;

        // Assert: Debe aparecer porque tiene balance
        expect(uniqueAccounts.length, 1,
            reason: 'Las cuentas con balance real NO deben ser filtradas');
        expect(uniqueAccounts.first.name, 'Prestamos');
      });

      test('should NOT filter liability accounts with custom names', () {
        // Arrange: Cuenta con nombre personalizado
        final customLoan = AccountModel.create(
          userId: 'test-user',
          name: 'Credito Hipotecario Casa',
          type: AccountType.loan,
          balance: 0,
        );

        final state = AccountsState(accounts: [customLoan]);

        // Act
        final uniqueAccounts = state.uniqueActiveAccounts;

        // Assert: Debe aparecer porque tiene nombre personalizado
        expect(uniqueAccounts.length, 1,
            reason: 'Las cuentas con nombres personalizados NO deben ser filtradas');
      });

      test('should NOT filter asset accounts even with balance 0', () {
        // Arrange: Cuenta de activo vacia
        final emptyBank = AccountModel.create(
          userId: 'test-user',
          name: 'Bancolombia',
          type: AccountType.bank,
          balance: 0,
        );

        final state = AccountsState(accounts: [emptyBank]);

        // Act
        final uniqueAccounts = state.uniqueActiveAccounts;

        // Assert: Activos no se filtran por balance
        expect(uniqueAccounts.length, 1,
            reason: 'Las cuentas de activo NO deben ser filtradas incluso con balance 0');
      });

      test('should filter all variants of generic ghost names', () {
        // Arrange: Todas las variantes de nombres genericos
        final genericNames = [
          'prestamos',
          'Prestamos',
          'PRESTAMOS',
          'prestamo',
          'Prestamo',
          'prestamo bancario',
          'Prestamo Bancario',
          'prestamo personal',
          'tarjeta de credito',
          'Tarjeta de Credito',
          'me deben',
          'Me Deben',
          'debo pagar',
          'Debo Pagar',
        ];

        for (final name in genericNames) {
          final ghostAccount = AccountModel.create(
            userId: 'test-user',
            name: name,
            type: AccountType.loan,
            balance: 0,
          );

          final state = AccountsState(accounts: [ghostAccount]);
          final uniqueAccounts = state.uniqueActiveAccounts;

          expect(uniqueAccounts, isEmpty,
              reason: 'El nombre generico "$name" debe ser filtrado');
        }
      });

      test('should handle mixed real and ghost accounts correctly', () {
        // Arrange: Mezcla de cuentas reales y fantasma
        final accounts = [
          // Cuentas fantasma (deben ser filtradas)
          AccountModel.create(
            userId: 'test-user',
            name: 'Prestamos',
            type: AccountType.loan,
            balance: 0,
          ),
          AccountModel.create(
            userId: 'test-user',
            name: 'Tarjeta de Credito',
            type: AccountType.credit,
            balance: 0,
          ),
          // Cuentas reales (NO deben ser filtradas)
          AccountModel.create(
            userId: 'test-user',
            name: 'Nequi',
            type: AccountType.wallet,
            balance: 150000,
          ),
          AccountModel.create(
            userId: 'test-user',
            name: 'Bancolombia',
            type: AccountType.bank,
            balance: 2500000,
          ),
          AccountModel.create(
            userId: 'test-user',
            name: 'Credito Libre Inversion',
            type: AccountType.loan,
            balance: 15000000,
          ),
        ];

        final state = AccountsState(accounts: accounts);

        // Act
        final uniqueAccounts = state.uniqueActiveAccounts;

        // Assert
        expect(uniqueAccounts.length, 3,
            reason: 'Solo deben quedar las 3 cuentas reales');

        final names = uniqueAccounts.map((a) => a.name).toSet();
        expect(names.contains('Nequi'), isTrue);
        expect(names.contains('Bancolombia'), isTrue);
        expect(names.contains('Credito Libre Inversion'), isTrue);
        expect(names.contains('Prestamos'), isFalse);
        expect(names.contains('Tarjeta de Credito'), isFalse);
      });
    });

    group('deduplication still works', () {
      test('should deduplicate accounts with same name and type', () {
        // Arrange: Cuentas duplicadas
        final accounts = [
          AccountModel.create(
            userId: 'test-user',
            name: 'Nequi',
            type: AccountType.wallet,
            balance: 100000,
          ),
          AccountModel.create(
            userId: 'test-user',
            name: 'Nequi',
            type: AccountType.wallet,
            balance: 50000,
          ),
        ];

        final state = AccountsState(accounts: accounts);

        // Act
        final uniqueAccounts = state.uniqueActiveAccounts;

        // Assert: Solo debe quedar una (la de mayor balance)
        expect(uniqueAccounts.length, 1);
        expect(uniqueAccounts.first.balance, 100000,
            reason: 'Debe mantenerse la cuenta con mayor balance');
      });
    });
  });
}
