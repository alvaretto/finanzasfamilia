import 'package:flutter_test/flutter_test.dart';
import 'package:finanzas_familiares/domain/services/accounting_service.dart';
import 'package:finanzas_familiares/domain/repositories/repositories.dart';

/// Tests Paramétricos para AccountingService
///
/// Reemplaza Property-Based Testing (glados) con tests paramétricos explícitos.
/// Cada test verifica invariantes contables con múltiples valores de borde.
///
/// Invariantes verificados:
/// 1. Balance Equation: sum(debits) == sum(credits) SIEMPRE
/// 2. Conservación Monetaria: Transferencias no crean ni destruyen dinero
/// 3. Idempotencia: create → delete deja el sistema inalterado
/// 4. Validación de Montos: Rechaza montos <= 0
/// 5. Consistencia Journal: Cada transacción genera exactamente 2 asientos
void main() {
  late AccountingService service;
  late InMemoryAccountRepository accountRepo;
  late InMemoryTransactionRepository transactionRepo;
  late InMemoryJournalEntryRepository journalRepo;
  late InMemoryCategoryRepository categoryRepo;
  late SimpleTransactionExecutor executor;

  /// Crea fixture fresco para cada test
  void createFreshFixture({double walletBalance = 1000000.0}) {
    accountRepo = InMemoryAccountRepository();
    transactionRepo = InMemoryTransactionRepository();
    journalRepo = InMemoryJournalEntryRepository();
    categoryRepo = InMemoryCategoryRepository();
    executor = SimpleTransactionExecutor();

    service = AccountingService(
      accountRepository: accountRepo,
      transactionRepository: transactionRepo,
      journalEntryRepository: journalRepo,
      categoryRepository: categoryRepo,
      transactionExecutor: executor,
    );

    // Seed cuentas básicas
    final now = DateTime.now();
    accountRepo.seed(AccountData(
      id: 'wallet',
      name: 'Billetera',
      categoryId: 'cat-cash',
      balance: walletBalance,
      isActive: true,
      createdAt: now,
      updatedAt: now,
    ), categoryType: 'asset');

    accountRepo.seed(AccountData(
      id: 'bank',
      name: 'Banco',
      categoryId: 'cat-bank',
      balance: 5000000.0,
      isActive: true,
      createdAt: now,
      updatedAt: now,
    ), categoryType: 'asset');

    accountRepo.seed(AccountData(
      id: 'credit-card',
      name: 'Tarjeta de Crédito',
      categoryId: 'cat-credit',
      balance: -500000.0,
      isActive: true,
      createdAt: now,
      updatedAt: now,
    ), categoryType: 'liability');

    // Seed categorías
    categoryRepo.seed(CategoryData(
      id: 'cat-expense',
      name: 'Gastos',
      type: 'expense',
      level: 0,
      isSystem: false,
      createdAt: now,
      updatedAt: now,
    ));

    categoryRepo.seed(CategoryData(
      id: 'cat-income',
      name: 'Ingresos',
      type: 'income',
      level: 0,
      isSystem: false,
      createdAt: now,
      updatedAt: now,
    ));
  }

  group('Invariante 1: Balance Equation (debits == credits)', () {
    // Montos de borde para verificar la ecuación de balance
    final testAmounts = [
      0.01, // Mínimo significativo
      1.0, // Unidad
      100.0, // Pequeño
      1000.0, // Normal
      100000.0, // Grande
      999999.99, // Muy grande
    ];

    for (final amount in testAmounts) {
      test('Balance holds for expense of \$$amount', () async {
        createFreshFixture();

        await service.recordExpense(
          categoryId: 'cat-expense',
          paymentAccountId: 'wallet',
          amount: amount,
          description: 'Test expense',
          date: DateTime.now(),
        );

        final entries = journalRepo.entries;
        final totalDebits = entries
            .where((e) => e.entryType == 'debit')
            .fold<double>(0, (sum, e) => sum + e.amount);
        final totalCredits = entries
            .where((e) => e.entryType == 'credit')
            .fold<double>(0, (sum, e) => sum + e.amount);

        expect(
          totalDebits,
          equals(totalCredits),
          reason: 'Debits must equal credits for amount $amount',
        );
      });
    }

    for (final amount in testAmounts) {
      test('Balance holds for income of \$$amount', () async {
        createFreshFixture();

        await service.recordIncome(
          categoryId: 'cat-income',
          destinationAccountId: 'wallet',
          amount: amount,
          description: 'Test income',
          date: DateTime.now(),
        );

        final entries = journalRepo.entries;
        final totalDebits = entries
            .where((e) => e.entryType == 'debit')
            .fold<double>(0, (sum, e) => sum + e.amount);
        final totalCredits = entries
            .where((e) => e.entryType == 'credit')
            .fold<double>(0, (sum, e) => sum + e.amount);

        expect(totalDebits, equals(totalCredits));
      });
    }
  });

  group('Invariante 2: Conservación Monetaria (Transferencias)', () {
    final transferAmounts = [100.0, 1000.0, 500000.0];

    for (final amount in transferAmounts) {
      test('Transfer of \$$amount preserves total money', () async {
        createFreshFixture();

        final initialWallet = await service.getAccountBalance('wallet');
        final initialBank = await service.getAccountBalance('bank');
        final totalBefore = initialWallet + initialBank;

        await service.recordTransfer(
          fromAccountId: 'wallet',
          toAccountId: 'bank',
          amount: amount,
          description: 'Test transfer',
          date: DateTime.now(),
        );

        final finalWallet = await service.getAccountBalance('wallet');
        final finalBank = await service.getAccountBalance('bank');
        final totalAfter = finalWallet + finalBank;

        expect(
          totalAfter,
          equals(totalBefore),
          reason: 'Total money must be conserved in transfer',
        );
        expect(
          finalWallet,
          equals(initialWallet - amount),
          reason: 'Source account decreases by transfer amount',
        );
        expect(
          finalBank,
          equals(initialBank + amount),
          reason: 'Destination account increases by transfer amount',
        );
      });
    }
  });

  group('Invariante 3: Idempotencia (create → delete = unchanged)', () {
    test('expense create-delete leaves wallet unchanged', () async {
      createFreshFixture();

      final initialBalance = await service.getAccountBalance('wallet');

      final tx = await service.recordExpense(
        categoryId: 'cat-expense',
        paymentAccountId: 'wallet',
        amount: 50000.0,
        description: 'Test expense',
        date: DateTime.now(),
      );

      await service.deleteTransaction(tx.id);

      final finalBalance = await service.getAccountBalance('wallet');
      expect(finalBalance, equals(initialBalance));
      expect(transactionRepo.transactions, isEmpty);
      expect(journalRepo.entries, isEmpty);
    });

    test('income create-delete leaves bank unchanged', () async {
      createFreshFixture();

      final initialBalance = await service.getAccountBalance('bank');

      final tx = await service.recordIncome(
        categoryId: 'cat-income',
        destinationAccountId: 'bank',
        amount: 100000.0,
        description: 'Test income',
        date: DateTime.now(),
      );

      await service.deleteTransaction(tx.id);

      final finalBalance = await service.getAccountBalance('bank');
      expect(finalBalance, equals(initialBalance));
    });

    test('transfer create-delete leaves both accounts unchanged', () async {
      createFreshFixture();

      final initialWallet = await service.getAccountBalance('wallet');
      final initialBank = await service.getAccountBalance('bank');

      final tx = await service.recordTransfer(
        fromAccountId: 'wallet',
        toAccountId: 'bank',
        amount: 200000.0,
        description: 'Test transfer',
        date: DateTime.now(),
      );

      await service.deleteTransaction(tx.id);

      final finalWallet = await service.getAccountBalance('wallet');
      final finalBank = await service.getAccountBalance('bank');

      expect(finalWallet, equals(initialWallet));
      expect(finalBank, equals(initialBank));
    });
  });

  group('Invariante 4: Validación de Montos', () {
    final invalidAmounts = [0.0, -1.0, -100.0, -0.01];

    for (final amount in invalidAmounts) {
      test('rejects expense with amount $amount', () async {
        createFreshFixture();

        expect(
          () => service.recordExpense(
            categoryId: 'cat-expense',
            paymentAccountId: 'wallet',
            amount: amount,
            description: 'Invalid',
            date: DateTime.now(),
          ),
          throwsA(isA<ArgumentError>()),
        );
      });

      test('rejects income with amount $amount', () async {
        createFreshFixture();

        expect(
          () => service.recordIncome(
            categoryId: 'cat-income',
            destinationAccountId: 'wallet',
            amount: amount,
            description: 'Invalid',
            date: DateTime.now(),
          ),
          throwsA(isA<ArgumentError>()),
        );
      });

      test('rejects transfer with amount $amount', () async {
        createFreshFixture();

        expect(
          () => service.recordTransfer(
            fromAccountId: 'wallet',
            toAccountId: 'bank',
            amount: amount,
            description: 'Invalid',
            date: DateTime.now(),
          ),
          throwsA(isA<ArgumentError>()),
        );
      });
    }
  });

  group('Invariante 5: Consistencia de Journal Entries', () {
    test('expense creates exactly 2 journal entries', () async {
      createFreshFixture();

      await service.recordExpense(
        categoryId: 'cat-expense',
        paymentAccountId: 'wallet',
        amount: 50000.0,
        description: 'Test',
        date: DateTime.now(),
      );

      expect(journalRepo.entries.length, equals(2));
      expect(
        journalRepo.entries.where((e) => e.entryType == 'debit').length,
        equals(1),
      );
      expect(
        journalRepo.entries.where((e) => e.entryType == 'credit').length,
        equals(1),
      );
    });

    test('income creates exactly 2 journal entries', () async {
      createFreshFixture();

      await service.recordIncome(
        categoryId: 'cat-income',
        destinationAccountId: 'bank',
        amount: 100000.0,
        description: 'Test',
        date: DateTime.now(),
      );

      expect(journalRepo.entries.length, equals(2));
    });

    test('transfer creates exactly 2 journal entries', () async {
      createFreshFixture();

      await service.recordTransfer(
        fromAccountId: 'wallet',
        toAccountId: 'bank',
        amount: 50000.0,
        description: 'Test',
        date: DateTime.now(),
      );

      expect(journalRepo.entries.length, equals(2));
    });

    test('journal entry amounts match transaction amount', () async {
      createFreshFixture();

      const amount = 75000.0;
      await service.recordExpense(
        categoryId: 'cat-expense',
        paymentAccountId: 'wallet',
        amount: amount,
        description: 'Test',
        date: DateTime.now(),
      );

      for (final entry in journalRepo.entries) {
        expect(
          entry.amount,
          equals(amount),
          reason: 'Journal entry amount must match transaction amount',
        );
      }
    });
  });

  group('Casos de borde adicionales', () {
    test('multiple sequential transactions maintain balance equation', () async {
      createFreshFixture(walletBalance: 10000000.0);

      // Ejecutar múltiples transacciones
      await service.recordExpense(
        categoryId: 'cat-expense',
        paymentAccountId: 'wallet',
        amount: 100000.0,
        description: 'Expense 1',
        date: DateTime.now(),
      );

      await service.recordIncome(
        categoryId: 'cat-income',
        destinationAccountId: 'wallet',
        amount: 200000.0,
        description: 'Income 1',
        date: DateTime.now(),
      );

      await service.recordTransfer(
        fromAccountId: 'wallet',
        toAccountId: 'bank',
        amount: 50000.0,
        description: 'Transfer 1',
        date: DateTime.now(),
      );

      await service.recordExpense(
        categoryId: 'cat-expense',
        paymentAccountId: 'bank',
        amount: 30000.0,
        description: 'Expense 2',
        date: DateTime.now(),
      );

      // Verificar balance equation después de múltiples transacciones
      final entries = journalRepo.entries;
      final totalDebits = entries
          .where((e) => e.entryType == 'debit')
          .fold<double>(0, (sum, e) => sum + e.amount);
      final totalCredits = entries
          .where((e) => e.entryType == 'credit')
          .fold<double>(0, (sum, e) => sum + e.amount);

      expect(totalDebits, equals(totalCredits));
      expect(entries.length, equals(8)); // 4 transactions × 2 entries
    });

    test('liability payment does not require asset balance validation', () async {
      createFreshFixture();

      // Pagar más de lo que hay en billetera (desde tarjeta de crédito como cuenta origen)
      // Esto debería funcionar porque la tarjeta es un pasivo
      await service.recordLiabilityPayment(
        liabilityAccountId: 'credit-card',
        paymentAccountId: 'wallet',
        amount: 100000.0,
        description: 'Pago TC',
        date: DateTime.now(),
      );

      final creditBalance = await service.getAccountBalance('credit-card');
      // -500000 + 100000 = -400000
      expect(creditBalance, equals(-400000.0));
    });
  });
}

// ============================================================
// In-Memory Repositories for Testing
// ============================================================

class InMemoryAccountRepository implements AccountRepository {
  final Map<String, AccountData> _accounts = {};
  final Map<String, String> _categoryTypes = {};

  void seed(AccountData account, {required String categoryType}) {
    _accounts[account.id] = account;
    _categoryTypes[account.id] = categoryType;
  }

  @override
  Future<AccountData?> getAccountById(String id) async => _accounts[id];

  @override
  Future<AccountWithCategoryData?> getAccountWithCategoryById(String id) async {
    final account = _accounts[id];
    if (account == null) return null;
    return AccountWithCategoryData(
      account: account,
      categoryType: _categoryTypes[id] ?? 'asset',
      categoryName: 'Test Category',
    );
  }

  @override
  Future<List<AccountData>> getActiveAccounts() async =>
      _accounts.values.where((a) => a.isActive).toList();

  @override
  Future<void> updateBalance(String accountId, double newBalance) async {
    final existing = _accounts[accountId];
    if (existing == null) throw StateError('Account not found: $accountId');
    _accounts[accountId] = AccountData(
      id: existing.id,
      name: existing.name,
      categoryId: existing.categoryId,
      balance: newBalance,
      isActive: existing.isActive,
      createdAt: existing.createdAt,
      updatedAt: DateTime.now(),
    );
  }

  @override
  Future<bool> accountExists(String accountId) async =>
      _accounts.containsKey(accountId);
}

class InMemoryTransactionRepository implements TransactionRepository {
  final List<TransactionData> transactions = [];

  @override
  Future<TransactionData?> getTransactionById(String id) async =>
      transactions.where((t) => t.id == id).firstOrNull;

  @override
  Future<void> insertTransaction(TransactionData transaction) async =>
      transactions.add(transaction);

  @override
  Future<void> deleteTransaction(String id) async =>
      transactions.removeWhere((t) => t.id == id);

  @override
  Future<List<TransactionData>> getTransactionsInPeriod(
    DateTime start,
    DateTime end,
  ) async =>
      transactions
          .where((t) =>
              t.transactionDate.isAfter(start) &&
              t.transactionDate.isBefore(end))
          .toList();
}

class InMemoryJournalEntryRepository implements JournalEntryRepository {
  final List<JournalEntryData> entries = [];
  int _nextNumber = 1;

  @override
  Future<List<JournalEntryData>> getEntriesByTransaction(
          String transactionId) async =>
      entries.where((e) => e.transactionId == transactionId).toList();

  @override
  Future<void> insertEntries(List<JournalEntryData> newEntries) async =>
      entries.addAll(newEntries);

  @override
  Future<void> deleteEntriesByTransaction(String transactionId) async =>
      entries.removeWhere((e) => e.transactionId == transactionId);

  @override
  Future<int> getNextEntryNumber() async => _nextNumber++;
}

class InMemoryCategoryRepository implements CategoryRepository {
  final Map<String, CategoryData> _categories = {};

  void seed(CategoryData category) {
    _categories[category.id] = category;
  }

  @override
  Future<CategoryData?> getCategoryById(String id) async => _categories[id];

  @override
  Future<List<CategoryData>> getAllCategories() async =>
      _categories.values.toList();

  @override
  Future<void> insertCategory(CategoryData category) async =>
      _categories[category.id] = category;

  @override
  Future<int> countChildren(String parentId) async =>
      _categories.values.where((c) => c.parentId == parentId).length;

  @override
  Future<List<CategoryData>> getChildCategories(String parentId) async =>
      _categories.values.where((c) => c.parentId == parentId).toList();

  @override
  Future<void> deleteCategory(String id) async => _categories.remove(id);
}

class SimpleTransactionExecutor implements TransactionExecutor {
  @override
  Future<T> execute<T>(Future<T> Function() action) => action();
}
