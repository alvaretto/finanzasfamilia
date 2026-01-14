import 'package:drift/drift.dart';
import '../database.dart';
import '../tables/transaction_attachments_table.dart';

part 'transaction_attachments_dao.g.dart';

/// DAO para gestionar los adjuntos de transacciones
@DriftAccessor(tables: [TransactionAttachments])
class TransactionAttachmentsDao extends DatabaseAccessor<AppDatabase>
    with _$TransactionAttachmentsDaoMixin {
  TransactionAttachmentsDao(super.db);

  /// Obtiene todos los adjuntos de una transacción
  Future<List<TransactionAttachment>> getAttachmentsForTransaction(
    String transactionId,
  ) {
    return (select(transactionAttachments)
          ..where((t) => t.transactionId.equals(transactionId))
          ..orderBy([(t) => OrderingTerm.desc(t.createdAt)]))
        .get();
  }

  /// Stream de adjuntos de una transacción
  Stream<List<TransactionAttachment>> watchAttachmentsForTransaction(
    String transactionId,
  ) {
    return (select(transactionAttachments)
          ..where((t) => t.transactionId.equals(transactionId))
          ..orderBy([(t) => OrderingTerm.desc(t.createdAt)]))
        .watch();
  }

  /// Obtiene un adjunto por ID
  Future<TransactionAttachment?> getAttachmentById(String id) {
    return (select(transactionAttachments)..where((t) => t.id.equals(id)))
        .getSingleOrNull();
  }

  /// Obtiene todos los adjuntos pendientes de sincronización
  Future<List<TransactionAttachment>> getPendingSyncAttachments() {
    return (select(transactionAttachments)
          ..where((t) => t.isSynced.equals(false)))
        .get();
  }

  /// Inserta un nuevo adjunto
  Future<void> insertAttachment(TransactionAttachmentsCompanion attachment) {
    return into(transactionAttachments).insert(attachment);
  }

  /// Actualiza un adjunto existente
  Future<void> updateAttachment(TransactionAttachmentsCompanion attachment) {
    return (update(transactionAttachments)
          ..where((t) => t.id.equals(attachment.id.value)))
        .write(attachment);
  }

  /// Marca un adjunto como sincronizado
  Future<void> markAsSynced(String id, String remoteUrl) {
    return (update(transactionAttachments)..where((t) => t.id.equals(id)))
        .write(TransactionAttachmentsCompanion(
      isSynced: const Value(true),
      remoteUrl: Value(remoteUrl),
    ));
  }

  /// Actualiza el texto OCR de un adjunto
  Future<void> updateOcrData(String id, String? ocrText, double? ocrAmount) {
    return (update(transactionAttachments)..where((t) => t.id.equals(id)))
        .write(TransactionAttachmentsCompanion(
      ocrText: Value(ocrText),
      ocrAmount: Value(ocrAmount),
    ));
  }

  /// Elimina un adjunto
  Future<void> deleteAttachment(String id) {
    return (delete(transactionAttachments)..where((t) => t.id.equals(id))).go();
  }

  /// Elimina todos los adjuntos de una transacción
  Future<void> deleteAttachmentsForTransaction(String transactionId) {
    return (delete(transactionAttachments)
          ..where((t) => t.transactionId.equals(transactionId)))
        .go();
  }

  /// Cuenta los adjuntos de una transacción
  Future<int> countAttachmentsForTransaction(String transactionId) async {
    final result = await (select(transactionAttachments)
          ..where((t) => t.transactionId.equals(transactionId)))
        .get();
    return result.length;
  }

  /// Obtiene todos los adjuntos con datos OCR (que tienen monto detectado)
  Future<List<TransactionAttachment>> getAttachmentsWithOcrAmount() {
    return (select(transactionAttachments)
          ..where((t) => t.ocrAmount.isNotNull()))
        .get();
  }
}
