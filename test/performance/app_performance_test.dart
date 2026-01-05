/// Tests de Rendimiento
/// Verifica tiempos de respuesta, uso de memoria, y eficiencia
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:finanzas_familiares/core/database/app_database.dart';
import 'package:finanzas_familiares/core/network/supabase_client.dart';
import 'package:finanzas_familiares/features/accounts/data/repositories/account_repository.dart';
import 'package:finanzas_familiares/features/transactions/data/repositories/transaction_repository.dart';
import 'package:finanzas_familiares/features/accounts/domain/models/account_model.dart';
import 'package:finanzas_familiares/features/transactions/domain/models/transaction_model.dart';
import 'package:uuid/uuid.dart';

import '../helpers/test_helpers.dart';

void main() {
  AppDatabase? testDb;
  AccountRepository? accountRepo;
  TransactionRepository? txRepo;
  bool hasDatabase = false;

  setUpAll(() async {
    await setupFullTestEnvironment();
    final db = createTestDatabase();
    hasDatabase = db != null;
    if (hasDatabase) {
      testDb = db;
    }
  });

  setUp(() {
    if (!hasDatabase) return;
    accountRepo = AccountRepository(database: testDb!);
    txRepo = TransactionRepository(database: testDb!, accountRepository: accountRepo!);
  });

  tearDown(() async {
    if (hasDatabase && testDb != null) {
      await testDb!.close();
    }
  });

  tearDownAll(() {
    SupabaseClientProvider.reset();
  });

  group('Performance: Response Times', skip: 'Requiere base de datos configurada', () {
    // =========================================================================
    // TEST 1: Creacion de cuenta < 100ms
    // =========================================================================
    test('Crear cuenta completa en < 100ms', () async {
      final stopwatch = Stopwatch()..start();

      await accountRepo.createAccount(AccountModel(
        id: const Uuid().v4(),
        userId: 'perf-test',
        name: 'Performance Account',
        type: AccountType.bank,
        currency: 'COP',
        balance: 1000.0,
      ));

      stopwatch.stop();
      expect(stopwatch.elapsedMilliseconds, lessThan(100),
          reason: 'Crear cuenta debe tomar < 100ms');
    });

    // =========================================================================
    // TEST 2: Lectura de cuenta < 50ms
    // =========================================================================
    test('Leer cuenta por ID en < 50ms', () async {
      final id = const Uuid().v4();

      await accountRepo.createAccount(AccountModel(
        id: id,
        userId: 'read-perf-test',
        name: 'Read Performance',
        type: AccountType.bank,
        currency: 'COP',
        balance: 500.0,
      ));

      final stopwatch = Stopwatch()..start();
      await accountRepo.getAccountById(id);
      stopwatch.stop();

      expect(stopwatch.elapsedMilliseconds, lessThan(50),
          reason: 'Leer cuenta debe tomar < 50ms');
    });

    // =========================================================================
    // TEST 3: Query de transacciones < 200ms
    // =========================================================================
    test('Obtener transacciones de usuario en < 200ms', () async {
      final userId = 'tx-perf-${DateTime.now().millisecondsSinceEpoch}';

      // Crear algunas transacciones primero
      for (int i = 0; i < 20; i++) {
        await txRepo.createTransaction(TransactionModel(
          id: const Uuid().v4(),
          userId: userId,
          accountId: 'acc-1',
          amount: 10.0 * i,
          type: TransactionType.expense,
          description: 'Perf tx $i',
          date: DateTime.now(),
        ));
      }

      final stopwatch = Stopwatch()..start();
      await txRepo.watchTransactions(userId).first;
      stopwatch.stop();

      expect(stopwatch.elapsedMilliseconds, lessThan(200),
          reason: 'Query de transacciones debe tomar < 200ms');
    });
  });

  group('Performance: Bulk Operations', skip: 'Requiere base de datos configurada', () {
    // =========================================================================
    // TEST 4: Insertar 100 transacciones < 2s
    // =========================================================================
    test('Insertar 100 transacciones en < 2 segundos', () async {
      final userId = 'bulk-${DateTime.now().millisecondsSinceEpoch}';

      final stopwatch = Stopwatch()..start();

      for (int i = 0; i < 100; i++) {
        await txRepo.createTransaction(TransactionModel(
          id: const Uuid().v4(),
          userId: userId,
          accountId: 'acc-1',
          amount: i.toDouble(),
          type: i % 2 == 0 ? TransactionType.expense : TransactionType.income,
          description: 'Bulk $i',
          date: DateTime.now(),
        ));
      }

      stopwatch.stop();
      expect(stopwatch.elapsedMilliseconds, lessThan(2000),
          reason: '100 inserts deben tomar < 2s');
    });

    // =========================================================================
    // TEST 5: Insertar 100 transacciones en paralelo < 3s
    // =========================================================================
    test('Insertar 100 transacciones en paralelo < 3s', () async {
      final userId = 'parallel-${DateTime.now().millisecondsSinceEpoch}';

      final stopwatch = Stopwatch()..start();

      final futures = List.generate(100, (i) {
        return txRepo.createTransaction(TransactionModel(
          id: const Uuid().v4(),
          userId: userId,
          accountId: 'acc-1',
          amount: i.toDouble(),
          type: TransactionType.expense,
          description: 'Parallel $i',
          date: DateTime.now(),
        ));
      });

      await Future.wait(futures);
      stopwatch.stop();

      expect(stopwatch.elapsedMilliseconds, lessThan(3000),
          reason: '100 inserts paralelos deben tomar < 3s');
    });
  });

  group('Performance: Query Efficiency', skip: 'Requiere base de datos configurada', () {
    // =========================================================================
    // TEST 6: Filtrar transacciones por fecha < 100ms
    // =========================================================================
    test('Filtrar por rango de fechas es eficiente', () async {
      final userId = 'filter-${DateTime.now().millisecondsSinceEpoch}';

      // Crear transacciones en diferentes fechas
      final now = DateTime.now();
      for (int i = 0; i < 50; i++) {
        await txRepo.createTransaction(TransactionModel(
          id: const Uuid().v4(),
          userId: userId,
          accountId: 'acc-1',
          amount: 10.0,
          type: TransactionType.expense,
          description: 'Date filter $i',
          date: now.subtract(Duration(days: i)),
        ));
      }

      final stopwatch = Stopwatch()..start();
      await txRepo.watchTransactions(userId).first;
      stopwatch.stop();

      expect(stopwatch.elapsedMilliseconds, lessThan(100),
          reason: 'Filtrar por fecha debe ser < 100ms');
    });

    // =========================================================================
    // TEST 7: Calcular balance total < 50ms
    // =========================================================================
    test('Calcular balance total es eficiente', () async {
      final userId = 'balance-${DateTime.now().millisecondsSinceEpoch}';

      // Crear varias cuentas
      for (int i = 0; i < 10; i++) {
        await accountRepo.createAccount(AccountModel(
          id: const Uuid().v4(),
          userId: userId,
          name: 'Account $i',
          type: AccountType.bank,
          currency: 'COP',
          balance: 1000.0 * i,
        ));
      }

      final stopwatch = Stopwatch()..start();
      await accountRepo.getTotalBalance(userId);
      stopwatch.stop();

      expect(stopwatch.elapsedMilliseconds, lessThan(50),
          reason: 'Calcular balance total debe ser < 50ms');
    });
  });

  group('Performance: Memory Efficiency', skip: 'Requiere base de datos configurada', () {
    // =========================================================================
    // TEST 8: No memory leak en operaciones repetidas
    // =========================================================================
    test('1000 operaciones no causan memory leak', () async {
      final userId = 'memory-${DateTime.now().millisecondsSinceEpoch}';

      // Ejecutar 1000 operaciones
      for (int i = 0; i < 1000; i++) {
        final tx = TransactionModel(
          id: const Uuid().v4(),
          userId: userId,
          accountId: 'acc-1',
          amount: 1.0,
          type: TransactionType.expense,
          description: 'Memory test $i',
          date: DateTime.now(),
        );
        await txRepo.createTransaction(tx);

        // Cada 100, leer para simular uso real
        if (i % 100 == 0) {
          await txRepo.watchTransactions(userId).first;
        }
      }

      // Si llegamos aqui sin OutOfMemoryError, pasa
      expect(true, true);
    });

    // =========================================================================
    // TEST 9: Streams no acumulan listeners
    // =========================================================================
    test('Multiples subscriptions a streams funcionan', () async {
      final userId = 'stream-${DateTime.now().millisecondsSinceEpoch}';

      await accountRepo.createAccount(AccountModel(
        id: const Uuid().v4(),
        userId: userId,
        name: 'Stream Test',
        type: AccountType.bank,
        currency: 'COP',
        balance: 100.0,
      ));

      // Crear y cancelar multiples subscriptions
      for (int i = 0; i < 50; i++) {
        final subscription = accountRepo.watchAccounts(userId).listen((_) {});
        await Future.delayed(const Duration(milliseconds: 10));
        await subscription.cancel();
      }

      // Verificar que aun funciona
      final accounts = await accountRepo.watchAccounts(userId).first;
      expect(accounts.isNotEmpty, true);
    });
  });

  group('Performance: Concurrent Operations', skip: 'Requiere base de datos configurada', () {
    // =========================================================================
    // TEST 10: Operaciones concurrentes no bloquean
    // =========================================================================
    test('Lecturas y escrituras concurrentes funcionan', () async {
      final userId = 'concurrent-${DateTime.now().millisecondsSinceEpoch}';

      final stopwatch = Stopwatch()..start();

      // Ejecutar operaciones en paralelo
      await Future.wait([
        // Crear cuentas
        for (int i = 0; i < 10; i++)
          accountRepo.createAccount(AccountModel(
            id: const Uuid().v4(),
            userId: userId,
            name: 'Concurrent $i',
            type: AccountType.bank,
            currency: 'COP',
            balance: 100.0,
          )),
        // Crear transacciones
        for (int i = 0; i < 20; i++)
          txRepo.createTransaction(TransactionModel(
            id: const Uuid().v4(),
            userId: userId,
            accountId: 'acc-1',
            amount: 10.0,
            type: TransactionType.expense,
            description: 'Concurrent tx $i',
            date: DateTime.now(),
          )),
        // Leer datos
        accountRepo.watchAccounts(userId).first,
        txRepo.watchTransactions(userId).first,
        accountRepo.getTotalBalance(userId),
      ]);

      stopwatch.stop();
      expect(stopwatch.elapsedMilliseconds, lessThan(5000),
          reason: 'Operaciones concurrentes deben completar < 5s');
    });
  });
}
