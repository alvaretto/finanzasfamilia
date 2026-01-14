import 'package:flutter_test/flutter_test.dart';
import 'package:finanzas_familiares/domain/exceptions/accounting_exceptions.dart';
import 'package:finanzas_familiares/domain/repositories/repositories.dart';
import 'package:finanzas_familiares/domain/services/accounting_service.dart';

/// Mock implementations for testing
class MockAccountRepository implements AccountRepository {
  final Map<String, AccountData> _accounts = {};
  final Map<String, String> _accountCategories = {};

  void addAccount(String id, String name, double balance, String categoryType) {
    _accounts[id] = AccountData(
      id: id,
      name: name,
      categoryId: 'cat-$id',
      balance: balance,
      isActive: true,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );
    _accountCategories[id] = categoryType;
  }

  @override
  Future<AccountData?> getAccountById(String id) async => _accounts[id];

  @override
  Future<AccountWithCategoryData?> getAccountWithCategoryById(String id) async {
    final account = _accounts[id];
    if (account == null) return null;
    return AccountWithCategoryData(
      account: account,
      categoryType: _accountCategories[id] ?? 'asset',
      categoryName: 'Test Category',
    );
  }

  @override
  Future<List<AccountData>> getActiveAccounts() async => _accounts.values.toList();

  @override
  Future<void> updateBalance(String accountId, double newBalance) async {
    final existing = _accounts[accountId];
    if (existing != null) {
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
  }

  @override
  Future<bool> accountExists(String accountId) async =>
      _accounts.containsKey(accountId);
}

class MockTransactionRepository implements TransactionRepository {
  final Map<String, TransactionData> _transactions = {};

  @override
  Future<void> insertTransaction(TransactionData transaction) async {
    _transactions[transaction.id] = transaction;
  }

  @override
  Future<TransactionData?> getTransactionById(String id) async =>
      _transactions[id];

  @override
  Future<void> deleteTransaction(String id) async {
    _transactions.remove(id);
  }

  @override
  Future<List<TransactionData>> getTransactionsInPeriod(
      DateTime start, DateTime end) async {
    return _transactions.values
        .where((t) =>
            t.transactionDate.isAfter(start) &&
            t.transactionDate.isBefore(end))
        .toList();
  }
}

class MockJournalEntryRepository implements JournalEntryRepository {
  int _nextNumber = 1;

  @override
  Future<int> getNextEntryNumber() async => _nextNumber++;

  @override
  Future<void> insertEntries(List<JournalEntryData> entries) async {}

  @override
  Future<void> deleteEntriesByTransaction(String transactionId) async {}

  @override
  Future<List<JournalEntryData>> getEntriesByTransaction(
      String transactionId) async {
    return [];
  }
}

class MockCategoryRepository implements CategoryRepository {
  final Map<String, CategoryData> _categories = {};

  void addCategory(String id, String name, String type) {
    _categories[id] = CategoryData(
      id: id,
      name: name,
      type: type,
      level: 0,
      isSystem: false,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );
  }

  @override
  Future<CategoryData?> getCategoryById(String id) async => _categories[id];

  @override
  Future<List<CategoryData>> getAllCategories() async =>
      _categories.values.toList();

  @override
  Future<List<CategoryData>> getChildCategories(String parentId) async =>
      _categories.values.where((c) => c.parentId == parentId).toList();

  @override
  Future<int> countChildren(String categoryId) async =>
      _categories.values.where((c) => c.parentId == categoryId).length;

  @override
  Future<void> insertCategory(CategoryData category) async {
    _categories[category.id] = category;
  }

  @override
  Future<void> deleteCategory(String categoryId) async {
    _categories.remove(categoryId);
  }
}

class MockTransactionExecutor implements TransactionExecutor {
  @override
  Future<T> execute<T>(Future<T> Function() action) => action();
}

void main() {
  group('AccountingService - Validación de saldo negativo', () {
    late AccountingService service;
    late MockAccountRepository accountRepo;
    late MockTransactionRepository transactionRepo;
    late MockJournalEntryRepository journalRepo;
    late MockCategoryRepository categoryRepo;

    setUp(() {
      accountRepo = MockAccountRepository();
      transactionRepo = MockTransactionRepository();
      journalRepo = MockJournalEntryRepository();
      categoryRepo = MockCategoryRepository();

      service = AccountingService(
        accountRepository: accountRepo,
        transactionRepository: transactionRepo,
        journalEntryRepository: journalRepo,
        categoryRepository: categoryRepo,
        transactionExecutor: MockTransactionExecutor(),
      );

      // Agregar categoría de gasto
      categoryRepo.addCategory('expense-cat', 'Gastos', 'expense');
    });

    test('permite gasto cuando hay saldo suficiente', () async {
      accountRepo.addAccount('nequi', 'Nequi', 100000, 'asset');

      final result = await service.recordExpense(
        categoryId: 'expense-cat',
        paymentAccountId: 'nequi',
        amount: 50000,
        description: 'Mercado',
        date: DateTime.now(),
      );

      expect(result.amount, 50000);
    });

    test('rechaza gasto cuando NO hay saldo suficiente en activo líquido',
        () async {
      accountRepo.addAccount('nequi', 'Nequi', 30000, 'asset');

      expect(
        () => service.recordExpense(
          categoryId: 'expense-cat',
          paymentAccountId: 'nequi',
          amount: 50000,
          description: 'Mercado',
          date: DateTime.now(),
        ),
        throwsA(isA<InsufficientFundsException>()
            .having((e) => e.available, 'available', 30000)
            .having((e) => e.required, 'required', 50000)
            .having((e) => e.accountName, 'accountName', 'Nequi')),
      );
    });

    test('permite usar tarjeta de crédito (pasivo) sin límite', () async {
      // Las tarjetas de crédito son pasivos, pueden "gastar" sin límite
      accountRepo.addAccount('visa', 'Visa', 0, 'liability');

      final result = await service.recordExpense(
        categoryId: 'expense-cat',
        paymentAccountId: 'visa',
        amount: 500000,
        description: 'Compra grande',
        date: DateTime.now(),
      );

      expect(result.amount, 500000);
    });

    test('rechaza transferencia cuando cuenta origen no tiene saldo', () async {
      accountRepo.addAccount('origen', 'Cuenta Origen', 10000, 'asset');
      accountRepo.addAccount('destino', 'Cuenta Destino', 0, 'asset');

      expect(
        () => service.recordTransfer(
          fromAccountId: 'origen',
          toAccountId: 'destino',
          amount: 50000,
          description: 'Transferencia',
          date: DateTime.now(),
        ),
        throwsA(isA<InsufficientFundsException>()),
      );
    });

    test('rechaza pago de pasivo cuando cuenta de pago no tiene saldo',
        () async {
      accountRepo.addAccount('ahorro', 'Cuenta Ahorro', 20000, 'asset');
      accountRepo.addAccount('visa', 'Visa', -100000, 'liability');

      expect(
        () => service.recordLiabilityPayment(
          liabilityAccountId: 'visa',
          paymentAccountId: 'ahorro',
          amount: 50000,
          description: 'Pago tarjeta',
          date: DateTime.now(),
        ),
        throwsA(isA<InsufficientFundsException>()),
      );
    });
  });

  group('InsufficientFundsException', () {
    test('toString formatea correctamente el mensaje', () {
      const exception = InsufficientFundsException(
        available: 30000,
        required: 50000,
        accountName: 'Nequi',
      );

      expect(exception.toString(),
          contains('Fondos insuficientes en Nequi'));
      expect(exception.toString(), contains('30000'));
      expect(exception.toString(), contains('50000'));
      expect(exception.shortfall, 20000);
    });
  });
}
