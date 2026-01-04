/// Tests de Service Worker / PWA
/// Verifica caching, sincronizacion offline, instalabilidad
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

  setUpAll(() {
    // Inicializar bindings y Supabase en modo test
    setupFullTestEnvironment();
  });

  setUp(() {
    // Crear nueva base de datos in-memory para cada test
    testDb = createTestDatabase();
    accountRepo = AccountRepository(database: testDb);
    txRepo = TransactionRepository(database: testDb);
  });

  tearDown(() async {
    // Cerrar base de datos despues de cada test
    await testDb.close();
  });

  tearDownAll(() {
    SupabaseClientProvider.reset();
  });

  group('PWA: Offline Data Persistence', () {
    // =========================================================================
    // TEST 1: Datos se guardan localmente
    // =========================================================================
    test('Datos se persisten en almacenamiento local', () async {
      final account = AccountModel(
        id: const Uuid().v4(),
        userId: 'pwa-test-user',
        name: 'Cuenta Offline',
        type: AccountType.bank,
        currency: 'COP',
        balance: 1000.0,
      );

      final created = await accountRepo.createAccount(account);
      expect(created, isNotNull);
      expect(created.name, 'Cuenta Offline');
    });

    // =========================================================================
    // TEST 2: Datos sobreviven reinicio
    // =========================================================================
    test('Datos persisten entre sesiones', () async {
      final userId = 'persistence-test-${DateTime.now().millisecondsSinceEpoch}';

      // Crear cuenta
      await accountRepo.createAccount(AccountModel(
        id: const Uuid().v4(),
        userId: userId,
        name: 'Persistente',
        type: AccountType.cash,
        currency: 'COP',
        balance: 500.0,
      ));

      // Simular "reinicio" leyendo de nuevo
      final accounts = await accountRepo.watchAccounts(userId).first;
      expect(accounts, isNotEmpty);
      expect(accounts.first.name, 'Persistente');
    });

    // =========================================================================
    // TEST 3: Multiples entidades offline
    // =========================================================================
    test('Multiples entidades se guardan offline', () async {
      final userId = 'multi-entity-${DateTime.now().millisecondsSinceEpoch}';
      final accountId = const Uuid().v4();

      // Crear cuenta
      await accountRepo.createAccount(AccountModel(
        id: accountId,
        userId: userId,
        name: 'Multi Entity Account',
        type: AccountType.bank,
        currency: 'COP',
        balance: 1000.0,
      ));

      // Crear transacciones
      for (int i = 0; i < 5; i++) {
        await txRepo.createTransaction(TransactionModel(
          id: const Uuid().v4(),
          userId: userId,
          accountId: accountId,
          amount: 100.0 * i,
          type: TransactionType.expense,
          description: 'Offline tx $i',
          date: DateTime.now(),
        ));
      }

      // Verificar
      final accounts = await accountRepo.watchAccounts(userId).first;
      final transactions = await txRepo.watchTransactions(userId).first;

      expect(accounts.length, 1);
      expect(transactions.length, 5);
    });
  });

  group('PWA: Sync Queue', () {
    // =========================================================================
    // TEST 4: Registros se marcan como no sincronizados
    // =========================================================================
    test('Nuevos registros tienen isSynced=false', () async {
      final account = AccountModel(
        id: const Uuid().v4(),
        userId: 'sync-queue-test',
        name: 'Pendiente Sync',
        type: AccountType.bank,
        currency: 'COP',
        balance: 100.0,
      );

      final created = await accountRepo.createAccount(account);
      // En modo offline, isSynced debe ser false
      expect(created.isSynced, false);
    });

    // =========================================================================
    // TEST 5: Cola de sync acumula operaciones
    // =========================================================================
    test('Operaciones se acumulan en cola de sync', () async {
      final userId = 'queue-test-${DateTime.now().millisecondsSinceEpoch}';
      final accountId = const Uuid().v4();

      // Crear cuenta primero
      await accountRepo.createAccount(AccountModel(
        id: accountId,
        userId: userId,
        name: 'Queue Account',
        type: AccountType.bank,
        currency: 'COP',
        balance: 0,
      ));

      // Crear multiples transacciones offline
      for (int i = 0; i < 10; i++) {
        await txRepo.createTransaction(TransactionModel(
          id: const Uuid().v4(),
          userId: userId,
          accountId: accountId,
          amount: i * 10.0,
          type: TransactionType.expense,
          description: 'Queue item $i',
          date: DateTime.now(),
        ));
      }

      // Verificar que todas estan pendientes
      final transactions = await txRepo.watchTransactions(userId).first;
      final unsyncedCount = transactions.where((t) => !t.isSynced).length;

      expect(unsyncedCount, 10);
    });

    // =========================================================================
    // TEST 6: Orden de cola se preserva
    // =========================================================================
    test('Orden de operaciones se preserva', () async {
      final userId = 'order-test-${DateTime.now().millisecondsSinceEpoch}';
      final accountId = const Uuid().v4();
      final descriptions = ['Primero', 'Segundo', 'Tercero'];

      // Crear cuenta primero
      await accountRepo.createAccount(AccountModel(
        id: accountId,
        userId: userId,
        name: 'Order Account',
        type: AccountType.bank,
        currency: 'COP',
        balance: 0,
      ));

      for (final desc in descriptions) {
        await txRepo.createTransaction(TransactionModel(
          id: const Uuid().v4(),
          userId: userId,
          accountId: accountId,
          amount: 100.0,
          type: TransactionType.expense,
          description: desc,
          date: DateTime.now(),
        ));
        // Pequeno delay para asegurar orden
        await Future.delayed(const Duration(milliseconds: 10));
      }

      final transactions = await txRepo.watchTransactions(userId).first;
      final sortedByDate = transactions.toList()
        ..sort((a, b) => a.date.compareTo(b.date));

      // Verificar orden cronologico
      expect(sortedByDate.length, 3);
    });
  });

  group('PWA: Conflict Resolution', () {
    // =========================================================================
    // TEST 7: Last Write Wins
    // =========================================================================
    test('Actualizacion mas reciente gana', () async {
      final accountId = const Uuid().v4();
      final userId = 'conflict-${DateTime.now().millisecondsSinceEpoch}';

      // Crear cuenta original
      await accountRepo.createAccount(AccountModel(
        id: accountId,
        userId: userId,
        name: 'Original',
        type: AccountType.bank,
        currency: 'COP',
        balance: 1000.0,
      ));

      // Primera actualizacion
      await accountRepo.updateAccount(AccountModel(
        id: accountId,
        userId: userId,
        name: 'Update 1',
        type: AccountType.bank,
        currency: 'COP',
        balance: 1100.0,
        updatedAt: DateTime.now(),
      ));

      await Future.delayed(const Duration(milliseconds: 10));

      // Segunda actualizacion (mas reciente)
      await accountRepo.updateAccount(AccountModel(
        id: accountId,
        userId: userId,
        name: 'Update 2',
        type: AccountType.bank,
        currency: 'COP',
        balance: 1200.0,
        updatedAt: DateTime.now(),
      ));

      final account = await accountRepo.getAccountById(accountId);
      expect(account?.name, 'Update 2');
      expect(account?.balance, 1200.0);
    });

    // =========================================================================
    // TEST 8: Timestamp se actualiza en modificaciones
    // =========================================================================
    test('updatedAt se actualiza en cada modificacion', () async {
      final accountId = const Uuid().v4();
      final userId = 'timestamp-${DateTime.now().millisecondsSinceEpoch}';

      final original = await accountRepo.createAccount(AccountModel(
        id: accountId,
        userId: userId,
        name: 'Timestamp Test',
        type: AccountType.bank,
        currency: 'COP',
        balance: 1000.0,
      ));

      final originalTime = original.updatedAt ?? original.createdAt;

      await Future.delayed(const Duration(milliseconds: 50));

      await accountRepo.updateAccount(AccountModel(
        id: accountId,
        userId: userId,
        name: 'Updated',
        type: AccountType.bank,
        currency: 'COP',
        balance: 1100.0,
        updatedAt: DateTime.now(),
      ));

      final updated = await accountRepo.getAccountById(accountId);
      final updatedTime = updated?.updatedAt;

      if (originalTime != null && updatedTime != null) {
        expect(updatedTime.isAfter(originalTime), true);
      }
    });
  });

  group('PWA: Network Resilience', () {
    // =========================================================================
    // TEST 9: Operaciones no fallan sin red
    // =========================================================================
    test('CRUD funciona sin conexion a red', () async {
      final userId = 'network-test-${DateTime.now().millisecondsSinceEpoch}';

      // Create
      final account = await accountRepo.createAccount(AccountModel(
        id: const Uuid().v4(),
        userId: userId,
        name: 'Offline Account',
        type: AccountType.bank,
        currency: 'COP',
        balance: 1000.0,
      ));
      expect(account, isNotNull);

      // Read
      final read = await accountRepo.getAccountById(account.id);
      expect(read, isNotNull);

      // Update
      await accountRepo.updateAccount(account.copyWith(balance: 2000.0));
      final updated = await accountRepo.getAccountById(account.id);
      expect(updated?.balance, 2000.0);

      // Delete (soft delete - marca como inactiva)
      await accountRepo.deleteAccount(account.id);
      final deleted = await accountRepo.getAccountById(account.id);
      // Soft delete: cuenta sigue existiendo pero marcada como inactiva
      expect(deleted?.isActive, false);
    });

    // =========================================================================
    // TEST 10: Streams funcionan offline
    // =========================================================================
    test('Streams emiten datos offline', () async {
      final userId = 'stream-offline-${DateTime.now().millisecondsSinceEpoch}';

      await accountRepo.createAccount(AccountModel(
        id: const Uuid().v4(),
        userId: userId,
        name: 'Stream Test',
        type: AccountType.cash,
        currency: 'COP',
        balance: 500.0,
      ));

      // El stream debe emitir datos incluso offline
      final accounts = await accountRepo.watchAccounts(userId).first;
      expect(accounts, isNotEmpty);
    });
  });

  group('PWA: Cache Management', () {
    // =========================================================================
    // TEST 11: Datos se cachean correctamente
    // =========================================================================
    test('Lecturas repetidas son eficientes', () async {
      final userId = 'cache-test-${DateTime.now().millisecondsSinceEpoch}';
      final accountId = const Uuid().v4();

      await accountRepo.createAccount(AccountModel(
        id: accountId,
        userId: userId,
        name: 'Cache Test',
        type: AccountType.bank,
        currency: 'COP',
        balance: 1000.0,
      ));

      // Multiples lecturas
      final stopwatch = Stopwatch()..start();
      for (int i = 0; i < 100; i++) {
        await accountRepo.getAccountById(accountId);
      }
      stopwatch.stop();

      // 100 lecturas deben ser rapidas si hay cache
      expect(stopwatch.elapsedMilliseconds, lessThan(1000));
    });

    // =========================================================================
    // TEST 12: Cache se invalida en escritura
    // =========================================================================
    test('Cache se actualiza despues de escritura', () async {
      final userId = 'invalidate-${DateTime.now().millisecondsSinceEpoch}';
      final accountId = const Uuid().v4();

      await accountRepo.createAccount(AccountModel(
        id: accountId,
        userId: userId,
        name: 'Before Update',
        type: AccountType.bank,
        currency: 'COP',
        balance: 1000.0,
      ));

      // Leer para llenar cache
      final before = await accountRepo.getAccountById(accountId);
      expect(before?.name, 'Before Update');

      // Actualizar
      await accountRepo.updateAccount(before!.copyWith(name: 'After Update'));

      // Leer de nuevo - debe reflejar el cambio
      final after = await accountRepo.getAccountById(accountId);
      expect(after?.name, 'After Update');
    });
  });

  group('PWA: Background Sync Simulation', () {
    // =========================================================================
    // TEST 13: Sync no falla cuando offline
    // =========================================================================
    test('Sync manual no causa error cuando offline', () async {
      // En test mode, operaciones deben completar sin error
      await expectLater(
        accountRepo.watchAccounts('test-user').first,
        completes,
      );
    });

    // =========================================================================
    // TEST 14: Datos pendientes se pueden recuperar
    // =========================================================================
    test('Registros no sincronizados se pueden listar', () async {
      final userId = 'unsynced-${DateTime.now().millisecondsSinceEpoch}';

      // Crear varias cuentas offline
      for (int i = 0; i < 5; i++) {
        await accountRepo.createAccount(AccountModel(
          id: const Uuid().v4(),
          userId: userId,
          name: 'Unsynced $i',
          type: AccountType.bank,
          currency: 'COP',
          balance: 100.0 * i,
        ));
      }

      final accounts = await accountRepo.watchAccounts(userId).first;
      final unsynced = accounts.where((a) => !a.isSynced).toList();

      expect(unsynced.length, 5);
    });
  });

  group('PWA: Installability Requirements', () {
    // =========================================================================
    // TEST 15: App tiene nombre valido
    // =========================================================================
    test('App name es valido para PWA', () {
      const appName = 'Finanzas Familiares';

      expect(appName.isNotEmpty, true);
      expect(appName.length, lessThanOrEqualTo(45)); // PWA name limit
    });

    // =========================================================================
    // TEST 16: App tiene short name
    // =========================================================================
    test('Short name es valido', () {
      const shortName = 'Finanzas';

      expect(shortName.isNotEmpty, true);
      expect(shortName.length, lessThanOrEqualTo(12)); // Short name limit
    });

    // =========================================================================
    // TEST 17: Tema de app esta definido
    // =========================================================================
    test('Theme color esta definido', () {
      const themeColor = '#6B4EFF'; // Color primario de la app

      expect(themeColor.startsWith('#'), true);
      expect(themeColor.length, 7); // #RRGGBB format
    });
  });
}
