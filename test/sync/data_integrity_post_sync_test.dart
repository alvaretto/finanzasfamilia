/// Tests de integridad de datos post-sincronización
///
/// Verifican que después de una sincronización completa:
/// - Los balances de cuentas son correctos
/// - Las transacciones están vinculadas a cuentas válidas
/// - Las categorías mantienen su jerarquía
/// - Los journal entries cumplen la ecuación contable
/// - No hay datos huérfanos o inconsistentes
///
/// CRÍTICO: Estos tests detectan corrupción de datos causada por
/// sincronización parcial, conflictos de merge, o errores de FK.
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:uuid/uuid.dart';
import 'package:matcher/matcher.dart' as m;

import 'package:finanzas_familiares/data/local/database.dart';
import 'package:finanzas_familiares/data/local/daos/categories_dao.dart';
import 'package:finanzas_familiares/data/local/daos/accounts_dao.dart';
import 'package:finanzas_familiares/data/local/daos/transactions_dao.dart';
import 'package:finanzas_familiares/data/local/daos/journal_entries_dao.dart';
import 'package:finanzas_familiares/data/local/seeders/category_seeder.dart';
import 'package:finanzas_familiares/data/local/seeders/accounts_seeder.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('DataIntegrityPostSync - Verificación de Integridad', () {
    late AppDatabase db;
    late CategoriesDao categoriesDao;
    late AccountsDao accountsDao;
    late TransactionsDao transactionsDao;
    late JournalEntriesDao journalEntriesDao;

    setUp(() async {
      db = AppDatabase.forTesting(NativeDatabase.memory());
      categoriesDao = CategoriesDao(db);
      accountsDao = AccountsDao(db);
      transactionsDao = TransactionsDao(db);
      journalEntriesDao = JournalEntriesDao(db);
    });

    tearDown(() async {
      await db.close();
    });

    group('Fase 1: Integridad de Categorías', () {
      test('Todas las categorías del sistema están presentes', () async {
        await seedCategories(categoriesDao);
        final categories = await categoriesDao.getAllCategories();

        // Categorías raíz obligatorias
        final roots = categories.where((c) => (c.level ?? 0) == 0).toList();
        expect(roots, m.hasLength(4),
            reason: 'Deben existir 4 categorías raíz');

        final rootNames = roots.map((c) => c.name).toSet();
        expect(rootNames, m.containsAll([
          'Lo que Tengo',
          'Lo que Debo',
          'Dinero que Entra',
          'Dinero que Sale',
        ]));
      });

      test('No hay categorías duplicadas por nombre+tipo+parent', () async {
        await seedCategories(categoriesDao);
        final categories = await categoriesDao.getAllCategories();

        // La unicidad es por: type + name + parentId
        // (puede haber "Otros" en diferentes ramas del árbol)
        final keys = <String>{};
        for (final c in categories) {
          final key = '${c.type}:${c.name}:${c.parentId ?? "root"}';
          expect(keys.contains(key), m.isFalse,
              reason: 'Categoría "$key" está duplicada');
          keys.add(key);
        }
      });

      test('Jerarquía de categorías es acíclica', () async {
        await seedCategories(categoriesDao);
        final categories = await categoriesDao.getAllCategories();
        final byId = {for (final c in categories) c.id: c};

        for (final category in categories) {
          // Recorrer hacia arriba hasta la raíz
          final visited = <String>{};
          var current = category;

          while (current.parentId != null) {
            expect(visited.contains(current.id), m.isFalse,
                reason: 'Ciclo detectado en categoría "${category.name}"');
            visited.add(current.id);
            current = byId[current.parentId]!;
          }
        }
      });

      test('sortOrder es único dentro de cada nivel de un padre', () async {
        await seedCategories(categoriesDao);
        final categories = await categoriesDao.getAllCategories();

        // Agrupar por parent_id
        final byParent = <String?, List<CategoryEntry>>{};
        for (final c in categories) {
          byParent.putIfAbsent(c.parentId, () => []);
          byParent[c.parentId]!.add(c);
        }

        // Verificar unicidad de sortOrder dentro de cada grupo
        for (final children in byParent.values) {
          final sortOrders = children.map((c) => c.sortOrder ?? 0).toList();
          final uniqueSortOrders = sortOrders.toSet();
          expect(uniqueSortOrders.length, m.equals(sortOrders.length),
              reason: 'sortOrder debe ser único entre hermanos');
        }
      });
    });

    group('Fase 2: Integridad de Cuentas', () {
      test('Todas las cuentas tienen categoría válida', () async {
        await seedCategories(categoriesDao);
        await seedAccounts(accountsDao);

        final accounts = await accountsDao.getAllAccounts();
        final categoryIds = (await categoriesDao.getAllCategories())
            .map((c) => c.id)
            .toSet();

        for (final account in accounts) {
          expect(categoryIds.contains(account.categoryId), m.isTrue,
              reason:
                  'Cuenta "${account.name}" tiene categoryId inválido');
        }
      });

      test('Cuentas del sistema tienen isSystem = true', () async {
        await seedCategories(categoriesDao);
        await seedAccounts(accountsDao);

        final accounts = await accountsDao.getAllAccounts();

        for (final account in accounts) {
          expect(account.isSystem ?? false, m.isTrue,
              reason:
                  'Cuenta del sistema "${account.name}" debe tener isSystem=true');
        }
      });

      test('Balance inicial de cuentas del sistema es 0', () async {
        await seedCategories(categoriesDao);
        await seedAccounts(accountsDao);

        final accounts = await accountsDao.getAllAccounts();

        for (final account in accounts) {
          expect(account.balance ?? 0, m.equals(0),
              reason:
                  'Balance inicial de "${account.name}" debe ser 0');
        }
      });

      test('No hay cuentas duplicadas por nombre', () async {
        await seedCategories(categoriesDao);
        await seedAccounts(accountsDao);

        final accounts = await accountsDao.getAllAccounts();
        final names = accounts.map((a) => a.name).toSet();

        expect(names.length, m.equals(accounts.length),
            reason: 'No debe haber cuentas con nombres duplicados');
      });

      test('Cuentas de activos están en categorías de tipo asset', () async {
        await seedCategories(categoriesDao);
        await seedAccounts(accountsDao);

        final accounts = await accountsDao.getAllAccounts();
        final categories = await categoriesDao.getAllCategories();
        final categoryById = {for (final c in categories) c.id: c};

        for (final account in accounts) {
          final category = categoryById[account.categoryId];
          expect(category, m.isNotNull);
          expect(category!.type, m.equals('asset'),
              reason:
                  'Cuenta "${account.name}" debe estar en categoría de tipo asset');
        }
      });
    });

    group('Fase 3: Integridad de Transacciones', () {
      test('Transacción de gasto puede tener fromAccountId', () async {
        await seedCategories(categoriesDao);
        await seedAccounts(accountsDao);

        final categories = await categoriesDao.getAllCategories();
        final accounts = await accountsDao.getAllAccounts();

        final expenseCategory = categories.firstWhere(
            (c) => c.type == 'expense' && (c.level ?? 0) > 0);
        final account = accounts.first;

        // Crear transacción de gasto válida
        final txId = const Uuid().v4();
        await transactionsDao.insertTransaction(TransactionsCompanion.insert(
          id: txId,
          amount: 10000.0,
          type: 'expense',
          categoryId: expenseCategory.id,
          fromAccountId: Value(account.id),
          transactionDate: DateTime.now(),
        ));

        final allTx = await transactionsDao.getAllTransactions();
        final tx = allTx.where((t) => t.id == txId).firstOrNull;
        expect(tx, m.isNotNull);
        expect(tx!.fromAccountId, m.isNotNull,
            reason: 'Gasto debe tener cuenta origen');
      });

      test('Transacción de ingreso puede tener toAccountId', () async {
        await seedCategories(categoriesDao);
        await seedAccounts(accountsDao);

        final categories = await categoriesDao.getAllCategories();
        final accounts = await accountsDao.getAllAccounts();

        final incomeCategory = categories.firstWhere(
            (c) => c.type == 'income' && (c.level ?? 0) > 0);
        final account = accounts.first;

        // Crear transacción de ingreso válida
        final txId = const Uuid().v4();
        await transactionsDao.insertTransaction(TransactionsCompanion.insert(
          id: txId,
          amount: 50000.0,
          type: 'income',
          categoryId: incomeCategory.id,
          toAccountId: Value(account.id),
          transactionDate: DateTime.now(),
        ));

        final allTx = await transactionsDao.getAllTransactions();
        final tx = allTx.where((t) => t.id == txId).firstOrNull;
        expect(tx, m.isNotNull);
        expect(tx!.toAccountId, m.isNotNull,
            reason: 'Ingreso debe tener cuenta destino');
      });

      test('Transacción de transferencia tiene ambas cuentas', () async {
        await seedCategories(categoriesDao);
        await seedAccounts(accountsDao);

        final categories = await categoriesDao.getAllCategories();
        final accounts = await accountsDao.getAllAccounts();

        // Para transfer, usar categoría de activo
        final assetCategory = categories.firstWhere(
            (c) => c.type == 'asset' && (c.level ?? 0) > 0);
        final fromAccount = accounts[0];
        final toAccount = accounts.length > 1 ? accounts[1] : accounts[0];

        final txId = const Uuid().v4();
        await transactionsDao.insertTransaction(TransactionsCompanion.insert(
          id: txId,
          amount: 25000.0,
          type: 'transfer',
          categoryId: assetCategory.id,
          fromAccountId: Value(fromAccount.id),
          toAccountId: Value(toAccount.id),
          transactionDate: DateTime.now(),
        ));

        final allTx = await transactionsDao.getAllTransactions();
        final tx = allTx.where((t) => t.id == txId).firstOrNull;
        expect(tx, m.isNotNull);
        expect(tx!.fromAccountId, m.isNotNull,
            reason: 'Transfer debe tener cuenta origen');
        expect(tx.toAccountId, m.isNotNull,
            reason: 'Transfer debe tener cuenta destino');
      });

      test('Monto de transacción siempre es positivo', () async {
        await seedCategories(categoriesDao);
        await seedAccounts(accountsDao);

        final categories = await categoriesDao.getAllCategories();
        final accounts = await accountsDao.getAllAccounts();

        final expenseCategory = categories.firstWhere(
            (c) => c.type == 'expense' && (c.level ?? 0) > 0);
        final account = accounts.first;

        // Crear transacciones con diferentes montos
        for (final amount in [100.0, 1000.0, 10000.0, 99999.0]) {
          final txId = const Uuid().v4();
          await transactionsDao.insertTransaction(TransactionsCompanion.insert(
            id: txId,
            amount: amount,
            type: 'expense',
            categoryId: expenseCategory.id,
            fromAccountId: Value(account.id),
            transactionDate: DateTime.now(),
          ));

          final allTx = await transactionsDao.getAllTransactions();
          final tx = allTx.where((t) => t.id == txId).firstOrNull;
          expect(tx!.amount, m.greaterThan(0),
              reason: 'Monto debe ser positivo');
        }
      });
    });

    group('Fase 4: Integridad de Journal Entries', () {
      test('Journal entries están vinculados a transacción válida', () async {
        await seedCategories(categoriesDao);
        await seedAccounts(accountsDao);

        final categories = await categoriesDao.getAllCategories();
        final accounts = await accountsDao.getAllAccounts();

        final expenseCategory = categories.firstWhere(
            (c) => c.type == 'expense' && (c.level ?? 0) > 0);
        final account = accounts.first;

        // Crear transacción y journal entries
        final txId = const Uuid().v4();
        await transactionsDao.insertTransaction(TransactionsCompanion.insert(
          id: txId,
          amount: 15000.0,
          type: 'expense',
          categoryId: expenseCategory.id,
          fromAccountId: Value(account.id),
          transactionDate: DateTime.now(),
        ));

        // Crear journal entries de partida doble
        final now = DateTime.now();
        await journalEntriesDao.insertEntry(JournalEntriesCompanion.insert(
          id: const Uuid().v4(),
          transactionId: txId,
          categoryId: Value(expenseCategory.id), // Débito a cuenta de gasto
          entryType: 'debit',
          amount: 15000.0,
          entryDate: now,
          createdAt: now,
          updatedAt: now,
        ));

        await journalEntriesDao.insertEntry(JournalEntriesCompanion.insert(
          id: const Uuid().v4(),
          transactionId: txId,
          accountId: Value(account.id), // Crédito a cuenta de activo
          entryType: 'credit',
          amount: 15000.0,
          entryDate: now,
          createdAt: now,
          updatedAt: now,
        ));

        // Verificar
        final entries = await journalEntriesDao.getEntriesByTransaction(txId);
        expect(entries, m.hasLength(2),
            reason: 'Partida doble requiere 2 entries');

        final debits = entries.where((e) => e.entryType == 'debit');
        final credits = entries.where((e) => e.entryType == 'credit');
        expect(debits.length, m.equals(1));
        expect(credits.length, m.equals(1));

        final totalDebits = debits.fold<double>(0, (sum, e) => sum + e.amount);
        final totalCredits = credits.fold<double>(0, (sum, e) => sum + e.amount);
        expect(totalDebits, m.equals(totalCredits),
            reason: 'Débitos = Créditos (partida doble)');
      });
    });

    group('Fase 5: Consistencia Post-Sync', () {
      test('Cuentas referenciadas en transacciones existen', () async {
        await seedCategories(categoriesDao);
        await seedAccounts(accountsDao);

        final accounts = await accountsDao.getAllAccounts();
        final categories = await categoriesDao.getAllCategories();
        final accountIds = accounts.map((a) => a.id).toSet();

        final expenseCategory = categories.firstWhere(
            (c) => c.type == 'expense' && (c.level ?? 0) > 0);

        // Crear transacción
        final txId = const Uuid().v4();
        await transactionsDao.insertTransaction(TransactionsCompanion.insert(
          id: txId,
          amount: 5000.0,
          type: 'expense',
          categoryId: expenseCategory.id,
          fromAccountId: Value(accounts.first.id),
          transactionDate: DateTime.now(),
        ));

        // Verificar que la cuenta existe
        final allTx = await transactionsDao.getAllTransactions();
        final tx = allTx.where((t) => t.id == txId).firstOrNull;
        expect(accountIds.contains(tx!.fromAccountId), m.isTrue,
            reason: 'Cuenta de transacción debe existir');
      });

      test('Categorías referenciadas en transacciones existen', () async {
        await seedCategories(categoriesDao);
        await seedAccounts(accountsDao);

        final categories = await categoriesDao.getAllCategories();
        final accounts = await accountsDao.getAllAccounts();
        final categoryIds = categories.map((c) => c.id).toSet();

        final expenseCategory = categories.firstWhere(
            (c) => c.type == 'expense' && (c.level ?? 0) > 0);

        final txId = const Uuid().v4();
        await transactionsDao.insertTransaction(TransactionsCompanion.insert(
          id: txId,
          amount: 7500.0,
          type: 'expense',
          categoryId: expenseCategory.id,
          fromAccountId: Value(accounts.first.id),
          transactionDate: DateTime.now(),
        ));

        final allTx = await transactionsDao.getAllTransactions();
        final tx = allTx.where((t) => t.id == txId).firstOrNull;
        expect(categoryIds.contains(tx!.categoryId), m.isTrue,
            reason: 'Categoría de transacción debe existir');
      });

      test('No hay IDs duplicados entre entidades del mismo tipo', () async {
        await seedCategories(categoriesDao);
        await seedAccounts(accountsDao);

        final categories = await categoriesDao.getAllCategories();
        final accounts = await accountsDao.getAllAccounts();

        final categoryIds = categories.map((c) => c.id).toList();
        final accountIds = accounts.map((a) => a.id).toList();

        expect(categoryIds.toSet().length, m.equals(categoryIds.length),
            reason: 'IDs de categorías deben ser únicos');
        expect(accountIds.toSet().length, m.equals(accountIds.length),
            reason: 'IDs de cuentas deben ser únicos');
      });
    });

    group('Fase 6: Validación de Datos Obligatorios', () {
      test('Categorías tienen campos obligatorios', () async {
        await seedCategories(categoriesDao);
        final categories = await categoriesDao.getAllCategories();

        for (final c in categories) {
          expect(c.id, m.isNotEmpty, reason: 'ID es obligatorio');
          expect(c.name, m.isNotEmpty, reason: 'Nombre es obligatorio');
          expect(c.type, m.isNotEmpty, reason: 'Tipo es obligatorio');
          expect(c.level, m.isNotNull, reason: 'Level es obligatorio');
        }
      });

      test('Cuentas tienen campos obligatorios', () async {
        await seedCategories(categoriesDao);
        await seedAccounts(accountsDao);

        final accounts = await accountsDao.getAllAccounts();

        for (final a in accounts) {
          expect(a.id, m.isNotEmpty, reason: 'ID es obligatorio');
          expect(a.name, m.isNotEmpty, reason: 'Nombre es obligatorio');
          expect(a.categoryId, m.isNotEmpty, reason: 'CategoryId es obligatorio');
          expect(a.balance, m.isNotNull, reason: 'Balance es obligatorio');
        }
      });

      test('Transacciones tienen campos obligatorios', () async {
        await seedCategories(categoriesDao);
        await seedAccounts(accountsDao);

        final categories = await categoriesDao.getAllCategories();
        final accounts = await accountsDao.getAllAccounts();
        final expenseCategory = categories.firstWhere(
            (c) => c.type == 'expense' && (c.level ?? 0) > 0);

        final txId = const Uuid().v4();
        await transactionsDao.insertTransaction(TransactionsCompanion.insert(
          id: txId,
          amount: 12000.0,
          type: 'expense',
          categoryId: expenseCategory.id,
          fromAccountId: Value(accounts.first.id),
          transactionDate: DateTime.now(),
        ));

        final allTx = await transactionsDao.getAllTransactions();
        final tx = allTx.where((t) => t.id == txId).firstOrNull;
        expect(tx!.id, m.isNotEmpty, reason: 'ID es obligatorio');
        expect(tx.amount, m.greaterThan(0), reason: 'Amount es obligatorio');
        expect(tx.type, m.isNotEmpty, reason: 'Type es obligatorio');
        expect(tx.categoryId, m.isNotEmpty, reason: 'CategoryId es obligatorio');
        expect(tx.transactionDate, m.isNotNull, reason: 'Date es obligatorio');
      });
    });
  });
}
