import 'package:flutter_test/flutter_test.dart';
import 'package:finanzasfamilia/features/accounts/domain/models/account_model.dart';
import 'package:finanzasfamilia/features/accounts/presentation/providers/account_provider.dart';

/// Tests para validar la deduplicación de cuentas en el Dashboard
/// 
/// Bug corregido: "Préstamos" aparecía 3 veces en "Tus Cuentas" del Dashboard
/// Causa raíz: Sincronización creaba duplicados con mismo nombre y tipo
/// Solución: Validación de duplicados en repository + deduplicación en provider
void main() {
  group('AccountsState - Deduplicación de cuentas', () {
    test('uniqueActiveAccounts elimina duplicados por nombre y tipo', () {
      // Arrange: Crear cuentas con duplicados (simula el bug)
      final accounts = [
        _createAccount('1', 'Préstamos', AccountType.loan, 1000),
        _createAccount('2', 'Préstamos', AccountType.loan, 500),
        _createAccount('3', 'Préstamos', AccountType.loan, 200),
        _createAccount('4', 'Davivienda', AccountType.bank, 5000),
        _createAccount('5', 'Nequi', AccountType.wallet, 300),
      ];

      final state = AccountsState(accounts: accounts);

      // Act
      final uniqueAccounts = state.uniqueActiveAccounts;

      // Assert
      expect(uniqueAccounts.length, 3); // Solo 3 cuentas únicas
      
      // Verificar que solo hay un "Préstamos"
      final prestamosCount = uniqueAccounts.where(
        (a) => a.name == 'Préstamos' && a.type == AccountType.loan,
      ).length;
      expect(prestamosCount, 1);
      
      // Verificar que se mantiene el de mayor balance
      final prestamos = uniqueAccounts.firstWhere(
        (a) => a.name == 'Préstamos',
      );
      expect(prestamos.balance, 1000); // El de mayor balance
    });

    test('uniqueActiveAccounts mantiene cuentas con mismo nombre pero diferente tipo', () {
      // Arrange: Mismo nombre, diferente tipo (válido)
      final accounts = [
        _createAccount('1', 'Personal', AccountType.bank, 1000),
        _createAccount('2', 'Personal', AccountType.savings, 2000),
        _createAccount('3', 'Personal', AccountType.cash, 500),
      ];

      final state = AccountsState(accounts: accounts);

      // Act
      final uniqueAccounts = state.uniqueActiveAccounts;

      // Assert
      expect(uniqueAccounts.length, 3); // Todos son únicos por tipo
    });

    test('uniqueActiveAccounts ignora mayúsculas/minúsculas y espacios', () {
      // Arrange: Duplicados con variaciones de capitalización
      final accounts = [
        _createAccount('1', 'Préstamos', AccountType.loan, 1000),
        _createAccount('2', 'préstamos', AccountType.loan, 500),
        _createAccount('3', ' Préstamos ', AccountType.loan, 200),
      ];

      final state = AccountsState(accounts: accounts);

      // Act
      final uniqueAccounts = state.uniqueActiveAccounts;

      // Assert
      expect(uniqueAccounts.length, 1);
    });

    test('uniqueActiveAccounts solo considera cuentas activas', () {
      // Arrange: Mezcla de cuentas activas e inactivas
      final accounts = [
        _createAccount('1', 'Cuenta 1', AccountType.bank, 1000, isActive: true),
        _createAccount('2', 'Cuenta 1', AccountType.bank, 500, isActive: false),
        _createAccount('3', 'Cuenta 2', AccountType.bank, 300, isActive: true),
      ];

      final state = AccountsState(accounts: accounts);

      // Act
      final uniqueAccounts = state.uniqueActiveAccounts;

      // Assert
      expect(uniqueAccounts.length, 2);
      expect(uniqueAccounts.every((a) => a.isActive), true);
    });

    test('uniqueActiveAccounts ordena alfabéticamente', () {
      // Arrange
      final accounts = [
        _createAccount('1', 'Zebra', AccountType.bank, 100),
        _createAccount('2', 'Apple', AccountType.bank, 200),
        _createAccount('3', 'Mango', AccountType.bank, 300),
      ];

      final state = AccountsState(accounts: accounts);

      // Act
      final uniqueAccounts = state.uniqueActiveAccounts;

      // Assert
      expect(uniqueAccounts[0].name, 'Apple');
      expect(uniqueAccounts[1].name, 'Mango');
      expect(uniqueAccounts[2].name, 'Zebra');
    });
  });

  group('AccountsState - Escenario real del bug', () {
    test('Dashboard con 3 préstamos duplicados muestra solo 1', () {
      // Arrange: Escenario exacto del bug reportado
      final accounts = [
        _createAccount('uuid-1', 'Préstamos', AccountType.loan, 150000),
        _createAccount('uuid-2', 'Préstamos', AccountType.loan, 150000),
        _createAccount('uuid-3', 'Préstamos', AccountType.loan, 150000),
        _createAccount('uuid-4', 'Davivienda', AccountType.bank, 500000),
        _createAccount('uuid-5', 'Nequi', AccountType.wallet, 50000),
        _createAccount('uuid-6', 'DaviPlata', AccountType.wallet, 25000),
      ];

      final state = AccountsState(accounts: accounts);

      // Act
      final uniqueAccounts = state.uniqueActiveAccounts;

      // Assert
      expect(uniqueAccounts.length, 4); // Solo 4 cuentas únicas
      
      // Verificar nombres únicos
      final names = uniqueAccounts.map((a) => a.name).toSet();
      expect(names, {'Préstamos', 'Davivienda', 'Nequi', 'DaviPlata'});
    });

    test('Balance total se calcula correctamente sin duplicar', () {
      // Arrange
      final accounts = [
        _createAccount('1', 'Préstamos', AccountType.loan, 100000),
        _createAccount('2', 'Préstamos', AccountType.loan, 100000), // Duplicado
        _createAccount('3', 'Banco', AccountType.bank, 500000),
      ];

      final state = AccountsState(accounts: accounts);

      // Act
      final uniqueAccounts = state.uniqueActiveAccounts;
      final totalBalance = uniqueAccounts
          .where((a) => a.includeInTotal)
          .fold(0.0, (sum, a) => sum + a.balance);

      // Assert
      expect(totalBalance, 600000); // 100000 (un préstamo) + 500000 (banco)
    });
  });

  group('AccountType - Propiedades', () {
    test('loan.displayName devuelve "Préstamo"', () {
      expect(AccountType.loan.displayName, 'Prestamo');
    });

    test('loan.isLiability devuelve true', () {
      expect(AccountType.loan.isLiability, true);
    });

    test('bank.isAsset devuelve true', () {
      expect(AccountType.bank.isAsset, true);
    });
  });
}

/// Helper para crear cuentas de prueba
AccountModel _createAccount(
  String id,
  String name,
  AccountType type,
  double balance, {
  bool isActive = true,
  bool includeInTotal = true,
}) {
  return AccountModel(
    id: id,
    userId: 'test-user-id',
    name: name,
    type: type,
    currency: 'COP',
    balance: balance,
    isActive: isActive,
    includeInTotal: includeInTotal,
  );
}
