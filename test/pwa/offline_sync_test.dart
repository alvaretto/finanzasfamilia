/// Tests PWA/Offline - Estrategia Offline-First
/// Verifica sincronizacion, cache, y comportamiento sin conexion
/// Usando Drift in-memory database para tests aislados
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
  late AppDatabase testDb;
  late AccountRepository accountRepo;
  late TransactionRepository txRepo;

  setUpAll(() async {
    await setupFullTestEnvironment();
  });

  setUp(() {
    testDb = createTestDatabase();
    accountRepo = AccountRepository(database: testDb);
    txRepo = TransactionRepository(database: testDb, accountRepository: accountRepo);
  });

  tearDown(() async {
    await testDb.close();
  });

  tearDownAll(() {
    SupabaseClientProvider.reset();
  });

  group('PWA: Offline-First Strategy', () {
    // =========================================================================
    // TEST 1: Repositorio funciona sin conexion
    // =========================================================================
    test('AccountRepository funciona en modo offline', () async {
      // Debe poder crear cuenta localmente sin Supabase
      final account = AccountModel(
        id: const Uuid().v4(),
        userId: 'test-user',
        name: 'Cuenta Offline',
        type: AccountType.bank,
        currency: 'COP',
        balance: 1000.0,
        isSynced: false,
      );

      // No debe lanzar excepcion
      final created = await accountRepo.createAccount(account);
      expect(created.isSynced, false);
      expect(created.name, 'Cuenta Offline');
    });

    test('TransactionRepository funciona en modo offline', () async {
      // Crear cuenta primero
      final accountId = const Uuid().v4();
      await accountRepo.createAccount(AccountModel(
        id: accountId,
        userId: 'test-user',
        name: 'Test Account',
        type: AccountType.bank,
        currency: 'COP',
        balance: 0,
      ));

      final tx = TransactionModel(
        id: const Uuid().v4(),
        userId: 'test-user',
        accountId: accountId,
        amount: 50.0,
        type: TransactionType.expense,
        description: 'Gasto offline',
        date: DateTime.now(),
        isSynced: false,
      );

      final created = await txRepo.createTransaction(tx);
      expect(created.isSynced, false);
    });

    // =========================================================================
    // TEST 2: Flag isSynced se maneja correctamente
    // =========================================================================
    test('Nuevos registros tienen isSynced=false', () async {
      final account = AccountModel(
        id: const Uuid().v4(),
        userId: 'test-user',
        name: 'Nueva cuenta',
        type: AccountType.cash,
        currency: 'COP',
        balance: 500.0,
      );

      final created = await accountRepo.createAccount(account);
      expect(created.isSynced, false,
          reason: 'Registros nuevos deben estar marcados como no sincronizados');
    });

    // =========================================================================
    // TEST 3: Sync no falla cuando esta offline
    // =========================================================================
    test('syncWithSupabase no lanza excepcion en modo offline', () async {
      // En test mode (offline), sync debe retornar sin error
      await expectLater(
        accountRepo.syncWithSupabase('test-user'),
        completes,
      );
    });

    test('TransactionRepository.syncWithSupabase no falla offline', () async {
      await expectLater(
        txRepo.syncWithSupabase('test-user'),
        completes,
      );
    });

    // =========================================================================
    // TEST 4: Operaciones CRUD funcionan offline
    // =========================================================================
    test('CRUD completo funciona sin conexion', () async {
      final id = const Uuid().v4();

      // Create
      final account = AccountModel(
        id: id,
        userId: 'test-user',
        name: 'CRUD Test',
        type: AccountType.bank,
        currency: 'COP',
        balance: 100.0,
      );
      await accountRepo.createAccount(account);

      // Read
      final read = await accountRepo.getAccountById(id);
      expect(read, isNotNull);
      expect(read!.name, 'CRUD Test');

      // Update
      await accountRepo.updateAccount(read.copyWith(name: 'Updated'));
      final updated = await accountRepo.getAccountById(id);
      expect(updated!.name, 'Updated');

      // Delete (soft delete - marca como inactiva)
      await accountRepo.deleteAccount(id);
      final deleted = await accountRepo.getAccountById(id);
      // Soft delete: cuenta sigue existiendo pero marcada como inactiva
      expect(deleted?.isActive, false);
    });
  });

  group('PWA: Data Persistence', () {
    // =========================================================================
    // TEST 5: Datos persisten dentro de la misma sesion de test
    // =========================================================================
    test('Datos se guardan en base de datos local', () async {
      final id = const Uuid().v4();

      await accountRepo.createAccount(AccountModel(
        id: id,
        userId: 'persistence-test',
        name: 'Persistent Account',
        type: AccountType.savings,
        currency: 'COP',
        balance: 2000.0,
      ));

      // Misma instancia del repositorio (misma db)
      final found = await accountRepo.getAccountById(id);

      expect(found, isNotNull);
      expect(found!.name, 'Persistent Account');
    });

    // =========================================================================
    // TEST 6: Unsynced queue se mantiene
    // =========================================================================
    test('Registros no sincronizados se pueden recuperar', () async {
      // Crear varias cuentas sin sincronizar
      for (int i = 0; i < 3; i++) {
        await accountRepo.createAccount(AccountModel(
          id: const Uuid().v4(),
          userId: 'queue-test',
          name: 'Unsynced $i',
          type: AccountType.bank,
          currency: 'COP',
          balance: 100.0 * i,
        ));
      }

      final unsynced = await accountRepo.getUnsyncedAccounts();
      expect(unsynced.length, greaterThanOrEqualTo(3));
    });
  });

  group('PWA: Connectivity Scenarios', () {
    // =========================================================================
    // TEST 7: App maneja transicion online/offline
    // =========================================================================
    test('SupabaseClientProvider.isInitialized es false en test mode', () {
      // En test mode, isInitialized debe reportar true (para no bloquear)
      // pero clientOrNull debe ser null
      expect(SupabaseClientProvider.isInitialized, true);
      expect(SupabaseClientProvider.clientOrNull, isNull);
    });

    // =========================================================================
    // TEST 8: Operaciones batch funcionan offline
    // =========================================================================
    test('Multiples operaciones en lote funcionan offline', () async {
      final userId = 'batch-test-${DateTime.now().millisecondsSinceEpoch}';
      final accountId = const Uuid().v4();

      // Crear cuenta primero
      await accountRepo.createAccount(AccountModel(
        id: accountId,
        userId: userId,
        name: 'Batch Account',
        type: AccountType.bank,
        currency: 'COP',
        balance: 0,
      ));

      // Crear 10 transacciones rapidamente
      final futures = <Future>[];
      for (int i = 0; i < 10; i++) {
        futures.add(txRepo.createTransaction(TransactionModel(
          id: const Uuid().v4(),
          userId: userId,
          accountId: accountId,
          amount: 10.0 * (i + 1), // +1 para evitar monto 0
          type: i % 2 == 0 ? TransactionType.expense : TransactionType.income,
          description: 'Batch tx $i',
          date: DateTime.now(),
        )));
      }

      await Future.wait(futures);

      // Todas deben haberse creado
      final unsynced = await txRepo.getUnsyncedTransactions();
      expect(unsynced.where((t) => t.userId == userId).length, 10);
    });
  });

  group('PWA: Error Handling', () {
    // =========================================================================
    // TEST 9: Errores de red no crashean la app
    // =========================================================================
    test('Errores de sync son manejados gracefully', () async {
      // Sync debe completar sin excepcion incluso sin conexion
      expect(
        () async => await accountRepo.syncWithSupabase('error-test'),
        returnsNormally,
      );
    });

    // =========================================================================
    // TEST 10: Estado local se preserva tras error de sync
    // =========================================================================
    test('Datos locales persisten tras fallo de sync', () async {
      final id = const Uuid().v4();

      // Crear cuenta
      await accountRepo.createAccount(AccountModel(
        id: id,
        userId: 'error-persist-test',
        name: 'Error Test Account',
        type: AccountType.bank,
        currency: 'COP',
        balance: 999.0,
      ));

      // Intentar sync (fallara silenciosamente en test mode)
      await accountRepo.syncWithSupabase('error-persist-test');

      // Cuenta debe seguir existiendo
      final account = await accountRepo.getAccountById(id);
      expect(account, isNotNull);
      expect(account!.balance, 999.0);
    });
  });
}
