import 'package:flutter_test/flutter_test.dart';
import 'package:finanzas_familiares/features/transactions/domain/models/transaction_model.dart';

void main() {
  group('TransactionModel', () {
    test('create() genera transaccion con valores correctos', () {
      final tx = TransactionModel.create(
        userId: 'user-123',
        accountId: 'account-456',
        amount: 150.50,
        type: TransactionType.expense,
        categoryId: 'cat-1',
        description: 'Compras supermercado',
      );

      expect(tx.userId, 'user-123');
      expect(tx.accountId, 'account-456');
      expect(tx.amount, 150.50);
      expect(tx.type, TransactionType.expense);
      expect(tx.categoryId, 'cat-1');
      expect(tx.description, 'Compras supermercado');
      expect(tx.isSynced, false);
      expect(tx.id, isNotEmpty);
    });

    test('amount siempre es positivo', () {
      final tx = TransactionModel.create(
        userId: 'user-123',
        accountId: 'account-456',
        amount: -100.0,
        type: TransactionType.expense,
      );

      expect(tx.amount, 100.0);
    });

    test('fecha por defecto es ahora', () {
      final before = DateTime.now();
      final tx = TransactionModel.create(
        userId: 'user-123',
        accountId: 'account-456',
        amount: 50.0,
        type: TransactionType.income,
      );
      final after = DateTime.now();

      expect(tx.date.isAfter(before.subtract(const Duration(seconds: 1))), true);
      expect(tx.date.isBefore(after.add(const Duration(seconds: 1))), true);
    });

    test('tags por defecto es lista vacia', () {
      final tx = TransactionModel.create(
        userId: 'user-123',
        accountId: 'account-456',
        amount: 50.0,
        type: TransactionType.income,
      );

      expect(tx.tags, isEmpty);
    });
  });

  group('TransactionType', () {
    test('displayName devuelve nombre correcto', () {
      expect(TransactionType.income.displayName, 'Ingreso');
      expect(TransactionType.expense.displayName, 'Gasto');
      expect(TransactionType.transfer.displayName, 'Transferencia');
    });

    test('icon devuelve icono correcto', () {
      expect(TransactionType.income.icon, 'arrow_downward');
      expect(TransactionType.expense.icon, 'arrow_upward');
      expect(TransactionType.transfer.icon, 'swap_horiz');
    });
  });

  group('CategoryModel', () {
    test('isIncome y isExpense funcionan correctamente', () {
      const incomeCategory = CategoryModel(
        id: 'cat-1',
        name: 'Salario',
        type: 'income',
      );

      const expenseCategory = CategoryModel(
        id: 'cat-2',
        name: 'Comida',
        type: 'expense',
      );

      expect(incomeCategory.isIncome, true);
      expect(incomeCategory.isExpense, false);
      expect(expenseCategory.isIncome, false);
      expect(expenseCategory.isExpense, true);
    });
  });
}
