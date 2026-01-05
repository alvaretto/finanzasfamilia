import 'package:flutter_test/flutter_test.dart';
import 'package:finanzas_familiares/features/transactions/domain/models/transaction_model.dart';

void main() {
  group('TransactionModel Validations', () {
    const userId = 'test-user-123';
    const accountId = 'account-123';

    test('transacción válida no tiene errores', () {
      final transaction = TransactionModel.create(
        userId: userId,
        accountId: accountId,
        amount: 1000.0,
        type: TransactionType.expense,
        categoryId: 'cat-1',
        date: DateTime.now(),
      );

      expect(transaction.isValid, true);
      expect(transaction.validationErrors, isEmpty);
    });

    test('monto cero genera error', () {
      final transaction = TransactionModel.create(
        userId: userId,
        accountId: accountId,
        amount: 0.0,
        type: TransactionType.expense,
        categoryId: 'cat-1',
      );

      expect(transaction.isValid, false);
      expect(
        transaction.validationErrors,
        contains('El monto debe ser mayor a cero'),
      );
    });

    test('monto negativo genera error (se convierte a positivo pero sigue siendo cero si es -0)', () {
      // El factory create() usa amount.abs(), así que -100 se convierte a 100
      final transaction = TransactionModel.create(
        userId: userId,
        accountId: accountId,
        amount: -100.0,
        type: TransactionType.expense,
        categoryId: 'cat-1',
      );

      // Como se convierte a abs(), debería ser válido si es > 0
      expect(transaction.isValid, true);
      expect(transaction.amount, 100.0);
    });

    test('fecha futura (más de 1 día) genera error', () {
      final futureDate = DateTime.now().add(const Duration(days: 2));
      final transaction = TransactionModel.create(
        userId: userId,
        accountId: accountId,
        amount: 100.0,
        type: TransactionType.expense,
        categoryId: 'cat-1',
        date: futureDate,
      );

      expect(transaction.isValid, false);
      expect(
        transaction.validationErrors,
        contains('La fecha no puede ser futura'),
      );
    });

    test('fecha de hoy es válida', () {
      final transaction = TransactionModel.create(
        userId: userId,
        accountId: accountId,
        amount: 100.0,
        type: TransactionType.expense,
        categoryId: 'cat-1',
        date: DateTime.now(),
      );

      expect(transaction.isValid, true);
    });

    test('gasto sin categoría genera error', () {
      final transaction = TransactionModel.create(
        userId: userId,
        accountId: accountId,
        amount: 100.0,
        type: TransactionType.expense,
        // categoryId: null (omitido)
      );

      expect(transaction.isValid, false);
      expect(
        transaction.validationErrors,
        contains('Debes seleccionar una categoría'),
      );
    });

    test('ingreso sin categoría genera error', () {
      final transaction = TransactionModel.create(
        userId: userId,
        accountId: accountId,
        amount: 100.0,
        type: TransactionType.income,
        // categoryId: null (omitido)
      );

      expect(transaction.isValid, false);
      expect(
        transaction.validationErrors,
        contains('Debes seleccionar una categoría'),
      );
    });

    test('transferencia sin cuenta destino genera error', () {
      final transaction = TransactionModel.create(
        userId: userId,
        accountId: accountId,
        amount: 100.0,
        type: TransactionType.transfer,
        // transferToAccountId: null (omitido)
      );

      expect(transaction.isValid, false);
      expect(
        transaction.validationErrors,
        contains('Debes seleccionar la cuenta de destino'),
      );
    });

    test('transferencia a la misma cuenta genera error', () {
      final transaction = TransactionModel.create(
        userId: userId,
        accountId: accountId,
        amount: 100.0,
        type: TransactionType.transfer,
        transferToAccountId: accountId, // Misma cuenta
      );

      expect(transaction.isValid, false);
      expect(
        transaction.validationErrors,
        contains('La cuenta de destino debe ser diferente a la de origen'),
      );
    });

    test('transferencia válida con cuenta diferente', () {
      final transaction = TransactionModel.create(
        userId: userId,
        accountId: accountId,
        amount: 100.0,
        type: TransactionType.transfer,
        transferToAccountId: 'account-456', // Cuenta diferente
      );

      expect(transaction.isValid, true);
      expect(transaction.validationErrors, isEmpty);
    });

    test('múltiples errores se acumulan', () {
      final futureDate = DateTime.now().add(const Duration(days: 2));
      final transaction = TransactionModel.create(
        userId: userId,
        accountId: accountId,
        amount: 0.0, // Error: monto cero
        type: TransactionType.expense,
        // categoryId: null, // Error: sin categoría
        date: futureDate, // Error: fecha futura
      );

      expect(transaction.isValid, false);
      expect(transaction.validationErrors.length, greaterThan(1));
      expect(
        transaction.validationErrors,
        contains('El monto debe ser mayor a cero'),
      );
      expect(
        transaction.validationErrors,
        contains('Debes seleccionar una categoría'),
      );
      expect(
        transaction.validationErrors,
        contains('La fecha no puede ser futura'),
      );
    });

    test('validate() lanza excepción si hay errores', () {
      final transaction = TransactionModel.create(
        userId: userId,
        accountId: accountId,
        amount: 0.0,
        type: TransactionType.expense,
      );

      expect(
        () => transaction.validate(),
        throwsA(isA<ArgumentError>()),
      );
    });

    test('validate() no lanza excepción si es válida', () {
      final transaction = TransactionModel.create(
        userId: userId,
        accountId: accountId,
        amount: 100.0,
        type: TransactionType.expense,
        categoryId: 'cat-1',
      );

      expect(() => transaction.validate(), returnsNormally);
    });
  });
}
