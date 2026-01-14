import 'package:flutter_test/flutter_test.dart';
import 'package:drift/drift.dart';
import 'package:drift/native.dart';

import 'package:finanzas_familiares/data/local/database.dart';
import 'package:finanzas_familiares/data/local/daos/daos.dart';
import 'package:finanzas_familiares/data/local/seeders/seeders.dart';
import 'package:finanzas_familiares/data/repositories/repositories.dart';
import 'package:finanzas_familiares/domain/services/accounting_service.dart';

void main() {
  group('AccountingService Integration Tests', () {
    late AppDatabase db;
    late AccountingService accountingService;
    late CategoriesDao categoriesDao;
    late AccountsDao accountsDao;
    late JournalEntriesDao journalEntriesDao;

    late String testAccountId;
    late String testExpenseCategoryId;
    late String testIncomeCategoryId;

    setUp(() async {
      db = AppDatabase.forTesting(NativeDatabase.memory());
      categoriesDao = CategoriesDao(db);
      accountsDao = AccountsDao(db);
      journalEntriesDao = JournalEntriesDao(db);

      // Crear repositorios (Clean Architecture)
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

      // Seed categorías
      await seedCategories(categoriesDao);

      // Obtener categorías para tests
      final expenseCategories = await categoriesDao.getCategoriesByType('expense');
      testExpenseCategoryId = expenseCategories.first.id;

      final incomeCategories = await categoriesDao.getCategoriesByType('income');
      testIncomeCategoryId = incomeCategories.first.id;

      // Obtener una categoría asset para crear cuenta
      final assetCategories = await categoriesDao.getCategoriesByType('asset');
      final assetCategoryId = assetCategories.first.id;

      // Crear cuenta de prueba
      testAccountId = 'test-account-001';
      await accountsDao.insertAccount(AccountsCompanion.insert(
        id: testAccountId,
        name: 'Cuenta Test',
        categoryId: assetCategoryId,
        balance: const Value(100000), // 100,000 COP inicial
      ));
    });

    tearDown(() async {
      await db.close();
    });

    group('recordExpense', () {
      test('crea transacción y asientos contables', () async {
        // Act
        final transaction = await accountingService.recordExpense(
          categoryId: testExpenseCategoryId,
          paymentAccountId: testAccountId,
          amount: 25000,
          description: 'Compra de prueba',
          date: DateTime.now(),
        );

        // Assert - Transacción creada
        expect(transaction.type, equals('expense'));
        expect(transaction.amount, equals(25000));
        expect(transaction.description, equals('Compra de prueba'));
        expect(transaction.categoryId, equals(testExpenseCategoryId));
        expect(transaction.fromAccountId, equals(testAccountId));

        // Assert - Asientos contables creados (2: débito y crédito)
        final entries = await journalEntriesDao.getEntriesByTransaction(transaction.id);
        expect(entries.length, equals(2));

        final debitEntry = entries.firstWhere((e) => e.entryType == 'debit');
        final creditEntry = entries.firstWhere((e) => e.entryType == 'credit');

        expect(debitEntry.amount, equals(25000));
        expect(debitEntry.categoryId, equals(testExpenseCategoryId));

        expect(creditEntry.amount, equals(25000));
        expect(creditEntry.accountId, equals(testAccountId));
      });

      test('actualiza balance de cuenta correctamente', () async {
        // Balance inicial: 100,000
        final initialAccount = await accountsDao.getAccountById(testAccountId);
        expect(initialAccount!.balance, equals(100000));

        // Act - Gastar 30,000
        await accountingService.recordExpense(
          categoryId: testExpenseCategoryId,
          paymentAccountId: testAccountId,
          amount: 30000,
          description: 'Gasto test',
          date: DateTime.now(),
        );

        // Assert - Balance final: 70,000
        final finalAccount = await accountsDao.getAccountById(testAccountId);
        expect(finalAccount!.balance, equals(70000));
      });

      test('rechaza monto cero o negativo', () async {
        expect(
          () => accountingService.recordExpense(
            categoryId: testExpenseCategoryId,
            paymentAccountId: testAccountId,
            amount: 0,
            description: 'Monto cero',
            date: DateTime.now(),
          ),
          throwsArgumentError,
        );

        expect(
          () => accountingService.recordExpense(
            categoryId: testExpenseCategoryId,
            paymentAccountId: testAccountId,
            amount: -100,
            description: 'Monto negativo',
            date: DateTime.now(),
          ),
          throwsArgumentError,
        );
      });

      test('rechaza cuenta inexistente', () async {
        expect(
          () => accountingService.recordExpense(
            categoryId: testExpenseCategoryId,
            paymentAccountId: 'cuenta-inexistente',
            amount: 1000,
            description: 'Test',
            date: DateTime.now(),
          ),
          throwsStateError,
        );
      });
    });

    group('recordIncome', () {
      test('crea transacción y asientos contables', () async {
        // Act
        final transaction = await accountingService.recordIncome(
          categoryId: testIncomeCategoryId,
          destinationAccountId: testAccountId,
          amount: 500000,
          description: 'Ingreso de prueba',
          date: DateTime.now(),
        );

        // Assert
        expect(transaction.type, equals('income'));
        expect(transaction.amount, equals(500000));
        expect(transaction.toAccountId, equals(testAccountId));

        // Verificar asientos
        final entries = await journalEntriesDao.getEntriesByTransaction(transaction.id);
        expect(entries.length, equals(2));
      });

      test('aumenta balance de cuenta correctamente', () async {
        // Balance inicial: 100,000
        final initialAccount = await accountsDao.getAccountById(testAccountId);
        expect(initialAccount!.balance, equals(100000));

        // Act - Recibir 200,000
        await accountingService.recordIncome(
          categoryId: testIncomeCategoryId,
          destinationAccountId: testAccountId,
          amount: 200000,
          description: 'Salario',
          date: DateTime.now(),
        );

        // Assert - Balance final: 300,000
        final finalAccount = await accountsDao.getAccountById(testAccountId);
        expect(finalAccount!.balance, equals(300000));
      });
    });

    group('recordTransfer', () {
      late String secondAccountId;

      setUp(() async {
        // Crear segunda cuenta para transferencias
        final assetCategories = await categoriesDao.getCategoriesByType('asset');
        secondAccountId = 'test-account-002';
        await accountsDao.insertAccount(AccountsCompanion.insert(
          id: secondAccountId,
          name: 'Segunda Cuenta Test',
          categoryId: assetCategories.first.id,
          balance: const Value(50000), // 50,000 COP inicial
        ));
      });

      test('transfiere entre cuentas correctamente', () async {
        // Balance inicial: Cuenta 1 = 100,000, Cuenta 2 = 50,000

        // Act - Transferir 20,000 de cuenta 1 a cuenta 2
        final transaction = await accountingService.recordTransfer(
          fromAccountId: testAccountId,
          toAccountId: secondAccountId,
          amount: 20000,
          description: 'Transferencia test',
          date: DateTime.now(),
        );

        // Assert - Transacción creada
        expect(transaction.type, equals('transfer'));
        expect(transaction.amount, equals(20000));
        expect(transaction.fromAccountId, equals(testAccountId));
        expect(transaction.toAccountId, equals(secondAccountId));

        // Assert - Balances actualizados
        final account1 = await accountsDao.getAccountById(testAccountId);
        final account2 = await accountsDao.getAccountById(secondAccountId);

        expect(account1!.balance, equals(80000)); // 100,000 - 20,000
        expect(account2!.balance, equals(70000)); // 50,000 + 20,000
      });

      test('crea asientos de partida doble', () async {
        final transaction = await accountingService.recordTransfer(
          fromAccountId: testAccountId,
          toAccountId: secondAccountId,
          amount: 15000,
          description: 'Transfer test',
          date: DateTime.now(),
        );

        final entries = await journalEntriesDao.getEntriesByTransaction(transaction.id);
        expect(entries.length, equals(2));

        // Débito en cuenta destino, crédito en cuenta origen
        final debitEntry = entries.firstWhere((e) => e.entryType == 'debit');
        final creditEntry = entries.firstWhere((e) => e.entryType == 'credit');

        expect(debitEntry.accountId, equals(secondAccountId));
        expect(creditEntry.accountId, equals(testAccountId));
      });
    });

    group('getAccountBalance', () {
      test('retorna balance correcto después de múltiples operaciones', () async {
        // Balance inicial: 100,000

        // Gasto: -25,000 = 75,000
        await accountingService.recordExpense(
          categoryId: testExpenseCategoryId,
          paymentAccountId: testAccountId,
          amount: 25000,
          description: 'Gasto 1',
          date: DateTime.now(),
        );

        // Ingreso: +50,000 = 125,000
        await accountingService.recordIncome(
          categoryId: testIncomeCategoryId,
          destinationAccountId: testAccountId,
          amount: 50000,
          description: 'Ingreso 1',
          date: DateTime.now(),
        );

        // Gasto: -10,000 = 115,000
        await accountingService.recordExpense(
          categoryId: testExpenseCategoryId,
          paymentAccountId: testAccountId,
          amount: 10000,
          description: 'Gasto 2',
          date: DateTime.now(),
        );

        // Assert
        final balance = await accountingService.getAccountBalance(testAccountId);
        expect(balance, equals(115000));
      });
    });

    group('Integridad de Partida Doble', () {
      test('débitos igualan créditos en todas las transacciones', () async {
        // Crear varias transacciones
        await accountingService.recordExpense(
          categoryId: testExpenseCategoryId,
          paymentAccountId: testAccountId,
          amount: 10000,
          description: 'Test 1',
          date: DateTime.now(),
        );

        await accountingService.recordIncome(
          categoryId: testIncomeCategoryId,
          destinationAccountId: testAccountId,
          amount: 50000,
          description: 'Test 2',
          date: DateTime.now(),
        );

        // Obtener todos los asientos
        final allEntries = await db.select(db.journalEntries).get();

        double totalDebits = 0;
        double totalCredits = 0;

        for (final entry in allEntries) {
          if (entry.entryType == 'debit') {
            totalDebits += entry.amount;
          } else {
            totalCredits += entry.amount;
          }
        }

        // La regla de oro: Débitos = Créditos
        expect(totalDebits, equals(totalCredits));
      });
    });
  });
}
