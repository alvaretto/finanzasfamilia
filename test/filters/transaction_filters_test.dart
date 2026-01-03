import 'package:flutter_test/flutter_test.dart';
import 'package:finanzas_familiares/features/transactions/domain/models/transaction_model.dart';
import 'package:finanzas_familiares/features/transactions/presentation/widgets/search_filter_sheet.dart';

void main() {
  late List<TransactionModel> testTransactions;

  setUp(() {
    testTransactions = [
      TransactionModel(
        id: '1',
        userId: 'user-1',
        accountId: 'acc-1',
        amount: 100.0,
        type: TransactionType.expense,
        date: DateTime.now(),
        description: 'Comida restaurante',
        categoryId: 1,
        categoryName: 'Alimentacion',
        accountName: 'Efectivo',
      ),
      TransactionModel(
        id: '2',
        userId: 'user-1',
        accountId: 'acc-2',
        amount: 5000.0,
        type: TransactionType.income,
        date: DateTime.now(),
        description: 'Salario mensual',
        categoryId: 2,
        categoryName: 'Salario',
        accountName: 'Banco',
      ),
      TransactionModel(
        id: '3',
        userId: 'user-1',
        accountId: 'acc-1',
        amount: 250.0,
        type: TransactionType.expense,
        date: DateTime.now(),
        description: 'Gasolina',
        categoryId: 3,
        categoryName: 'Transporte',
        accountName: 'Efectivo',
      ),
      TransactionModel(
        id: '4',
        userId: 'user-1',
        accountId: 'acc-1',
        amount: 1000.0,
        type: TransactionType.transfer,
        date: DateTime.now(),
        description: 'Transferencia ahorro',
        transferToAccountId: 'acc-3',
        accountName: 'Efectivo',
      ),
    ];
  });

  group('TransactionFilters', () {
    test('sin filtros devuelve todas las transacciones', () {
      const filters = TransactionFilters();
      final result = filters.apply(testTransactions);

      expect(result.length, 4);
    });

    test('filtrar por tipo expense', () {
      const filters = TransactionFilters(type: TransactionType.expense);
      final result = filters.apply(testTransactions);

      expect(result.length, 2);
      expect(result.every((tx) => tx.type == TransactionType.expense), true);
    });

    test('filtrar por tipo income', () {
      const filters = TransactionFilters(type: TransactionType.income);
      final result = filters.apply(testTransactions);

      expect(result.length, 1);
      expect(result.first.type, TransactionType.income);
    });

    test('filtrar por cuenta', () {
      const filters = TransactionFilters(accountId: 'acc-1');
      final result = filters.apply(testTransactions);

      expect(result.length, 3);
      expect(result.every((tx) => tx.accountId == 'acc-1'), true);
    });

    test('filtrar por categoria', () {
      const filters = TransactionFilters(categoryId: 1);
      final result = filters.apply(testTransactions);

      expect(result.length, 1);
      expect(result.first.categoryId, 1);
    });

    test('filtrar por monto minimo', () {
      const filters = TransactionFilters(minAmount: 500.0);
      final result = filters.apply(testTransactions);

      expect(result.length, 2);
      expect(result.every((tx) => tx.amount >= 500.0), true);
    });

    test('filtrar por monto maximo', () {
      const filters = TransactionFilters(maxAmount: 500.0);
      final result = filters.apply(testTransactions);

      expect(result.length, 2);
      expect(result.every((tx) => tx.amount <= 500.0), true);
    });

    test('filtrar por rango de monto', () {
      const filters = TransactionFilters(minAmount: 100.0, maxAmount: 1000.0);
      final result = filters.apply(testTransactions);

      expect(result.length, 3);
      expect(result.every((tx) => tx.amount >= 100.0 && tx.amount <= 1000.0), true);
    });

    test('busqueda por texto en descripcion', () {
      const filters = TransactionFilters(searchQuery: 'salario');
      final result = filters.apply(testTransactions);

      expect(result.length, 1);
      expect(result.first.description, 'Salario mensual');
    });

    test('busqueda por texto en categoria', () {
      const filters = TransactionFilters(searchQuery: 'alimentacion');
      final result = filters.apply(testTransactions);

      expect(result.length, 1);
      expect(result.first.categoryName, 'Alimentacion');
    });

    test('busqueda por texto en cuenta', () {
      const filters = TransactionFilters(searchQuery: 'banco');
      final result = filters.apply(testTransactions);

      expect(result.length, 1);
      expect(result.first.accountName, 'Banco');
    });

    test('combinar multiples filtros', () {
      const filters = TransactionFilters(
        type: TransactionType.expense,
        accountId: 'acc-1',
        maxAmount: 200.0,
      );
      final result = filters.apply(testTransactions);

      expect(result.length, 1);
      expect(result.first.description, 'Comida restaurante');
    });

    test('hasActiveFilters detecta filtros activos', () {
      const noFilters = TransactionFilters();
      const withFilters = TransactionFilters(type: TransactionType.expense);

      expect(noFilters.hasActiveFilters, false);
      expect(withFilters.hasActiveFilters, true);
    });

    test('activeFilterCount cuenta filtros activos', () {
      const filters = TransactionFilters(
        searchQuery: 'test',
        type: TransactionType.expense,
        accountId: 'acc-1',
        minAmount: 100.0,
      );

      expect(filters.activeFilterCount, 4);
    });

    test('copyWith mantiene valores existentes', () {
      const original = TransactionFilters(
        type: TransactionType.expense,
        accountId: 'acc-1',
      );

      final copied = original.copyWith(categoryId: 1);

      expect(copied.type, TransactionType.expense);
      expect(copied.accountId, 'acc-1');
      expect(copied.categoryId, 1);
    });

    test('copyWith con clear elimina valores', () {
      const original = TransactionFilters(
        searchQuery: 'test',
        type: TransactionType.expense,
      );

      final cleared = original.copyWith(clearSearch: true);

      expect(cleared.searchQuery, null);
      expect(cleared.type, TransactionType.expense);
    });
  });
}
