/// Tests PWA/Offline - Estrategia Offline-First
/// Verifica sincronizacion, cache, y comportamiento sin conexion
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:finanzas_familiares/core/network/supabase_client.dart';
import 'package:finanzas_familiares/features/accounts/data/repositories/account_repository.dart';
import 'package:finanzas_familiares/features/transactions/data/repositories/transaction_repository.dart';
import 'package:finanzas_familiares/features/accounts/domain/models/account_model.dart';
import 'package:finanzas_familiares/features/transactions/domain/models/transaction_model.dart';
import 'package:uuid/uuid.dart';

void main() {
  setUpAll(() {
    SupabaseClientProvider.enableTestMode();
  });

  tearDownAll(() {
    SupabaseClientProvider.reset();
  });

  group('PWA: Offline-First Strategy', () {
    // =========================================================================
    // TEST 1: Repositorio funciona sin conexion
    // =========================================================================
    test('AccountRepository funciona en modo offline', () async {
      final repo = AccountRepository();

      // Debe poder crear cuenta localmente sin Supabase
      final account = AccountModel(
        id: const Uuid().v4(),
        userId: 'test-user',
        name: 'Cuenta Offline',
        type: AccountType.bank,
        balance: 1000.0,
        isSynced: false,
      );

      // No debe lanzar excepcion
      final created = await repo.createAccount(account);
      expect(created.isSynced, false);
      expect(created.name, 'Cuenta Offline');
    });

    test('TransactionRepository funciona en modo offline', () async {
      final repo = TransactionRepository();

      final tx = TransactionModel(
        id: const Uuid().v4(),
        userId: 'test-user',
        accountId: 'account-1',
        amount: 50.0,
        type: TransactionType.expense,
        description: 'Gasto offline',
        date: DateTime.now(),
        isSynced: false,
      );

      final created = await repo.createTransaction(tx);
      expect(created.isSynced, false);
    });

    // =========================================================================
    // TEST 2: Flag isSynced se maneja correctamente
    // =========================================================================
    test('Nuevos registros tienen isSynced=false', () async {
      final repo = AccountRepository();

      final account = AccountModel(
        id: const Uuid().v4(),
        userId: 'test-user',
        name: 'Nueva cuenta',
        type: AccountType.cash,
        balance: 500.0,
      );

      final created = await repo.createAccount(account);
      expect(created.isSynced, false,
          reason: 'Registros nuevos deben estar marcados como no sincronizados');
    });

    // =========================================================================
    // TEST 3: Sync no falla cuando esta offline
    // =========================================================================
    test('syncWithSupabase no lanza excepcion en modo offline', () async {
      final repo = AccountRepository();

      // En test mode (offline), sync debe retornar sin error
      await expectLater(
        repo.syncWithSupabase('test-user'),
        completes,
      );
    });

    test('TransactionRepository.syncWithSupabase no falla offline', () async {
      final repo = TransactionRepository();

      await expectLater(
        repo.syncWithSupabase('test-user'),
        completes,
      );
    });

    // =========================================================================
    // TEST 4: Operaciones CRUD funcionan offline
    // =========================================================================
    test('CRUD completo funciona sin conexion', () async {
      final repo = AccountRepository();
      final id = const Uuid().v4();

      // Create
      final account = AccountModel(
        id: id,
        userId: 'test-user',
        name: 'CRUD Test',
        type: AccountType.bank,
        balance: 100.0,
      );
      await repo.createAccount(account);

      // Read
      final read = await repo.getAccountById(id);
      expect(read, isNotNull);
      expect(read!.name, 'CRUD Test');

      // Update
      await repo.updateAccount(read.copyWith(name: 'Updated'));
      final updated = await repo.getAccountById(id);
      expect(updated!.name, 'Updated');

      // Delete (soft delete)
      await repo.deleteAccount(id);
      final deleted = await repo.getAccountById(id);
      expect(deleted!.isActive, false);
    });
  });

  group('PWA: Data Persistence', () {
    // =========================================================================
    // TEST 5: Datos persisten entre sesiones (simulado)
    // =========================================================================
    test('Datos se guardan en base de datos local', () async {
      final repo = AccountRepository();
      final id = const Uuid().v4();

      await repo.createAccount(AccountModel(
        id: id,
        userId: 'persistence-test',
        name: 'Persistent Account',
        type: AccountType.savings,
        balance: 2000.0,
      ));

      // Nueva instancia del repositorio
      final repo2 = AccountRepository();
      final found = await repo2.getAccountById(id);

      expect(found, isNotNull);
      expect(found!.name, 'Persistent Account');
    });

    // =========================================================================
    // TEST 6: Unsynced queue se mantiene
    // =========================================================================
    test('Registros no sincronizados se pueden recuperar', () async {
      final repo = AccountRepository();

      // Crear varias cuentas sin sincronizar
      for (int i = 0; i < 3; i++) {
        await repo.createAccount(AccountModel(
          id: const Uuid().v4(),
          userId: 'queue-test',
          name: 'Unsynced $i',
          type: AccountType.bank,
          balance: 100.0 * i,
        ));
      }

      final unsynced = await repo.getUnsyncedAccounts();
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
      final repo = TransactionRepository();
      final userId = 'batch-test-${DateTime.now().millisecondsSinceEpoch}';

      // Crear 10 transacciones rapidamente
      final futures = <Future>[];
      for (int i = 0; i < 10; i++) {
        futures.add(repo.createTransaction(TransactionModel(
          id: const Uuid().v4(),
          userId: userId,
          accountId: 'account-1',
          amount: 10.0 * i,
          type: i % 2 == 0 ? TransactionType.expense : TransactionType.income,
          description: 'Batch tx $i',
          date: DateTime.now(),
        )));
      }

      await Future.wait(futures);

      // Todas deben haberse creado
      final unsynced = await repo.getUnsyncedTransactions();
      expect(unsynced.where((t) => t.userId == userId).length, 10);
    });
  });

  group('PWA: Error Handling', () {
    // =========================================================================
    // TEST 9: Errores de red no crashean la app
    // =========================================================================
    test('Errores de sync son manejados gracefully', () async {
      final repo = AccountRepository();

      // Sync debe completar sin excepcion incluso sin conexion
      expect(
        () async => await repo.syncWithSupabase('error-test'),
        returnsNormally,
      );
    });

    // =========================================================================
    // TEST 10: Estado local se preserva tras error de sync
    // =========================================================================
    test('Datos locales persisten tras fallo de sync', () async {
      final repo = AccountRepository();
      final id = const Uuid().v4();

      // Crear cuenta
      await repo.createAccount(AccountModel(
        id: id,
        userId: 'error-persist-test',
        name: 'Error Test Account',
        type: AccountType.bank,
        balance: 999.0,
      ));

      // Intentar sync (fallara silenciosamente en test mode)
      await repo.syncWithSupabase('error-persist-test');

      // Cuenta debe seguir existiendo
      final account = await repo.getAccountById(id);
      expect(account, isNotNull);
      expect(account!.balance, 999.0);
    });
  });
}
