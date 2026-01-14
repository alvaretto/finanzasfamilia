import 'package:flutter_test/flutter_test.dart';

import 'package:finanzas_familiares/domain/exceptions/accounting_exceptions.dart';

void main() {
  group('InsufficientFundsException', () {
    test('calcula shortfall correctamente', () {
      const exception = InsufficientFundsException(
        available: 50000,
        required: 80000,
        accountName: 'Nequi',
      );

      expect(exception.shortfall, equals(30000));
    });

    test('shortfall es negativo cuando hay suficiente', () {
      // Edge case: si se crea con available > required
      const exception = InsufficientFundsException(
        available: 100000,
        required: 50000,
        accountName: 'Nequi',
      );

      expect(exception.shortfall, equals(-50000));
    });

    test('toString contiene información relevante', () {
      const exception = InsufficientFundsException(
        available: 50000,
        required: 80000,
        accountName: 'Nequi',
      );

      final message = exception.toString();
      expect(message, contains('Nequi'));
      expect(message, contains('50000'));
      expect(message, contains('80000'));
      expect(message, contains('30000'));
      expect(message, contains('Fondos insuficientes'));
    });

    test('formatea montos sin decimales', () {
      const exception = InsufficientFundsException(
        available: 50000.75,
        required: 80000.50,
        accountName: 'Cuenta',
      );

      final message = exception.toString();
      expect(message, contains('\$50001'));
      expect(message, contains('\$80001') , reason: 'Debería redondear hacia arriba');
    });

    test('implements Exception', () {
      const exception = InsufficientFundsException(
        available: 0,
        required: 100,
        accountName: 'Test',
      );

      expect(exception, isA<Exception>());
    });
  });

  group('AccountHasBalanceException', () {
    test('toString contiene nombre de cuenta y saldo', () {
      const exception = AccountHasBalanceException(
        balance: 150000,
        accountName: 'Cuenta Ahorros',
      );

      final message = exception.toString();
      expect(message, contains('Cuenta Ahorros'));
      expect(message, contains('150000'));
      expect(message, contains('No se puede eliminar'));
    });

    test('toString sugiere transferir saldo', () {
      const exception = AccountHasBalanceException(
        balance: 100000,
        accountName: 'Nequi',
      );

      expect(exception.toString(), contains('Transfiere'));
    });

    test('maneja saldo negativo', () {
      const exception = AccountHasBalanceException(
        balance: -50000,
        accountName: 'Tarjeta Crédito',
      );

      final message = exception.toString();
      expect(message, contains('-50000'));
    });

    test('implements Exception', () {
      const exception = AccountHasBalanceException(
        balance: 0,
        accountName: 'Test',
      );

      expect(exception, isA<Exception>());
    });
  });

  group('CategoryHasChildrenException', () {
    test('toString contiene nombre de categoría y cantidad de hijos', () {
      const exception = CategoryHasChildrenException(
        categoryName: 'Alimentación',
        childCount: 5,
      );

      final message = exception.toString();
      expect(message, contains('Alimentación'));
      expect(message, contains('5'));
      expect(message, contains('No se puede eliminar'));
    });

    test('toString sugiere eliminar subcategorías primero', () {
      const exception = CategoryHasChildrenException(
        categoryName: 'Gastos',
        childCount: 3,
      );

      expect(exception.toString(), contains('subcategoría'));
      expect(exception.toString(), contains('Elimina primero'));
    });

    test('maneja singular/plural en subcategorías', () {
      const exception1 = CategoryHasChildrenException(
        categoryName: 'Cat',
        childCount: 1,
      );
      const exception5 = CategoryHasChildrenException(
        categoryName: 'Cat',
        childCount: 5,
      );

      // Ambos usan el mismo texto (subcategoría(s))
      expect(exception1.toString(), contains('subcategoría'));
      expect(exception5.toString(), contains('subcategoría'));
    });

    test('implements Exception', () {
      const exception = CategoryHasChildrenException(
        categoryName: 'Test',
        childCount: 0,
      );

      expect(exception, isA<Exception>());
    });
  });

  group('SystemCategoryException', () {
    test('toString contiene nombre de categoría', () {
      const exception = SystemCategoryException(
        categoryName: 'Activos',
      );

      final message = exception.toString();
      expect(message, contains('Activos'));
      expect(message, contains('No se puede eliminar'));
    });

    test('toString indica que es categoría del sistema', () {
      const exception = SystemCategoryException(
        categoryName: 'Pasivos',
      );

      expect(exception.toString(), contains('categoría del sistema'));
    });

    test('implements Exception', () {
      const exception = SystemCategoryException(categoryName: 'Test');

      expect(exception, isA<Exception>());
    });
  });

  group('Exception throwing and catching', () {
    test('InsufficientFundsException puede ser lanzada y capturada', () {
      expect(
        () => throw const InsufficientFundsException(
          available: 100,
          required: 200,
          accountName: 'Test',
        ),
        throwsA(isA<InsufficientFundsException>()),
      );
    });

    test('AccountHasBalanceException puede ser lanzada y capturada', () {
      expect(
        () => throw const AccountHasBalanceException(
          balance: 100,
          accountName: 'Test',
        ),
        throwsA(isA<AccountHasBalanceException>()),
      );
    });

    test('CategoryHasChildrenException puede ser lanzada y capturada', () {
      expect(
        () => throw const CategoryHasChildrenException(
          categoryName: 'Test',
          childCount: 1,
        ),
        throwsA(isA<CategoryHasChildrenException>()),
      );
    });

    test('SystemCategoryException puede ser lanzada y capturada', () {
      expect(
        () => throw const SystemCategoryException(categoryName: 'Test'),
        throwsA(isA<SystemCategoryException>()),
      );
    });

    test('todas las excepciones pueden ser capturadas como Exception', () {
      final exceptions = <Exception>[
        const InsufficientFundsException(available: 0, required: 100, accountName: 'A'),
        const AccountHasBalanceException(balance: 100, accountName: 'B'),
        const CategoryHasChildrenException(categoryName: 'C', childCount: 1),
        const SystemCategoryException(categoryName: 'D'),
      ];

      for (final exception in exceptions) {
        expect(
          () => throw exception,
          throwsA(isA<Exception>()),
        );
      }
    });
  });
}
