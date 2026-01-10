import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:drift/drift.dart';
import 'package:uuid/uuid.dart';

import '../../data/local/database.dart';
import '../../data/local/daos/transaction_attachments_dao.dart';
import '../services/attachment_service.dart';
import 'database_provider.dart';

part 'attachment_provider.g.dart';

/// Provider del servicio de adjuntos
@riverpod
AttachmentService attachmentService(Ref ref) {
  final service = AttachmentService();
  ref.onDispose(() => service.dispose());
  return service;
}

/// Provider del DAO de adjuntos
@riverpod
TransactionAttachmentsDao transactionAttachmentsDao(Ref ref) {
  final db = ref.watch(appDatabaseProvider);
  return TransactionAttachmentsDao(db);
}

/// Provider de adjuntos de una transacción específica (stream)
@riverpod
Stream<List<TransactionAttachment>> transactionAttachments(
  Ref ref,
  String transactionId,
) {
  final dao = ref.watch(transactionAttachmentsDaoProvider);
  return dao.watchAttachmentsForTransaction(transactionId);
}

/// Datos de un adjunto con información adicional
class AttachmentData {
  final String id;
  final String transactionId;
  final String fileName;
  final String mimeType;
  final String localPath;
  final String? remoteUrl;
  final int fileSize;
  final String? ocrText;
  final double? ocrAmount;
  final bool isSynced;
  final DateTime createdAt;

  const AttachmentData({
    required this.id,
    required this.transactionId,
    required this.fileName,
    required this.mimeType,
    required this.localPath,
    this.remoteUrl,
    required this.fileSize,
    this.ocrText,
    this.ocrAmount,
    required this.isSynced,
    required this.createdAt,
  });

  factory AttachmentData.fromEntry(TransactionAttachment entry) {
    return AttachmentData(
      id: entry.id,
      transactionId: entry.transactionId,
      fileName: entry.fileName,
      mimeType: entry.mimeType,
      localPath: entry.localPath,
      remoteUrl: entry.remoteUrl,
      fileSize: entry.fileSize,
      ocrText: entry.ocrText,
      ocrAmount: entry.ocrAmount,
      isSynced: entry.isSynced,
      createdAt: entry.createdAt,
    );
  }

  /// Formatea el tamaño del archivo para mostrar
  String get formattedSize {
    if (fileSize < 1024) return '$fileSize B';
    if (fileSize < 1024 * 1024) {
      return '${(fileSize / 1024).toStringAsFixed(1)} KB';
    }
    return '${(fileSize / (1024 * 1024)).toStringAsFixed(1)} MB';
  }

  /// Verifica si es una imagen
  bool get isImage => mimeType.startsWith('image/');
}

/// Notifier para gestionar adjuntos de transacciones
@riverpod
class AttachmentsNotifier extends _$AttachmentsNotifier {
  @override
  Future<List<AttachmentData>> build(String transactionId) async {
    final dao = ref.watch(transactionAttachmentsDaoProvider);
    final entries = await dao.getAttachmentsForTransaction(transactionId);
    return entries.map(AttachmentData.fromEntry).toList();
  }

  /// Captura una imagen desde la cámara y la agrega como adjunto
  Future<AttachmentData?> captureFromCamera({bool processOcr = true}) async {
    final service = ref.read(attachmentServiceProvider);
    final captured = await service.captureFromCamera();

    if (captured == null) return null;
    return _saveAttachment(captured, processOcr: processOcr);
  }

  /// Selecciona una imagen desde la galería y la agrega como adjunto
  Future<AttachmentData?> pickFromGallery({bool processOcr = true}) async {
    final service = ref.read(attachmentServiceProvider);
    final captured = await service.pickFromGallery();

    if (captured == null) return null;
    return _saveAttachment(captured, processOcr: processOcr);
  }

  Future<AttachmentData?> _saveAttachment(
    CapturedImage captured, {
    bool processOcr = true,
  }) async {
    final dao = ref.read(transactionAttachmentsDaoProvider);
    final service = ref.read(attachmentServiceProvider);
    final id = const Uuid().v4();

    String? ocrText;
    double? ocrAmount;

    // Procesar OCR si está habilitado
    if (processOcr && captured.mimeType.startsWith('image/')) {
      final ocrResult = await service.processWithOcr(captured.localPath);
      ocrText = ocrResult.fullText.isNotEmpty ? ocrResult.fullText : null;
      ocrAmount = ocrResult.detectedAmount;
    }

    final attachment = TransactionAttachmentsCompanion(
      id: Value(id),
      transactionId: Value(transactionId),
      fileName: Value(captured.fileName),
      mimeType: Value(captured.mimeType),
      localPath: Value(captured.localPath),
      fileSize: Value(captured.fileSize),
      ocrText: Value(ocrText),
      ocrAmount: Value(ocrAmount),
      isSynced: const Value(false),
      createdAt: Value(DateTime.now()),
    );

    await dao.insertAttachment(attachment);
    ref.invalidateSelf();

    return AttachmentData(
      id: id,
      transactionId: transactionId,
      fileName: captured.fileName,
      mimeType: captured.mimeType,
      localPath: captured.localPath,
      fileSize: captured.fileSize,
      ocrText: ocrText,
      ocrAmount: ocrAmount,
      isSynced: false,
      createdAt: DateTime.now(),
    );
  }

  /// Reprocesa OCR para un adjunto existente
  Future<OcrResult?> reprocessOcr(String attachmentId) async {
    final dao = ref.read(transactionAttachmentsDaoProvider);
    final service = ref.read(attachmentServiceProvider);

    final attachment = await dao.getAttachmentById(attachmentId);
    if (attachment == null) return null;

    final ocrResult = await service.processWithOcr(attachment.localPath);
    await dao.updateOcrData(
      attachmentId,
      ocrResult.fullText.isNotEmpty ? ocrResult.fullText : null,
      ocrResult.detectedAmount,
    );

    ref.invalidateSelf();
    return ocrResult;
  }

  /// Elimina un adjunto
  Future<void> deleteAttachment(String attachmentId) async {
    final dao = ref.read(transactionAttachmentsDaoProvider);
    final service = ref.read(attachmentServiceProvider);

    final attachment = await dao.getAttachmentById(attachmentId);
    if (attachment != null) {
      await service.deleteLocalFile(attachment.localPath);
    }

    await dao.deleteAttachment(attachmentId);
    ref.invalidateSelf();
  }

  /// Elimina todos los adjuntos de la transacción
  Future<void> deleteAllAttachments() async {
    final dao = ref.read(transactionAttachmentsDaoProvider);
    final service = ref.read(attachmentServiceProvider);

    final attachments = await dao.getAttachmentsForTransaction(transactionId);
    for (final attachment in attachments) {
      await service.deleteLocalFile(attachment.localPath);
    }

    await dao.deleteAttachmentsForTransaction(transactionId);
    ref.invalidateSelf();
  }
}

/// Provider del espacio de almacenamiento usado por adjuntos
@riverpod
Future<int> attachmentsStorageUsed(Ref ref) async {
  final service = ref.watch(attachmentServiceProvider);
  return service.getTotalStorageUsed();
}

/// Provider de adjuntos pendientes de sincronización
@riverpod
Future<List<AttachmentData>> pendingSyncAttachments(Ref ref) async {
  final dao = ref.watch(transactionAttachmentsDaoProvider);
  final entries = await dao.getPendingSyncAttachments();
  return entries.map(AttachmentData.fromEntry).toList();
}
