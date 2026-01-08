import 'package:drift/native.dart';
import 'package:drift/drift.dart' hide isNotNull;
import 'package:flutter_test/flutter_test.dart';
import 'package:finanzas_familiares/data/local/database.dart';
import 'package:finanzas_familiares/data/local/daos/daos.dart';
import 'package:finanzas_familiares/data/local/seeders/seeders.dart';

/// Tests de integración E2E para la integridad contable
/// Prueba: Transacciones, Balances, Flujo de Caja
void main() {
  group('E2E: Integridad de Transacciones', () {
    test('múltiples transacciones mantienen consistencia', () async {
      // ======================
      // Setup
      // ======================
      final db = AppDatabase.forTesting(NativeDatabase.memory());
      final categoriesDao = CategoriesDao(db);
      final transactionsDao = TransactionsDao(db);

      await seedCategories(categoriesDao);
      final categories = await categoriesDao.getAllCategories();

      final expenseCategory = categories.firstWhere(
        (c) => c.type == 'expense' && c.parentId != null,
      );
      final incomeCategory = categories.firstWhere(
        (c) => c.type == 'income' && c.parentId != null,
      );

      // ======================
      // Crear múltiples transacciones
      // ======================
      final txData = [
        (id: 'tx-001', type: 'income', amount: 4000000.0, catId: incomeCategory.id),
        (id: 'tx-002', type: 'expense', amount: 500000.0, catId: expenseCategory.id),
        (id: 'tx-003', type: 'expense', amount: 300000.0, catId: expenseCategory.id),
        (id: 'tx-004', type: 'income', amount: 200000.0, catId: incomeCategory.id),
        (id: 'tx-005', type: 'expense', amount: 150000.0, catId: expenseCategory.id),
      ];

      for (final tx in txData) {
        await transactionsDao.insertTransaction(TransactionsCompanion.insert(
          id: tx.id,
          type: tx.type,
          amount: tx.amount,
          description: Value('Transaction ${tx.id}'),
          categoryId: tx.catId,
          transactionDate: DateTime(2026, 1, 15),
        ));
      }

      // ======================
      // Verificar totales
      // ======================
      final allTransactions = await transactionsDao.getAllTransactions();
      expect(allTransactions.length, equals(5));

      final totalIncome = allTransactions
          .where((t) => t.type == 'income')
          .fold<double>(0, (sum, t) => sum + t.amount);

      final totalExpense = allTransactions
          .where((t) => t.type == 'expense')
          .fold<double>(0, (sum, t) => sum + t.amount);

      expect(totalIncome, equals(4200000)); // 4M + 200k
      expect(totalExpense, equals(950000)); // 500k + 300k + 150k

      final netBalance = totalIncome - totalExpense;
      expect(netBalance, equals(3250000));

      await db.close();
    });

    test('transacciones se filtran correctamente por período', () async {
      final db = AppDatabase.forTesting(NativeDatabase.memory());
      final categoriesDao = CategoriesDao(db);
      final transactionsDao = TransactionsDao(db);

      await seedCategories(categoriesDao);
      final categories = await categoriesDao.getAllCategories();

      final expenseCategory = categories.firstWhere(
        (c) => c.type == 'expense' && c.parentId != null,
      );
      final incomeCategory = categories.firstWhere(
        (c) => c.type == 'income' && c.parentId != null,
      );

      // Transacciones en enero
      await transactionsDao.insertTransaction(TransactionsCompanion.insert(
        id: 'tx-jan-001',
        type: 'income',
        amount: 5000000,
        description: const Value('Salario Enero'),
        categoryId: incomeCategory.id,
        transactionDate: DateTime(2026, 1, 5),
      ));

      await transactionsDao.insertTransaction(TransactionsCompanion.insert(
        id: 'tx-jan-002',
        type: 'expense',
        amount: 1500000,
        description: const Value('Arriendo'),
        categoryId: expenseCategory.id,
        transactionDate: DateTime(2026, 1, 10),
      ));

      // Transacciones en febrero
      await transactionsDao.insertTransaction(TransactionsCompanion.insert(
        id: 'tx-feb-001',
        type: 'income',
        amount: 5200000,
        description: const Value('Salario Febrero'),
        categoryId: incomeCategory.id,
        transactionDate: DateTime(2026, 2, 5),
      ));

      await transactionsDao.insertTransaction(TransactionsCompanion.insert(
        id: 'tx-feb-002',
        type: 'expense',
        amount: 800000,
        description: const Value('Servicios'),
        categoryId: expenseCategory.id,
        transactionDate: DateTime(2026, 2, 15),
      ));

      // ======================
      // Verificar filtro por período - Enero
      // ======================
      final januaryTx = await transactionsDao.getTransactionsInPeriod(
        DateTime(2026, 1, 1),
        DateTime(2026, 1, 31),
      );

      expect(januaryTx.length, equals(2));

      final januaryIncome = januaryTx
          .where((t) => t.type == 'income')
          .fold<double>(0, (sum, t) => sum + t.amount);
      final januaryExpense = januaryTx
          .where((t) => t.type == 'expense')
          .fold<double>(0, (sum, t) => sum + t.amount);

      expect(januaryIncome, equals(5000000));
      expect(januaryExpense, equals(1500000));

      // ======================
      // Verificar filtro por período - Febrero
      // ======================
      final februaryTx = await transactionsDao.getTransactionsInPeriod(
        DateTime(2026, 2, 1),
        DateTime(2026, 2, 28),
      );

      expect(februaryTx.length, equals(2));

      final februaryIncome = februaryTx
          .where((t) => t.type == 'income')
          .fold<double>(0, (sum, t) => sum + t.amount);
      final februaryExpense = februaryTx
          .where((t) => t.type == 'expense')
          .fold<double>(0, (sum, t) => sum + t.amount);

      expect(februaryIncome, equals(5200000));
      expect(februaryExpense, equals(800000));

      await db.close();
    });
  });

  group('E2E: Verificación por Categoría', () {
    test('saldos por categoría son correctos', () async {
      final db = AppDatabase.forTesting(NativeDatabase.memory());
      final categoriesDao = CategoriesDao(db);
      final transactionsDao = TransactionsDao(db);

      await seedCategories(categoriesDao);
      final categories = await categoriesDao.getAllCategories();

      // Encontrar dos categorías de gasto diferentes
      final expenseCategories = categories
          .where((c) => c.type == 'expense' && c.parentId != null)
          .toList();

      final cat1 = expenseCategories[0];
      final cat2 = expenseCategories.length > 1 ? expenseCategories[1] : cat1;

      // Crear transacciones en diferentes categorías
      await transactionsDao.insertTransaction(TransactionsCompanion.insert(
        id: 'tx-cat1-001',
        type: 'expense',
        amount: 300000,
        description: const Value('Gasto cat1 - 1'),
        categoryId: cat1.id,
        transactionDate: DateTime(2026, 1, 5),
      ));

      await transactionsDao.insertTransaction(TransactionsCompanion.insert(
        id: 'tx-cat1-002',
        type: 'expense',
        amount: 200000,
        description: const Value('Gasto cat1 - 2'),
        categoryId: cat1.id,
        transactionDate: DateTime(2026, 1, 10),
      ));

      await transactionsDao.insertTransaction(TransactionsCompanion.insert(
        id: 'tx-cat2-001',
        type: 'expense',
        amount: 450000,
        description: const Value('Gasto cat2'),
        categoryId: cat2.id,
        transactionDate: DateTime(2026, 1, 15),
      ));

      // ======================
      // Verificar totales por categoría
      // ======================
      final cat1Total = await transactionsDao.getTotalByCategoryInPeriod(
        cat1.id,
        DateTime(2026, 1, 1),
        DateTime(2026, 1, 31),
      );

      expect(cat1Total, equals(500000)); // 300k + 200k

      final cat2Total = await transactionsDao.getTotalByCategoryInPeriod(
        cat2.id,
        DateTime(2026, 1, 1),
        DateTime(2026, 1, 31),
      );

      // Si cat2 == cat1, el total incluye todas las transacciones
      if (cat1.id == cat2.id) {
        expect(cat2Total, equals(950000));
      } else {
        expect(cat2Total, equals(450000));
      }

      await db.close();
    });

    test('transacciones por tipo se filtran correctamente', () async {
      final db = AppDatabase.forTesting(NativeDatabase.memory());
      final categoriesDao = CategoriesDao(db);
      final transactionsDao = TransactionsDao(db);

      await seedCategories(categoriesDao);
      final categories = await categoriesDao.getAllCategories();

      final expenseCategory = categories.firstWhere(
        (c) => c.type == 'expense' && c.parentId != null,
      );
      final incomeCategory = categories.firstWhere(
        (c) => c.type == 'income' && c.parentId != null,
      );

      // Crear transacciones de ambos tipos
      await transactionsDao.insertTransaction(TransactionsCompanion.insert(
        id: 'tx-type-001',
        type: 'income',
        amount: 2000000,
        description: const Value('Ingreso 1'),
        categoryId: incomeCategory.id,
        transactionDate: DateTime(2026, 1, 5),
      ));

      await transactionsDao.insertTransaction(TransactionsCompanion.insert(
        id: 'tx-type-002',
        type: 'expense',
        amount: 500000,
        description: const Value('Gasto 1'),
        categoryId: expenseCategory.id,
        transactionDate: DateTime(2026, 1, 10),
      ));

      await transactionsDao.insertTransaction(TransactionsCompanion.insert(
        id: 'tx-type-003',
        type: 'income',
        amount: 1000000,
        description: const Value('Ingreso 2'),
        categoryId: incomeCategory.id,
        transactionDate: DateTime(2026, 1, 15),
      ));

      // ======================
      // Filtrar por tipo
      // ======================
      final incomeTransactions = await transactionsDao.getTransactionsByType('income');
      expect(incomeTransactions.length, equals(2));

      final totalIncome = incomeTransactions.fold<double>(
        0,
        (sum, t) => sum + t.amount,
      );
      expect(totalIncome, equals(3000000));

      final expenseTransactions = await transactionsDao.getTransactionsByType('expense');
      expect(expenseTransactions.length, equals(1));
      expect(expenseTransactions.first.amount, equals(500000));

      await db.close();
    });
  });
}
