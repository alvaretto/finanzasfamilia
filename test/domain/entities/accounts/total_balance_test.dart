import 'package:flutter_test/flutter_test.dart';

import 'package:finanzas_familiares/domain/entities/accounts/total_balance.dart';

void main() {
  group('TotalBalance', () {
    test('constructor con valores positivos', () {
      const balance = TotalBalance(
        assets: 10000000,
        liabilities: 2000000,
        netWorth: 8000000,
        accountCount: 5,
      );

      expect(balance.assets, equals(10000000));
      expect(balance.liabilities, equals(2000000));
      expect(balance.netWorth, equals(8000000));
      expect(balance.accountCount, equals(5));
    });

    test('balance getter retorna netWorth', () {
      const totalBalance = TotalBalance(
        assets: 5000000,
        liabilities: 1000000,
        netWorth: 4000000,
        accountCount: 3,
      );

      expect(totalBalance.balance, equals(totalBalance.netWorth));
      expect(totalBalance.balance, equals(4000000));
    });

    test('netWorth puede ser negativo (más deudas que activos)', () {
      const balance = TotalBalance(
        assets: 5000000,
        liabilities: 8000000,
        netWorth: -3000000,
        accountCount: 4,
      );

      expect(balance.netWorth, equals(-3000000));
      expect(balance.balance, equals(-3000000));
    });

    test('TotalBalance.empty crea balance vacío', () {
      final empty = TotalBalance.empty();

      expect(empty.assets, equals(0));
      expect(empty.liabilities, equals(0));
      expect(empty.netWorth, equals(0));
      expect(empty.accountCount, equals(0));
    });

    test('TotalBalance.empty balance getter retorna 0', () {
      final empty = TotalBalance.empty();

      expect(empty.balance, equals(0));
    });

    test('accountCount puede ser 0', () {
      const balance = TotalBalance(
        assets: 0,
        liabilities: 0,
        netWorth: 0,
        accountCount: 0,
      );

      expect(balance.accountCount, equals(0));
    });

    test('valores grandes son soportados', () {
      const balance = TotalBalance(
        assets: 999999999999.99,
        liabilities: 111111111111.11,
        netWorth: 888888888888.88,
        accountCount: 100,
      );

      expect(balance.assets, equals(999999999999.99));
    });
  });
}
