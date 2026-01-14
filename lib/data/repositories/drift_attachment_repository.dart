import 'package:drift/drift.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../domain/repositories/attachment_repository.dart';
import '../local/daos/transaction_attachments_dao.dart';
import '../local/database.dart';

/// Implementación Drift del repositorio de adjuntos.
class DriftAttachmentRepository implements AttachmentRepository {
  final TransactionAttachmentsDao _dao;

  DriftAttachmentRepository(this._dao);

  /// Obtiene el userId del usuario autenticado actual
  /// Retorna null si Supabase no está inicializado (en tests)
  String? get _currentUserId {
    try {
      return Supabase.instance.client.auth.currentUser?.id;
    } catch (_) {
      return null;
    }
  }

  @override
  Future<List<AttachmentData>> getAttachmentsForTransaction(
    String transactionId,
  ) async {
    final entries = await _dao.getAttachmentsForTransaction(transactionId);
    return entries.map(_toData).toList();
  }

  @override
  Future<AttachmentData?> getAttachmentById(String id) async {
    final entry = await _dao.getAttachmentById(id);
    return entry != null ? _toData(entry) : null;
  }

  @override
  Future<List<AttachmentData>> getPendingSyncAttachments() async {
    final entries = await _dao.getPendingSyncAttachments();
    return entries.map(_toData).toList();
  }

  @override
  Future<void> insertAttachment(String id, CreateAttachmentData data) async {
    await _dao.insertAttachment(TransactionAttachmentsCompanion(
      id: Value(id),
      userId: Value(_currentUserId),
      transactionId: Value(data.transactionId),
      fileName: Value(data.fileName),
      mimeType: Value(data.mimeType),
      localPath: Value(data.localPath),
      fileSize: Value(data.fileSize),
      ocrText: Value(data.ocrText),
      ocrAmount: Value(data.ocrAmount),
      isSynced: const Value(false),
      createdAt: Value(DateTime.now()),
    ));
  }

  @override
  Future<void> updateOcrData(
    String id,
    String? ocrText,
    double? ocrAmount,
  ) async {
    await _dao.updateOcrData(id, ocrText, ocrAmount);
  }

  @override
  Future<void> markAsSynced(String id, String remoteUrl) async {
    await _dao.markAsSynced(id, remoteUrl);
  }

  @override
  Future<void> deleteAttachment(String id) async {
    await _dao.deleteAttachment(id);
  }

  @override
  Future<void> deleteAttachmentsForTransaction(String transactionId) async {
    await _dao.deleteAttachmentsForTransaction(transactionId);
  }

  @override
  Stream<List<AttachmentData>> watchAttachmentsForTransaction(
    String transactionId,
  ) {
    return _dao
        .watchAttachmentsForTransaction(transactionId)
        .map((entries) => entries.map(_toData).toList());
  }

  @override
  Future<int> getTotalStorageUsed() async {
    // La implementación real está en el servicio de archivos.
    // El repositorio no tiene acceso directo al sistema de archivos.
    return 0;
  }

  AttachmentData _toData(TransactionAttachment entry) => AttachmentData(
        id: entry.id,
        transactionId: entry.transactionId,
        fileName: entry.fileName,
        mimeType: entry.mimeType,
        localPath: entry.localPath,
        remoteUrl: entry.remoteUrl,
        fileSize: entry.fileSize,
        ocrText: entry.ocrText,
        ocrAmount: entry.ocrAmount,
        isSynced: entry.isSynced ?? false,
        createdAt: entry.createdAt,
      );
}
