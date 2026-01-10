import 'package:drift/drift.dart' hide isNull, isNotNull;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:uuid/uuid.dart';

import 'package:finanzas_familiares/data/local/database.dart';
import 'package:finanzas_familiares/data/local/daos/transaction_attachments_dao.dart';

void main() {
  late AppDatabase db;
  late TransactionAttachmentsDao dao;

  setUp(() {
    db = AppDatabase.forTesting(NativeDatabase.memory());
    dao = TransactionAttachmentsDao(db);
  });

  tearDown(() async {
    await db.close();
  });

  group('TransactionAttachmentsDao', () {
    Future<String> insertTestAttachment({
      String? transactionId,
      String fileName = 'test.jpg',
      String mimeType = 'image/jpeg',
      String localPath = '/path/to/test.jpg',
      int fileSize = 1024,
      String? ocrText,
      double? ocrAmount,
      bool isSynced = false,
    }) async {
      final id = const Uuid().v4();
      final txId = transactionId ?? const Uuid().v4();

      await dao.insertAttachment(TransactionAttachmentsCompanion(
        id: Value(id),
        transactionId: Value(txId),
        fileName: Value(fileName),
        mimeType: Value(mimeType),
        localPath: Value(localPath),
        fileSize: Value(fileSize),
        ocrText: Value(ocrText),
        ocrAmount: Value(ocrAmount),
        isSynced: Value(isSynced),
        createdAt: Value(DateTime.now()),
      ));
      return id;
    }

    test('insertAttachment agrega un adjunto', () async {
      final transactionId = const Uuid().v4();
      await insertTestAttachment(transactionId: transactionId);

      final result = await dao.getAttachmentsForTransaction(transactionId);
      expect(result.length, equals(1));
      expect(result.first.fileName, equals('test.jpg'));
    });

    test('getAttachmentsForTransaction retorna lista vacía si no hay adjuntos',
        () async {
      final result = await dao.getAttachmentsForTransaction('non-existent');
      expect(result, isEmpty);
    });

    test('getAttachmentById retorna el adjunto correcto', () async {
      final id = await insertTestAttachment(fileName: 'factura.pdf');

      final result = await dao.getAttachmentById(id);
      expect(result, isNotNull);
      expect(result!.fileName, equals('factura.pdf'));
    });

    test('getAttachmentById retorna null si no existe', () async {
      final result = await dao.getAttachmentById('non-existent');
      expect(result, isNull);
    });

    test('getPendingSyncAttachments retorna solo adjuntos no sincronizados',
        () async {
      final transactionId = const Uuid().v4();
      await insertTestAttachment(
        transactionId: transactionId,
        fileName: 'synced.jpg',
        isSynced: true,
      );
      await insertTestAttachment(
        transactionId: transactionId,
        fileName: 'pending.jpg',
        isSynced: false,
      );

      final result = await dao.getPendingSyncAttachments();
      expect(result.length, equals(1));
      expect(result.first.fileName, equals('pending.jpg'));
    });

    test('markAsSynced actualiza el estado de sincronización', () async {
      final id = await insertTestAttachment(isSynced: false);

      await dao.markAsSynced(id, 'https://storage.example.com/file.jpg');

      final result = await dao.getAttachmentById(id);
      expect(result!.isSynced, isTrue);
      expect(result.remoteUrl, equals('https://storage.example.com/file.jpg'));
    });

    test('updateOcrData actualiza texto y monto OCR', () async {
      final id = await insertTestAttachment();

      await dao.updateOcrData(id, 'Total: \$50.000', 50000);

      final result = await dao.getAttachmentById(id);
      expect(result!.ocrText, equals('Total: \$50.000'));
      expect(result.ocrAmount, equals(50000));
    });

    test('deleteAttachment elimina el adjunto', () async {
      final transactionId = const Uuid().v4();
      final id = await insertTestAttachment(transactionId: transactionId);

      expect(
        (await dao.getAttachmentsForTransaction(transactionId)).length,
        equals(1),
      );

      await dao.deleteAttachment(id);

      expect(
        (await dao.getAttachmentsForTransaction(transactionId)).length,
        equals(0),
      );
    });

    test('deleteAttachmentsForTransaction elimina todos los adjuntos', () async {
      final transactionId = const Uuid().v4();
      await insertTestAttachment(
          transactionId: transactionId, fileName: 'a.jpg');
      await insertTestAttachment(
          transactionId: transactionId, fileName: 'b.jpg');
      await insertTestAttachment(
          transactionId: transactionId, fileName: 'c.jpg');

      expect(
        (await dao.getAttachmentsForTransaction(transactionId)).length,
        equals(3),
      );

      await dao.deleteAttachmentsForTransaction(transactionId);

      expect(
        (await dao.getAttachmentsForTransaction(transactionId)).length,
        equals(0),
      );
    });

    test('countAttachmentsForTransaction cuenta correctamente', () async {
      final transactionId = const Uuid().v4();
      await insertTestAttachment(transactionId: transactionId);
      await insertTestAttachment(transactionId: transactionId);

      final count = await dao.countAttachmentsForTransaction(transactionId);
      expect(count, equals(2));
    });

    test('getAttachmentsWithOcrAmount retorna solo adjuntos con monto OCR',
        () async {
      await insertTestAttachment(ocrAmount: 50000);
      await insertTestAttachment(ocrAmount: null);
      await insertTestAttachment(ocrAmount: 75000);

      final result = await dao.getAttachmentsWithOcrAmount();
      expect(result.length, equals(2));
    });

    test('watchAttachmentsForTransaction emite cambios', () async {
      final transactionId = const Uuid().v4();
      final stream = dao.watchAttachmentsForTransaction(transactionId);

      final firstValue = await stream.first;
      expect(firstValue, isEmpty);
    });

    test('múltiples adjuntos para diferentes transacciones', () async {
      final tx1 = const Uuid().v4();
      final tx2 = const Uuid().v4();

      await insertTestAttachment(transactionId: tx1, fileName: 'tx1-a.jpg');
      await insertTestAttachment(transactionId: tx1, fileName: 'tx1-b.jpg');
      await insertTestAttachment(transactionId: tx2, fileName: 'tx2-a.jpg');

      final resultTx1 = await dao.getAttachmentsForTransaction(tx1);
      final resultTx2 = await dao.getAttachmentsForTransaction(tx2);

      expect(resultTx1.length, equals(2));
      expect(resultTx2.length, equals(1));
    });
  });
}
