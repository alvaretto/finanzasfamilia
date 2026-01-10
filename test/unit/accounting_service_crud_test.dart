import 'package:drift/drift.dart' hide isNull, isNotNull;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:finanzas_familiares/data/local/database.dart';
import 'package:finanzas_familiares/data/local/daos/daos.dart';
import 'package:finanzas_familiares/data/repositories/repositories.dart';
import 'package:finanzas_familiares/domain/services/accounting_service.dart';

/// Tests para AccountingService - CRUD de Transacciones
/// Verifica: crear, eliminar, actualizar transacciones con reversión de asientos
void main() {
  late AppDatabase db;
  late AccountingService accountingService;
  late AccountsDao accountsDao;
  late TransactionsDao transactionsDao;
  late JournalEntriesDao journalEntriesDao;

  // IDs de prueba
  const testAccountId = 'test-account-001';
  const testCategoryId = 'test-category-001';
  const testIncomeAccountId = 'test-income-account-001';
  const testIncomeCategoryId = 'test-income-category-001';

  setUp(() async {
    db = AppDatabase.forTesting(NativeDatabase.memory());
    accountsDao = AccountsDao(db);
    transactionsDao = TransactionsDao(db);
    journalEntriesDao = JournalEntriesDao(db);

    // Crear repositorios
    final accountRepository = DriftAccountRepository(db);
    final transactionRepository = DriftTransactionRepository(db);
    final journalEntryRepository = DriftJournalEntryRepository(db);
    final categoryRepository = DriftCategoryRepository(db);
    final transactionExecutor = DriftTransactionExecutor(db);

    accountingService = AccountingService(
      accountRepository: accountRepository,
      transactionRepository: transactionRepository,
      journalEntryRepository: journalEntryRepository,
      categoryRepository: categoryRepository,
      transactionExecutor: transactionExecutor,
    );

    // Crear categoría padre para activos (requerida por FK)
    await db.into(db.categories).insert(
          CategoriesCompanion.insert(
            id: 'asset-category',
            name: 'Activos',
            type: 'asset',
            level: const Value(0),
          ),
        );

    // Crear categoría de gasto
    await db.into(db.categories).insert(
          CategoriesCompanion.insert(
            id: testCategoryId,
            name: 'Alimentación',
            type: 'expense',
            level: const Value(1),
          ),
        );

    // Crear categoría de ingreso
    await db.into(db.categories).insert(
          CategoriesCompanion.insert(
            id: testIncomeCategoryId,
            name: 'Salario',
            type: 'income',
            level: const Value(1),
          ),
        );

    // Crear cuenta de activo para pagos
    await db.into(db.accounts).insert(
          AccountsCompanion.insert(
            id: testAccountId,
            name: 'Efectivo',
            categoryId: 'asset-category',
            balance: const Value(1000000), // 1M inicial
          ),
        );

    // Crear cuenta para ingresos
    await db.into(db.accounts).insert(
          AccountsCompanion.insert(
            id: testIncomeAccountId,
            name: 'Banco',
            categoryId: 'asset-category',
            balance: const Value(500000), // 500k inicial
          ),
        );
  });

  tearDown(() async {
    await db.close();
  });

  group('AccountingService - Eliminar Transacción', () {
    test('deleteTransaction elimina gasto y revierte balance', () async {
      // Arrange - Crear un gasto
      final expense = await accountingService.recordExpense(
        categoryId: testCategoryId,
        paymentAccountId: testAccountId,
        amount: 100000,
        description: 'Compra test',
        date: DateTime.now(),
      );

      // Verificar que el balance bajó
      final accountAfterExpense = await accountsDao.getAccountById(testAccountId);
      expect(accountAfterExpense!.balance, equals(900000)); // 1M - 100k

      // Act - Eliminar la transacción
      await accountingService.deleteTransaction(expense.id);

      // Assert - El balance debe volver al original
      final accountAfterDelete = await accountsDao.getAccountById(testAccountId);
      expect(accountAfterDelete!.balance, equals(1000000)); // Vuelve a 1M

      // Verificar que la transacción fue eliminada
      final transactions = await transactionsDao.getAllTransactions();
      expect(transactions.where((t) => t.id == expense.id), isEmpty);

      // Verificar que los asientos fueron eliminados
      final entries = await journalEntriesDao.getEntriesByTransaction(expense.id);
      expect(entries, isEmpty);
    });

    test('deleteTransaction elimina ingreso y revierte balance', () async {
      // Arrange - Crear un ingreso
      final income = await accountingService.recordIncome(
        categoryId: testIncomeCategoryId,
        destinationAccountId: testIncomeAccountId,
        amount: 200000,
        description: 'Ingreso test',
        date: DateTime.now(),
      );

      // Verificar que el balance subió
      final accountAfterIncome =
          await accountsDao.getAccountById(testIncomeAccountId);
      expect(accountAfterIncome!.balance, equals(700000)); // 500k + 200k

      // Act - Eliminar la transacción
      await accountingService.deleteTransaction(income.id);

      // Assert - El balance debe volver al original
      final accountAfterDelete =
          await accountsDao.getAccountById(testIncomeAccountId);
      expect(accountAfterDelete!.balance, equals(500000)); // Vuelve a 500k
    });

    test('deleteTransaction elimina transferencia y revierte ambos balances',
        () async {
      // Arrange - Crear una transferencia
      final transfer = await accountingService.recordTransfer(
        fromAccountId: testAccountId,
        toAccountId: testIncomeAccountId,
        amount: 50000,
        description: 'Transferencia test',
        date: DateTime.now(),
      );

      // Verificar balances después de transferencia
      final fromAfter = await accountsDao.getAccountById(testAccountId);
      final toAfter = await accountsDao.getAccountById(testIncomeAccountId);
      expect(fromAfter!.balance, equals(950000)); // 1M - 50k
      expect(toAfter!.balance, equals(550000)); // 500k + 50k

      // Act - Eliminar la transferencia
      await accountingService.deleteTransaction(transfer.id);

      // Assert - Ambos balances deben volver al original
      final fromAfterDelete = await accountsDao.getAccountById(testAccountId);
      final toAfterDelete =
          await accountsDao.getAccountById(testIncomeAccountId);
      expect(fromAfterDelete!.balance, equals(1000000)); // Vuelve a 1M
      expect(toAfterDelete!.balance, equals(500000)); // Vuelve a 500k
    });

    test('deleteTransaction lanza error si transacción no existe', () async {
      // Act & Assert
      expect(
        () => accountingService.deleteTransaction('non-existent-id'),
        throwsA(isA<StateError>()),
      );
    });
  });

  group('AccountingService - Actualizar Transacción', () {
    test('updateTransaction actualiza monto de gasto correctamente', () async {
      // Arrange - Crear un gasto
      final expense = await accountingService.recordExpense(
        categoryId: testCategoryId,
        paymentAccountId: testAccountId,
        amount: 100000,
        description: 'Gasto original',
        date: DateTime.now(),
      );

      final balanceAfterCreate =
          await accountsDao.getAccountById(testAccountId);
      expect(balanceAfterCreate!.balance, equals(900000)); // 1M - 100k

      // Act - Actualizar el monto a 150000
      final updated = await accountingService.updateTransaction(
        transactionId: expense.id,
        type: 'expense',
        categoryId: testCategoryId,
        amount: 150000,
        description: 'Gasto actualizado',
        date: DateTime.now(),
        fromAccountId: testAccountId,
      );

      // Assert - El balance debe reflejar el nuevo monto
      final balanceAfterUpdate =
          await accountsDao.getAccountById(testAccountId);
      expect(balanceAfterUpdate!.balance, equals(850000)); // 1M - 150k

      // Verificar que la descripción se actualizó
      expect(updated.description, equals('Gasto actualizado'));
      expect(updated.amount, equals(150000));
    });

    test('updateTransaction cambia tipo de expense a income', () async {
      // Arrange - Crear un gasto
      final expense = await accountingService.recordExpense(
        categoryId: testCategoryId,
        paymentAccountId: testAccountId,
        amount: 100000,
        description: 'Era gasto',
        date: DateTime.now(),
      );

      final accountBalanceAfterExpense =
          await accountsDao.getAccountById(testAccountId);
      expect(accountBalanceAfterExpense!.balance, equals(900000)); // 1M - 100k

      // Act - Cambiar a ingreso
      await accountingService.updateTransaction(
        transactionId: expense.id,
        type: 'income',
        categoryId: testIncomeCategoryId,
        amount: 100000,
        description: 'Ahora es ingreso',
        date: DateTime.now(),
        toAccountId: testIncomeAccountId,
      );

      // Assert
      // La cuenta original debe volver a su balance inicial (reversión del gasto)
      final accountAfterUpdate =
          await accountsDao.getAccountById(testAccountId);
      expect(accountAfterUpdate!.balance, equals(1000000)); // Vuelve a 1M

      // La cuenta destino del ingreso debe aumentar
      final incomeAccountAfter =
          await accountsDao.getAccountById(testIncomeAccountId);
      expect(incomeAccountAfter!.balance, equals(600000)); // 500k + 100k
    });

    test('updateTransaction lanza error si transacción no existe', () async {
      // Act & Assert
      expect(
        () => accountingService.updateTransaction(
          transactionId: 'non-existent-id',
          type: 'expense',
          categoryId: testCategoryId,
          amount: 100000,
          description: 'Test',
          date: DateTime.now(),
          fromAccountId: testAccountId,
        ),
        throwsA(isA<StateError>()),
      );
    });
  });

  group('AccountingService - getTransactionById', () {
    test('retorna transacción existente', () async {
      // Arrange
      final expense = await accountingService.recordExpense(
        categoryId: testCategoryId,
        paymentAccountId: testAccountId,
        amount: 50000,
        description: 'Test get',
        date: DateTime.now(),
      );

      // Act
      final found = await accountingService.getTransactionById(expense.id);

      // Assert
      expect(found, isNotNull);
      expect(found!.id, equals(expense.id));
      expect(found.amount, equals(50000));
    });

    test('retorna null para transacción inexistente', () async {
      // Act
      final found =
          await accountingService.getTransactionById('non-existent-id');

      // Assert
      expect(found, isNull);
    });
  });

  group('AccountingService - Flujo completo CRUD', () {
    test('crea, lee, actualiza y elimina transacción correctamente', () async {
      // CREATE
      final expense = await accountingService.recordExpense(
        categoryId: testCategoryId,
        paymentAccountId: testAccountId,
        amount: 75000,
        description: 'CRUD Test',
        date: DateTime(2026, 1, 15),
      );
      expect(expense.id, isNotEmpty);

      // READ
      final found = await accountingService.getTransactionById(expense.id);
      expect(found, isNotNull);
      expect(found!.amount, equals(75000));

      // UPDATE
      final updated = await accountingService.updateTransaction(
        transactionId: expense.id,
        type: 'expense',
        categoryId: testCategoryId,
        amount: 80000,
        description: 'CRUD Test Updated',
        date: DateTime(2026, 1, 16),
        fromAccountId: testAccountId,
      );
      expect(updated.amount, equals(80000));
      expect(updated.description, equals('CRUD Test Updated'));

      // DELETE
      await accountingService.deleteTransaction(updated.id);
      final afterDelete =
          await accountingService.getTransactionById(updated.id);
      expect(afterDelete, isNull);

      // Balance debe volver al original
      final finalBalance = await accountsDao.getAccountById(testAccountId);
      expect(finalBalance!.balance, equals(1000000));
    });
  });
}
