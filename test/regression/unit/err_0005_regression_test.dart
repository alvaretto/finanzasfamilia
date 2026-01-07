import 'package:flutter_test/flutter_test.dart';
import 'package:finanzas_familiares/features/transactions/domain/models/transaction_model.dart';
import 'package:finanzas_familiares/features/transactions/data/repositories/transaction_repository.dart';
import 'package:finanzas_familiares/features/accounts/data/repositories/account_repository.dart';
import 'package:finanzas_familiares/core/database/app_database.dart';
import '../../helpers/test_helpers.dart';

/// Test de regresión para ERR-0005: Anti-patrón: amount: i.toDouble() en loops que generan transacciones
///
/// **Causa raíz**: Uso directo del índice de loop (i) como monto sin offset, generando amount=0 en primera iteración cuando i=0
/// **Archivo original**: test/performance/app_performance_test.dart:98,128,153
///
/// **Anti-patrones corregidos**:
/// 1. `amount: i.toDouble()` en loop que empieza en 0
/// 2. `amount: 10.0 * i` en loop que empieza en 0
/// 3. Falta de validación de datos de prueba antes de insertar
///
/// **Solución**: Helper test_data_generators.dart + documentación
///
/// Este test verifica que:
/// - El helper generateTestTransaction() nunca genera montos <= 0
/// - El helper respeta parámetros baseAmount y multiplier
/// - La validación en TransactionRepository funciona correctamente
/// - Los validadores de test data detectan datos inválidos
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

  tearDownAll(() async {
    await tearDownTestEnvironment();
  });

  group('ERR-0005 Regression - generateTestTransaction()', () {
    // =========================================================================
    // TEST 1: Helper nunca genera amount <= 0 con índice 0
    // =========================================================================
    test('Helper nunca genera amount <= 0 con índice 0', () {
      final tx = generateTestTransaction(
        index: 0,  // Índice 0 - el caso problemático
        userId: 'user-1',
      );

      expect(tx.amount, greaterThan(0),
          reason: 'Helper debe garantizar amount > 0 incluso con index=0');
      expect(tx.amount, equals(1.0),
          reason: 'Con baseAmount=1.0 (default) e index=0, amount debe ser 1.0');
    });

    // =========================================================================
    // TEST 2: Helper respeta baseAmount y multiplier
    // =========================================================================
    test('Helper respeta baseAmount y multiplier', () {
      // baseAmount = 10.0, index = 0 → amount = 10.0 * (0+1) = 10.0
      final tx1 = generateTestTransaction(
        index: 0,
        userId: 'user-1',
        baseAmount: 10.0,
      );
      expect(tx1.amount, equals(10.0));

      // baseAmount = 10.0, index = 5 → amount = 10.0 * (5+1) = 60.0
      final tx2 = generateTestTransaction(
        index: 5,
        userId: 'user-1',
        baseAmount: 10.0,
      );
      expect(tx2.amount, equals(60.0));

      // baseAmount = 5.0, multiplier = 2.0, index = 0 → amount = 5.0 * (0+1) * 2.0 = 10.0
      final tx3 = generateTestTransaction(
        index: 0,
        userId: 'user-1',
        baseAmount: 5.0,
        multiplier: 2.0,
      );
      expect(tx3.amount, equals(10.0));
    });

    // =========================================================================
    // TEST 3: generateTestTransactionList() genera lista válida de 100 items
    // =========================================================================
    test('generateTestTransactionList() genera lista válida de 100 items', () {
      final txs = generateTestTransactionList(
        count: 100,
        userId: 'user-test',
        baseAmount: 1.0,
      );

      expect(txs.length, equals(100));

      // Verificar que NINGUNA transacción tiene amount <= 0
      for (int i = 0; i < txs.length; i++) {
        expect(txs[i].amount, greaterThan(0),
            reason: 'Transaction $i debe tener amount > 0, tiene ${txs[i].amount}');
        expect(txs[i].amount, equals(i + 1.0),
            reason: 'Transaction $i debe tener amount ${i + 1}.0');
      }
    });
  });

  group('ERR-0005 Regression - TransactionRepository Validation', () {
    // =========================================================================
    // TEST 4: TransactionRepository rechaza amount <= 0 (validación existente)
    // =========================================================================
    test('TransactionRepository rechaza amount <= 0', () async {
      // amount = 0
      expect(
        () => txRepo.createTransaction(TransactionModel(
          id: 'test-1',
          userId: 'user-1',
          accountId: 'acc-1',
          amount: 0.0,  // ← Inválido
          type: TransactionType.expense,
          description: 'Test zero amount',
          date: DateTime.now(),
        )),
        throwsA(isA<ArgumentError>()),
        reason: 'TransactionRepository debe rechazar amount = 0',
      );

      // amount < 0
      expect(
        () => txRepo.createTransaction(TransactionModel(
          id: 'test-2',
          userId: 'user-1',
          accountId: 'acc-1',
          amount: -10.0,  // ← Inválido
          type: TransactionType.expense,
          description: 'Test negative amount',
          date: DateTime.now(),
        )),
        throwsA(isA<ArgumentError>()),
        reason: 'TransactionRepository debe rechazar amount < 0',
      );
    });

    // =========================================================================
    // TEST 5: TransactionRepository acepta amount > 0
    // =========================================================================
    test('TransactionRepository acepta amount > 0', () async {
      final tx = TransactionModel(
        id: 'test-valid',
        userId: 'user-1',
        accountId: 'acc-1',
        amount: 1.0,  // ← Válido
        type: TransactionType.expense,
        description: 'Test valid amount',
        date: DateTime.now(),
      );

      // Usar expectLater con completes para operaciones async
      await expectLater(
        txRepo.createTransaction(tx),
        completes,
        reason: 'TransactionRepository debe aceptar amount > 0',
      );
    });

    // =========================================================================
    // TEST 6: Loop completo de 10 iteraciones no falla con helper
    // =========================================================================
    test('Loop completo de 10 iteraciones no falla con helper', () async {
      // Este test replica el escenario que causaba el error original
      // pero usando el helper que garantiza montos válidos
      // Reducido a 10 iteraciones para reliability (el anti-patrón se valida igual)
      for (int i = 0; i < 10; i++) {
        final tx = generateTestTransaction(
          index: i,
          userId: 'loop-user',
          baseAmount: 10.0,
        );

        // Await para asegurar que cada transacción se cree antes de continuar
        await expectLater(
          txRepo.createTransaction(tx),
          completes,
          reason: 'Iteration $i no debe fallar con helper',
        );
      }

      // Verificar que se crearon las 10 transacciones
      final created = await txRepo.watchTransactions('loop-user').first;
      expect(created.length, equals(10));
    });
  });

  group('ERR-0005 Regression - TestDataValidators', () {
    // =========================================================================
    // TEST 7: Validador detecta amount <= 0
    // =========================================================================
    test('Validador detecta amount <= 0', () {
      final badTx = TransactionModel(
        id: 'bad-tx',
        userId: 'user-1',
        accountId: 'acc-1',
        amount: 0.0,  // ← Inválido
        type: TransactionType.expense,
        description: 'Bad transaction',
        date: DateTime.now(),
      );

      expect(
        () => TestDataValidators.validateTransaction(badTx),
        throwsA(isA<ArgumentError>()),
        reason: 'Validador debe detectar amount <= 0',
      );
    });

    // =========================================================================
    // TEST 8: Validador acepta amount > 0
    // =========================================================================
    test('Validador acepta amount > 0', () {
      final goodTx = TransactionModel(
        id: 'good-tx',
        userId: 'user-1',
        accountId: 'acc-1',
        amount: 10.0,  // ← Válido
        type: TransactionType.expense,
        description: 'Good transaction',
        date: DateTime.now(),
      );

      expect(() => TestDataValidators.validateTransaction(goodTx), returnsNormally,
          reason: 'Validador debe aceptar amount > 0');
    });

    // =========================================================================
    // TEST 9: Validar lista completa de transacciones
    // =========================================================================
    test('Validar lista completa de transacciones', () {
      // Lista generada con helper - todas válidas
      final validList = generateTestTransactionList(
        count: 50,
        userId: 'user-1',
      );

      expect(() => TestDataValidators.validateTransactionList(validList), returnsNormally,
          reason: 'Lista generada con helper debe ser 100% válida');

      // Lista con una transacción inválida
      final invalidList = [
        ...validList,
        TransactionModel(
          id: 'bad-one',
          userId: 'user-1',
          accountId: 'acc-1',
          amount: 0.0,  // ← Inválida
          type: TransactionType.expense,
          description: 'Invalid',
          date: DateTime.now(),
        ),
      ];

      expect(
        () => TestDataValidators.validateTransactionList(invalidList),
        throwsA(isA<ArgumentError>()),
        reason: 'Validador debe detectar lista con elementos inválidos',
      );
    });
  });

  group('ERR-0005 Regression - Anti-Pattern Demonstration', () {
    // =========================================================================
    // TEST 10: Anti-patrón documentado falla cuando se usa (demostración)
    // =========================================================================
    test('Anti-patrón documentado falla cuando se usa (demostración)', () async {
      // Este test DEMUESTRA el anti-patrón original y verifica que falla
      // NO usar este patrón en código real - solo para documentación

      // Anti-patrón 1: amount: i.toDouble() donde i empieza en 0
      expect(
        () => txRepo.createTransaction(TransactionModel(
          id: 'anti-pattern-1',
          userId: 'demo-user',
          accountId: 'acc-1',
          amount: 0.toDouble(),  // i = 0 → amount = 0.0 ← FALLA
          type: TransactionType.expense,
          description: 'Anti-pattern demo',
          date: DateTime.now(),
        )),
        throwsA(isA<ArgumentError>()),
        reason: 'Anti-patrón amount: i.toDouble() con i=0 debe fallar',
      );

      // Anti-patrón 2: amount: 10.0 * i donde i = 0
      expect(
        () => txRepo.createTransaction(TransactionModel(
          id: 'anti-pattern-2',
          userId: 'demo-user',
          accountId: 'acc-1',
          amount: 10.0 * 0,  // i = 0 → amount = 0.0 ← FALLA
          type: TransactionType.expense,
          description: 'Anti-pattern demo 2',
          date: DateTime.now(),
        )),
        throwsA(isA<ArgumentError>()),
        reason: 'Anti-patrón amount: 10.0 * i con i=0 debe fallar',
      );

      // Patrón correcto: usar helper o (i+1)
      final correctTx = generateTestTransaction(
        index: 0,  // index puede ser 0
        userId: 'demo-user',
      );

      await expectLater(
        txRepo.createTransaction(correctTx),
        completes,
        reason: 'Patrón correcto con helper NO debe fallar',
      );
    });
  });
}
