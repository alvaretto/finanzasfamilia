import 'package:drift/drift.dart' hide isNotNull;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:finanzas_familiares/data/local/database.dart';
import 'package:finanzas_familiares/data/local/daos/daos.dart';
import 'package:finanzas_familiares/data/repositories/repositories.dart';
import 'package:finanzas_familiares/domain/services/accounting_service.dart';

/// Tests para el AccountingService - Motor de Partida Doble
/// El usuario ve un formulario simple, pero el sistema escribe
/// registros de Contabilidad de Partida Doble automáticamente.
void main() {
  late AppDatabase database;
  late AccountingService accountingService;
  late JournalEntriesDao journalEntriesDao;

  setUp(() async {
    database = AppDatabase.forTesting(NativeDatabase.memory());
    journalEntriesDao = JournalEntriesDao(database);

    // Crear repositorios
    final accountRepository = DriftAccountRepository(database);
    final transactionRepository = DriftTransactionRepository(database);
    final journalEntryRepository = DriftJournalEntryRepository(database);
    final categoryRepository = DriftCategoryRepository(database);
    final transactionExecutor = DriftTransactionExecutor(database);

    accountingService = AccountingService(
      accountRepository: accountRepository,
      transactionRepository: transactionRepository,
      journalEntryRepository: journalEntryRepository,
      categoryRepository: categoryRepository,
      transactionExecutor: transactionExecutor,
    );

    // Sembrar categorías de prueba
    await _seedTestCategories(database);
    // Sembrar cuentas de prueba
    await _seedTestAccounts(database);
  });

  tearDown(() async {
    await database.close();
  });

  group('AccountingService - Registro de Gastos', () {
    test('registra gasto con partida doble: Débito en Gasto, Crédito en Activo',
        () async {
      // Arrange
      const expenseCategoryId = 'cat-mercado';
      const paymentAccountId = 'acc-nequi';
      const amount = 150000.0;
      const description = 'Compra en D1';

      // Act
      final transaction = await accountingService.recordExpense(
        categoryId: expenseCategoryId,
        paymentAccountId: paymentAccountId,
        amount: amount,
        description: description,
        date: DateTime.now(),
      );

      // Assert - Transacción creada
      expect(transaction, isNotNull);
      expect(transaction.amount, equals(amount));
      expect(transaction.type, equals('expense'));

      // Assert - Asientos contables creados (Partida Doble)
      final entries =
          await journalEntriesDao.getEntriesByTransaction(transaction.id);
      expect(entries.length, equals(2));

      // Debe haber un débito en la categoría de gasto
      final debitEntry = entries.firstWhere((e) => e.entryType == 'debit');
      expect(debitEntry.amount, equals(amount));

      // Debe haber un crédito en la cuenta de pago (activo)
      final creditEntry = entries.firstWhere((e) => e.entryType == 'credit');
      expect(creditEntry.amount, equals(amount));
      expect(creditEntry.accountId, equals(paymentAccountId));
    });

    test('la partida doble está balanceada (débitos = créditos)', () async {
      // Arrange & Act
      final transaction = await accountingService.recordExpense(
        categoryId: 'cat-mercado',
        paymentAccountId: 'acc-nequi',
        amount: 250000.0,
        description: 'Compra semanal',
        date: DateTime.now(),
      );

      // Assert
      final isBalanced =
          await journalEntriesDao.isTransactionBalanced(transaction.id);
      expect(isBalanced, isTrue);
    });

    test('actualiza el saldo de la cuenta de pago después del gasto', () async {
      // Arrange
      const initialBalance = 1000000.0;
      const expenseAmount = 150000.0;

      // Act
      await accountingService.recordExpense(
        categoryId: 'cat-mercado',
        paymentAccountId: 'acc-nequi',
        amount: expenseAmount,
        description: 'Compra',
        date: DateTime.now(),
      );

      // Assert - El saldo debe disminuir
      final account =
          await (database.select(database.accounts)
                ..where((a) => a.id.equals('acc-nequi')))
              .getSingle();
      expect(account.balance, equals(initialBalance - expenseAmount));
    });
  });

  group('AccountingService - Registro de Ingresos', () {
    test(
        'registra ingreso con partida doble: Débito en Activo, Crédito en Ingreso',
        () async {
      // Arrange
      const incomeCategoryId = 'cat-salario';
      const destinationAccountId = 'acc-bancolombia';
      const amount = 5000000.0;

      // Act
      final transaction = await accountingService.recordIncome(
        categoryId: incomeCategoryId,
        destinationAccountId: destinationAccountId,
        amount: amount,
        description: 'Salario Enero',
        date: DateTime.now(),
      );

      // Assert
      expect(transaction.type, equals('income'));

      final entries =
          await journalEntriesDao.getEntriesByTransaction(transaction.id);
      expect(entries.length, equals(2));

      // Débito en el activo (aumenta)
      final debitEntry = entries.firstWhere((e) => e.entryType == 'debit');
      expect(debitEntry.accountId, equals(destinationAccountId));

      // Crédito en el ingreso
      final creditEntry = entries.firstWhere((e) => e.entryType == 'credit');
      expect(creditEntry.amount, equals(amount));
    });

    test('actualiza el saldo de la cuenta destino después del ingreso',
        () async {
      // Arrange
      const initialBalance = 2000000.0;
      const incomeAmount = 5000000.0;

      // Act
      await accountingService.recordIncome(
        categoryId: 'cat-salario',
        destinationAccountId: 'acc-bancolombia',
        amount: incomeAmount,
        description: 'Salario',
        date: DateTime.now(),
      );

      // Assert
      final account =
          await (database.select(database.accounts)
                ..where((a) => a.id.equals('acc-bancolombia')))
              .getSingle();
      expect(account.balance, equals(initialBalance + incomeAmount));
    });
  });

  group('AccountingService - Transferencias', () {
    test(
        'registra transferencia: Débito en cuenta destino, Crédito en cuenta origen',
        () async {
      // Arrange
      const fromAccountId = 'acc-bancolombia';
      const toAccountId = 'acc-nequi';
      const amount = 500000.0;

      // Act
      final transaction = await accountingService.recordTransfer(
        fromAccountId: fromAccountId,
        toAccountId: toAccountId,
        amount: amount,
        description: 'Transferencia a Nequi',
        date: DateTime.now(),
      );

      // Assert
      expect(transaction.type, equals('transfer'));

      final entries =
          await journalEntriesDao.getEntriesByTransaction(transaction.id);
      expect(entries.length, equals(2));

      // Crédito en cuenta origen (disminuye)
      final creditEntry = entries.firstWhere((e) => e.entryType == 'credit');
      expect(creditEntry.accountId, equals(fromAccountId));

      // Débito en cuenta destino (aumenta)
      final debitEntry = entries.firstWhere((e) => e.entryType == 'debit');
      expect(debitEntry.accountId, equals(toAccountId));
    });

    test('actualiza ambos saldos correctamente en transferencia', () async {
      // Arrange
      const fromInitial = 2000000.0;
      const toInitial = 1000000.0;
      const transferAmount = 300000.0;

      // Act
      await accountingService.recordTransfer(
        fromAccountId: 'acc-bancolombia',
        toAccountId: 'acc-nequi',
        amount: transferAmount,
        description: 'Transferencia',
        date: DateTime.now(),
      );

      // Assert
      final fromAccount =
          await (database.select(database.accounts)
                ..where((a) => a.id.equals('acc-bancolombia')))
              .getSingle();
      final toAccount =
          await (database.select(database.accounts)
                ..where((a) => a.id.equals('acc-nequi')))
              .getSingle();

      expect(fromAccount.balance, equals(fromInitial - transferAmount));
      expect(toAccount.balance, equals(toInitial + transferAmount));
    });
  });

  group('AccountingService - Pago de Pasivos', () {
    test(
        'registra pago de tarjeta: Débito en Pasivo, Crédito en Activo',
        () async {
      // Arrange - Pagar tarjeta de crédito con cuenta de ahorros
      const liabilityAccountId = 'acc-tc-visa';
      const paymentAccountId = 'acc-bancolombia';
      const amount = 800000.0;

      // Act
      final transaction = await accountingService.recordLiabilityPayment(
        liabilityAccountId: liabilityAccountId,
        paymentAccountId: paymentAccountId,
        amount: amount,
        description: 'Pago TC Visa',
        date: DateTime.now(),
      );

      // Assert
      final entries =
          await journalEntriesDao.getEntriesByTransaction(transaction.id);
      expect(entries.length, equals(2));

      // Débito en pasivo (disminuye la deuda)
      final debitEntry = entries.firstWhere((e) => e.entryType == 'debit');
      expect(debitEntry.accountId, equals(liabilityAccountId));

      // Crédito en activo (disminuye el saldo)
      final creditEntry = entries.firstWhere((e) => e.entryType == 'credit');
      expect(creditEntry.accountId, equals(paymentAccountId));
    });

    test('reduce el saldo del pasivo después del pago', () async {
      // Arrange
      const initialDebt = 1500000.0;
      const paymentAmount = 500000.0;

      // Act
      await accountingService.recordLiabilityPayment(
        liabilityAccountId: 'acc-tc-visa',
        paymentAccountId: 'acc-bancolombia',
        amount: paymentAmount,
        description: 'Pago parcial TC',
        date: DateTime.now(),
      );

      // Assert
      final liability =
          await (database.select(database.accounts)
                ..where((a) => a.id.equals('acc-tc-visa')))
              .getSingle();
      // El pasivo se almacena como negativo, el pago lo acerca a 0
      expect(liability.balance, equals(-(initialDebt - paymentAmount)));
    });
  });

  group('AccountingService - Balance de Cuentas', () {
    test('calcula el balance correcto usando asientos contables', () async {
      // Arrange - Registrar varias transacciones
      await accountingService.recordIncome(
        categoryId: 'cat-salario',
        destinationAccountId: 'acc-nequi',
        amount: 2000000,
        description: 'Ingreso 1',
        date: DateTime.now(),
      );

      await accountingService.recordExpense(
        categoryId: 'cat-mercado',
        paymentAccountId: 'acc-nequi',
        amount: 300000,
        description: 'Gasto 1',
        date: DateTime.now(),
      );

      // Act
      final balance =
          await accountingService.getAccountBalance('acc-nequi');

      // Assert
      // Saldo inicial: 1,000,000 + 2,000,000 - 300,000 = 2,700,000
      expect(balance, equals(2700000));
    });
  });

  group('AccountingService - Validaciones', () {
    test('lanza excepción si el monto es negativo o cero', () async {
      expect(
        () => accountingService.recordExpense(
          categoryId: 'cat-mercado',
          paymentAccountId: 'acc-nequi',
          amount: -100,
          description: 'Monto negativo',
          date: DateTime.now(),
        ),
        throwsA(isA<ArgumentError>()),
      );

      expect(
        () => accountingService.recordExpense(
          categoryId: 'cat-mercado',
          paymentAccountId: 'acc-nequi',
          amount: 0,
          description: 'Monto cero',
          date: DateTime.now(),
        ),
        throwsA(isA<ArgumentError>()),
      );
    });

    test('lanza excepción si la cuenta no existe', () async {
      expect(
        () => accountingService.recordExpense(
          categoryId: 'cat-mercado',
          paymentAccountId: 'cuenta-inexistente',
          amount: 100000,
          description: 'Cuenta no existe',
          date: DateTime.now(),
        ),
        throwsA(isA<StateError>()),
      );
    });
  });
}

/// Siembra categorías de prueba
Future<void> _seedTestCategories(AppDatabase db) async {
  final now = DateTime.now();

  await db.batch((batch) {
    batch.insertAll(db.categories, [
      // Categorías de Gastos
      CategoriesCompanion.insert(
        id: 'cat-gastos',
        name: 'Gastos',
        type: 'expense',
        level: const Value(0),
        isSystem: const Value(true),
        createdAt: Value(now),
        updatedAt: Value(now),
      ),
      CategoriesCompanion.insert(
        id: 'cat-alimentacion',
        name: 'Alimentación',
        type: 'expense',
        parentId: const Value('cat-gastos'),
        level: const Value(1),
        isSystem: const Value(true),
        createdAt: Value(now),
        updatedAt: Value(now),
      ),
      CategoriesCompanion.insert(
        id: 'cat-mercado',
        name: 'Mercado',
        type: 'expense',
        parentId: const Value('cat-alimentacion'),
        level: const Value(2),
        isSystem: const Value(true),
        createdAt: Value(now),
        updatedAt: Value(now),
      ),

      // Categorías de Ingresos
      CategoriesCompanion.insert(
        id: 'cat-ingresos',
        name: 'Ingresos',
        type: 'income',
        level: const Value(0),
        isSystem: const Value(true),
        createdAt: Value(now),
        updatedAt: Value(now),
      ),
      CategoriesCompanion.insert(
        id: 'cat-salario',
        name: 'Salario',
        type: 'income',
        parentId: const Value('cat-ingresos'),
        level: const Value(1),
        isSystem: const Value(true),
        createdAt: Value(now),
        updatedAt: Value(now),
      ),

      // Categorías de Activos
      CategoriesCompanion.insert(
        id: 'cat-activos',
        name: 'Activos',
        type: 'asset',
        level: const Value(0),
        isSystem: const Value(true),
        createdAt: Value(now),
        updatedAt: Value(now),
      ),
      CategoriesCompanion.insert(
        id: 'cat-bancos',
        name: 'Bancos',
        type: 'asset',
        parentId: const Value('cat-activos'),
        level: const Value(1),
        isSystem: const Value(true),
        createdAt: Value(now),
        updatedAt: Value(now),
      ),

      // Categorías de Pasivos
      CategoriesCompanion.insert(
        id: 'cat-pasivos',
        name: 'Pasivos',
        type: 'liability',
        level: const Value(0),
        isSystem: const Value(true),
        createdAt: Value(now),
        updatedAt: Value(now),
      ),
      CategoriesCompanion.insert(
        id: 'cat-tc',
        name: 'Tarjetas de Crédito',
        type: 'liability',
        parentId: const Value('cat-pasivos'),
        level: const Value(1),
        isSystem: const Value(true),
        createdAt: Value(now),
        updatedAt: Value(now),
      ),
    ]);
  });
}

/// Siembra cuentas de prueba
Future<void> _seedTestAccounts(AppDatabase db) async {
  final now = DateTime.now();

  await db.batch((batch) {
    batch.insertAll(db.accounts, [
      // Cuentas de Activos
      AccountsCompanion.insert(
        id: 'acc-nequi',
        name: 'Nequi',
        categoryId: 'cat-bancos',
        balance: const Value(1000000.0),
        createdAt: Value(now),
        updatedAt: Value(now),
      ),
      AccountsCompanion.insert(
        id: 'acc-bancolombia',
        name: 'Bancolombia Ahorros',
        categoryId: 'cat-bancos',
        balance: const Value(2000000.0),
        createdAt: Value(now),
        updatedAt: Value(now),
      ),

      // Cuentas de Pasivos (saldo negativo representa deuda)
      AccountsCompanion.insert(
        id: 'acc-tc-visa',
        name: 'TC Visa',
        categoryId: 'cat-tc',
        balance: const Value(-1500000.0),
        createdAt: Value(now),
        updatedAt: Value(now),
      ),
    ]);
  });
}
