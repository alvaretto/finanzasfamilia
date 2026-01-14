import 'package:drift/drift.dart' hide isNull, isNotNull;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:uuid/uuid.dart';

import 'package:finanzas_familiares/data/local/database.dart';
import 'package:finanzas_familiares/data/local/daos/transaction_details_dao.dart';

void main() {
  late AppDatabase db;
  late TransactionDetailsDao dao;
  const uuid = Uuid();
  late String transactionId;
  late String categoryId;

  setUp(() async {
    db = AppDatabase.forTesting(NativeDatabase.memory());
    dao = TransactionDetailsDao(db);

    // Crear datos base para foreign keys
    categoryId = uuid.v4();
    transactionId = uuid.v4();
    final accountId = uuid.v4();

    // Insertar categoría
    await db.into(db.categories).insert(CategoriesCompanion(
          id: Value(categoryId),
          name: const Value('Alimentación'),
          type: const Value('expense'),
          level: const Value(1),
          createdAt: Value(DateTime.now()),
          updatedAt: Value(DateTime.now()),
        ));

    // Insertar cuenta
    await db.into(db.accounts).insert(AccountsCompanion(
          id: Value(accountId),
          name: const Value('Nequi'),
          categoryId: Value(categoryId),
          balance: const Value(1000000),
          createdAt: Value(DateTime.now()),
          updatedAt: Value(DateTime.now()),
        ));

    // Insertar transacción
    await db.into(db.transactions).insert(TransactionsCompanion(
          id: Value(transactionId),
          type: const Value('expense'),
          amount: const Value(50000),
          transactionDate: Value(DateTime.now()),
          categoryId: Value(categoryId),
          fromAccountId: Value(accountId),
          createdAt: Value(DateTime.now()),
          updatedAt: Value(DateTime.now()),
        ));
  });

  tearDown(() async {
    await db.close();
  });

  group('TransactionDetailsDao - CRUD', () {
    test('insertDetail crea un detalle correctamente', () async {
      final detailId = uuid.v4();
      await dao.insertDetail(TransactionDetailsCompanion(
        id: Value(detailId),
        transactionId: Value(transactionId),
        concept: const Value('Arroz'),
        categoryId: Value(categoryId),
        unitValue: const Value(5000),
        quantity: const Value(2),
        totalValue: const Value(10000),
        createdAt: Value(DateTime.now()),
        updatedAt: Value(DateTime.now()),
      ));

      final detail = await dao.getDetailById(detailId);
      expect(detail, isNotNull);
      expect(detail!.concept, equals('Arroz'));
      expect(detail.unitValue, equals(5000));
      expect(detail.quantity, equals(2));
      expect(detail.totalValue, equals(10000));
    });

    test('insertDetails inserta múltiples detalles', () async {
      final details = List.generate(
        5,
        (i) => TransactionDetailsCompanion(
          id: Value(uuid.v4()),
          transactionId: Value(transactionId),
          concept: Value('Item $i'),
          categoryId: Value(categoryId),
          unitValue: Value((i + 1) * 1000.0),
          quantity: const Value(1),
          totalValue: Value((i + 1) * 1000.0),
          sortOrder: Value(i),
          createdAt: Value(DateTime.now()),
          updatedAt: Value(DateTime.now()),
        ),
      );

      await dao.insertDetails(details);
      final result = await dao.getDetailsByTransaction(transactionId);

      expect(result, hasLength(5));
    });

    test('getDetailsByTransaction retorna ordenado por sortOrder', () async {
      await dao.insertDetails([
        TransactionDetailsCompanion(
          id: Value(uuid.v4()),
          transactionId: Value(transactionId),
          concept: const Value('Tercero'),
          categoryId: Value(categoryId),
          unitValue: const Value(1000),
          quantity: const Value(1),
          totalValue: const Value(1000),
          sortOrder: const Value(2),
          createdAt: Value(DateTime.now()),
          updatedAt: Value(DateTime.now()),
        ),
        TransactionDetailsCompanion(
          id: Value(uuid.v4()),
          transactionId: Value(transactionId),
          concept: const Value('Primero'),
          categoryId: Value(categoryId),
          unitValue: const Value(1000),
          quantity: const Value(1),
          totalValue: const Value(1000),
          sortOrder: const Value(0),
          createdAt: Value(DateTime.now()),
          updatedAt: Value(DateTime.now()),
        ),
        TransactionDetailsCompanion(
          id: Value(uuid.v4()),
          transactionId: Value(transactionId),
          concept: const Value('Segundo'),
          categoryId: Value(categoryId),
          unitValue: const Value(1000),
          quantity: const Value(1),
          totalValue: const Value(1000),
          sortOrder: const Value(1),
          createdAt: Value(DateTime.now()),
          updatedAt: Value(DateTime.now()),
        ),
      ]);

      final result = await dao.getDetailsByTransaction(transactionId);

      expect(result[0].concept, equals('Primero'));
      expect(result[1].concept, equals('Segundo'));
      expect(result[2].concept, equals('Tercero'));
    });

    test('getDetailById retorna null para ID inexistente', () async {
      final result = await dao.getDetailById('non-existent');
      expect(result, isNull);
    });

    test('updateDetail actualiza correctamente', () async {
      final detailId = uuid.v4();
      await dao.insertDetail(TransactionDetailsCompanion(
        id: Value(detailId),
        transactionId: Value(transactionId),
        concept: const Value('Original'),
        categoryId: Value(categoryId),
        unitValue: const Value(1000),
        quantity: const Value(1),
        totalValue: const Value(1000),
        createdAt: Value(DateTime.now()),
        updatedAt: Value(DateTime.now()),
      ));

      final original = await dao.getDetailById(detailId);
      final updated = TransactionDetailEntry(
        id: original!.id,
        transactionId: original.transactionId,
        concept: 'Actualizado',
        categoryId: original.categoryId,
        unitValue: 2000,
        quantity: 3,
        totalValue: 6000,
        mode: original.mode,
        discount: original.discount,
        sortOrder: original.sortOrder,
        createdAt: original.createdAt,
        updatedAt: DateTime.now(),
      );

      await dao.updateDetail(updated);
      final result = await dao.getDetailById(detailId);

      expect(result!.concept, equals('Actualizado'));
      expect(result.unitValue, equals(2000));
      expect(result.quantity, equals(3));
      expect(result.totalValue, equals(6000));
    });

    test('deleteDetail elimina un detalle', () async {
      final detailId = uuid.v4();
      await dao.insertDetail(TransactionDetailsCompanion(
        id: Value(detailId),
        transactionId: Value(transactionId),
        concept: const Value('A eliminar'),
        categoryId: Value(categoryId),
        unitValue: const Value(1000),
        quantity: const Value(1),
        totalValue: const Value(1000),
        createdAt: Value(DateTime.now()),
        updatedAt: Value(DateTime.now()),
      ));

      final count = await dao.deleteDetail(detailId);
      expect(count, equals(1));

      final result = await dao.getDetailById(detailId);
      expect(result, isNull);
    });

    test('deleteDetailsByTransaction elimina todos los detalles', () async {
      await dao.insertDetails([
        TransactionDetailsCompanion(
          id: Value(uuid.v4()),
          transactionId: Value(transactionId),
          concept: const Value('Item 1'),
          categoryId: Value(categoryId),
          unitValue: const Value(1000),
          quantity: const Value(1),
          totalValue: const Value(1000),
          createdAt: Value(DateTime.now()),
          updatedAt: Value(DateTime.now()),
        ),
        TransactionDetailsCompanion(
          id: Value(uuid.v4()),
          transactionId: Value(transactionId),
          concept: const Value('Item 2'),
          categoryId: Value(categoryId),
          unitValue: const Value(2000),
          quantity: const Value(1),
          totalValue: const Value(2000),
          createdAt: Value(DateTime.now()),
          updatedAt: Value(DateTime.now()),
        ),
      ]);

      final count = await dao.deleteDetailsByTransaction(transactionId);
      expect(count, equals(2));

      final result = await dao.getDetailsByTransaction(transactionId);
      expect(result, isEmpty);
    });
  });

  group('TransactionDetailsDao - Agregaciones', () {
    test('getTransactionTotal calcula suma de totalValue', () async {
      await dao.insertDetails([
        TransactionDetailsCompanion(
          id: Value(uuid.v4()),
          transactionId: Value(transactionId),
          concept: const Value('Item 1'),
          categoryId: Value(categoryId),
          unitValue: const Value(10000),
          quantity: const Value(1),
          totalValue: const Value(10000),
          createdAt: Value(DateTime.now()),
          updatedAt: Value(DateTime.now()),
        ),
        TransactionDetailsCompanion(
          id: Value(uuid.v4()),
          transactionId: Value(transactionId),
          concept: const Value('Item 2'),
          categoryId: Value(categoryId),
          unitValue: const Value(5000),
          quantity: const Value(3),
          totalValue: const Value(15000),
          createdAt: Value(DateTime.now()),
          updatedAt: Value(DateTime.now()),
        ),
      ]);

      final total = await dao.getTransactionTotal(transactionId);
      expect(total, equals(25000));
    });

    test('getTransactionTotal retorna 0 si no hay detalles', () async {
      final total = await dao.getTransactionTotal(transactionId);
      expect(total, equals(0));
    });

    test('getItemCount cuenta items correctamente', () async {
      await dao.insertDetails([
        TransactionDetailsCompanion(
          id: Value(uuid.v4()),
          transactionId: Value(transactionId),
          concept: const Value('Item 1'),
          categoryId: Value(categoryId),
          unitValue: const Value(1000),
          quantity: const Value(1),
          totalValue: const Value(1000),
          createdAt: Value(DateTime.now()),
          updatedAt: Value(DateTime.now()),
        ),
        TransactionDetailsCompanion(
          id: Value(uuid.v4()),
          transactionId: Value(transactionId),
          concept: const Value('Item 2'),
          categoryId: Value(categoryId),
          unitValue: const Value(1000),
          quantity: const Value(1),
          totalValue: const Value(1000),
          createdAt: Value(DateTime.now()),
          updatedAt: Value(DateTime.now()),
        ),
        TransactionDetailsCompanion(
          id: Value(uuid.v4()),
          transactionId: Value(transactionId),
          concept: const Value('Item 3'),
          categoryId: Value(categoryId),
          unitValue: const Value(1000),
          quantity: const Value(1),
          totalValue: const Value(1000),
          createdAt: Value(DateTime.now()),
          updatedAt: Value(DateTime.now()),
        ),
      ]);

      final count = await dao.getItemCount(transactionId);
      expect(count, equals(3));
    });

    test('getItemCount retorna 0 si no hay detalles', () async {
      final count = await dao.getItemCount(transactionId);
      expect(count, equals(0));
    });
  });

  group('TransactionDetailsDao - Consultas por Categoría', () {
    test('getDetailsByCategoryInPeriod filtra por categoría y período', () async {
      final now = DateTime.now();
      final startDate = DateTime(now.year, now.month, 1);
      final endDate = DateTime(now.year, now.month + 1, 0);

      await dao.insertDetails([
        TransactionDetailsCompanion(
          id: Value(uuid.v4()),
          transactionId: Value(transactionId),
          concept: const Value('Dentro del período'),
          categoryId: Value(categoryId),
          unitValue: const Value(1000),
          quantity: const Value(1),
          totalValue: const Value(1000),
          createdAt: Value(now),
          updatedAt: Value(now),
        ),
      ]);

      final result = await dao.getDetailsByCategoryInPeriod(
        categoryId,
        startDate,
        endDate,
      );

      expect(result, hasLength(1));
      expect(result.first.concept, equals('Dentro del período'));
    });

    test('getTotalByCategoryInPeriod suma valores en período', () async {
      final now = DateTime.now();
      final startDate = DateTime(now.year, now.month, 1);
      final endDate = DateTime(now.year, now.month + 1, 0);

      await dao.insertDetails([
        TransactionDetailsCompanion(
          id: Value(uuid.v4()),
          transactionId: Value(transactionId),
          concept: const Value('Item 1'),
          categoryId: Value(categoryId),
          unitValue: const Value(5000),
          quantity: const Value(1),
          totalValue: const Value(5000),
          createdAt: Value(now),
          updatedAt: Value(now),
        ),
        TransactionDetailsCompanion(
          id: Value(uuid.v4()),
          transactionId: Value(transactionId),
          concept: const Value('Item 2'),
          categoryId: Value(categoryId),
          unitValue: const Value(3000),
          quantity: const Value(2),
          totalValue: const Value(6000),
          createdAt: Value(now),
          updatedAt: Value(now),
        ),
      ]);

      final total = await dao.getTotalByCategoryInPeriod(
        categoryId,
        startDate,
        endDate,
      );

      expect(total, equals(11000));
    });

    test('getTotalByCategoryInPeriod retorna 0 para categoría sin detalles',
        () async {
      final now = DateTime.now();
      final total = await dao.getTotalByCategoryInPeriod(
        'non-existent-category',
        DateTime(now.year, now.month, 1),
        DateTime(now.year, now.month + 1, 0),
      );

      expect(total, equals(0));
    });
  });
}
