import 'package:flutter_test/flutter_test.dart';

import 'package:finanzas_familiares/core/constants/enums.dart';

void main() {
  group('AccountType', () {
    test('tiene 4 valores', () {
      expect(AccountType.values, hasLength(4));
    });

    test('contiene todos los tipos esperados', () {
      expect(AccountType.values, contains(AccountType.asset));
      expect(AccountType.values, contains(AccountType.liability));
      expect(AccountType.values, contains(AccountType.income));
      expect(AccountType.values, contains(AccountType.expense));
    });

    test('asset es el primer valor (índice 0)', () {
      expect(AccountType.values[0], equals(AccountType.asset));
    });

    test('name retorna el nombre del enum', () {
      expect(AccountType.asset.name, equals('asset'));
      expect(AccountType.liability.name, equals('liability'));
      expect(AccountType.income.name, equals('income'));
      expect(AccountType.expense.name, equals('expense'));
    });

    test('index retorna posición correcta', () {
      expect(AccountType.asset.index, equals(0));
      expect(AccountType.liability.index, equals(1));
      expect(AccountType.income.index, equals(2));
      expect(AccountType.expense.index, equals(3));
    });
  });

  group('TransactionType', () {
    test('tiene 3 valores', () {
      expect(TransactionType.values, hasLength(3));
    });

    test('contiene todos los tipos esperados', () {
      expect(TransactionType.values, contains(TransactionType.income));
      expect(TransactionType.values, contains(TransactionType.expense));
      expect(TransactionType.values, contains(TransactionType.transfer));
    });

    test('name retorna el nombre del enum', () {
      expect(TransactionType.income.name, equals('income'));
      expect(TransactionType.expense.name, equals('expense'));
      expect(TransactionType.transfer.name, equals('transfer'));
    });

    test('index retorna posición correcta', () {
      expect(TransactionType.income.index, equals(0));
      expect(TransactionType.expense.index, equals(1));
      expect(TransactionType.transfer.index, equals(2));
    });
  });

  group('SyncStatus', () {
    test('tiene 3 valores', () {
      expect(SyncStatus.values, hasLength(3));
    });

    test('contiene todos los estados esperados', () {
      expect(SyncStatus.values, contains(SyncStatus.pending));
      expect(SyncStatus.values, contains(SyncStatus.synced));
      expect(SyncStatus.values, contains(SyncStatus.error));
    });

    test('name retorna el nombre del enum', () {
      expect(SyncStatus.pending.name, equals('pending'));
      expect(SyncStatus.synced.name, equals('synced'));
      expect(SyncStatus.error.name, equals('error'));
    });

    test('index retorna posición correcta', () {
      expect(SyncStatus.pending.index, equals(0));
      expect(SyncStatus.synced.index, equals(1));
      expect(SyncStatus.error.index, equals(2));
    });
  });

  group('Enum usage patterns', () {
    test('AccountType puede usarse en switch', () {
      String describe(AccountType type) {
        switch (type) {
          case AccountType.asset:
            return 'Lo que tengo';
          case AccountType.liability:
            return 'Lo que debo';
          case AccountType.income:
            return 'Dinero que entra';
          case AccountType.expense:
            return 'Dinero que sale';
        }
      }

      expect(describe(AccountType.asset), equals('Lo que tengo'));
      expect(describe(AccountType.liability), equals('Lo que debo'));
      expect(describe(AccountType.income), equals('Dinero que entra'));
      expect(describe(AccountType.expense), equals('Dinero que sale'));
    });

    test('TransactionType puede usarse en condicionales', () {
      bool isMoneyMovement(TransactionType type) {
        return type == TransactionType.income || type == TransactionType.expense;
      }

      expect(isMoneyMovement(TransactionType.income), isTrue);
      expect(isMoneyMovement(TransactionType.expense), isTrue);
      expect(isMoneyMovement(TransactionType.transfer), isFalse);
    });

    test('SyncStatus permite verificar estado', () {
      bool needsSync(SyncStatus status) {
        return status == SyncStatus.pending || status == SyncStatus.error;
      }

      expect(needsSync(SyncStatus.pending), isTrue);
      expect(needsSync(SyncStatus.error), isTrue);
      expect(needsSync(SyncStatus.synced), isFalse);
    });
  });
}
