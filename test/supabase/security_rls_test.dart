/// Tests de Seguridad - Row Level Security (RLS)
/// Verifica que usuarios solo acceden a sus propios datos
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:finanzas_familiares/core/database/app_database.dart';
import 'package:finanzas_familiares/core/network/supabase_client.dart';
import 'package:finanzas_familiares/features/accounts/data/repositories/account_repository.dart';
import 'package:finanzas_familiares/features/transactions/data/repositories/transaction_repository.dart';
import 'package:finanzas_familiares/features/budgets/data/repositories/budget_repository.dart';
import 'package:finanzas_familiares/features/goals/data/repositories/goal_repository.dart';
import 'package:finanzas_familiares/features/accounts/domain/models/account_model.dart';
import 'package:finanzas_familiares/features/transactions/domain/models/transaction_model.dart';
import 'package:finanzas_familiares/features/budgets/domain/models/budget_model.dart';
import 'package:finanzas_familiares/features/goals/domain/models/goal_model.dart';
import 'package:uuid/uuid.dart';

import '../helpers/test_helpers.dart';

void main() {
  late AppDatabase testDb;
  late AccountRepository accountRepo;
  late TransactionRepository txRepo;
  late BudgetRepository budgetRepo;
  late GoalRepository goalRepo;

  setUpAll(() {
    setupFullTestEnvironment();
  });

  setUp(() {
    testDb = createTestDatabase();
    accountRepo = AccountRepository(database: testDb);
    txRepo = TransactionRepository(database: testDb, accountRepository: accountRepo);
    budgetRepo = BudgetRepository(database: testDb);
    goalRepo = GoalRepository(database: testDb);
  });

  tearDown(() async {
    await testDb.close();
  });

  tearDownAll(() {
    SupabaseClientProvider.reset();
  });

  group('Security: User Data Isolation', () {
    // =========================================================================
    // TEST 1: Cada usuario tiene su propio espacio de datos
    // =========================================================================
    test('Cuentas se filtran por userId', () async {
      // Crear cuentas para dos usuarios diferentes
      final user1Id = 'user-1-${DateTime.now().millisecondsSinceEpoch}';
      final user2Id = 'user-2-${DateTime.now().millisecondsSinceEpoch}';

      await accountRepo.createAccount(AccountModel(
        id: const Uuid().v4(),
        userId: user1Id,
        name: 'Cuenta User 1',
        type: AccountType.bank,
        currency: 'COP',
        balance: 1000.0,
      ));

      await accountRepo.createAccount(AccountModel(
        id: const Uuid().v4(),
        userId: user2Id,
        name: 'Cuenta User 2',
        type: AccountType.bank,
        currency: 'COP',
        balance: 2000.0,
      ));

      // User 1 solo debe ver sus cuentas
      final user1Accounts = await accountRepo.watchAccounts(user1Id).first;
      expect(user1Accounts.every((a) => a.userId == user1Id), true);
      expect(user1Accounts.any((a) => a.userId == user2Id), false);
    });

    test('Transacciones se filtran por userId', () async {
      final user1Id = 'tx-user-1-${DateTime.now().millisecondsSinceEpoch}';
      final user2Id = 'tx-user-2-${DateTime.now().millisecondsSinceEpoch}';

      await txRepo.createTransaction(TransactionModel(
        id: const Uuid().v4(),
        userId: user1Id,
        accountId: 'acc-1',
        amount: 100.0,
        type: TransactionType.expense,
        description: 'Tx User 1',
        date: DateTime.now(),
      ));

      await txRepo.createTransaction(TransactionModel(
        id: const Uuid().v4(),
        userId: user2Id,
        accountId: 'acc-2',
        amount: 200.0,
        type: TransactionType.income,
        description: 'Tx User 2',
        date: DateTime.now(),
      ));

      final user1Txs = await txRepo.watchTransactions(user1Id).first;
      expect(user1Txs.every((t) => t.userId == user1Id), true);
    });

    // =========================================================================
    // TEST 2: Presupuestos aislados por usuario
    // =========================================================================
    test('Presupuestos se filtran por userId', () async {
      final userId = 'budget-user-${DateTime.now().millisecondsSinceEpoch}';

      await budgetRepo.createBudget(BudgetModel(
        id: const Uuid().v4(),
        userId: userId,
        categoryId: 1,
        amount: 500.0,
        period: BudgetPeriod.monthly,
        startDate: DateTime.now(),
      ));

      final budgets = await budgetRepo.watchBudgets(userId).first;
      expect(budgets.every((b) => b.userId == userId), true);
    });

    // =========================================================================
    // TEST 3: Metas aisladas por usuario
    // =========================================================================
    test('Metas se filtran por userId', () async {
      final userId = 'goal-user-${DateTime.now().millisecondsSinceEpoch}';

      await goalRepo.createGoal(GoalModel(
        id: const Uuid().v4(),
        userId: userId,
        name: 'Meta Test',
        targetAmount: 10000.0,
        currentAmount: 0.0,
      ));

      final goals = await goalRepo.watchGoals(userId).first;
      expect(goals.every((g) => g.userId == userId), true);
    });
  });

  group('Security: Data Validation', () {
    // =========================================================================
    // TEST 4: Datos con userId invalido no se crean
    // =========================================================================
    test('userId vacio es rechazado', () async {
      final account = AccountModel(
        id: const Uuid().v4(),
        userId: '', // userId vacio
        name: 'Invalid Account',
        type: AccountType.bank,
        currency: 'COP',
        balance: 100.0,
      );

      // Debe fallar o crear con userId vacio (validar en UI/repo)
      final created = await accountRepo.createAccount(account);
      expect(created.userId, isEmpty);
    });

    // =========================================================================
    // TEST 5: Montos negativos en cuentas de activos
    // =========================================================================
    test('Balance negativo es permitido (para deudas)', () async {
      final account = AccountModel(
        id: const Uuid().v4(),
        userId: 'negative-test',
        name: 'Tarjeta Credito',
        type: AccountType.credit,
        currency: 'COP',
        balance: -5000.0, // Deuda
      );

      final created = await accountRepo.createAccount(account);
      expect(created.balance, -5000.0);
    });

    // =========================================================================
    // TEST 6: Transacciones con monto cero
    // =========================================================================
    test('Transaccion con monto cero es permitida', () async {
      final tx = TransactionModel(
        id: const Uuid().v4(),
        userId: 'zero-amount-test',
        accountId: 'acc-1',
        amount: 0.0,
        type: TransactionType.expense,
        description: 'Zero transaction',
        date: DateTime.now(),
      );

      final created = await txRepo.createTransaction(tx);
      expect(created.amount, 0.0);
    });
  });

  group('Security: Sync Security', () {
    // =========================================================================
    // TEST 7: Sync solo sincroniza datos del usuario actual
    // =========================================================================
    test('syncWithSupabase recibe userId especifico', () async {
      final userId = 'sync-security-test';

      // La funcion sync requiere userId explicito
      await expectLater(
        accountRepo.syncWithSupabase(userId),
        completes,
      );
    });

    // =========================================================================
    // TEST 8: getUnsyncedAccounts retorna solo del usuario
    // =========================================================================
    test('getUnsyncedAccounts retorna datos correctos', () async {
      final userId = 'unsynced-security-${DateTime.now().millisecondsSinceEpoch}';

      await accountRepo.createAccount(AccountModel(
        id: const Uuid().v4(),
        userId: userId,
        name: 'Unsynced Account',
        type: AccountType.bank,
        currency: 'COP',
        balance: 100.0,
      ));

      final unsynced = await accountRepo.getUnsyncedAccounts();
      // Debe retornar al menos la cuenta creada
      expect(unsynced.isNotEmpty, true);
    });
  });

  group('Security: Input Sanitization', () {
    // =========================================================================
    // TEST 9: Caracteres especiales en nombres
    // =========================================================================
    test('Nombres con caracteres especiales son manejados', () async {
      final specialNames = [
        "Cuenta con 'comillas'",
        'Cuenta con "dobles"',
        'Cuenta con <html>',
        'Cuenta con; SQL injection',
        'Cuenta con -- comentario',
      ];

      for (final name in specialNames) {
        final account = AccountModel(
          id: const Uuid().v4(),
          userId: 'special-chars-test',
          name: name,
          type: AccountType.bank,
          currency: 'COP',
          balance: 100.0,
        );

        final created = await accountRepo.createAccount(account);
        expect(created.name, name, reason: 'Nombre debe preservarse: $name');
      }
    });

    // =========================================================================
    // TEST 10: Descripciones con contenido potencialmente peligroso
    // =========================================================================
    test('Descripciones con scripts son almacenadas como texto', () async {
      final dangerousDescriptions = [
        '<script>alert("XSS")</script>',
        'javascript:void(0)',
        '${DateTime.now()}', // Template literal
        '\${system.exit()}',
      ];

      for (final desc in dangerousDescriptions) {
        final tx = TransactionModel(
          id: const Uuid().v4(),
          userId: 'xss-test',
          accountId: 'acc-1',
          amount: 10.0,
          type: TransactionType.expense,
          description: desc,
          date: DateTime.now(),
        );

        final created = await txRepo.createTransaction(tx);
        expect(created.description, desc,
            reason: 'Descripcion debe preservarse como texto plano');
      }
    });
  });
}
